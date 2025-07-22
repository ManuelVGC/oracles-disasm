; ==================================================================================================
; INTERAC_MISC_PUZZLES
; ==================================================================================================
interactionCode90:
	ld e,Interaction.subid
	ld a,(de)
	rst_jumpTable
	.dw miscPuzzles_subid00
	.dw miscPuzzles_subid01
	.dw miscPuzzles_subid02
	.dw miscPuzzles_subid03
	.dw miscPuzzles_subid04
	.dw miscPuzzles_subid05
	.dw miscPuzzles_subid06
	.dw miscPuzzles_subid07
	.dw miscPuzzles_subid08
	.dw miscPuzzles_subid09
	.dw miscPuzzles_subid0a
	.dw miscPuzzles_subid0b
	.dw miscPuzzles_subid0c
	.dw miscPuzzles_subid0d
	.dw miscPuzzles_subid0e
	.dw miscPuzzles_subid0f
	.dw miscPuzzles_subid10
	.dw miscPuzzles_subid11
	.dw miscPuzzles_subid12
	.dw miscPuzzles_subid13
	.dw miscPuzzles_subid14
	.dw miscPuzzles_subid15
	.dw miscPuzzles_subid16
	.dw miscPuzzles_subid17
	.dw miscPuzzles_subid18
	.dw miscPuzzles_subid19
	.dw miscPuzzles_subid1a
	.dw miscPuzzles_subid1b
	.dw miscPuzzles_subid1c
	.dw miscPuzzles_subid1d
	.dw miscPuzzles_subid1e
	.dw miscPuzzles_subid1f
	.dw miscPuzzles_subid20
	.dw miscPuzzles_subid21


; Boss key puzzle in D6
; Hay dos palancas. Cuando tiras de cualquiera de ellas, si es la primera vez, saldrán serpientes. Después, al volver a tirar de alguna, se tira un elige un número
; aleatorio de 0 a 3 y si es 0, sale el cofre; pero si es distinto de 0, salen las serpientes. Cuando salga el cofre ya se activa un bit de wActiveTriggers y se
; abre la puerta de la sala.
miscPuzzles_subid00:
	ld e,Interaction.state
	ld a,(de)
	rst_jumpTable
	.dw @state0
	.dw @state1
	.dw @state2
	.dw @state3

; State 0: initialization
@state0:
	call interactionIncState

; State 1: waiting for a lever to be pulled
@state1:
	; Return if a lever has not been pulled?
	ld hl,wLever1PullDistance
	bit 7,(hl)
	jr nz,+ ;si el bit 7 de la lever 1 está a 1, saltamos a +
	inc l 
	bit 7,(hl) ;si el bit 7 de la lever 2 está a 1, saltamos a +
	ret z ; si ninguno de ambas lever tiene el bit 7 activado, sale. Ninguna lever está completamente extendida.
+
	; Si alguna de las dos lever ha sido totalmente extendida, sigue el código.

	; Check if the chest has already been opened
	call getThisRoomFlags
	and ROOMFLAG_ITEM
	jr nz,@alreadyOpened ;si ya se ha abierto el cofre, activa el trigger para que se abra la puerta de la sala y borra la interacción.

	; Go to state 2 (or possibly 3, if this gets called again)
	call interactionIncState

	; Check whether this is the first time pulling the lever
	ld l,Interaction.counter2
	ld a,(hl)
	or a
	jr nz,@checkRng ;Si counter2 != 0, salta a checkRNG

	; Si counter2 = 0, entonces es la primera vez tirando de una lever
	; This was the first time pulling the lever; always unsuccessful
	ld (hl),$01
	jr @error

@checkRng:
	; Get a number between 0 and 3.
	call getRandomNumber
	and $03

	; If the number is 0, the chest will appear; go to state 3.
	jp z,interactionIncState

	; If the number is 1-3, make the snakes appear. 
@error:
	ld a,SND_ERROR
	call playSound

	ld a,(wActiveTilePos)
	ld (wWarpDestPos),a

	ld hl,wTmpcec0
	ld b,$20
	call clearMemory

	callab roomInitialization.generateRandomBuffer ;se seleccionan posiciones aleatorias donde saldrán los enemigos cada vez que se falla.

	; Spawn the snakes?
	ld hl,objectData.objectData78db
	jp parseGivenObjectData

; State 2: lever has been pulled unsuccessfully. Wait for snakes to be killed before
; returning to state 1.
@state2:
	ld a,(wNumEnemies)
	or a
	ret nz ;cuando mates todas las serpientes, se vuelve al state1.

	; Go back to state 1
	ld a,$01
	ld e,Interaction.state
	ld (de),a
	ret

; State 3: lever has been pulled successfully. Make the chest and delete self.
; Cuando aciertas el RNG sale el cofre y se activa el trigger para que se abra la puerta y se borra la interacción.
@state3:
	ld a,$01
	ld (wActiveTriggers),a
	jpab agesInteractionsBank08.spawnChestAndDeleteSelf

@alreadyOpened:
	ld a,$01
	ld (wActiveTriggers),a
	jp interactionDelete



; Underwater switch hook puzzle in past d6
; Comprueba que en X tiles haya tilesindex de switch diamond.
miscPuzzles_subid01:
	call interactionDeleteAndRetIfEnabled02
	call miscPuzzles_deleteSelfAndRetIfItemFlagSet

	ld hl,@diamondPositions
	call miscPuzzles_verifyTilesAtPositions
	ret nz
	jpab agesInteractionsBank08.spawnChestAndDeleteSelf

@diamondPositions:
	.db TILEINDEX_SWITCH_DIAMOND
	.db $16 $17 $18
	.db $26 $27 $28
	.db $00



