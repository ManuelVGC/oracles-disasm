; ==================================================================================================
; INTERAC_DUNGEON_EVENTS
; ==================================================================================================
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

	;Mirar si algún tile en la misma Y que la interacción es una baldosa de color.
	ld e,Interaction.yh
	ld a,(de) ; a será igual a la Y de la interacción
	ld c,a
	ld b,>wRoomLayout

	;se mira la fila c en el RoomLayout que es algo como:
	;wRoomLayout = [
		;$00, $00, $0B, $0B, $0B, $00, $00, $00,  ; primera fila de tiles. Cada dígito es un tile index.
		;$00, $00, $00, $00, $00, $00, $00, $00,
		; ...
		;$00, $00, $0D, $0C, $0B, $00, $00, $00,  
		;...
	;]
	ld a,(bc) ; a apunta a la fila de tiles donde está la interacción
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


; d3: Drop a small key when 3 blocks have been pushed.
interaction21_subid09:
	call interactionDeleteAndRetIfItemFlagSet
	ld hl,@tileData
	jp verifyTilesAndDropSmallKey

@tileData:
	.db TILEINDEX_PUSHABLE_BLOCK $3b $59 $5d $00


; d3: When an orb is hit, spawn an armos, as well as interaction which will spawn a chest
; when it's killed.
interaction21_subid0a:
	call checkInteractionState
	jr nz,@initialized

	ld hl,wToggleBlocksState
	res 4,(hl)

	ld hl,objectData.moonlitGrotto_orb
	call parseGivenObjectData

	call interactionDeleteAndRetIfItemFlagSet
	call interactionIncState

@initialized:
	ld hl,wToggleBlocksState
	bit 4,(hl)
	ret z

	; Do something with the chest?
	ld a,$01
	ld ($cca2),a

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
	ld a,(wActiveTriggers)
	or a
	ret z
	ld ($cca2),a
	ld hl,objectData.moonlitGrotto_onArmosSwitchPressed
	call parseGivenObjectData
	jp interactionDelete


; d3: Crystal breakage handler
interaction21_subid0d:
	ld e,Interaction.state
	ld a,(de)
	rst_jumpTable
	.dw @state0
	.dw @state1
	.dw interactionRunScript
	.dw @state3

@state0:
	ld a,GLOBALFLAG_D3_CRYSTALS
	call checkGlobalFlag
	jp nz,interactionDelete
	call getThisRoomFlags
	and $40
	jp nz,interactionDelete

	ld a,(wSwitchState)
	ld e,Interaction.counter2
	ld (de),a
	jp interactionIncState

@state1:
	ld a,(wSwitchState)
	ld b,a
	ld e,Interaction.counter2
	ld a,(de)
	cp b
	ret z

	ld a,(wLinkDeathTrigger)
	or a
	ret nz

	inc a
	ld (wDisabledObjects),a
	ld (wMenuDisabled),a
	ld (wDisableScreenTransitions),a
	ld (wDisableWarpTiles),a

	ld hl,mainScripts.moonlitGrottoScript_brokeCrystal
	call interactionSetScript
	call interactionRunScript
	jp interactionIncState

@state3:
	ld a,(wSwitchState)
	and $f0
	cp $f0
	jr nz,@enableControl

	ld a,$02
	ld (wScreenShakeMagnitude),a

	ld hl,mainScripts.moonlitGrottoScript_brokeAllCrystals
	call interactionSetScript

	ld e,Interaction.state
	ld a,$02
	ld (de),a

	xor a
	ld (wSpinnerState),a
	ret

@enableControl:
	jpab scriptHelp.moonlitGrotto_enableControlAfterBreakingCrystal


; d3: Small key falls when a block is pushed into place
interaction21_subid0e:
	call interactionDeleteAndRetIfItemFlagSet
	ld hl,wRoomLayout+$4a
	ld a,(hl)
	cp $2a
	ret nz
	jp spawnSmallKeyFromCeiling


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

@tileData:
	.db TILEINDEX_RED_TOGGLE_FLOOR  $54 $58 $ff
	.db TILEINDEX_BLUE_TOGGLE_FLOOR $55 $57 $00


; Tile-filling puzzle: when all the blue turns red, a chest will spawn here.
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
	jp nz,interactionDelete

	ld e,Interaction.xh
	ld a,(de)
	ld b,a
	ld a,(wActiveTriggers)
	cp b
	jr nz,@triggerInactive

@triggerActive:
	ld e,Interaction.yh
	ld a,(de)
	ld c,a
	ld b,>wRoomLayout
	ld a,(bc)
	cp TILEINDEX_CHEST
	ret z

	ld a,TILEINDEX_CHEST
	call setTile
	call createPuffAt
	ld a,SND_SOLVEPUZZLE
	jp playSound

@triggerInactive:
	ld e,Interaction.yh
	ld a,(de)
	ld c,a
	ld b,>wRoomLayout
	ld a,(bc)
	cp TILEINDEX_CHEST
	ret nz

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
interaction21_subid18:
	call getThisRoomFlags
	ld b,$00

	ld l,<ROOM_AGES_45d
	bit 6,(hl)
	jr z,+
	set 4,b
+
	ld l,<ROOM_AGES_45f
	bit 6,(hl)
	jr z,+
	set 5,b
+
	ld l,<ROOM_AGES_461
	bit 6,(hl)
	jr z,+
	set 6,b
+
	ld l,<ROOM_AGES_463
	bit 6,(hl)
	jr z,+
	set 7,b
+
	ld a,(wSwitchState)
	or b
	ld (wSwitchState),a
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
