; ==================================================================================================
; INTERAC_DUNGEON_EVENTS
; ==================================================================================================

; Los dungeonEvents ejecutan todo su código cada frame. Cada frame vuelven a ejecutarse desde el principio por lo que se usan cosas como los contadores o los states.

; Los contadores por ejemplo ayudan a que no se ejecute más código hasta que no se llega a X valor. Por ejemplo, cada frame se ejecuta el código y hace una
; comprobación de si el contador es 0, sino, decrementa el contador y sale. Siguiente frame, se ejecuta desde el principio, y lo mismo, hasta que en un frame se
; ejecute desde el principio y el contador ya sea 0 y por tanto siga el código.
; Los states por otra parte ayudan para que el código entre dentro de otra parte nueva. Por ejemplo, primer frame se ejecuta desde el principio y se entra en un código
; dependiendo del state, si es 0 entra en el state0 e imagínate que al final se cambia el valor de state por 1.
; Siguiente frame, se ejecuta desde arriba el código y ahora entra en vez de en state0 en state1, y así.

; Los dungeonEvents se usan si quiero comprobar algo cada frame.

interactionCode21:
	ld e,Interaction.subid
	ld a,(de)
	rst_jumpTable
	.dw interactionDelete
	.dw interaction21_subid01
	.dw interaction21_subid02
	.dw interaction21_subid03
	.dw interaction21_subid04
	.dw interaction21_subid05
	.dw interaction21_subid06
	.dw interaction21_subid07
	.dw interaction21_subid08
	.dw interaction21_subid09
	.dw interaction21_subid0a
	.dw interaction21_subid0b
	.dw interaction21_subid0c
	.dw interaction21_subid0d
	.dw interaction21_subid0e
	.dw interaction21_subid0f
	.dw interaction21_subid10
	.dw interaction21_subid11
	.dw interaction21_subid12
	.dw interaction21_subid13
	.dw interaction21_subid14
	.dw interaction21_subid15
	.dw interaction21_subid16
	.dw interaction21_subid17
	.dw interaction21_subid18
	.dw interaction21_subid19


; D2: Verify a 2x2 floor pattern
interaction21_subid01:
	call interactionDeleteAndRetIfItemFlagSet
	ld hl,subid01_tileData

verifyTilesAndDropSmallKey:
	call verifyTiles
	ret nz
	jp spawnSmallKeyFromCeiling

subid01_tileData:
	.db TILEINDEX_YELLOW_TOGGLE_FLOOR  $67 $77 $ff ; Tiles at $67 and $77 must be yellow
	.db TILEINDEX_BLUE_TOGGLE_FLOOR    $68 $78 $00 ; Tiles at $68 and $78 must be blue


; D2: Verify a floor tile is red to open a door
; Si el tile en la posición 5a es un tile de tipo toggle floor rojo entonces pone wActiveTriggers a 1.
interaction21_subid02:
	ld a,(wRoomLayout+$5a)
	cp TILEINDEX_RED_TOGGLE_FLOOR
	ld a,$01
	jr z,+
	dec a
+
	ld (wActiveTriggers),a
	ret


; Light torches when a colored cube rolls into this position.
interaction21_subid03:
	call checkInteractionState
	jr nz,@initialized

	call interactionIncState
	call objectGetTileAtPosition ;devuelve en a el tile en la posición de la interacción y en hl dónde está en el wRoomLayout
	ld a,(wRotatingCubePos) ;guarda en a la posición del rotating cube
	ld e,Interaction.var03
	ld (de),a ; pone el var03 de la interacción a wRotatingCubPos
	cp l
	call z,@lightCubeTorches ; si la posición de la interacción (l) es la misma que la del cubo, enciende la antorcha

@initialized:
	ld e,Interaction.var03
	ld a,(de)
	ld b,a
	ld a,(wRotatingCubePos)
	cp b
	ret z ;si la posición no ha cambiado, sale.

	call objectGetTileAtPosition
	ld a,(wRotatingCubePos)
	cp l
	call z,@lightCubeTorches ;si la posición del cubo es la misma que la de la interacción entonces enciende la llama
	ld a,(wRotatingCubePos)
	ld e,Interaction.var03
	ld (de),a ;pone en var03 de la interacción la posición del cubo
	ret

