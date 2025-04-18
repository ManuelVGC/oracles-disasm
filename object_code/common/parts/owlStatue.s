; ==================================================================================================
; PART_OWL_STATUE
; ==================================================================================================
partCode13:
	jr z,@normalStatus
	ld e,Part.var2a
	ld a,(de)
	cp $9a ;si var2a vale 9a, signfica que se ha usado una semilla misteriosa en el búho
	jr nz,@normalStatus ;si no se le ha dado una semilla salta a comportamiento normal, sin hacer nada
	ld h,d
	ld l,Part.state
	ld a,(hl)
	cp $02
	jr nc,@normalStatus
	inc (hl) ;avanza al state2 (se llega hasta el 1 en la ejecució normal)
	ld l,Part.counter1
	ld (hl),$32
@normalStatus:
	ld e,Part.state
	ld a,(de)
	rst_jumpTable
	.dw @state0
	.dw @stateStub
	.dw @state2
	.dw @state3

@state0:
	ld h,d
	ld l,e
	inc (hl)
	ld l,Part.var3f
	set 5,(hl)
	call objectMakeTileSolid
	ld h,>wRoomLayout
	ld (hl),$00
	jp objectSetVisible83

@stateStub:
	ret ;si no se le ha dado una semilla misteriosa sencillamente no hace nada más.

; Aquí entra cuando se le da una semilla misteriosa.
; En este estado se hace una animación + chispas
@state2:
	call partCommon_decCounter1IfNonzero
	jr nz,+
	ld (hl),$1e
	ld l,e
	inc (hl)
	ld a,$01
	jp partSetAnimation
+
	ld a,(hl)
	and $07
	ret nz
	ld a,(hl)
	rrca
	rrca
	sub $02
	ld hl,@owlStatueSparkleOffset
	rst_addAToHl
	ldi a,(hl)
	ld b,a
	ld c,(hl)
	call getFreeInteractionSlot
	ret nz
	ld (hl),INTERAC_SPARKLE
.ifdef ROM_SEASONS
	; substate
	inc l
	ld (hl),$05
.endif
	jp objectCopyPositionWithOffset
@owlStatueSparkleOffset:
	.db $f9 $05
	.db $06 $ff
	.db $fc $fa
	.db $02 $07
	.db $00 $fa
	.db $ff $02

; En este estado muestra el texto correspondiente
@state3:
	call partCommon_decCounter1IfNonzero
	jr nz,+
	ld l,e
	ld (hl),$01
	xor a
	jp partSetAnimation
+
	ld a,(hl)
	cp $16
	ret nz
	ld l,Part.subid
	ld c,(hl)
	ld b,$39
	jp showText ;el texto que se muestra es 0x39+subID, por ejemplo si subID = 01 el texto sería 0x3901.