; Spot to put a rolling colored block on in present d6
miscPuzzles_subid02:
	call interactionDeleteAndRetIfEnabled02

	; Check that the tile at this position matches the cube color
	call objectGetTileAtPosition
	sub TILEINDEX_RED_TOGGLE_FLOOR
	ld b,a ;guarda en b el color del tile donde está la interacción
	ld a,(wRotatingCubePos)
	cp l
	ret nz
	ld a,(wRotatingCubeColor)
	and $03
	cp b ;compara el color del tile donde está la interacción con el color del dado
	ret nz

	; They match.
	ld c,l
	ld a,TILEINDEX_STANDARD_FLOOR
	call setTile ;cambia el tile por un tileindex de suelo normal
	ld b,>wRoomCollisions
	ld a,$0f
	ld (bc),a
	ld a,SND_SOLVEPUZZLE
	call playSound
	jp interactionDelete



; Chest from solving colored cube puzzle in d6 (related to subid $02)
miscPuzzles_subid03:
	call interactionDeleteAndRetIfEnabled02
	call miscPuzzles_deleteSelfAndRetIfItemFlagSet

	ld hl,@wantedFloorTiles
	call miscPuzzles_verifyTilesAtPositions
	ret nz
	jpab agesInteractionsBank08.spawnChestAndDeleteSelf

@wantedFloorTiles:
	.db TILEINDEX_STANDARD_FLOOR ;tile que esperamos
	.db $37 $65 $69 ;posiciones en la que lo esperamos
	.db $00 ;fin de tabla

;;
; @param	hl	Pointer to data. First byte is a tile index; then an arbitrary
;			number of positions in the room where that tile should be; $ff to
;			give a new tile index; $00 to stop.
; @param[out]	zflag	z if all tiles matched as expected.
; Comprueba las posiciones de la sala que se le pasan con @wantedFloorTiles para ver si hay suelo normal en ellas. 
miscPuzzles_verifyTilesAtPositions:
	ld b,>wRoomLayout
@newTileIndex:
	ldi a,(hl) ;a = tileindex_standard_floor. Queremos ver si los tiles en las posiciones indicadas en @wantedFloorTiles son de ese tipo.
	or a
	ret z
	ld e,a ; e = a
@nextTile:
	ldi a,(hl) ;lee una posición de las que le pasamos.
	ld c,a
	or a
	ret z
	inc a
	jr z,@newTileIndex
	ld a,(bc)
	cp e ;compara el tileindex en la posición con e (tileindex de suelo normal). Si no coincide sale, si coincide sigue comprobando el resto de posiciones que
	; se le han pasado con la tabla.
	ret nz
	jr @nextTile



; Floor changer in present D6, triggered by orb
miscPuzzles_subid04:
	call checkInteractionState
	jr z,@state0

@state1:
	; Check for change in state
	ld a,(wToggleBlocksState)
	ld b,a
	ld e,Interaction.counter2
	ld a,(de)
	cp b ;compara el estado actual del orbe (b) con el estado anterior del orbe (counter2).
	ret z ;Si es igual, no ha cambiado, sale. Si no, sigue.

	ld a,b
	ld (de),a ;actualiza counter2 con el estado actual
	ld a,$ff
	ld (wDisabledObjects),a
	ld (wMenuDisabled),a

	ld e,Interaction.counter1
	ld a,(de) ;a = counter1
	inc a ;incrementa a que sería 0 ó 1 así que será 1 ó 2
	and $01 ;se queda solo con el bit más bajo así que a pasará a ser 0 ó 1.
	ld b,a ;b = a = 0 ó 1. 
	ld (de),a ;counter1 = a = 0 ó 1.

	ld c,$05
	call @spawnSubid
	ld c,$06
	call @spawnSubid
	callab bank16.loadD6ChangingFloorPatternToBigBuffer ;carga en el buffer los dos mapas de tiles distintos que habrá. Según el valor de b se mostrará uno u otro.
	ret

@spawnSubid:
	call getFreeInteractionSlot
	ret nz
	ld (hl),INTERAC_MISC_PUZZLES
	inc l
	ld (hl),c
	inc l
	ld (hl),b
	ret

; Guarda el estado inicial del orbe (wToggleBlocksState) en counter2.
@state0:
	ld a,(wToggleBlocksState)
	ld e,Interaction.counter2
	ld (de),a
	jp interactionIncState


; Helpers for floor changer (subid $04).
; Pintan los tiles cargados en el subid $04.
miscPuzzles_subid05:
miscPuzzles_subid06:
	ld e,Interaction.substate
	ld a,(de)
	or a
	jr nz,@substate1

; Carga las variables var30, var31, var32 y var33 con la forma de pintar los tiles.
@substate0:
	ld e,Interaction.subid
	ld a,(de)
	sub $05 ;a = 0 ó 1. 
	add a
	ld hl,@data
	rst_addDoubleIndex
	ld b,$04
	ld e,Interaction.var30
	call copyMemory ;copia b bytes desde var30.
	jp interactionIncSubstate

; Values for var30-var33
; var30: Start position. Posición inicial desde la que escribir los tiles.
; var31: Value to add to position (Y) (alternates direction each column). Moverse una fila hacia arriba o hacia abajo (distancia a añadir para pasar a otra fila)
; var32: Value to add to position (X). Moverse una columna hacia arriba o hacia abajo (distancia a añadir para pasar a otra columna).
; var33: Offset in wBigBuffer to read from. Desde dónde leer en wBigBuffer.
@data:
	.db $91 $f0 $01 $00 ; subid 5. El subid 5 pinta la mitad de la sala. $f0 = moverse una fila hacia arriba. $01 = moverse una columna hacia la derecha.
	.db $1d $10 $ff $80 ; subid 6. El subid 6 pinta la otra mitad de la sala. $10 = moverse una fila hacia abajo. $ff = moverse una columna hacia la izquierda.

