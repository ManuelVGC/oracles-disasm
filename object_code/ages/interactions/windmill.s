; ==================================================================================================
; INTERAC_WINDMILL
; ==================================================================================================
interactionCode50:
	ld e,Interaction.subid
	ld a,(de)
	rst_jumpTable
	.dw @subid0

	call @func_72de
	jp objectSetVisible80
	call @func_72de
	jp objectSetVisible81

@subid0:
	call checkInteractionState
	jr nz,+
	ld h,d
	ld l,e
	inc (hl)
	ld l,$40
	set 7,(hl)
	call interactionInitGraphics
	jp objectSetVisible80
+
	call getThisRoomFlags
	bit 6,(hl)
	jr z,+
	ld e,$60
	ld a,(de)
	cp $10
	jr nz,+
	ld a,$02
	ld (de),a
+
	jp interactionAnimate
@func_72de:
	call checkInteractionState
	jr nz,+
	ld a,$01
	ld (de),a
	jp interactionInitGraphics
+
	pop hl
	jp interactionAnimate
