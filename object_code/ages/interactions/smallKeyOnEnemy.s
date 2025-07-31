; ==================================================================================================
; INTERAC_SMALL_KEY_ON_ENEMY
; ==================================================================================================
interactionCode77:
	ld e,Interaction.state
	ld a,(de)
	rst_jumpTable
	.dw @state0
	.dw @state1
	.dw @state2

; Comprueba si ya se ha obtenido la llave y si no, compara el subid de la llave con los enemigos de la lista de enemigos de la sala.
@state0:
	; Comprobar si ya se ha conseguido la llave, si es así, se elimina la interacción.
	call getThisRoomFlags
	and ROOMFLAG_ITEM
	jp nz,interactionDelete

	ld e,Interaction.subid
	ld a,(de)
	ld b,a
	ldhl FIRST_ENEMY_INDEX, Enemy.id ;hl apunta al slot del primer enemigo.
@nextEnemy:
	ld a,(hl) ;cargas el id del enemigo en a
	cp b ;comparas el subid de la llave con el id del enemigo.
	jr z,@foundMatch ;si son iguales, salta a foundMatch.
	inc h ;avanza al siguiente enemigo
	ld a,h
	cp LAST_ENEMY_INDEX+1 ;compara con el último enemigo de la lista

	; BUG: Original game does "jp c", meaning this only works if the enemy in
	; question is in the first enemy slot.
.ifdef ENABLE_BUGFIXES
	jp nc,interactionDelete
.else
	jp c,interactionDelete ;si hemos llegado al último y no hemos encontrado coincidencia, borra la interacción
.endif
	jr @nextEnemy ;si aún no hemos llegado al último seguimos con el siguiente enemigo

; Found the enemy to attach the key to
@foundMatch:
	dec l ;apunta al campo enabled del enemigo
	ld a,l
	ld e,Interaction.relatedObj2
	ld (de),a ;cargas enemy.enabled en relatedObj2.
	ld a,h ;a apunta al enemigo ahora
	inc e ;pasas al otro byte de relatedObj2 (está conformado por dos bytes)
	ld (de),a ;cargas en el byte alto de relatedObj2 el enemigo, consiguiendo que relatedObj2 apunte a Enemy.enabled.
	call interactionInitGraphics ;carga el gráfico de la llave
	call objectSetVisible80 ;activa el flag de visibilidad de la llave
	call interactionIncState

; Hace que la posición de llave sea la misma que la del enemigo.
@takeRelatedObj2Position:
	ld a,Object.y
	call objectGetRelatedObject2Var ;hl = enemy.y
	jp objectTakePosition ; hace que la posición de llave sea la misma que la del enemigo.

; Mientras que el enemigo esté enabled, la llave copia su posición
@state1: ; Copies the position of relatedObj2
	ld a,Object.enabled
	call objectGetRelatedObject2Var ; hl = enemy.enabled
	ld a,(hl) ; a = valor de enemy.enabled.
	or a 
	jp z,interactionIncState ; si enemy.enabled = 0 (el enemigo ha desaparecido, ha muerto), saltas a state2.

	;Mientras que el enemigo no esté muerto, la llave está con él.
	call @takeRelatedObj2Position ; hace que la posición de la llave sea la misma que la del enemigo.
	ld a,Object.visible
	call objectGetRelatedObject2Var ;hl = enemy.visible
	ld b,$01
	jp objectFlickerVisibility ; afecta a la visibilidad de la llave, haciendo que parpadee.

; El enemigo ha muerto, la llave cae.
@state2: ; relatedObj2 is gone, fall to the ground and create a key
	call objectSetVisible ; activa de nuevo la visibilidad de la llave
	ld c,$20
	call objectUpdateSpeedZ_paramC ; la llave "salta" del enemigo
	ret nz ;cuando la llave toque el suelo el código sigue
	ldbc TREASURE_SMALL_KEY,$00 ;carga el tesoro de la small key
	call createTreasure ;lo crea
	call objectCopyPosition ;copia la posición de la interacción a la llave que se acaba de crear
	jp interactionDelete ;borra finalmente la interacción