@lightCubeTorches:
	ld hl,wRotatingCubeColor ;este wRotatingCubeColor viene efectivamente determinado por el color del cubo, que se settea en coloredCube.s.
	set 7,(hl) ;pone en 1 el bit 7 de wRotatingCubeColor para hacer visible la llama
	ld a,SND_LIGHTTORCH
	jp playSound


; d2: Set torch color based on the color of the tile at this position.
; Actualiza wRotatingCubeColor con el tile donde está la interacción
interaction21_subid04:
	call checkInteractionState
	jr nz,@initialized ; si state != 0, ya ha sido inicializada entonces salta a @initialized

	call interactionIncState
	call objectGetTileAtPosition ; esta función devuelve el tile en el que está la interacción en la variable a
	ld e,Interaction.var03 ; guarda en e el offset donde se encuentra var03. Básicamente hace un ld e, $03 (este 03 se saca de structs.s).
	ld (de),a ; d apunta a la interacción actual (esto funciona así porque funciona así en el motor), en este caso la 21 y e apunta a var03.
	; Por tanto aquí lo que hace es guardar en el var03 de la interacción 21 el valor de a, que es el tile en el que está la interacción
	sub TILEINDEX_RED_TOGGLE_FLOOR ;resta al tile donde está la interacción el código del tile tipo toggle floor rojo. Si el resultado es 0, 1 o 2, es que entonces
	; el tile en el que está la interacción es un tile de tipo toggle floor.
	set 7,a ; pone el bit 7 a 1. Te quedaría algo como que el resultado será 0x80 (0 si fuese rojo el tile en el que está la interacción y 8 por activar el bit 7).
	; esto se hace porque poner el bit a 7 de wRotatingCubeColor hace que la llama sea visible.
	ld (wRotatingCubeColor),a ;se guarda ese valor en wRotatingCubeColor
	ld a,$57
	ld (wRotatingCubePos),a ;guarda en wRotatingCubePos la posición donde está la interacción. Da igual un poco el valor porque simplemente se usa para comprobar
	; que no sea 0 en coloredCubeFlame.s. Si != 0 es que la interacción21 subid04 ha cambiado wRotatingCubePos y por tanto existe.

@initialized:
	call objectGetTileAtPosition
	ld b,a ;guarda el b el tile actual donde está la interacción
	sub TILEINDEX_RED_TOGGLE_FLOOR
	cp $03 
	ret nc ; si el resultado del código del tile actual menos el código del tile toggle floor rojo es 3 o más, sale, porque entonces es que el tile actual no es
	; un tile de tipo toggle floor

	ld e,Interaction.var03
	ld a,(de) ;guarda el valor de var03 en a, es decir, el valor que teníamos antes, que es el tile en el que estaba la interacción
	cp b 
	ret z ;comparas con b y si son igual el cp da zero así que sale, si ha cambiado sigue

	ld a,b
	ld (de),a ;se guarda en el var03 el tile nuevo
	sub TILEINDEX_RED_TOGGLE_FLOOR
	set 7,a ;activa el bit 7
	ld (wRotatingCubeColor),a ;guarda el resultado en wRotatingCubeColor
	ret


; d2: Drop a small key here when a colored block puzzle has been solved.
interaction21_subid05:
	call interactionDeleteAndRetIfItemFlagSet
	ld hl,@tileData
	jp verifyTilesAndDropSmallKey

@tileData:
	.db TILEINDEX_RED_PUSHABLE_BLOCK     $49 $4b $69 $6b $ff
	.db TILEINDEX_YELLOW_PUSHABLE_BLOCK  $5a $ff
	.db TILEINDEX_BLUE_PUSHABLE_BLOCK    $4a $59 $5b $6a $00


