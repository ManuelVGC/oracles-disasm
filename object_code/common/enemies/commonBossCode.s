; This code is included at the start of banks $0f-$10. Similar to "enemyCommon.s", but
; only for those two banks since they deal with boss enemies.
;
; Function names are prefixed with "enemyBoss" to show they come from here.


;;
; Enemy bosses call this when they're dead (ENEMYSTATUS_NO_HEALTH). They don't disappear
; right away, they flicker for a second, then explode.
enemyBoss_dead:
	ld h,d
	ld l,Enemy.collisionType
	ld a,(hl)
	or a
	jr z,@alreadyPlayedDeathSound ;si collisionType es 0, salta.

	ld (hl),$00 ;collisionType = 0. Se desactivan las colisiones de forma que Link no pueda interactuar con él mientras muere.
	ld l,Enemy.counter1
	ld (hl),120
	ld a,$01
	ld (wDisableLinkCollisionsAndMenu),a ;se evita que el jugador interfiera de alguna forma durante la muerte del boss
	ld a,SND_BOSS_DEAD
	call playSound ;reproduce sonido de boss derrotado

@alreadyPlayedDeathSound:
	call ecom_decCounter1
	jp nz,ecom_flickerVisibility ;parpadea unos frames

	inc (hl) ;contador = contador + 1. Por seguridad extra. Si se vuelve a ejecutar la rutina por lo que sea, sigue directamente el código en vez de parpadear.
	; Dejamos preparado el contador en 1, de forma que al entrar y restar 1, pase a 0 y siga el código.

	; Spawn explosion
	call getFreePartSlot ;creamos una part para la explosión
	ret nz
	ld (hl),PART_BOSS_DEATH_EXPLOSION
	inc l
	ld e,Enemy.id
	ld a,(de)
	ld (hl),a ; [Part.subid] = [Enemy.id]

	call objectCopyPosition ;copia la posición del objeto d al objeto h, en este caso del boss a la explosión
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

;;
; Creates a "large shadow" object and attaches it to the enemy.
;
; @param	b	Shadow size (0-2 for small-large)
; @param	c	Y-offset of shadow relative to self
; @param[out]	zflag	z on success
enemyBoss_spawnShadow:
	call getFreePartSlot
	ret nz
	ld (hl),PART_SHADOW
	inc l
	ld (hl),b ; [subid]
	inc l
	ld (hl),c ; [var03]
	ld l,Part.relatedObj1
	ld a,Enemy.start
	ldi (hl),a
	ld (hl),d
	xor a
	ret

;;
; Loads extra graphics for enemy, palette header, stops music, forces Link to walk into
; the room.
;
; @param	a	Enemy ID for graphics to load (or $ff to not load extra graphics)
; @param	b	Palette header to load (or 0 for none)
enemyBoss_initializeRoom:
	bit 7,a
	jr nz,+
	ld (wEnemyIDToLoadExtraGfx),a ;si tienes que cargar gfx extra el a es el id del enemigo, sino es ff.
+
	ld a,b
	or a
	call nz,loadPaletteHeader ;b = 0 si no tienes que cargar una palette header.
	; si no usas ninguna de estas cosas extras usas directamente enemyBoss_initializeRoomWithoutExtraGfx.

	; Fall through

;;
; Stops music, forces Link to walk into the room.
enemyBoss_initializeRoomWithoutExtraGfx:
.ifdef ROM_SEASONS
	ldh a,(<hActiveObject)
	ld d,a
.endif
	ld a,SNDCTRL_STOPMUSIC
	call playSound ;paramos música

	xor a
	ld (wDisableLinkCollisionsAndMenu),a ;habilitamos colisiones y menú
	dec a
	ld (wActiveMusic),a ;activeMusic = ff, que indica que no hay música

	ld hl,wcc93
	set 7,(hl) ;parece tener que ver con el manejo de las puertas de la sala, que se cierran al entrar y se abren al derrotar al boss

	ld a,(wScrollMode)
	and SCROLLMODE_01 
	ret nz ;si la pantalla se está desplazando se sale continuamente hasta que pare el desplazamiento

	ld a,LINK_STATE_FORCE_MOVEMENT 
	ld (wLinkForceState),a ;se activa ese estado de Link (linkStates.s) que indica que será movido, el jugador pasa a no controlar a Link

.ifdef ROM_AGES
	ld a,$16
.else; ROM_SEASONS
	ld a,$1a
.endif
	ld (wLinkStateParameter),a ;número de frames que se mantendrá en estado marioneta (siendo movido) antes de devolver el control al jugador

	ld hl,w1Link.direction
	ld a,(wScreenTransitionDirection)
	ldi (hl),a ;pone la dirección de Link a la dirección de transición de la pantalla y deja l apuntando al ángulo.
	swap a 
	rrca
	ld (hl),a ;se setea el ángulo de Link en función de hacia dónde mira el sprite (se calcula el ángulo haciendo ese swap a + rrca a partir de la dirección, consiguiendo
	; los valores de directions.s).
	ret

	; Dirección = dónde mira el sprite
	; Ángulo = hacia dónde se mueve el sprite


.ifdef ROM_AGES

;;
; Plays miniboss music, enables controls.
enemyBoss_beginMiniboss:
	ld b,MUS_MINIBOSS
	jr ++

;;
; Plays boss music, enables controls.
enemyBoss_beginBoss:
	ld b,MUS_BOSS
++
	xor a
	ld (wDisabledObjects),a
	ld (wMenuDisabled),a
	ld a,b
	ld (wActiveMusic),a
	jp playSound


.endif ; ROM_AGES