@substate1:
	ld e,Interaction.var33
	ld a,(de)
	ld l,a
	ld h,>wBigBuffer

; escribe el siguiente tile que toque escribir. Recorre el buffer por columnas y dentro de esas columnas lo va pintando por filas. Cuando se llega a final de columna
; pasa a la siguiente y se invierte la forma de recorrerla, si al principio se recorría de arriba abajo, después que empiezas la columna por abajo se recorrería de abajo
; arriba.
@nextTile:
	ldi a,(hl)
	or a
	jr z,@deleteSelf
	cp $ff
	jr nz,@setTile ;si el valor leído no es ff, escribes el tile

	; si es ff, cambias de columna a la siguiente.
	ld e,Interaction.var32
	ld a,(de)
	ld b,a
	ld e,Interaction.var30
	ld a,(de)
	add b
	ld (de),a

	; se invierte el desplazamiento vertical, para que se pinte al revés, haciendo un efecto de zigzag. Es decir, imagínate, primera columna se pinta el tile de arriba
	; a la izquierda, luego el de debajo de ese, luego el de debajo de ese, etc. Luego, cuando termina la columna, se pasa a la siguiente y se invierte este
	; desplazamiento, pasando al tile de arriba, luego al de arriba suya y así.
	ld e,Interaction.var31
	ld a,(de)
	cpl ;invierte el valor que se le pase
	inc a
	ld (de),a
	call @nextRow ;vas recorriendo por filas cada columna para ir escribiendo los tiles
	jr @nextTile

@setTile:
	ldh (<hFF8B),a
	ld e,Interaction.var33
	ld a,l
	ld (de),a
	call @nextRow
	ldh a,(<hFF8B)
	jp setTile

; [var30] += [var31]
@nextRow:
	ld e,Interaction.var31
	ld a,(de)
	ld b,a
	ld e,Interaction.var30
	ld a,(de)
	ld c,a
	add b
	ld (de),a
	ret

@deleteSelf:
	xor a
	ld (wDisabledObjects),a
	ld (wMenuDisabled),a
	jp interactionDelete



; Wall retraction event after lighting torches in past d6
miscPuzzles_subid07:
	call checkInteractionState
	jr z,@state0

; Cuando cambia el número de antorchas encendidas comprueba el orden de encendido y si es incorrecto, las apaga, y si es correcto, cuando llega a 4 encendidas,
; mueve la pared.
@state1:
	call checkLinkVulnerable
	ret nc

	; Check if the number of lit torches has changed.
	call @checkLitTorches
	ld e,Interaction.counter1
	ld a,(de)
	cp b ;compara el estado de las antorchas que guardó en el state1 con el estado actual de las antorchas (b)
	ret z ;si no ha cambiado, sale, si sí, sigue

	; It's changed.
	ld a,b
	ld (de),a ;actualiza counter1 con el estado actual de las antorchas

	ld e,Interaction.substate ;número de antochas encendidas
	ld a,(de)
	ld hl,@torchLightOrder
	rst_addAToHl
	ld a,(hl)
	cp b ;compara que la antorcha encendida esté en su orden correcto. Por ejemplo, si hay dos antorchas encendidas a = 0011 y si las antorchas encendidas no
	; se hubiesen encendido en orden, pon por ejemplo que se encendió primero la primera y luego la cuarta, b = 1001, así que como a != b, no se han encendido en
	; orden. La primera estaba en orden, a = 0001 y b = 0001, pero en la segunda falla.
	jr nz,@litWrongTorch

	ld a,(de)
	cp $03
	jp c,interactionIncSubstate ; si aún no hay cuatro antorchas encendidas, aumenta el número de encendidas

	; Lit all torches
	ld a, $ff ~ (DISABLE_ITEMS | DISABLE_ALL_BUT_INTERACTIONS)
	ld (wDisabledObjects),a
	ld (wMenuDisabled),a

	;Cuando todas las antorchas estén encendidas hace el movimiento de la pared
	ld a,CUTSCENE_WALL_RETRACTION
	ld (wCutsceneTrigger),a

	; Set bit 6 in the present version of this room
	call getThisRoomFlags
	ld l,<ROOM_AGES_525
	set 6,(hl)
	jp interactionDelete

; apaga las antorchas y vuelve a crear las PART_LIGHTABLE_TORCH
@litWrongTorch:
	xor a
	ld (de),a
	ld e,Interaction.counter1
	ld (de),a
	ld a,SND_ERROR
	call playSound
	ld a,TILEINDEX_UNLIT_TORCH
	ld c,$31
	call setTile
	ld a,TILEINDEX_UNLIT_TORCH
	ld c,$33
	call setTile
	ld a,TILEINDEX_UNLIT_TORCH
	ld c,$35
	call setTile
	ld a,TILEINDEX_UNLIT_TORCH
	ld c,$53
	call setTile
	jr @makeTorchesLightable

@torchLightOrder:
	.db $01 $03 $07 $0f ;0001 0011 0111 1111. Establece el orden en que que deben encenderse, primero la del bit 0, luego la del 1, etc.


; Si ya se ha resuelto el puzzle (4 antorchas encendidas en el orden correcto), borra la interacción.
; Si no, guarda las antorchas encendidas (0000, el código solo se ejecuta al entrar a la sala así que están todavía apagadas (estado inicial)).
@state0:
	call getThisRoomFlags
	and ROOMFLAG_80
	jp nz,interactionDelete ;cuando ya se haya retraido la pared, se borra la interacción

	call interactionIncState
	call @checkLitTorches ;actualiza el bitmask b indicando qué antorchas están encendidas
	ld a,b
	ld e,Interaction.counter1
	ld (de),a ;guarda en counter1 el estado de las antorchas encendidas

