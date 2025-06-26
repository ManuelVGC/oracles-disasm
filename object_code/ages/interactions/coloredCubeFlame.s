; ==================================================================================================
; INTERAC_COLORED_CUBE_FLAME
; ==================================================================================================
interactionCode1a:
	call checkInteractionState
	jr nz,@initialized
	ld a,(wRotatingCubePos) ;comprueba si existe la interacción21 subid04 (que es la que pone un valor a wRotatingCubePos, probablemente haya otras que se usen
	; de forma igual pero justo estoy viendo esa) y si no sale.
	or a
	ret z

	call @updateColor
	call interactionInitGraphics
	call objectSetVisible82
	call interactionIncState

; Si el bit 7 es 1 entonces la llama se hace visible
@initialized:
	ld a,(wRotatingCubeColor)
	rlca
	jp nc,objectSetInvisible ; si el bit 7 estaba a 0 se pone invisible la llama
	call objectSetVisible ; sino, se hace visible la llama
	call @updateColor
	jp interactionAnimate

; Cambia el color de la llama dependiendo del color del tile donde se encuentre la interacción de donde se sacará el cambio de color de la llama.
@updateColor:
	ld a,(wRotatingCubeColor) ;carga el color del tile donde se encuentra la interacción que indica de qué color será la llama.
	and $7f ; pone el bit 7 a 0
	ld hl,@palettes
	rst_addAToHl
	ld e,Interaction.oamFlags
	ld a,(de)
	and $f8
	or (hl)
	ld (de),a
	ret

@palettes:
	.db $02 $03 $01
