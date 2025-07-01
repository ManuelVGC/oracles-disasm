; ==================================================================================================
; INTERAC_TRIGGER_TRANSLATOR
; ==================================================================================================
interactionCode24:
	call interactionDeleteAndRetIfEnabled02
	ld e,Interaction.subid
	ld a,(de)
	and $0f
	rst_jumpTable
	.dw @subid0
	.dw @subid1
	.dw @subid2

; Subid 0: control a bit in wActiveTriggers based on wToggleBlocksState.
@subid0:
	ld a,(wToggleBlocksState)
	ld c,a

@label_08_081:
	ld e,Interaction.subid
	ld a,(de)
	swap a
	and $07
	ld hl,bitTable
	add l
	ld l,a

	ld a,c
	and (hl)
	ld b,a
	ld a,(hl)
	cpl
	ld c,a
	ld a,(wActiveTriggers)
	and c
	or b
	ld (wActiveTriggers),a
	ret

; Subid 1: control a bit in wActiveTriggers based on wSwitchState.
@subid1:
	ld a,(wSwitchState)
	ld c,a
	jr @label_08_081

; Subid 2: check that [wNumLitTorches] == Y y activa un bit en wActiveTriggers
@subid2:
	ld e,Interaction.yh
	ld a,(de)
	ld b,a ; b = Y de la interacción

	ld e,Interaction.xh
	ld a,(de)
	ld c,a ; c = X de la interacción

	ld a,(wNumTorchesLit)
	cp b ;devuelve z si a = b 
	jr nz,++ ;si el número de antorchas encendidas es Y entonces sigue el código, sino, salta a ++

	ld a,(wActiveTriggers)
	or c ;activa un bit en wActiveTriggers
	ld (wActiveTriggers),a
	ret
++
	;si hay alguna antorcha apagada desactiva el bit c de wActiveTriggers
	ld a,c
	cpl
	ld c,a
	ld a,(wActiveTriggers)
	and c
	ld (wActiveTriggers),a
	ret