@makeTorchesLightable:
	call @makeTorchesUnlightable ;borra las part_lightable_torch
	ld hl,objectData.objectData_makeTorchesLightableForD6Room ;las vuelve a crear
	jp parseGivenObjectData

;; Borra las PART_LIGHTABLE_TORCH
@makeTorchesUnlightable:
	ldhl FIRST_PART_INDEX, Part.id
--
	ld a,(hl)
	cp PART_LIGHTABLE_TORCH
	call z,@deletePartObject
	inc h
	ld a,h
	cp LAST_PART_INDEX+1
	jr c,--
	ret

@deletePartObject:
	push hl
	dec l
	ld b,$40
	call clearMemory
	pop hl
	ret

;;
; @param[out]	b	Bitset of lit torches (in bits 0-3)
; Comprueba qué antorchas están encendidas y construye un bitmask con esa información
@checkLitTorches:
	ld a,TILEINDEX_LIT_TORCH
	ld b,$00 ;bitmask de antorchas encendidas
	ld hl,wRoomLayout+$31
	cp (hl) ;compara si el tile en la posición (3,1) es una antorcha encendida
	jr nz,+ ;sino, salta a comprobar la siguiente antorcha
	set 0,b ;si el tileindex es una antorcha encendida activa el bit 0 del bitmask b.
+
	ld l,$33
	cp (hl) ;compara si el tile en la posición (3,3) es una antorcha encendida
	jr nz,+
	set 1,b ;si el tileindex es una antorcha encendida activa el bit 1 del bitmask b.
+
	ld l,$53
	cp (hl) ;compara si el tile en la posición (5,3) es una antorcha encendida
	jr nz,+
	set 2,b ;si el tileindex es una antorcha encendida activa el bit 2 del bitmask b.
+
	ld l,$35
	cp (hl) ;compara si el tile en la posición (3,5) es una antorcha encendida
	ret nz
	set 3,b ;si el tileindex es una antorcha encendida activa el bit 3 del bitmask b.
	ret



; Checks to set the "bombable wall open" bit in d6 (north)
miscPuzzles_subid08:
	call interactionDeleteAndRetIfEnabled02
	call getThisRoomFlags
	bit ROOMFLAG_BIT_KEYDOOR_UP,(hl)
	ret z
	ld l,<ROOM_AGES_519
	set ROOMFLAG_BIT_KEYDOOR_UP,(hl)
	jp interactionDelete



; Checks to set the "bombable wall open" bit in d6 (east)
miscPuzzles_subid09:
	call interactionDeleteAndRetIfEnabled02
	call getThisRoomFlags
	bit ROOMFLAG_BIT_KEYDOOR_RIGHT,(hl)
	ret z
	ld l,<ROOM_AGES_526
	set ROOMFLAG_BIT_KEYDOOR_RIGHT,(hl)
	jp interactionDelete



; Jabu-jabu water level controller script, in the room with the 3 buttons.
; Controla el valor de wJabuWaterLevel dependiendo de los botones pulsados.
miscPuzzles_subid0a:
	ld e,Interaction.state
	ld a,(de)
	rst_jumpTable
	.dw @state0
	.dw @state1
	.dw @state2
	.dw @state3

;Inicialización. Carga wActiveTriggers en var30 y el estado de los botones en wSwitchState.
@state0:
	ld a,(wActiveTriggers)
	ld e,Interaction.var30
	ld (de),a ;carga wActiveTriggers en var30

	ld a,(wJabuWaterLevel)
	and $f0 ;se queda solo con los bits altos de wJabuWaterLevel
	ld (wSwitchState),a ;guarda los bits altos de wJabuWaterLevel en wSwitchState. Guarda el estado de los botones en el wSwitchState, vaya.
	jp interactionIncState

; Compruebas qué botón se ha pulsado. Dependiendo de cuál se drena o aumenta el nivel del agua.
@state1:
	; Comprobación de si se ha pulsado un botón.
	ld a,(wActiveTriggers)
	ld b,a
	ld e,Interaction.var30
	ld a,(de)
	xor b ;se ponen en 1 los bits que han cambiado de wActiveTriggers
	ld c,a ;se cargan esos bits cambiados en c
	ld a,b 
	ld (de),a ;se actualiza el var30 con los wActiveTriggers actuales

	bit 7,c ;comprueba el bit 7 de c. Recordamos que el botón A (el que vacía de agua la mazmorra) activa el bit 7 de wActiveTriggers. Básicamente, si se pulsa
	; ese botón, la mazmorra se drena.
	jr nz,@drainWater ; Si es 1 el bit 7 de c, es decir, ha cambiado el bit 7 de wActiveTriggers, drena el agua.

	; Si wActiveTriggers nuevos AND c == 0, entonces no ha habido ningún cambio (que eso solo pasa si no se han cambiado wActiveTriggers, se podría haber comprobado
	; c directamente creo yo).
	and c ; Se hace a and c. Es decir, wActiveTriggers actual AND bits que habían cambiado.
	ret z ;si no ha habido cambios, sale.

	; Si sí han cambiado wActiveTriggers pero el anterior botón pulsado es el mismo, sale. Es decir, en wSwitchState tienes guardado el comportamiento de los botones
	; si el botón C se pulsa, el wSwitchState guarda que se ha pulsado ese botón y lo guarda como pulsado. Si después pulsas
	; el botón C otra vez, como wSwitchSatate lo tiene como pulsado, no pasa nada. Esto no se puede hacer con wActiveTriggers porque los botones se desactivan al
	; despisarlos, poniendo a 0 de nuevo wActiveTriggers.
	ld a,(wSwitchState)
	and c 
	ret nz ;si el botón ya estaba activado antes, sale.

	;Si se ha pulsado un botón que no estaba pulsado antes y no es el de drenar el agua, es decir, si se han pulsado el botón B o C (los que suben un nivel
	; el nivel del agua), sigue.
	;Actualizas wSwitchState.
	ld a,c ;cargas el bitmask que indica qué botón ha cambiado (4 para el C, 5 para el B).
	ld hl,wSwitchState 
	or (hl)
	ld (hl),a ;activas el bit de wSwitchState correspondiente al bótón que se ha activado

	;Actualizas wJabuWaterLevel con wSwitchState en la parte alta y nivel de agua actual + 1 en la parte baja.
	and $f0 ;te quedas solo con la parte alta de ese byte.
	ld b,a ;cargas eso en b
	ld hl,wJabuWaterLevel 
	ld a,(hl) ;cargas el nivel del agua en a
	and $03 ;te quedas solo con los bits bajos
	inc a ;sumas 1, es decir, subes un piso el nivel del agua.
	or b 
	ld (hl),a ;actualizas wJabuWaterLevel ya con la información de botones en los bits altos y la información del nivel del agua en los bits bajos.