; d2: Set trigger 1 when the colored flames are lit red.
interaction21_subid06:
	ld b,$80 ;$80 es el código de color para el rojo
	jr ++

; d1: Set trigger 1 when the colored flames are lit blue.
interaction21_subid19:
	ld b,$82
++
	ld a,(wRotatingCubeColor)
	cp b ;compara el color de la llama con el código del color rojo
	ld a,$01 ;si son iguales, pone a = 1.
	jr z,+ ;si son iguales se salta a +
	dec a ;si no son iguales resta 1 a a.
+
	ld (wActiveTriggers),a ;activa el wActiveTriggers
	ret


; Toggle a bit in wSwitchState based on whether a toggleable floor tile at position Y is
; blue. The bitmask to use is X.
interaction21_subid07:

	;Mirar si algún tile en la posición de la sala determinada por la Y de la interacción
	ld e,Interaction.yh
	ld a,(de) ; a será igual a la Y de la interacción
	ld c,a
	ld b,>wRoomLayout

	;wRoomLayout = [
		;$00, $00, $0B, $0B, $0B, $00, $00, $00,  ; Cada dígito es un tile index.
		;$00, $00, $00, $00, $00, $00, $00, $00,
		; ...
		;$00, $00, $0D, $0C, $0B, $00, $00, $00,  
		;...
	;]
	ld a,(bc) ; a es el valor del tileindex que se encuentra en la posición bc.
	sub TILEINDEX_RED_TOGGLE_FLOOR
	cp $03 ;mira si hay algún tile de tipo toggle floor
	ret nc ;si no es tile de toggle floor, la función sale

	; si es un tile de toggle floor, si es o rojo o amarillo se salta a unsetSwitch, sino, si es azul vaya, se sigue a setSwitch
	ld a,(bc)
	cp TILEINDEX_RED_TOGGLE_FLOOR
	jr z,unsetSwitch
	cp TILEINDEX_YELLOW_TOGGLE_FLOOR
	jr z,unsetSwitch

; pone a 1 un bit (indicado por el bitmask Interaction.xh) del switchState usando el OR. Ejemplo: wSwitchState = %00000000  (todos los bits apagados)
; bitmask      = %00000100  (bit 2 encendido) --> wSwitchState OR bitmask → %00000000 OR %00000100 = %00000100
setSwitch:
	ld e,Interaction.xh
	ld a,(de)
	ld hl,wSwitchState
	or (hl)
	ld (hl),a
	ret

unsetSwitch:
	ld e,Interaction.xh
	ld a,(de)
	cpl ;invierte el bitmask, desactivando ese bit en vez de activándolo, haciendo lo contrario de setSwitch.
	ld hl,wSwitchState
	and (hl)
	ld (hl),a
	ret


; Toggle a bit in wSwitchState based on whether blue flames are lit. The bitmask to use is
; X.
interaction21_subid08:
	ld hl,wRotatingCubeColor
	bit 7,(hl)
	ret z
	res 7,(hl)
	ld a,(hl)
	cp $02
	jr z,setSwitch
	jr unsetSwitch


; d3: Drop a small key when 3 blocks have been pushed (to a certain location).
interaction21_subid09:
	call interactionDeleteAndRetIfItemFlagSet ;borra la interacción en caso de que ya se haya activado la llave
	ld hl,@tileData
	jp verifyTilesAndDropSmallKey ;mira si los tiles de tileData son pushable blocks, es decir, que has movido ahí los pushable blocks, y en ese caso aparece
	; una llave

@tileData:
	.db TILEINDEX_PUSHABLE_BLOCK $3b $59 $5d $00 


; d3: Crea un orbe, when an orb is hit, spawn an armos, as well as interaction which will spawn a chest
; when it's killed.
interaction21_subid0a:
	call checkInteractionState
	jr nz,@initialized ;si ya se ha inicializado salta a initialized

	ld hl,wToggleBlocksState
	res 4,(hl) ;borra el bit 4 de wToggleBlockState porque es el que se activará cuando golpees el orbe que se crea más abajo.
	; La intrucción res pone el bit a 0.

	ld hl,objectData.moonlitGrotto_orb
	call parseGivenObjectData ;crea el orbe anterior. El orbe se crea en la posición (7,5) y el subid es 4, indicando que ese será el bit de wToggleBlocksState
	; que hará que esté golpeado o no.

	call interactionDeleteAndRetIfItemFlagSet
	call interactionIncState

