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
	ld e,Enemy.invincibilityCounter ;contador que decrementa cada frame, hace que no puedas hacer daño al enemigo y hace que parpadee la visibilidad y en rojo.
	ld a,(de)
	ret nz ;espera a que termine el contador de invicibility.
	call checkLinkCollisionsEnabled ;si c = 1 colisiones habilitadas. Las colisiones no estarán habilitadas por diversas razones, como por ejemplo si Link está muriendo o en el aire.
	ret nc ;aquí sencillamente esperamos a que Link pueda colisionar.

	ld a,DISABLE_LINK
	ld (wDisabledObjects),a
	ld (wMenuDisabled),a
	ld h,d
	ld l,Enemy.health
	inc (hl) ;le aumentamos la vida para evitar que se borre el boss uutomáticamente.
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
	ld (wEnemyIDToLoadExtraGfx),a 
	call ecom_incState
	ld l,Enemy.counter1
	ld (hl),60 ;pone un contador a 96
	ld l,Enemy.speed 
	ld (hl),SPEED_140 ;setea speed
	ld l,Enemy.var30
	dec (hl) ;var30 = var30 - 1
	ld a,$02 
	call enemySetAnimation ;setea animación
	jp objectSetVisible82 ;setea tipo de visibilidad $82

; Cutscene just prior to fairy form
veranFairy_state1:
	inc e
	ld a,(de)
	rst_jumpTable
	.dw @substate0
	.dw @substate1
	.dw @substate2
	.dw @substate3
	.dw @substate4
	.dw @substate5
	.dw @substate6
	.dw @substate7
	.dw @substate8
	.dw @substate9
	.dw @substateA
	.dw @substateB
	.dw @substateC

; parpadeo del principio
@substate0:
	call ecom_decCounter1 ;aquí queda apuntando el hl al enemy.counter1
	jp nz,ecom_flickerVisibility ;durante 96 frames hace un flicker de la visibilidad
	ld (hl),$08 ;se setea el counter1 a 8
	ld l,e ;l a apunta al substate
	inc (hl) ; substate = substate + 1
	jp objectSetVisible83

; muestra primer texto después de parpadear
@substate1:
	call ecom_decCounter1
	ret nz
	ld l,e
	inc (hl) ; substate = substate + 1
	ld bc,TX_560f
	jp showText

; cambia la animación del personaje
@substate2:
	call ecom_incSubstate ; substate = substate + 1
	ld l,Enemy.counter1
	ld (hl),30 ;setea counter a 48 
	ld a,$04
	jp enemySetAnimation ;setea una nueva animación

; creación y aparición de rayos y tal
@substate3:
	ld c,$33 ;lugar donde caerá el rayo, lo usa más tarde en setShortPosition_paramC

; define un contador que se usa para espaciar los rayos
@strikeLightningAfterCountdown:
	call ecom_decCounter1
	ret nz
	ld (hl),10 ; [counter1]
	ld l,e
	inc (hl) ; [substate]

; crea un rayo
@strikeLightning:
	call getFreePartSlot
	ret nz
	ld (hl),PART_LIGHTNING
	ld l,Part.yh
	jp setShortPosition_paramC

; espera y cae rayo en la posición $7b
@substate4:
	ld c,$7b
	jr @strikeLightningAfterCountdown

; espera y cae rayo en la posición $55
@substate5:
	ld c,$55
	jr @strikeLightningAfterCountdown

; espera y cae rayo en la posición $3b
@substate6:
	ld c,$3b
	jr @strikeLightningAfterCountdown

; espera y cae rayo en la posición $73
@substate7:
	ld c,$73
	jr @strikeLightningAfterCountdown

; espera y cae rayo en la posición $59 y luego fade a blanco
@substate8:
	call ecom_decCounter1
	ret nz
	ld l,e
	inc (hl) ; [substate]
	ld c,$59
	call @strikeLightning
	jp fadeoutToWhite

; Remove pillar tiles
@substate9:
	ld b,$0c ; b = 12, que son el número de tiles de pilar que hay que sustituir
	ld hl,@pillarPositions
@loop
	push bc ;guarda b y c en la pila para usarlos ahora y que no se pierdan sus valores
	ldi a,(hl) ;carga el valor de la primera posición en a y apunta a la siguiente
	ld c,a ; c = a = valor de la primera posición
	ld a,$a5 ;tileindex que se va a poner
	push hl ;guarda hl para recuperarlo después
	call setTile ;setea el tile en la posición que toca
	pop hl 
	pop bc
	dec b ; se decrementa el número de tiles que quedan por sustituir
	jr nz,@loop ;cuando no queden tiles que sustituir se termina el bucle
	jp ecom_incSubstate

@pillarPositions:
	.db $23 $33 $63 $73 $45 $55 $49 $59
	.db $2b $3b $6b $7b

