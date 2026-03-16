; ==================================================================================================
; ENEMY_VERAN_FAIRY
;
; Variables:
;   var03: Attack index
;   var30: Movement pattern index (0-3)
;   var31/var32: Pointer to movement pattern
;   var33/var34: Target position to move to
;   var35: Number from 0-2 based on health (lower means more health)
;   var36: ?
;   var38: Timer to stay still after doing a movement pattern
; ==================================================================================================
enemyCode06:
	jr z,@normalStatus ;si status = 0, entonces entra en normalStatus. El normal es 0 por enemyStates.s. 
	sub ENEMYSTATUS_NO_HEALTH 
	ret c ;sale para status < de ENEMYSTATUS_NO_HEALTH
	jr nz,@justHit ;si el status != ENEMYSTATUS_NO_HEALTH (al hacer el sub ENEMYSTATUS_NO_HEALTH si el status fuese igual daría 0 y se activaría el flag z) salta a justHit

	; No health
	ld h,d
	ld l,Enemy.collisionType
	ld a,(hl)
	or a
	jr z,++ ;si collisionType es 0, salta.

	ld (hl),$00 ;collisionType = 0. Se desactivan las colisiones de forma que Link no pueda interactuar con él mientras muere.
	ld a,$01
	ld (wDisableLinkCollisionsAndMenu),a ;se evita que el jugador interfiera de alguna forma durante la muerte del boss

	ld a,SND_BOSS_DEAD
	call playSound ;reproduce sonido de boss derrotado

++
	ld h,d
	ld l,Enemy.health
	inc (hl) ;le aumentamos la vida para evitar que se borre el boss automáticamente.
	ld l,Enemy.state
	ld (hl),$05 ;cuando la vida es 0 y por tanto está activado ENEMYSTATUS_NO_HEALTH, state = 5.
	inc l ;apuntamos al substate
	ld (hl),$00 ; [substate]
	ld l,Enemy.counter1
	ld (hl),60 ;seteamos contador
	jr @normalStatus ;saltamos normalStatus, state5 y substate0.

; Actualiza var35 (que indicará la fase en la que se encuentra el boss) y la velocidad del enemigo dependiendo de la vida que le quede. Aumenta la velocidad por fase del boss.
@justHit:
	call veranFairy_updateVar35BasedOnHealth ; actualiza var35 y a dependiendo de la vida del enemigo. Serán 0, 1 o 2, indicando la fase en la que se encuentra Veran.
	ld hl,veranFairy_speedTable
	rst_addAToHl
	ld e,Enemy.speed ;actualizas al speed del enemigo dependiendo de la fase en la que esté, es decir, dependiendo de la a que conseguimos en veranFairy_updateVar35BasedOnHealth.
	ld a,(hl)
	ld (de),a 

@normalStatus:
	ld e,Enemy.state
	ld a,(de)
	rst_jumpTable
	.dw veranFairy_state0
	.dw veranFairy_state1
	.dw veranFairy_state2
	.dw veranFairy_state3
	.dw veranFairy_state4
	.dw veranFairy_state5


;inicialización
veranFairy_state0:
	ld a,ENEMY_VERAN_FAIRY
	ld b,$00
	call enemyBoss_initializeRoom

	call ecom_incState

	ld l,Enemy.speed 
	ld (hl),SPEED_140 ;setea speed

	ld l,Enemy.var30
	dec (hl) ;var30 = var30 - 1

	ld b,$00
	ld c,$08
	jp enemyBoss_spawnShadow

; Cutscene de aparición de Veran e inicio del combate
veranFairy_state1:
	inc e
	ld a,(de)
	rst_jumpTable
	.dw @substate0
	.dw @substate1
	.dw @substate2
	.dw @substate3

; desactivamos a Link y esperamos a que se cierren las puertas
@substate0:

	ld a,DISABLE_LINK
	ld (wDisabledObjects),a
	ld (wMenuDisabled),a

	; Wait for door to close
	ld a,($cc93)
	or a
	ret nz

	ld e,Enemy.counter1
	ld a,20
	ld (de),a

	jp ecom_incSubstate
	