.ifndef REGION_JP
	ld a,<TX_1209 ;texto que indica que el agua sube
.endif
	jr @beginCutscene

; Pone wJabuWaterLevel a 0 (tanto botones como nivel del agua) y wSwitchState a 0.
@drainWater:
	ld a,(wJabuWaterLevel)
	and $07
	ret z ; si se ha pulsado el botón A pero no hay agua en la mazmorra, sale, no hace nada.
	xor a
	ld (wJabuWaterLevel),a ;se pone a 0 el wJabuWaterLevel
	ld (wSwitchState),a ;se pone a 0 el estado de los botones
.ifndef REGION_JP
	ld a,<TX_1208 ;carga un texto de "Se ha drenado el agua"
.endif

; Desactiva Link y demás y para la música.
@beginCutscene:
.ifndef REGION_JP
	ld e,Interaction.var31
	ld (de),a ;carga en var31 el texto
.endif

	;desactiva interacciones y a Link
	ld a,DISABLE_ALL_BUT_INTERACTIONS | DISABLE_LINK
	ld (wDisabledObjects),a
	ld (wMenuDisabled),a 

	ld e,Interaction.counter1
	ld a,60
	ld (de),a ;carga counter1 a 60

	ld a,SNDCTRL_STOPMUSIC 
	call playSound ;para la música actual
	jp interactionIncState

; Espera ciertos frames, se agita la pantalla y suena agua.
@state2:
	call interactionDecCounter1
	ret nz ;espera 60 frames después de la cutscene.

	ld a,$f0
	ld (hl),a ;se recarga el counter1
	call setScreenShakeCounter ;tiembla la pantalla
	ld a,SND_FLOODGATES 
	call playSound ;sonido de agua
	jp interactionIncState

; Espera ciertos frames, muestra un texto, reactiva Link y demás y la música.
@state3:
	call interactionDecCounter1
	ret nz ;espera a que termine counter1

	ld l,Interaction.state
	ld (hl),$01 ;vuelve al state1

	;reactivas interacciones, Link y demás.
	xor a
	ld (wDisabledObjects),a
	ld (wMenuDisabled),a

.ifdef REGION_JP
	ld bc,TX_1209
.else
	ld b,>TX_1200
	ld l,Interaction.var31
	ld c,(hl)
.endif
	call showText ;se muestra el texto de agua ha subido o se ha drenado

	ld a,SNDCTRL_STOPSFX
	call playSound
	ld a,(wActiveMusic)
	jp playSound ;vuelve la música



; Ladder spawner in d7 miniboss room
miscPuzzles_subid0b:
	ld e,Interaction.state
	ld a,(de)
	rst_jumpTable
	.dw miscPuzzles_deleteSelfOrIncStateIfRoomFlag7Set
	.dw @state1
	.dw @state2

@state1:
	ld a,(wNumEnemies)
	or a
	ret nz

	call getThisRoomFlags
	set ROOMFLAG_BIT_80,(hl)
	ld l,<ROOM_AGES_54d
	set ROOMFLAG_BIT_80,(hl)
	ld e,Interaction.counter1
	ld a,$08
	ld (de),a
	jp interactionIncState

@state2:
	call interactionDecCounter1
	ret nz

	; Add the next ladder tile
	ld (hl),$08
	call objectGetTileAtPosition
	ld c,l
	ld a,c
	ldh (<hFF92),a

	ld a,TILEINDEX_SS_LADDER
	call setTile

	ld b,INTERAC_PUFF
	call objectCreateInteractionWithSubid00

	ld e,Interaction.yh
	ld a,(de)
	add $10
	ld (de),a

	ldh a,(<hFF92)
	cp $90
	ret c

	; Restore the entrance on the left side
	ld c,$80
	ld a,TILEINDEX_SS_52
	call setTile
	ld c,$90
	ld a,TILEINDEX_SS_EMPTY
	call setTile

	ld a,SND_SOLVEPUZZLE
	call playSound
	xor a
	ld (wDisableLinkCollisionsAndMenu),a
	jp interactionDelete



; Switch hook puzzle early in d7 for a small key
miscPuzzles_subid0c:
	call interactionDeleteAndRetIfEnabled02
	call miscPuzzles_deleteSelfAndRetIfItemFlagSet

	ld hl,miscPuzzles_subid0c_wantedTiles
	call miscPuzzles_verifyTilesAtPositions
	ret nz

;;
miscPuzzles_dropSmallKeyHere:
	ldbc TREASURE_SMALL_KEY, $01
	call createTreasure
	ret nz
	call objectCopyPosition
	jp interactionDelete

