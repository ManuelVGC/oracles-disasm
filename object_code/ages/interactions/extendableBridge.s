; ==================================================================================================
; INTERAC_EXTENDABLE_BRIDGE
; ==================================================================================================
interactionCode23:
	ld e,Interaction.state
	ld a,(de)
	rst_jumpTable
	.dw @state0 ;inicialización
	.dw @state1 ;espera a que el bit de wSwitchState cambie para crear el puente
	.dw @state2 ;espera a que el bit de wSwitchState cambie para eliminar el puente

; usa el subid para indicar el bit que nos importa de wSwitchState. Checkea si el tile donde está la interacción es un tile de puente y si lo es pasa a state2 y si no
; pasa a state1.
@state0:
	ld e,Interaction.subid
	ld a,(de)
	ld b,a ; b = subid
	and $07 ;se queda con los últimos tres bits
	ld hl,bitTable
	add l ;sumas a a l
	ld l,a ;y apuntas al elemento de bitTable especificado por el subid. La tabla tiene 8 entradas, con cada una un bit activado distinto (0000 0001, 0000 0010, ...)
	ld a,(hl) ;cargas el bitmask correspondiente en a. 
	inc e
	ld (de),a ; [var03] = bitmask corresponding to [subid].
	;el bit que se usa como comprobador se especifica con el subid

	; Check whether the tile here is a bridge; go to state 2 if so, state 1 otherwise
	ld e,Interaction.yh
	ld a,(de) 
	ld c,a ; c = Y de la interacción
	ld b,>wRoomLayout

	ld a,(bc) ;checkea si el tile que está en Y es un tile de puente
	sub TILEINDEX_VERTICAL_BRIDGE
	sub $06

	ld a,$02 ;asumimos que el tile es un tile de puente así que a = 2.
	jr c,+ ; si el tile era efectivamente de puente salta a +
	dec a ;sino era puente a = 1.
+
	ld e,Interaction.state
	ld (de),a ;se cambia al state determinado por a
	ld e,Interaction.var30
	ld a,(wSwitchState)
	ld (de),a ;var30 = wSwitchState
	ret

; State 1: waiting for switch to toggle to create bridge.
; Crea tileindex de puente en los tiles indicados en la tabla bridgeCreationData, a la cual apuntamos a una de las filas con la X de la interacción.
@state1:
	ld e,Interaction.substate
	ld a,(de)
	rst_jumpTable
	.dw @state1Substate0
	.dw @state1Substate1

@state1Substate0:
	call @checkSwitchStateChanged
	ret z ; si el bit que nos importa de wSwitchState no ha cambiado, sale.
	ld hl,@bridgeCreationData 

; lee los tiles que se deberán modificar dependiendo de la X de la interacción y apunta al primero. Además, settea un contador para que no se creen todos de golpe y un valor
; que indica porque posición de la lista de tiles vamos leyendo
@startLoadingBridgeData:
	ld e,Interaction.var30
	ld a,(wSwitchState)
	ld (de),a ; var30 = wSwitchState. Guarda el nuevo estado del wSwitchState para comparar luego si vuelve a cambiar o no.

	ld e,Interaction.xh
	ld a,(de)
	rst_addDoubleIndex ;dependiendo de la X de la interacción elige una de las listas de tiles de creación del puente
	ldi a,(hl)
	ld h,(hl)
	ld l,a

	ldi a,(hl)
	ld e,Interaction.var31 
	ld (de),a ;se lee el primer tile de la lista y se guarda en var31
	ld e,Interaction.relatedObj2 ;relatedObj2 se usa para guardar la dirección actual en la lista de tiles que estamos leyendo.
	ld a,l
	ld (de),a
	inc e
	ld a,h
	ld (de),a

	;se usa un contador para que los tiles vayan apareciendo poco a poco y no todos de golpe
	ld a,$0a
	ld e,Interaction.counter1
	ld (de),a
	jp interactionIncSubstate

; se van creando los tiles del puente en los tiles indicados en la tabla
@state1Substate1:
	call interactionDecCounter1
	ret nz 
	ld (hl),$0a
	call @updateNextTile
	ld a,c
	inc a
	jr z,@gotoNextState
	ld e,Interaction.var31
	ld a,(de)
	call setTile
	ld a,SND_DOORCLOSE
	jp playSound

@gotoNextState:
	call interactionIncState
	inc l
	ld (hl),$00
	ret

