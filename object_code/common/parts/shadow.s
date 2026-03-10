; ==================================================================================================
; PART_SHADOW
;
; Variables:
;   relatedObj1: Object that this shadow is for
;   var30: ID of relatedObj1 (deletes self if it changes)
; ==================================================================================================
partCode07:
	ld e,Part.state
	ld a,(de)
	or a
	call z,@initialize

	; If parent's ID changed, delete self
	ld a,Object.id
	call objectGetRelatedObject1Var
	ld e,Part.var30
	ld a,(de)
	cp (hl)
	jp nz,partDelete

	; Take parent's position, with offset
	ld a,Object.yh
	call objectGetRelatedObject1Var
	ld e,Part.var03
	ld a,(de)
	ld b,a
	ld c,$00
	call objectTakePositionWithOffset

	xor a
	ld (de),a ; [this.zh] = 0

	ld a,(hl) ; [parent.zh]
	or a
	jp z,objectSetInvisible

	; Flicker visibility
	ld e,Part.visible
	ld a,(de)
	xor $80
	ld (de),a

	ld e,Part.subid
	ld a,(de) ;a = subid
	add a ;subid * 2
	ld bc,@animationIndices ;bc apunta a la tabla animationIndices
	call addDoubleIndexToBc ;cada subid corresponde a 4 tamaños, que se eligen justo abajo según la altura a la que esté el boss.
	; Esta función busca por doubleindex, multiplicando el índice por 2, consiguiendo subid * 4 al haber hecho antes el add a (que multiplica por 2).
	; Esto se usa porque tenemos en memoria un array de 12 elementos y queremos tratarlos de 4 en 4, así que la primera línea empieza en el índice 0, la segunda en 4 y la tercera
	; en 8, así que para llegar al principio de una línea tienes que multiplicar por 4.
	; Por ejemplo, bc apunta al inicio de la tabla, tienes sub01 así que quieres apuntar al principio de la primera línea, que empieza en el elemento 4 así que sumas subid01 * 4 = 4.
	; Si no hiciésemos add a y addDoubleIndexToBc entonces apuntaríamos al índice 01, al segundo elemento de ese array en memoria.

	; Set shadow size based on how close the parent is to the ground
	ld a,(hl) ; [parent.zh]
	cp $e0
	jr nc,@setAnim ;comparamos la altura con un valor y si es ese o más nos quedamos con ese valor de la tabla
	inc bc ;sino, apuntamos al siguiente valor.
	cp $c0
	jr nc,@setAnim
	inc bc
	cp $a0
	jr nc,@setAnim
	inc bc

@setAnim:
	ld a,(bc)
	jp partSetAnimation

@animationIndices:
	.db $01 $01 $00 $00 ; Subid 0
	.db $02 $01 $01 $00 ; Subid 1
	.db $03 $02 $01 $00 ; Subid 2

@initialize:
	inc a
	ld (de),a ; [state] = 1

	ld a,Object.id
	call objectGetRelatedObject1Var
	ld e,Part.var30
	ld a,(hl)
	ld (de),a

	jp objectSetVisible83