miscPuzzles_subid0c_wantedTiles:
	.db TILEINDEX_SWITCH_DIAMOND
	.db $36 $3a $76 $7a
	.db $00



; Staircase spawner after moving first set of stone panels in d8
miscPuzzles_subid0d:
	ld e,Interaction.state
	ld a,(de)
	rst_jumpTable
	.dw @state0
	.dw @state1
	.dw @state2

@state0:
	call getThisRoomFlags
	and ROOMFLAG_40
	jp nz,interactionDelete

	ld a,(wNumTorchesLit)
	cp $01
	ret nz
	ld hl,wActiveTriggers
	ld a,(hl)
	cp $07
	ret nz

	ld e,Interaction.counter1
	ld a,30
	ld (de),a
	ld a,$08
	call setScreenShakeCounter
	ld a,SND_DOORCLOSE
	call playSound
	jp interactionIncState

@state1:
	call interactionDecCounter1
	ret nz

	ld hl,wActiveTriggers
	ld a,(hl)
	cp $07
	jr z,++
	ld e,Interaction.state
	xor a
	ld (de),a
	ret
++
	set 7,(hl)
	jp interactionIncState

@state2:
	; Wait for bit 7 of wActiveTriggers to be unset by another object?
	ld a,(wActiveTriggers)
	bit 7,a
	ret nz

	ld a,SND_SOLVEPUZZLE
	call playSound
	ld b,INTERAC_PUFF
	call objectCreateInteractionWithSubid00

	call objectGetTileAtPosition
	ld c,l
	ld a,TILEINDEX_NORTH_STAIRS
	call setTile
	jp interactionDelete



; Staircase spawner after putting in slates in d8
miscPuzzles_subid0e:
	call checkInteractionState
	jp nz,@state1

@state0:
	call getThisRoomFlags
	bit ROOMFLAG_BIT_40,(hl)
	jp nz,interactionDelete

	; Wait for all slates to be put in
	ld a,(hl)
	and ROOMFLAG_01|ROOMFLAG_02|ROOMFLAG_04|ROOMFLAG_08
	cp  ROOMFLAG_01|ROOMFLAG_02|ROOMFLAG_04|ROOMFLAG_08
	ret nz

	ld hl,wActiveTriggers
	set 7,(hl)
	jp interactionIncState

@state1:
	; Wait for another object to unset bit 7 of wActiveTriggers?
	ld a,(wActiveTriggers)
	bit 7,a
	ret nz

	ld a,SND_SOLVEPUZZLE
	call playSound
	ld b,INTERAC_PUFF
	call objectCreateInteractionWithSubid00

	call objectGetTileAtPosition
	ld c,l
	ld a,TILEINDEX_NORTH_STAIRS
	call setTile
	jp interactionDelete



; Octogon boss initialization (in the room just before the boss)
miscPuzzles_subid0f:
	ld hl,wTmpcfc0.octogonBoss.loadedExtraGfx
	xor a
	ldi (hl),a
	ldi (hl),a ; [var03] = 0
	dec a
	ldi (hl),a ; [direction] = $ff
	ld (hl),$28 ; [health]
	inc l
	ld (hl),$28 ; [y]
	inc l
	ld (hl),$78 ; [x]
	inc l
	ld (hl),a ; [var30] = $ff
	jp interactionDelete



; Something at the top of Talus Peaks?
miscPuzzles_subid10:
	ld hl,wTmpcfc0.patchMinigame.fixingSword
	ld b,$08
	call clearMemory
	jp interactionDelete



; D5 keyhole opening
miscPuzzles_subid11:
	call checkInteractionState
	jp nz,interactionRunScript

	call returnIfScrollMode01Unset
	call getThisRoomFlags
	and ROOMFLAG_80
	jp nz,interactionDelete

	push de
	call reloadTileMap
	pop de
	ld hl,mainScripts.miscPuzzles_crownDungeonOpeningScript

;;
miscPuzzles_setScriptAndIncState:
	call interactionSetScript
	call interactionSetAlwaysUpdateBit
	jp interactionIncState



; D6 present/past keyhole opening
miscPuzzles_subid12:
	call checkInteractionState
	jp nz,interactionRunScript

	call getThisRoomFlags
	and ROOMFLAG_80
	jp nz,interactionDelete
	ld hl,mainScripts.miscPuzzles_mermaidsCaveDungeonOpeningScript
	jr miscPuzzles_setScriptAndIncState



; Eyeglass library keyhole opening
miscPuzzles_subid13:
	call checkInteractionState
	jp nz,interactionRunScript

	call getThisRoomFlags
	and ROOMFLAG_80
	jp nz,interactionDelete
	ld hl,mainScripts.miscPuzzles_eyeglassLibraryOpeningScript
	jr miscPuzzles_setScriptAndIncState



; Spot to put a rolling colored block on in Hero's Cave
miscPuzzles_subid14:
	call checkInteractionState
	jp z,miscPuzzles_deleteSelfOrIncStateIfRoomFlag7Set

	; Check that the tile at this position matches the cube color
	call objectGetTileAtPosition
	sub TILEINDEX_RED_TOGGLE_FLOOR
	cp $03
	ret nc
	ld b,a
	ld a,(wRotatingCubePos)
	cp l
	ret nz
	ld a,(wRotatingCubeColor)
	and $03
	cp b
	ret nz

	; They match.
	ld c,l
	ld hl,wActiveTriggers
	ld a,b
	call setFlag

	ld a,$a3
	call setTile

	ld b,>wRoomCollisions
	ld a,$0f
	ld (bc),a
	ld a,SND_CLINK
	jp playSound