@initialized:
	ld hl,wToggleBlocksState
	bit 4,(hl) ; La intrucción bit comprueba el valor del bit que le indiquemos
	ret z ;mientras que el orbe no esté golpeado, sale

	
	ld a,$01
	ld ($cca2),a ;pone cca2 a 1. Esto es para el armos que se crea más adelante.

	; crea un armos que crea enemigos estatuas donde haya tiles de estatua y crea un dungeon stuff (con subid02) que hace aparecer un cofre cuando numEnemigos = 0.
	ld hl,objectData.moonlitGrotto_onOrbActivation
	call parseGivenObjectData

	jp interactionDelete


; Unused? A chest appears when 4 torches in a diamond formation are lit?
interaction21_subid0b:
	call checkInteractionState
	jr nz,@initialized

	call getThisRoomFlags
	and $80
	jp nz,interactionDelete

	ld hl,objectData.objectData77d4
	call parseGivenObjectData

	ldbc $4b,$35
	call makeTorchAtPositionTemporarilyLightable
	jp nz,interactionDelete

	ldbc $4b,$53
	call makeTorchAtPositionTemporarilyLightable
	jp nz,interactionDelete

	ldbc $4b,$57
	call makeTorchAtPositionTemporarilyLightable
	jp nz,interactionDelete

	ldbc $4b,$75
	call makeTorchAtPositionTemporarilyLightable
	jp nz,interactionDelete

	call interactionIncState

@initialized:
	ld a,(wNumTorchesLit)
	cp $04
	ret nz
	ld hl,wDisabledObjects
	set 3,(hl)
	call getThisRoomFlags
	set 7,(hl)
	ld a,$01
	ld (wActiveTriggers),a
	jp interactionDelete


; d3: 4 armos spawn when trigger 0 is activated.
interaction21_subid0c:
	ld a,(wActiveTriggers) ;se carga wActiveTriggers en a
	or a
	ret z ;si no hay ningún trigger activo sale sin hacer nada.

	;si hay algún bit de wActiveTriggers activo sigue el código
	ld ($cca2),a ;carga wActiveTriggers en $cca2 (cca2 es una variable temporal)
	ld hl,objectData.moonlitGrotto_onArmosSwitchPressed ;tabla que define la interacción dungeon stuff 00 (spawnea llave cuando numEnemigos = 0)
	; y el enemigo estatua, que se encargará de spawnear 4 estatuas
	call parseGivenObjectData ;lee una tabla y crea los objetos definidos en ella, en este caso la tabla de moonlitGrotto_onArmosSwitchPressed
	jp interactionDelete ;se borra la interacción al terminar su función


; d3: Crystal breakage handler
interaction21_subid0d:
	ld e,Interaction.state
	ld a,(de)
	rst_jumpTable
	.dw @state0
	.dw @state1
	.dw interactionRunScript
	.dw @state3

; si ya se ha resuelto el puzzle de los cristales o si ya se ha roto el cristal de la sala, se borra esta interacción
@state0:
	ld a,GLOBALFLAG_D3_CRYSTALS ;flag que indica si ya se ha resuelto el puzzle de los cristales
	call checkGlobalFlag
	jp nz,interactionDelete ;en caso de que el puzzle ya esté resuelto se borra esta interacción, ya no hace falta
	call getThisRoomFlags
	and $40 ;comprueba el bit 6 de los flags de la sala, que indica si se ha roto el cristal
	jp nz,interactionDelete ;si se ha roto el cristal, la interacción ya no hace falta, se borra

	ld a,(wSwitchState) ;Ojo, el wSwitchState es distinto de los flags de la sala. El partGrottoCrystal cambia el wSwitchState, este evento subid0d cambia
	; un bit de los flags de la sala.
	ld e,Interaction.counter2
	ld (de),a ;se guarda en counter2 el valor de wSwitchState
	jp interactionIncState ;se incrementa el state para que en el siguiente frame se ejecute ya state1

