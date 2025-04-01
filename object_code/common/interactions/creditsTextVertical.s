; ==================================================================================================
; INTERAC_CREDITS_TEXT_VERTICAL
;
; Variables:
;   var30/var31: 16-bit counter?
; ==================================================================================================
interactionCodeaf:
	ld e,Interaction.state
	ld a,(de)
	rst_jumpTable
	.dw @state0
	.dw @state1

;si el subid = 0 (es el padre) se carga la coordenada Y correspondiente y se almacena en var30 (se usará como contador). Además se establece una
;velocidad de desplazamiento.
;si subid = 1 (es un hijo) directamente se salta a establecer la velocidad de desplazamiento.
@state0:
	ld a,$01
	ld (de),a ; [state]. Cambia el valor del state a 1.
	ld e,Interaction.subid
	ld a,(de)
	or a
	jr nz,+ ;si el subID es 0 sigue si no salta a +
	ld hl,@data_66bc ;carga una tabla de datos de coordenadas
	jp @storeVar30Value ;almacena el valor de var30 y var31
+
	ld h,d
	ld l,Interaction.speed
	ld (hl),SPEED_80 ;establece una velocidad de desplazamiento vertical
	ret

; si el subid = 0 (es el padre) y ya no hay fade activo, espera 32 frames (primera línea de data_66bc) y luego spawnea un hijo. Cuando ya no queden más
; hijos cambia cfcf a ff, indicando que han terminado los créditos verticales.
; si el subid = 1 (es un hijo) se salta a @subid1
@state1:
	ld e,Interaction.subid
	ld a,(de)
	or a
	jr nz,@subid1 ;si el subID es distinto de 0, salta a subID1

	ld a,(wPaletteThread_mode)
	or a
	ret nz ;si no hay fade activo, el código sigue

	ld h,d ;byte alto del subID, 0 entiendo
	ld l,Interaction.var30 ;hl vale al final var30
	call decHlRef16WithCap ;se reduce el valor de var30 hasta que llega a 0
	ret nz

	call @spawnChild ;cuando el contador llega a 0 spawnea un objeto hijo
	ld e,Interaction.var30 ;e = byte bajo de var30, véase si por ejemplo fuese la primera línea de data_66bc sería 0x20
	ld a,(de) ;carga en a el valor de var30 (d = 0x00 de antes). Si por ejemplo var30 fuese la primera línea de data_66bc, a aquí sería 0x0020
	inc a ;incrementa a
	ret nz ;mientras que sea != 0 retorna. Esto ocurre cuando haces inc a y el valor de a es ff, es decir, cuando se llegue al final de la tabla
	;data_66bc.

.ifdef ROM_AGES
	ld hl,wTmpcfc0.genericCutscene.cfdf
	ld (hl),$ff ;cuando terminan de mostrarse los créditos pone cfdf a ff
.else
	ld hl,wTmpcfc0.genericCutscene.cfde 
	ld (hl),$01
.endif

	jp interactionDelete ;una vez que terminan los créditos borra la interacción padre

;crea un nuevo objeto interacción con subID1 y apunta a la siguiente posición de la tabla data_66bc
@spawnChild:
	call getFreeInteractionSlot ;mira si hay un espacio libre para una interacción
	jr nz,++ ;si hay un espacio libre para la interacción, sigue el código
	ld (hl),INTERAC_CREDITS_TEXT_VERTICAL ;se carga esta misma interacción
	inc l ;apunta al subid del hijo
	ld (hl),$01 ; [child.subid] = 1. Se carga esta interacción pero con el subID1.
	inc l
	ld e,Interaction.counter1
	ld a,(de)
	ld (hl),a ; [child.var03] Carga counter1 en var03 del hijo
	call objectCopyPosition 
++
	ld h,d 
	ld l,Interaction.counter1 ;vuelve a cargar en hl el counter1
	inc (hl) ;suma uno al counter1
	ld a,(hl) ;a = counter1 + 1
	ld hl,@data_66bc ;se carga la siguiente fila de la tabla, es decir, el siguiente hijo. 
	rst_addDoubleIndex ;se recorre la tabla con el valor de a 

; pone en var30 el valor de la tabla que se le pase
@storeVar30Value:
	ldi a,(hl) ;a = (hl) y luego incrementa el puntero hl, apuntando al byte alto de la línea de la tabla a la que se estaba apuntando.
	;hl al principio apunta al byte bajo de la línea de la tabla a que se está apuntando (0x20 en el caso de la primera línea por ejemplo)
	ld e,Interaction.var30 ;carga en e la dirección de var30
	ld (de),a ;carga en var30 el valor a
	inc e ;apunta a var31
	ldi a,(hl) ;carga a = (hl) y luego incrementa el puntero hl. En este caso a será igual al byte alto de la línea correspondiente (0x00 para el
	;caso de la primera línea de la tabla por ejemplo)
	ld (de),a ;carga var31 = a
	ret

; si no hay fade activo, se aplica una velocidad al texto hacia arriba y cuando llega arriba del todo se borra.
@subid1:
	ld a,(wPaletteThread_mode)
	or a
	ret nz ;si no hay fade activo, sigue el código
	call objectApplySpeed ;aplica la velocidad

	;cuando la y = 0 (ha llegado arriba de la pantalla), se elimina el objeto
	ld h,d
	ld l,Interaction.yh 
	ldi a,(hl)
	ld b,a
	or a
	jp z,interactionDelete

	inc l
	ld c,(hl) ; [xh]
	jp interactionFunc_3e6d ;de aquí es de donde se saca el texto a mostrar

; esta tabla almacena coordenadas Y para la posición de cada línea de los créditos. Los valores indican dónde comienza el texto en pantalla. $ff indica
; el final de la tabla.
@data_66bc:
.ifdef ROM_AGES

.ifdef REGION_JP
	.dw $0020
	.dw $00e0
	.dw $0120
	.dw $0110
	.dw $00e0
	.dw $0160
	.dw $00e0
	.dw $0100
	.dw $0140
	.dw $0150
	.dw $0130
	.dw $0180
	.db $ff
.else ; REGION_US
	.dw $0020
	.dw $00e0
	.dw $0120
	.dw $0110
	.dw $00f0
	.dw $0160
	.dw $00f0
	.dw $0120
	.dw $0170
	.dw $0150
	.dw $0160
	.dw $0140
	.dw $0140
	.dw $0160
	.dw $0110
	.dw $0160
	.dw $01a0
	.db $ff
.endif

.else ;ROM_SEASONS
	.dw $0020
	.dw $00e0
	.dw $0120
	.dw $0110
	.dw $00f0
	.dw $0160
	.dw $00f0
	.dw $0120
	.dw $0170
	.dw $0170
	.dw $0160
	.dw $0140
	.dw $0150
	.dw $0110
	.dw $0160
	.dw $01a0
	.db $ff
.endif