; Stairs from solving colored cube puzzle in Hero's Cave (related to subid $14)
miscPuzzles_subid15:
	call checkInteractionState
	jp z,miscPuzzles_deleteSelfOrIncStateIfRoomFlag7Set

	ld a,(wActiveTriggers)
	cp $07
	ret nz

	ld a,SND_SOLVEPUZZLE
	call playSound
	ld a,TILEINDEX_INDOOR_DOWNSTAIRCASE
	ld c,$15
	call setTile
	call getThisRoomFlags
	set ROOMFLAG_BIT_80,(hl)
	jp interactionDelete



; Warps Link out of Hero's Cave upon opening the chest
miscPuzzles_subid16:
	ld e,Interaction.state
	ld a,(de)
	rst_jumpTable
	.dw miscPuzzles_deleteSelfOrIncStateIfItemFlagSet
	.dw @state1
	.dw @state2

@state1:
	call getThisRoomFlags
	and ROOMFLAG_ITEM
	ret z
	call interactionIncState

@state2:
	ld a,DISABLE_ALL_BUT_INTERACTIONS | DISABLE_LINK
	ld (wDisabledObjects),a
	ld (wDisableLinkCollisionsAndMenu),a
	call retIfTextIsActive
	ld hl,@warpDestData
	call setWarpDestVariables
	jp interactionDelete

@warpDestData:
	m_HardcodedWarpA ROOM_AGES_048, $01, $28, $03



; Enables portal in Hero's Cave first room if its other end is active
miscPuzzles_subid17:
	call getThisRoomFlags
	push hl
	ld l,<ROOM_AGES_4c9
	bit ROOMFLAG_BIT_ITEM,(hl)
	pop hl
	jr z,+
	set ROOMFLAG_BIT_ITEM,(hl)
+
	jp interactionDelete



; Drops a key in hero's cave block-pushing puzzle
miscPuzzles_subid18:
	call checkInteractionState
	jp z,miscPuzzles_deleteSelfOrIncStateIfItemFlagSet

	ld hl,wRoomLayout+$95
	ld a,(hl)
	cp TILEINDEX_PUSHABLE_STATUE
	ret nz
	ld l,$5d
	ld a,(hl)
	cp TILEINDEX_PUSHABLE_STATUE
	ret nz
	jp miscPuzzles_dropSmallKeyHere



; Bridge controller in d5 room after the miniboss
miscPuzzles_subid19:
	ld e,Interaction.state
	ld a,(de)
	rst_jumpTable
	.dw interactionIncState
	.dw @state1
	.dw @state2
	.dw @state3
	.dw @state4

; Trigger off, waiting for it to be pressed
@state1:
	ld a,(wActiveTriggers)
	rrca
	ret nc
	ld e,Interaction.counter1
	ld a,$08
	ld (de),a
	jp interactionIncState

; Trigger enabled, in the process of extending the bridge
@state2:
	ld a,(wActiveTriggers)
	rrca
	jr nc,@@releasedTrigger ;si el jugador ha releaseado el trigger, se salta a quitar el puente.
	call interactionDecCounter1
	ret nz ;se hace un pequeño delay entre pisar el botón y construir el puente.
	ld (hl),$08
	ld hl,wRoomLayout+$55 ;carga como primera posición a comprobar el tile 55 (posición (5,5) en la sala)
--
	ld c,l
	ldi a,(hl) ;carga el tile actual y salta al siguiente para después
	cp TILEINDEX_BLANK_HOLE ;comprueba si el tileindex de la posición es un agujero
	jr nz,++
	ld a,TILEINDEX_HORIZONTAL_BRIDGE 
	call setTileInAllBuffers ;si es un agujero, lo cambia por una tilendex de puente
	ld a,SND_DOORCLOSE
	jp playSound
++
	ld a,l
	cp $5a ;se compara hasta que el tile que estemos comprobando sea el 5a (se comprueban por tanto del 55 al 59)
	jr c,-- ;mientras no sea 5a, se sigue el bucle
	jp interactionIncState ;cuando ya se haya construido el bucle entero se pasa al siguiente estado

@@releasedTrigger:
	call interactionIncState
	inc (hl)
	ret

; Bridge fully extended, waiting for trigger to be released
@state3:
	ld a,(wActiveTriggers)
	rrca
	ret c
	jp interactionIncState

; Trigger released, in the process of retracting the bridge
; Hace lo mismo que el state2 pero al contrario.
@state4:
	ld a,(wActiveTriggers)
	rrca
	jr c,@@pressedTrigger ;si se presiona el trigger vuelve al state1.
	call interactionDecCounter1
	ret nz

	ld (hl),$08

	ld hl,wRoomLayout+$59
--
	ld c,l
	ldd a,(hl)
	cp TILEINDEX_BLANK_HOLE
	jr z,++

	cp TILEINDEX_SWITCH_DIAMOND
	call z,@createDebris

	ld a,TILEINDEX_BLANK_HOLE
	call setTileInAllBuffers
	ld a,SND_DOORCLOSE
	jp playSound
++
	ld a,l
	cp $55
	jr nc,--

@@pressedTrigger:
	ld e,Interaction.state
	ld a,$01
	ld (de),a
	ret

@createDebris:
	push hl
	push bc
	ld b,INTERAC_ROCKDEBRIS
	call objectCreateInteractionWithSubid00
	pop bc
	pop hl
	ret



; Checks solution to pushblock puzzle in Hero's Cave
miscPuzzles_subid1a:
	call interactionDeleteAndRetIfEnabled02
	call miscPuzzles_deleteSelfAndRetIfItemFlagSet

	ld hl,@wantedTiles
	call miscPuzzles_verifyTilesAtPositions
	ret nz
	jpab agesInteractionsBank08.spawnChestAndDeleteSelf