; State 2: waiting for switch to toggle to remove bridge.
; Igual que el state1 pero borra los tiles indicados en la posición de la tabla que indicas con la X de la interacción.
@state2:
	ld e,Interaction.substate
	ld a,(de)
	rst_jumpTable
	.dw @state2Substate0
	.dw @state2Substate1

@state2Substate0:
	call @checkSwitchStateChanged
	ret z 
	ld hl,@bridgeRemovalData 
	jr @startLoadingBridgeData

@state2Substate1:
	call interactionDecCounter1
	ret nz
	ld (hl),$0a

	call @updateNextTile
	ld a,c
	inc a
	jr z,@gotoState1
	ld e,Interaction.var31
	ld a,(de)
	call setTile
	ld a,SND_DOORCLOSE
	jp playSound

@gotoState1:
	ld h,d
	ld l,Interaction.state
	ld (hl),$01
	inc l
	ld (hl),$00
	ret

;;
; @param[out]	zflag	nz if the switch has been toggled
; Devuelve 0 en caso de que el bit que nos importa del wSwitchState no haya cambiado. Es decir, Z = 1 si no ha cambiado el bit que nos interesa en wSwitchState.
@checkSwitchStateChanged:
	ld a,(wSwitchState)
	ld b,a ;b = wSwitchState
	ld e,Interaction.var30
	ld a,(de) ; a = var30
	xor b ; a = a xor b, que tendrá en 1 los bits que hayan cambiado
	ld b,a ; b = a xor b
	ld e,Interaction.var03 
	ld a,(de) ; a = bitmask
	and b ; a and b = 0 si el bit de la bitmask que nos importa no ha cambiado (1 el bit del resultado del XOR indica que ha cambiado pero al hacer un AND con
	; el bitmask, si ese bit no está marcado en el bitmask y por tanto no nos interesa 1 AND 0 = 0).
	ret

;;
; @param[out]	c	Next byte
@updateNextTile:
	ld h,d
	ld l,Interaction.relatedObj2
	ld e,l
	ldi a,(hl)
	ld h,(hl)
	ld l,a

	ldi a,(hl)
	ld c,a

	ld a,l
	ld (de),a
	inc e
	ld a,h
	ld (de),a
	ret


; Which data is read from here depends on the value of "Interaction.xh".
@bridgeCreationData:
	.dw @creation0
	.dw @creation1
	.dw @creation2
	.dw @creation3
	.dw @creation4
	.dw @creation5
	.dw @creation6

; Data format:
;   First byte is the tile index to create for the bridge.
;   Subsequent bytes are positions at which to create that tile until it reaches $ff.

@creation0:
	.db TILEINDEX_VERTICAL_BRIDGE   $43 $53 $63 $ff
@creation1:
	.db TILEINDEX_HORIZONTAL_BRIDGE $76 $77 $78 $79 $ff
@creation2:
	.db TILEINDEX_HORIZONTAL_BRIDGE $39 $38 $37 $36 $ff
@creation3:
	.db TILEINDEX_VERTICAL_BRIDGE   $42 $52 $62 $ff
@creation4:
	.db TILEINDEX_VERTICAL_BRIDGE   $4c $5c $6c $ff
@creation5:
	.db TILEINDEX_HORIZONTAL_BRIDGE $2a $29 $28 $27 $ff
@creation6:
	.db TILEINDEX_VERTICAL_BRIDGE   $3d $4d $5d $6d $ff


@bridgeRemovalData:
	.dw @removal0
	.dw @removal1
	.dw @removal2
	.dw @removal3
	.dw @removal4
	.dw @removal5
	.dw @removal6

; Data format is the same as above.
; TILEINDEX_HOLE+1 is a hole that's completely black (doesn't have "ground" surrounding
; it.)

@removal0:
	.db TILEINDEX_HOLE+1  $63 $53 $43 $ff
@removal1:
	.db TILEINDEX_HOLE+1  $79 $78 $77 $76 $ff
@removal2:
	.db TILEINDEX_HOLE+1  $36 $37 $38 $39 $ff
@removal3:
	.db TILEINDEX_HOLE+1  $62 $52 $42 $ff
@removal4:
	.db TILEINDEX_HOLE+1  $6c $5c $4c $ff
@removal5:
	.db TILEINDEX_HOLE+1  $27 $28 $29 $2a $ff
@removal6:
	.db TILEINDEX_HOLE+1  $6d $5d $4d $3d $ff