; Se espera unos frames y aparece Veran con una velocidad inicial
@substate1:
	call ecom_decCounter1 
	ret nz ;espera hasta que counter1 sea 0

	ld e,Enemy.counter1
	ld a,10
	ld (de),a

	call ecom_incSubstate
	ld c,$24
	call ecom_setZAboveScreen ;seteamos la posición de Veran c por encima del borde superior de la pantalla

	; se limpian los flags de la OAM. Con esto se consigue que la Veran fairy no siga azul, como el sprite forma humana.
	ld l,Enemy.oamFlagsBackup
	xor a
	ldi (hl),a 
	ld (hl),a

	
	; Se le da una velocidad inicial a Veran
	ld b,$00
	ld c,$b0 ;speedZ
	call objectSetSpeedZ


	ld a,$05 
	call enemySetAnimation ;setea animación

	ld c,$00 ;inicialización del boolean que hace que se skipeen frames al diminuir la velocidad de bajada de Veran.

	jp objectSetVisible83 ;setea tipo de visibilidad $83
	
; Baja boss hasta el suelo, espera X frames y dice texto
@substate2:
	call veranUpdateZ_flying ;Veran descendiendo
	jp nz,veranFairy_animate

	;pequeña espera después de que llegue al suelo y antes de que diga el texto
	call ecom_decCounter1 
	ret nz ;espera hasta que counter1 sea 0

	call ecom_incSubstate

	ld bc,TX_5610
	jp showText

; espera X frames y empieza boss fight
@substate3: 
	ld h,d
	ld l,Enemy.state
	inc (hl) ;pasas al state2
	ld l,Enemy.counter2
	ld (hl),120
	jp enemyBoss_beginBoss ;devuelve el control al jugador y reproduce música


; Choosing a movement pattern and attack
veranFairy_state2:
	call getRandomNumber_noPreserveVars
	and $07
	ld b,a
	ld e,Enemy.var35
	ld a,(de)
	swap a
	rrca
	add b
	ld hl,veranFairy_attackTable
	rst_addAToHl
	ld e,Enemy.var03
	ld a,(hl)
	ld (de),a

	call ecom_incState
	ld l,Enemy.var38
	ld (hl),60
	ld l,Enemy.var36
	ld (hl),$00
--
	call getRandomNumber
	and $03
	ld l,Enemy.var30
	cp (hl)
	jr z,--
	ld (hl),a

	ld hl,veranFairy_movementPatternTable
	rst_addDoubleIndex
	ldi a,(hl)
	ld h,(hl)
	ld l,a
	ld e,Enemy.var33
	ldi a,(hl)
	ld (de),a
	inc e
	ldi a,(hl) ; [var34]
	ld (de),a

veranFairy_saveMovementPatternPointer:
	ld e,Enemy.var31
	ld a,l
	ld (de),a
	inc e
	ld a,h
	ld (de),a
	ret


; Moving and attacking
veranFairy_state3:
	call veranFairy_66ed

	ld h,d
	ld l,Enemy.var33
	call ecom_readPositionVars
	sub c
	add $02
	cp $05
	jr nc,@updateMovement
	ldh a,(<hFF8F)
	sub b
	add $02
	cp $05
	jr nc,@updateMovement

	; Reached target position
	ld l,Enemy.yh
	ld (hl),b
	ld l,Enemy.xh
	ld (hl),c
	call veranFairy_checkLoopAroundScreen

	; Get next target position
	ld h,d
	ld l,Enemy.var31
	ldi a,(hl)
	ld h,(hl)
	ld l,a
	ldi a,(hl)
	or a
	jr nz,++
	ld a,$05
	call enemySetAnimation
	jp ecom_incState
++
	ld e,Enemy.var33
	ld (de),a
	ld b,a
	inc e
	ldi a,(hl)
	ld (de),a ; [var34]
	ld c,a
	call veranFairy_saveMovementPatternPointer
@updateMovement:
	call ecom_moveTowardPosition
veranFairy_animate:
	jp enemyAnimate


veranFairy_state4:
	ld h,d
	ld l,Enemy.var38
	dec (hl)
	jr nz,veranFairy_animate
	ld l,e
	ld (hl),$02 ; [state]
	jr veranFairy_animate


; Dead
veranFairy_state5:
	inc e ;apuntamos al substate
	ld a,(de)
	rst_jumpTable
	.dw @substate0
	.dw @substate1
	.dw @substate2
	.dw @substate3

