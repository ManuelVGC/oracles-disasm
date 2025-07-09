; ==================================================================================================
; PART_SEED_SHOOTER_EYE_STATUE
; ==================================================================================================
partCode46:
	jr z,@normalStatus

	;cuando impacta un proyectil a la part, se entra por aquí.
	ld h,d
	ld l,$c6
	ld (hl),$2d ; objeto.c6 = 2d. Se usa como contador que indica cuánto tiempo estará activado el ojo.
	ld l,$c2 ;c2 será un bitmask que tiene cada ojo con un bit activo que indica qué ojo es
	ld a,(hl)
	and $07 
	ld hl,wActiveTriggers
	call setFlag ;activas el bit del ojo correspondiente en wActiveTriggers
	call objectSetVisible83 ;hace visible el ojo

; este código se ejecuta de normal. Cuando no ha sido activada por el seed shooter.
@normalStatus:
	ld e,$c4
	ld a,(de)
	or a
	jr z,@state0 ;c4 se usa como estado. Si es 0 entonces primero se inicializa en state0.

	call partCommon_decCounter1IfNonzero
	ret nz ;decrementa c6 hasta que sea 0
	ld e,$c2
	ld a,(de)
	ld hl,wActiveTriggers
	call unsetFlag ;se desactiva el flag que indica que ese ojo estaba activado/visible.
	jp objectSetInvisible ;el ojo se hace invisible

; simplemente cambia el state a 1, al normalstatus.
@state0:
	inc a
	ld (de),a
	ret
