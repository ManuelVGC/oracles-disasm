; ==================================================================================================
; INTERAC_PUSHBLOCK_SYNCHRONIZER
; ==================================================================================================
interactionCodebd:
	ld e,Interaction.state
	ld a,(de)
	rst_jumpTable
	.dw interactionIncState
	.dw @state1
	.dw @state2

@state1:
	; Wait for a block to be pushed
	ld a,(w1ReservedInteraction1.enabled) ;cuando un bloque está siendo empujado, copia su información en w1ReservedInteraction1, poniendo además
	; w1ReservedInteraction1.enabled a 1, indicando que está activo.
	or a
	ret z ;si no hay un bloque siendo empujado, sale

	;si sí hay un bloque siendo empujado sigue con el código
	ld a,(w1ReservedInteraction1.var31) ; Tile index of block being pushed
	ldh (<hFF8B),a ;guarda el tileindex empujado en hFF8B
	call findTileInRoom
	jr nz,@incState ;si no encuentra otro tileindex igual en la sala, vuelve al principio de este state1.

	; Found another tile of the same type; push it, then search for more tiles of that type
	call @pushBlockAt
--
	ldh a,(<hFF8B)
	call backwardsSearch
	jr nz,@incState
	call @pushBlockAt
	jr --

@incState:
	jp interactionIncState

@state2:
	ld e,Interaction.state
	ld a,$01
	ld (de),a
	ret

;;
; @param	hl	Position of block to push in wRoomLayout
; @param	hFF8B	Index of tile to push
@pushBlockAt:
	push hl ;guarda en la pila la posición original del bloque a mover.

	ldh a,(<hFF8B)
	cp TILEINDEX_SOMARIA_BLOCK
	jr z,@return ;si el tileindex es un somaria block, no lo empuja, es un tileindex especial

	ld a,l 
	ldh (<hFF8D),a
	ld h,d
	ld l,Interaction.yh
	call setShortPosition

	ld l,Interaction.angle
	ld a,(wBlockPushAngle)
	and $1f
	ld (hl),a

	call interactionCheckAdjacentTileIsSolid
	jr nz,@return
	call getFreeInteractionSlot
	jr nz,@return

	ld (hl),INTERAC_PUSHBLOCK
	ld l,Interaction.angle
	ld e,l
	ld a,(de)
	ld (hl),a
	ldbc -$02, $00
	call objectCopyPositionWithOffset

	; [pushblock.var30] = tile position
	ld l,Interaction.var30
	ldh a,(<hFF8D)
	ld (hl),a
@return:
	pop hl
	dec l
	ret