@substate0:
	call ecom_decCounter1
	jp nz,ecom_flickerVisibility ;el boss parpadea
	ld l,e
	inc (hl) ;substate = substate + 1
	jp objectSetVisible82 ;lo hace visible con prioridad 2 (mira el campo visible del ObjectStruct de struct.s).

@substate1:
	call ecom_incSubstate
	ld l,Enemy.counter2
	ld (hl),16 
	ld bc,TX_5612
	jp showText

; cuando termina el texto se crean cuatro explosiones separadas por 16 frames. Además, después de X frames (33 frames, 65 del contador - 32 que es cuando empieza) empieza un fade
; a blanco. Cuando termina el contador se salta a triggear la cutscene.
@substate2:
	call ecom_decCounter2 
	ret nz

	call ecom_incSubstate
	ld l,Enemy.counter2
	ld (hl),65 

	; Spawn explosion
	call getFreePartSlot ;creamos una part para la explosión
	ret nz
	ld (hl),PART_BOSS_DEATH_EXPLOSION
	inc l
	ld e,Enemy.id
	ld a,(de)
	ld (hl),a ; [Part.subid] = [Enemy.id]

	jp objectCopyPosition ;copia la posición del objeto d al objeto h, en este caso del boss a la explosión
	

@substate3:
	call ecom_decCounter2 
	ret nz

	call markEnemyAsKilledInRoom

	ld e,Enemy.id
	ld a,(de)
	sub $08
	cp $68
	jr c,++ ;esta comparación hace que los enemigos no bosses o minibosses no cambien su música. Los bosses y minibosses todos tienen id igual o mayor que 70.
	ld a,(wActiveMusic2)
	ld (wActiveMusic),a
	call playSound ;se vuelve a poner la música que sonaba antes de enfrertarte al boss
++
	jp enemyDelete