; comprueba si cambia el wSwitchState (se rompe el cristal) y si es así muestra un texto, agita la pantalla y activa el bit 6 de la sala
@state1:
	ld a,(wSwitchState) ;carga el wSwitchState actual en a. 
	ld b,a ;lo pasa a b
	ld e,Interaction.counter2 ;carga el wSwitchState anterior en e
	ld a,(de) ;lo pasa a a 
	cp b ;compara a con b
	ret z ;comprueba si el wSwitchState anterior es igual al wSwitchState actual. Si sigue igual sale con ret así que se queda haciendo este bucle hasta que se
	; rompa.

	;cuando se haya roto el cristal sigue el código
	ld a,(wLinkDeathTrigger)
	or a
	ret nz ;si Link está muriendo, sale.

	;se disablean todos los controles del jugador
	inc a
	ld (wDisabledObjects),a
	ld (wMenuDisabled),a
	ld (wDisableScreenTransitions),a
	ld (wDisableWarpTiles),a

	ld hl,mainScripts.moonlitGrottoScript_brokeCrystal ;animación de shake de la pantalla, muestra texto de cristal roto y activa el bit 6 de los flags de la sala.
	call interactionSetScript
	call interactionRunScript ;ejecuta el script hasta el primer wait, momento en el que retorna del call. 
	jp interactionIncState ;entra en state2, que sigue ejecutando el script de moonlitGrottoScript_brokeCrystal. Lo ejecuta todo porque lo llama frame tras frame
	; decrementando los wait y siguiendo el código hasta el final.
	; Parece que teóricamente podrías quitar el interactionRunScript de este state1 pero quizá por temas de quitarle el control al jugador un frame antes o algo así
	; pues lo hacen así. Haciendo el runScript en state1 se quita el input de Link en este frame, no en el siguiente cuando se ejecute state2.
	; Parece que en el juego lo suelen hacer así, ejecutan el principio del script en el mismo frame donde se triggea y luego lo siguen ejecutando frame a frame,
	; en vez de ejecutarlo frame a frame directamente pero desde el frame siguiente al que se triggea.

; si todos los cristales se han roto, se hace una animación con sonidos, se muestra un texto y cambia el valor de wSpinnerState a 0.
; estos bits de wSwitchState los cambia a 1 el handler de la primera mazmorra (subid18) cuando se van poniendo a 1 el bit 6 de las salas donde hay cristales.
@state3:
	ld a,(wSwitchState)
	and $f0
	cp $f0 ;comprueba todos los bits altos de wSwitchState (f0 = 11110000). Si todos están a 1 significa que todos los cristales se han roto
	jr nz,@enableControl ;si aún no se han roto todos los cristales, le devuelve el control al jugador

	;si todos los cristales se han roto sigue el código
	ld a,$02
	ld (wScreenShakeMagnitude),a

	ld hl,mainScripts.moonlitGrottoScript_brokeAllCrystals ;marca el flag global que indica que se han roto todos los cristales y hace ciertas animaciones y sonidos
	call interactionSetScript

	ld e,Interaction.state
	ld a,$02
	ld (de),a ;cambia el state a 02, es decir, ejecuta el script que se ha setteado anteriormente

	xor a
	ld (wSpinnerState),a ;cambia el valor de wSpinnerState a 0
	ret

@enableControl:
	jpab scriptHelp.moonlitGrotto_enableControlAfterBreakingCrystal


; d3: Small key falls when a block is pushed into place
interaction21_subid0e:
	call interactionDeleteAndRetIfItemFlagSet
	ld hl,wRoomLayout+$4a ;carga en hl el tile concreto que va a querer comprobar
	ld a,(hl)
	cp $2a ;comprueba si el tile index de esa posición $4a de la sala es el $2a, es decir, una estatua verde.
	ret nz
	jp spawnSmallKeyFromCeiling ;en caso de que lo sea spawnea una llave