; Spawn mimics y cambia la forma de Veran a la forma fairy
@substateA:
	ld b,$04 ; número de mimics
	ld hl,@mimicPositions

@nextMimic:
	ldi a,(hl) ;se carga en a una posición de la lista de posiciones donde irán los mimics
	ld c,a ; c = a
	push hl
	call getFreeEnemySlot
	jr nz,++
	ld (hl),ENEMY_LINK_MIMIC
	ld l,Enemy.yh
	call setShortPosition_paramC ;se pone el mimic creado en y = c = a = posición de la lista de posiciones de mimicPositions
++
	pop hl
	dec b ;se decrementa el número de mimic que faltan por spawnear
	jr nz,@nextMimic ;hasta que no se hayan spawneado 4 mimics no sigue el código

	call ecom_incSubstate
	ld l,Enemy.counter1
	ld (hl),30 ;counter = 48

	; se limpian los flags de la OAM
	ld l,Enemy.oamFlagsBackup
	xor a
	ldi (hl),a 
	ld (hl),a

	ld l,Enemy.zh
	dec (hl) ;se mueve un poco Veran hacia abajo
	call objectSetVisible83 ; se pone visibilidad 83
	ld a,$05
	call enemySetAnimation ;nueva animación
	ld a,$04
	jp fadeinFromWhiteWithDelay ;fade desde blanco

@mimicPositions:
	.db $33 $73 $3b $7b

; cuando termina el fade desde blanco espera un poco y muestra un texto
@substateB:
	ld a,(wPaletteThread_mode)
	or a
	ret nz ;cuando termine el fade sigue el código
	call ecom_decCounter1 
	ret nz ;espera hasta que counter1 sea 0
	ld l,e
	inc (hl) ;incrementa substate
	ld bc,TX_5610
	jp showText

; pasa a la lucha contra el boss, devuelve el control al jugador y reproduce música de boss
@substateC:
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

@substate0:
	call ecom_decCounter1
	jp nz,ecom_flickerVisibility ;el boss parpadea
	ld l,e
	inc (hl) ;substate = substate + 1
	jp objectSetVisible82 ;lo hace visible con prioridad 2 (mira el campo visible del ObjectStruct de struct.s).

@substate1:
	call ecom_incSubstate
	ld l,Enemy.counter2
	ld (hl),65 
	ld bc,TX_5612
	jp showText

; cuando termina el texto se crean cuatro explosiones separadas por 16 frames. Además, después de X frames (33 frames, 65 del contador - 32 que es cuando empieza) empieza un fade
; a blanco. Cuando termina el contador se salta a triggear la cutscene.
@substate2:
	call ecom_decCounter2 
	jr z,@triggerCutscene ;cuando el contador sea 0 se salta a la cutscene del intento de huida de la Torre Negra.
	;mientras que no sea 0 el código sigue.

	ld a,(hl) ; [counter2]
	and $0f
	ret nz ;cada 16 frames sigue el código. Esto hace que las explosiones que se van a generar salgan cada 16 frames.
	ld a,(hl) ; [counter2]
	and $f0 ;te quedas con los bits altos
	swap a ;los cambias por los bajos
	dec a ;restas 1
	push af ;guardas af en la pila
	dec a ;restas 1
	call z,fadeoutToWhite ;cuando la resta dé 0 (cuando el contador vaya por 32 en decimal), llamas a fadeoutToWhite, empieza el fade a blanco.
	pop af
	ld hl,@explosionPositions ; se recorre la tabla según el a, que empieza en 3 (el contador era 65 así que la primera vez que el código llega aquí a = 3, luego 2, 1 y 0.
	; Hay cuatro explosiones).
	rst_addDoubleIndex
	ldi a,(hl)
	ld c,(hl)
	ld b,a ;cargas en b y en c la posición de explosión que toca
	call getFreeInteractionSlot
	ret nz
	ld (hl),INTERAC_EXPLOSION ; creas la explosión
	ld l,Interaction.var03
	inc (hl) ; [explosion.var03] = $01 
	jp objectCopyPositionWithOffset ;pones la explosión en la posición determinada por b y c

; Cuando la pantalla esté completamente blanca se elimina a Veran fairy y se salta a la cutscene.
@triggerCutscene:
	ld a,(wPaletteThread_mode)
	or a
	ret nz ;cuando la pantalla esté completamente blanca, se sigue el código.
	call clearAllParentItems
	call dropLinkHeldItem
	ld a,CUTSCENE_BLACK_TOWER_ESCAPE_ATTEMPT
	ld (wCutsceneTrigger),a
	jp enemyDelete

@explosionPositions:
	.db $f0 $f0
	.db $10 $08
	.db $f8 $04
	.db $08 $f8


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