; BUG(?): $00 acts as a terminator, but it's also used as a position value, meaning one movement
; pattern stops early? (Doesn't apply if $00 is in the first row.)
veranFairy_movementPatternTable:
	.dw @pattern0
	.dw @pattern1
	.dw @pattern2
	.dw @pattern3

@pattern0:
	.db $00 $78
	.db $00 $f7 ; Terminates early here?
	.db $c0 $e0
	.db $58 $78
	.db $00
@pattern1:
	.db $00 $f7
	.db $58 $78
	.db $58 $f7
	.db $c0 $f7
	.db $58 $78
	.db $00
@pattern2:
	.db $58 $f7
	.db $30 $f7
	.db $c0 $38
	.db $c0 $b8
	.db $58 $78
	.db $00
@pattern3:
	.db $00 $f7
	.db $c0 $f7
	.db $10 $f7
	.db $90 $f7
	.db $58 $78
	.db $00


veranFairy_attackTable:
	.db $00 $00 $00 $00 $00 $00 $01 $01 ; High health
	.db $00 $00 $00 $00 $00 $01 $01 $02 ; Mid health
	.db $00 $00 $01 $01 $01 $02 $02 $02 ; Low health


veranFairy_speedTable:
	.db SPEED_140, SPEED_1c0, SPEED_200

;;
veranFairy_checkLoopAroundScreen:
	call objectGetShortPosition
	ld e,a
	ld hl,@data1
	call lookupKey
	ret nc

	ld hl,@data2
	rst_addAToHl
	ld e,Enemy.yh
	ldi a,(hl)
	ld (de),a
	ldh (<hFF8F),a
	ld e,Enemy.xh
	ld a,(hl)
	ld (de),a
	ldh (<hFF8E),a
	ret

@data1:
	.db $07 $00
	.db $0f $02
	.db $1f $04
	.db $3f $06
	.db $5f $08
	.db $9f $0a
	.db $c3 $0c
	.db $cb $0a
	.db $ce $0e
	.db $cf $00
	.db $00

@data2:
	.db $c0 $00
	.db $00 $00
	.db $90 $00
	.db $00 $38
	.db $30 $00
	.db $58 $00
	.db $00 $b8
	.db $c0 $78

;;
; @param[out]	a	Value written to var35
; Pone var35 a 0, 1 o 2 dependiendo de si la vida del enemigo es > 20, <20 y >10 o < 10. Son como tres fases.
veranFairy_updateVar35BasedOnHealth:
	ld b,$00
	ld e,Enemy.health
	ld a,(de) ; a = enemy.health
	cp 20 ; si a < 20 entonces se activa el carry porque en cp el carry se activa cuando a < b (internamente hace una resta para comparar los números)
	jr nc,++ ; si enemy.health > 20, salta y pone var35 a b, que es 0
	inc b
	cp 10 
	jr nc,++ ; si enemy.health > 10, salta y pone var35 a b, que es 1
	inc b ; si enemy.health es < 10, pone var35 a 2
++
	ld e,Enemy.var35
	ld a,b
	ld (de),a 
	ret

;;
veranFairy_66ed:
	call ecom_decCounter2
	ret nz
	ld e,Enemy.var03
	ld a,(de)
	rst_jumpTable
	.dw attack0
	.dw attack1
	.dw attack2

; Shooting occasional projectiles
attack0:
	ld e,Enemy.var36
	ld a,(de)
	or a
	jr nz,@label_10_227

	call getRandomNumber_noPreserveVars
	and $0f
	ld b,a
	ld h,d
	ld l,Enemy.var35
	ld a,(hl)
	add a
	add $08
	cp b
	ld l,Enemy.counter2
	ld (hl),60
	ret nc

	xor a
	ldd (hl),a
	inc a
	ld (hl),a
	ld l,Enemy.var36
	ld (hl),a
	ld l,Enemy.var37
	ld (hl),$04

@label_10_227:
	call ecom_decCounter1
	jr z,@label_10_228
	ld a,(hl)
	cp $0e
	ret nz
	ld a,$05
	jp enemySetAnimation

@label_10_228:
	call veranFairy_checkWithinBoundary
	ret nc
	ld l,Enemy.var37
	dec (hl)
	jr z,@label_10_229

	ld l,Enemy.counter1
	ld (hl),30

	ld b,PART_VERAN_FAIRY_PROJECTILE
	call ecom_spawnProjectile
	ld a,$06
	jp enemySetAnimation

@label_10_229:
	ld l,Enemy.counter2
	ld (hl),90
	ld l,Enemy.var36
	ld (hl),$00
	ret

; Circular projectile attack
attack1:
	ld e,Enemy.var36
	ld a,(de)
	or a
	jr nz,@label_10_230

	call veranFairy_checkWithinBoundary
	ret nc

	call getRandomNumber_noPreserveVars
	and $0f
	ld b,a
	ld h,d
	ld l,Enemy.var35
	ld a,(hl)
	add a
	add $06
	cp b
	ld l,Enemy.counter2
	ld (hl),90
	ret nc

	ld (hl),$00 ; [counter2]
	dec l
	ld (hl),180 ; [counter1]
	ld l,Enemy.var36
	ld (hl),$01

	ld b,PART_VERAN_PROJECTILE
	call ecom_spawnProjectile
	ld a,$06
	call enemySetAnimation

@label_10_230:
	pop hl
	call ecom_decCounter1
	jp nz,enemyAnimate

	inc l
	ld (hl),120 ; [counter2]
	ld l,Enemy.var36
	ld (hl),$00
	ld a,$05
	jp enemySetAnimation

; Baby ball attack
attack2:
	ld h,d
	ld l,Enemy.var36
	bit 0,(hl)
	jr nz,@label_10_231

	call veranFairy_checkWithinBoundary
	ret nc

	ld (hl),$01
	ld l,Enemy.counter1
	ld (hl),30
	ld b,PART_BABY_BALL
	call ecom_spawnProjectile
	ld a,$06
	call enemySetAnimation

@label_10_231:
	pop hl
	call ecom_decCounter1
	jp nz,enemyAnimate

	inc l
	ld (hl),$f0
	ld l,Enemy.var36
	ld (hl),$00
	ld a,$05
	jp enemySetAnimation

;;
; @param[out]	cflag	nc if veran is outside the room boundary
veranFairy_checkWithinBoundary:
	ld e,Enemy.yh
	ld a,(de)
	sub $10
	cp $90
	ret nc
	ld e,Enemy.xh
	ld a,(de)
	sub $10
	cp $d0
	ret
