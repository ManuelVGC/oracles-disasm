; ==================================================================================================
; INTERAC_SLATE_SLOT
;
; Variables:
;   var3f: Counter to push against this object until the slate will be placed
; ==================================================================================================
interactionCodedb:
	ld e,Interaction.state
	ld a,(de)
	rst_jumpTable
	.dw @state0
	.dw @state1
	.dw @state2

@state0:
	; Check if slate already placed
	ld e,Interaction.subid
	ld a,(de) ; a = subid
	ld bc,bitTable 
	add c ; a = a + c
	ld c,a ; c = subid + c
	call getThisRoomFlags
	ld a,(bc) ; valor de bitTable correspondiente a la tablilla en cuestión obtenido usando el subid de la tablilla, por ejemplo, el subid 0 corresponde con
	; 0000 0001 y el subid 1 con el 0000 0010.
	and (hl)
	jp nz,interactionDelete ; si el bit de roomflags correspondiente a la tablilla en cuestión (indicado usando un valor de bitTable) es 1, entonces es que
	; ya está colocada la tablilla y se puede eliminar la interacción.

	
	ld hl,mainScripts.slateSlotScript
	call interactionSetScript ;carga el script del texto de "parece que algo va en este hueco"
	jp interactionIncState

@state1:
	call objectCheckCollidedWithLink_notDead
	call nc,@resetCounter
	call objectCheckLinkPushingAgainstCenter ;chequea si Link está empujando bien hacia el centro para colocar la tablilla (que no sea un simple roce,
	; para poner la tablilla tienes que empujar en esa dirección bien).
	call nc,@resetCounter

	ld h,d
	ld l,Interaction.var3f
	dec (hl)
	jr nz,@state2 ;decrementa el contador var3f que dictamina el tiempo que hay que estar empujando apara que se coloque la tablilla.
	; Si no empujas lo suficiente, salta a state2, que en este caso muestra el texto de "algo va en este hueco"

	; Time to place the slate, if available
	ld a,(wNumSlates)
	or a
	jr nz,@placeSlate ; si tienes tablillas para poner, salta a placeState

	; Not enough slates
	ld bc,TX_5111
	call showText ;si no tienes tablillas para poner, muestra el texto de "algo va en este hueco"

@resetCounter:
	ld e,Interaction.var3f
	ld a,$0a
	ld (de),a
	ret

@placeSlate:
	call checkLinkVulnerable
	jr nc,@resetCounter

	ld a,DISABLE_ALL_BUT_INTERACTIONS | DISABLE_LINK
	ld (wDisabledObjects),a
	ld (wMenuDisabled),a

	ld hl,mainScripts.slateSlotScript_placeSlate
	call interactionSetScript
	call interactionIncState ; pasa a state2 para ejecutar el script de poner la tablilla, que pone el tile de tablilla puesta, enciende las antorchas
	; correspondientes, decrementa el número de tablillas que tienes y cambia los flags de la sala.

; Ejecuta el script que se le pase
@state2:
	call interactionRunScript
	ret nc
	jp interactionDelete