; d4: A door opens when a certain floor pattern is achieved
interaction21_subid0f:
	call interactionDeleteAndRetIfEnabled02
	ld hl,@tileData
	call verifyTiles
	ld a,$01
	jr z,+
	dec a
+
	ld (wActiveTriggers),a
	ret

; el formato es: tileindex a comprobar si es ese, tres posiciones y o final de línea ($ff) o final de función ($00).
; por ejemplo, la primera línea es tileindex rojo, posición (4,3), posición (4,5), posición (6,4) y final de línea.
@tileData:
	.db TILEINDEX_RED_TOGGLE_FLOOR    $43 $45 $64 $ff
	.db TILEINDEX_YELLOW_TOGGLE_FLOOR $54 $63 $65 $ff
	.db TILEINDEX_BLUE_TOGGLE_FLOOR   $44 $53 $55 $00


; d4: A small key falls when a certain froor pattern is achieved
interaction21_subid10:
	call interactionDeleteAndRetIfEnabled02
	call interactionDeleteAndRetIfItemFlagSet
	ld hl,@tileData
	jp verifyTilesAndDropSmallKey

; el formato es: tileindex a comprobar si es ese, dos posiciones y o final de línea ($ff) o final de función ($00).
; por ejemplo, la primera línea es tileindex rojo, posición (5,4), posición (5,8) y final de línea.
@tileData:
	.db TILEINDEX_RED_TOGGLE_FLOOR  $54 $58 $ff
	.db TILEINDEX_BLUE_TOGGLE_FLOOR $55 $57 $00


; Tile-filling puzzle: when all the blue tiles ya no están, a chest will spawn here.
interaction21_subid11:
	call interactionDeleteAndRetIfEnabled02
	call interactionDeleteAndRetIfItemFlagSet

	ld a,TILEINDEX_BLUE_FLOOR
	call findTileInRoom
	ret z

spawnChestAndDeleteSelf:
	ld a,SND_SOLVEPUZZLE
	call playSound
	call objectGetTileAtPosition
	ld c,l
	ld a,TILEINDEX_CHEST
	call setTile
	call objectCreatePuff
	jp interactionDelete


; d4: A chest spawns here when the torches light up with the color blue.
interaction21_subid12:
	call interactionDeleteAndRetIfItemFlagSet
	ld a,(wRotatingCubeColor)
	bit 7,a
	ret z
	and $03
	cp $02
	ret nz
	jr spawnChestAndDeleteSelf


; d5: A chest spawns here when all the spaces around the owl statue are filled.
interaction21_subid13:
	call interactionDeleteAndRetIfEnabled02
	call interactionDeleteAndRetIfItemFlagSet
	ld b,>wRoomLayout
	ld hl,@positionsToCheck
@next:
	ldi a,(hl)
	or a
	jr z,spawnChestAndDeleteSelf
	ld c,a
	ld a,(bc)
	sub TILEINDEX_RED_PUSHABLE_BLOCK
	cp $03
	jr c,@next
	ret

@positionsToCheck: ; The positions in a circle around the owl statue
	.db $47 $48 $49 $57 $59 $67 $68 $69 $00


; d5: A chest spawns here when two blocks are pushed to the right places
interaction21_subid14:
	call interactionDeleteAndRetIfEnabled02
	call interactionDeleteAndRetIfItemFlagSet
	ld hl,@tileData
	call verifyTiles
	ret nz
	jp spawnChestAndDeleteSelf

@tileData:
	.db TILEINDEX_PUSHABLE_STATUE  $45 $49 $00


; d5: Cane of Somaria chest spawns here when blocks are pushed into a pattern
interaction21_subid15:
	call interactionDeleteAndRetIfEnabled02
	call interactionDeleteAndRetIfItemFlagSet
	ld hl,@tileData
	call verifyTiles
	ret nz
	jp spawnChestAndDeleteSelf