@wantedTiles:
	.db TILEINDEX_RED_PUSHABLE_BLOCK    $4a $4b $4c $ff
	.db TILEINDEX_YELLOW_PUSHABLE_BLOCK $5a $5c $ff
	.db TILEINDEX_BLUE_PUSHABLE_BLOCK   $6a $6c $00



; Subids $1b-$1d: Spawn gasha seeds at the top of the maku tree at specific times.
; b = essence that must be obtained; c = position to spawn it at.
miscPuzzles_subid1b:
	ldbc $08, $53
	jr ++

miscPuzzles_subid1c:
	ldbc $40, $34
	jr ++

miscPuzzles_subid1d:
	ldbc $20, $34
++
	push bc
	ld a,TREASURE_ESSENCE
	call checkTreasureObtained
	pop bc
	jr nc,@delete
	and b
	jr z,@delete

	call objectSetShortPosition
	call getThisRoomFlags
	and ROOMFLAG_ITEM
	jr nz,@delete

	ld bc,TREASURE_OBJECT_GASHA_SEED_07
	call createTreasure
	call z,objectCopyPosition
@delete:
	jp interactionDelete



; Play "puzzle solved" sound after navigating eyeball puzzle in final dungeon
miscPuzzles_subid1e:
	call returnIfScrollMode01Unset
	ld a,(wScreenTransitionDirection)
	or a
	jp nz,interactionDelete
	ld a,SND_SOLVEPUZZLE
	call playSound
	jp interactionDelete



; Checks if Link gets stuck in the d5 boss key puzzle, resets the room if so
miscPuzzles_subid1f:
	ld e,Interaction.state
	ld a,(de)
	rst_jumpTable
	.dw interactionIncState
	.dw @state1
	.dw @state2

@state1:
	call interactionDecCounter1
	ret nz

	ld (hl),30

	; Get Link's short position in 'e'
	ld hl,w1Link.yh
	ldi a,(hl)
	and $f0
	ld b,a
	inc l
	ld a,(hl)
	and $f0
	swap a
	or b
	ld e,a

	push de
	ld hl,@offsetsToCheck
	ld d,$08

@checkNextOffset:
	ldi a,(hl)
	add e
	ld c,a
	ld b,>wRoomCollisions
	ld a,(bc)
	or a
	jr z,@doneCheckingIfTrapped

	; For odd-indexed offsets only (one tile away from Link), check if we're near the
	; screen edge? If so, skip the next check?
	bit 0,d
	jr nz,++

	ld b,>wRoomLayout
	ld a,(bc)
	or a
	jr nz,++
	inc hl
	dec d
++
	dec d
	jr nz,@checkNextOffset

@doneCheckingIfTrapped:
	ld a,d
	pop de
	or a
	ret nz

	; Link is trapped; warp him out
	call checkLinkVulnerable
	ret nc
	ld a,DISABLE_LINK
	ld (wMenuDisabled),a
	ld (wDisabledObjects),a
	ld a,SND_ERROR
	call playSound

	ld e,Interaction.counter1
	ld a,60
	ld (de),a
	jp interactionIncState

; Checks if there are solid walls / holes at all of these positions relative to Link
@offsetsToCheck:
	.db $f0 $e0 $01 $02 $10 $20 $ff $fe

@state2:
	call interactionDecCounter1
	ret nz
	xor a
	ld (wMenuDisabled),a
	ld (wDisabledObjects),a
	ld hl,@warpDest
	jp setWarpDestVariables

@warpDest:
	m_HardcodedWarpA ROOM_AGES_49b, $00, $12, $03



; Money in sidescrolling room in Hero's Cave
miscPuzzles_subid20:
	call getThisRoomFlags
	and ROOMFLAG_ITEM
	jr nz,@delete

	ld bc,TREASURE_OBJECT_RUPEES_16
	call createTreasure
	jp nz,@delete
	call objectCopyPosition
@delete:
	jp interactionDelete



; Creates explosions while screen is fading out
miscPuzzles_subid21:
	call checkInteractionState
	jr z,@state0

	ld a,(wPaletteThread_mode)
	or a
	jp z,interactionDelete

	ld a,(wFrameCounter)
	ld b,a
	and $1f
	ret nz

	ld a,b
	and $70
	swap a
	ld hl,@explosionPositions
	rst_addDoubleIndex
	ldi a,(hl)
	ld b,a
	ld c,(hl)
	call getFreeInteractionSlot
	ret nz
	ld (hl),INTERAC_EXPLOSION
	jp objectCopyPositionWithOffset

@explosionPositions:
	.db $f4 $0c
	.db $04 $fb
	.db $08 $10
	.db $fe $f4
	.db $0c $08
	.db $fc $04
	.db $06 $f8
	.db $f8 $fe

@state0:
	call interactionIncState
	ld a,$04
	jp fadeoutToWhiteWithDelay

;;
miscPuzzles_deleteSelfAndRetIfItemFlagSet:
	call getThisRoomFlags
	and ROOMFLAG_ITEM
	ret z
	pop hl
	jp interactionDelete

;;
miscPuzzles_deleteSelfOrIncStateIfItemFlagSet:
	call getThisRoomFlags
	and ROOMFLAG_ITEM
	jp nz,interactionDelete
	jp interactionIncState

;;
miscPuzzles_deleteSelfOrIncStateIfRoomFlag7Set:
	call getThisRoomFlags
	and ROOMFLAG_80
	jp nz,interactionDelete
	jp interactionIncState

;;
; Unused
miscPuzzles_deleteSelfOrIncStateIfRoomFlag6Set:
	call getThisRoomFlags
	and ROOMFLAG_40
	jp nz,interactionDelete
	jp interactionIncState