@tileData:
	.db TILEINDEX_RED_PUSHABLE_BLOCK    $54 $62 $ff
	.db TILEINDEX_YELLOW_PUSHABLE_BLOCK $33 $52 $ff
	.db TILEINDEX_BLUE_PUSHABLE_BLOCK   $44 $73 $00


; d5: Sets floor tiles to show a pattern when a switch is held down.
interaction21_subid16:
	call interactionDeleteAndRetIfEnabled02
	ld e,Interaction.state
	ld a,(de)
	rst_jumpTable
	.dw @state0
	.dw interaction21_subid16_state1

@state0:
	ld a,(wActiveTriggers)
	or a
	ret z

	call interactionIncState

	ld c,$5c
	ld a,TILEINDEX_RED_TOGGLE_FLOOR
	call setTileWithPuff

	ld c,$6a
	ld a,TILEINDEX_RED_TOGGLE_FLOOR
	call setTileWithPuff

	ld c,$3b
	ld a,TILEINDEX_YELLOW_TOGGLE_FLOOR
	call setTileWithPuff

	ld c,$5a
	ld a,TILEINDEX_YELLOW_TOGGLE_FLOOR
	call setTileWithPuff

	ld c,$4c
	ld a,TILEINDEX_BLUE_TOGGLE_FLOOR
	call setTileWithPuff

	ld c,$7b
	ld a,TILEINDEX_BLUE_TOGGLE_FLOOR
	jr setTileWithPuff

setTileToStandardFloor:
	ld a,TILEINDEX_STANDARD_FLOOR

setTileWithPuff:
	call setTile

;;
; @param	c	Position to create puff at
createPuffAt:
	call getFreeInteractionSlot
	ret nz
	ld (hl),INTERAC_PUFF
	ld l,Interaction.yh
	jp setShortPosition_paramC

interaction21_subid16_state1:
	ld a,(wActiveTriggers)
	or a
	ret nz

	ld c,$5c
	call setTileToStandardFloor
	ld c,$6a
	call setTileToStandardFloor
	ld c,$3b
	call setTileToStandardFloor
	ld c,$5a
	call setTileToStandardFloor
	ld c,$4c
	call setTileToStandardFloor
	ld c,$7b
	call setTileToStandardFloor

	ld e,Interaction.state
	xor a
	ld (de),a
	ret


; Create a chest at position Y which appears when [wActiveTriggers] == X, but which also
; disappears when the trigger is released.
interaction21_subid17:
	call interactionDeleteAndRetIfEnabled02
	call getThisRoomFlags
	and ROOMFLAG_ITEM
	jp nz,interactionDelete ;si ya se ha abierto el cofre, se elimina la interacción

	ld e,Interaction.xh ;la X de la interacción indica el bit/los bit de wActiveTriggers que controlará la aparición del cofre
	ld a,(de)
	ld b,a
	ld a,(wActiveTriggers)
	cp b
	jr nz,@triggerInactive ;se compara el valor de X con el wActiveTriggers y no coincide es que no está el bit que queremos activado y por tanto salta a
	; la función para eliminar el cofre (o no hacer nada en caso de que aún no haya cofre). Si el bit sí está activado, el código sigue, entrando a @triggerActive.

;poner el cofre
@triggerActive:
	ld e,Interaction.yh
	ld a,(de)
	ld c,a
	ld b,>wRoomLayout
	ld a,(bc)
	cp TILEINDEX_CHEST
	ret z ;comprueba si ya hay un chest en esa posición de la sala

	;si no lo hay, lo crea
	ld a,TILEINDEX_CHEST
	call setTile
	call createPuffAt
	ld a,SND_SOLVEPUZZLE
	jp playSound

;quitar el cofre
@triggerInactive:
	ld e,Interaction.yh
	ld a,(de)
	ld c,a
	ld b,>wRoomLayout
	ld a,(bc)
	cp TILEINDEX_CHEST
	ret nz ;comprueba si hay un cofre en esa posición de la sala, si no lo hay, sale.

	; si hay un cofre en esa posición vuelve a poner el tile que había ahí antes de un cofre.
	; Retrieve whatever tile was there before the chest
	ld a,:w3RoomLayoutBuffer
	ld ($ff00+R_SVBK),a
	ld b,>w3RoomLayoutBuffer
	ld a,(bc)
	ld l,a
	xor a
	ld ($ff00+R_SVBK),a

	ld a,l
	call setTile
	jp createPuffAt


; d3: Calculate the value for [wSwitchState] based on which crystals are broken.
; Comprueba el bit 6 de cada sala donde hay un cristal y modifica los bits correspondientes de wSwitchState para que el subid0d haga algo cuando todos esos bits
; están activados.
interaction21_subid18:
	call getThisRoomFlags ;hl apunta a los flags de la sala actual
	ld b,$00

	ld l,<ROOM_AGES_45d ;dentro del grupo h de salas que sacas con getThisRoomFlags, apunta a la sala 45d.
	; ROOM_AGES_45d es un identificador del grupo y sala esa concreta, pero no su dirección. Al hacer que l = <ROOM_AGES_45d se hace que se coja el identificador
	; de la sala (el byte bajo) y lo use como offset dentro del grupo al que apuntaba h.
	bit 6,(hl) ;comprueba si el bit 6 de el flag de esa sala está activo (cristal roto)
	jr z,+ ;sino, salta
	set 4,b ;si está roto activamos el bit 4 en b.
+
	ld l,<ROOM_AGES_45f
	bit 6,(hl)
	jr z,+
	set 5,b ;si está roto activamos el bit 5 en b
+
	ld l,<ROOM_AGES_461
	bit 6,(hl)
	jr z,+
	set 6,b ;si está roto activamos el bit 6 en b
+
	ld l,<ROOM_AGES_463
	bit 6,(hl)
	jr z,+
	set 7,b ;si está roto activamos el bit 7 en b
+
	ld a,(wSwitchState) ;hace a = wSwitchState
	or b ;hace un or sobre él con b, que tenía marcados los bits que indican qué cristales se han roto, activando esos bits de a y manteniendo los bits que estaban
	; ya activados antes (1 OR 0 da 1)
	ld (wSwitchState),a ;vuelve a guardar en wSwitchState el valor de a, con los bits que indican los cristales rotos ya modificados.
	jp interactionDelete


;;
interactionDeleteAndRetIfItemFlagSet:
	call getThisRoomFlags
	and ROOMFLAG_ITEM
	ret z
	pop hl
	jp interactionDelete

;;
spawnSmallKeyFromCeiling:
	ldbc TREASURE_SMALL_KEY, $01
	call createTreasure
	ret nz
	call objectCopyPosition
	jp interactionDelete

;;
; Verifies that certain tiles in the room layout equal specified values.
;
; @param	hl	Data structure where the first byte is a tile index, and
;			subsequent bytes are positions where the tile is expected to equal
;			that index. Value $ff starts a new "group", and $00 ends the
;			structure.
; @param[out]	zflag	Set if the tiles all match the expected values.
verifyTiles:
	ld b,>wRoomLayout
@nextTileIndex:
	ldi a,(hl)
	or a
	ret z
	ld e,a
@nextPosition:
	ldi a,(hl)
	ld c,a
	or a
	ret z
	inc a
	jr z,@nextTileIndex
	ld a,(bc)
	cp e
	ret nz
	jr @nextPosition

;;
; @param	b	Number of frames it can stay lit before burning out
; @param	c	Position
; @param[out]	zflag	Set if the part object was created successfully
makeTorchAtPositionTemporarilyLightable:
	call getFreePartSlot
	ret nz

	ld (hl),PART_LIGHTABLE_TORCH
	inc l
	ld (hl),$01
	ld l,Part.counter2
	ld (hl),b
	ld l,Part.yh
	call setShortPosition_paramC
	xor a
	ret
