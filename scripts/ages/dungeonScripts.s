; These are a bunch of scripts used by INTERAC_DUNGEON_SCRIPT.

; Se ejecuta una instrucción cada frame. Tiene un pointer que cada frame ejecuta una instrucción y avanza a la siguiente o se queda bloqeuado (como en los check o
; los wait). Cuando llega a la instrucción scriptend, se destruye.

; Los dungeonScripts se usan si quiero reaccionar cuando se cumpla una condición.


dungeonScript_spawnChestOnTriggerBit0:
	stopifitemflagset
	checkflagset $00, wActiveTriggers ; cada frame hace este check hasta que sea cierto, es decir, se queda aquí bloqueado hasta que esta instrucción se cumpla,
	; esto se veía bien por ejemplo en los diálogos y movimientos de los personajes en las cutscenes, que se coordinaban:
	; checkmemoryeq wTmpcfc0.genericCutscene.cfd0, $04 ;si cfd0 es 4 sigue el código. cfd0 lo pone Nayru a 4 cuando terminan ambos el diálogo con Link.
	; Por ejemplo, ahí Ralph esperaba a que Nayru hubiese cambiado la cfd0 para seguir su script. 
	scriptjump spawnChestAfterPuff


makuPathScript_spawnChestWhenActiveTriggersEq01:
	stopifitemflagset
	checkmemoryeq wActiveTriggers, $01

spawnChestAfterPuff:
	playsound SND_SOLVEPUZZLE
	createpuff
	wait 15
	settilehere TILEINDEX_CHEST
	scriptend ;scriptend hace que se destruya el script, no se vuelve a ejecutar nunca más.

makuPathScript_spawnDownStairsWhenEnemiesKilled:
	stopifroomflag80set
	wait 30
	checknoenemies
	playsound SND_SOLVEPUZZLE
	orroomflag $80
	createpuff
	wait 15
	settilehere $45
	scriptend

makuPathScript_spawn30Rupees:
	stopifitemflagset
	spawnitem TREASURE_RUPEES, $0c
	scriptend

makuPathScript_keyFallsFromCeilingWhen1TorchLit:
	stopifitemflagset
	checkmemoryeq wNumTorchesLit, $01
	spawnitem TREASURE_SMALL_KEY, $01
	scriptend

makuPathScript_spawnUpStairsWhen2TorchesLit:
	stopifitemflagset
	checkmemoryeq wNumTorchesLit, $02
	orroomflag $80
	playsound SND_SOLVEPUZZLE
	createpuff
	wait 15
	settilehere $46
	scriptend


; Spawn the moving platform in the room with 2 buttons when the right one is pressed.
spiritsGraveScript_spawnMovingPlatform:
	checkflagset $01, wActiveTriggers
	setcoords $48, $78
	asm15 objectCreatePuff
	setcoords $58, $78
	asm15 objectCreatePuff
	wait 30
	spawninteraction INTERAC_MOVING_PLATFORM, $09, $50, $78
	playsound SND_SOLVEPUZZLE
	scriptend

spiritsGraveScript_spawnBracelet:
	stopifitemflagset
	spawnitem TREASURE_BRACELET, $00
	scriptend


; Create the miniboss portal when it's killed.
dungeonScript_minibossDeath:
	stopifroomflag80set
	checknoenemies
	orroomflag $80
	wait 20
	spawninteraction INTERAC_MINIBOSS_PORTAL, $00, $00, $00


enableLinkAndMenu:
	writememory wDisableLinkCollisionsAndMenu, $00
	scriptend

; Spawn a heart container when the boss is killed.
dungeonScript_bossDeath:
	jumpifroomflagset $80, ++
	checknoenemies
	orroomflag $80
++
	stopifitemflagset
	setcoords $58, $78

spawnHeartContainer:
	spawnitem TREASURE_HEART_CONTAINER, $00
	scriptjump enableLinkAndMenu

wingDungeonScript_bossDeath:
	jumpifroomflagset $80, @spawnHeart
	checknoenemies
	orroomflag $80

	; Create staircase tiles
	setcoords $a8, $48
	createpuff
	settilehere $19
	setcoords $a8, $a8
	createpuff
	settilehere $19

@spawnHeart:
	stopifitemflagset
	setcoords $98, $78
	scriptjump spawnHeartContainer


; Spawn stairs to the bracelet room when the two torches are lit.
spiritsGraveScript_stairsToBraceletRoom:
	stopifroomflag80set
	asm15 scriptHelp.makeTorchesLightable
	checkmemoryeq wNumTorchesLit, $02
	orroomflag $80
	playsound SND_SOLVEPUZZLE
	asm15 objectCreatePuff
	settilehere $45
	scriptend


wingDungeonScript_spawnFeather:
	stopifitemflagset
	spawnitem TREASURE_FEATHER, $00
	scriptend

wingDungeonScript_spawn30Rupees:
	stopifitemflagset
	spawnitem TREASURE_RUPEES, $0c
	scriptend

moonlitGrottoScript_spawnChestWhen2TorchesLit:
	stopifitemflagset
	checkmemoryeq wNumTorchesLit, $02
	scriptjump spawnChestAfterPuff


; The room with the moving platform and an orb to hit
skullDungeonScript_spawnChestWhenOrb0Hit:
	stopifitemflagset
	checkflagset $00, wToggleBlocksState
	scriptjump spawnChestAfterPuff

; The room with an orb that's being blocked by a moldorm
skullDungeonScript_spawnChestWhenOrb1Hit:
	stopifitemflagset
	checkflagset $01, wToggleBlocksState
	scriptjump spawnChestAfterPuff


; The room with 3 eyeball-statue things that need to be hit with a seed shooter
; Comprueba los tres bits más bajos de wActiveTriggers, que indican si los ojos están activos. Si los tres están a 1, spawnea un cofre.
crownDungeonScript_spawnChestWhen3TriggersActive:
	stopifitemflagset
	checkmemoryeq wActiveTriggers, $07
	scriptjump spawnChestAfterPuff


mermaidsCaveScript_spawnBridgeWhenOrbHit:
	stopifroomflag40set
	checkflagset $00, wToggleBlocksState
	asm15 scriptHelp.mermaidsCave_spawnBridge_room38
	scriptend

mermaidsCaveScript_updateTrigger2BasedOnTriggers0And1:
	wait 1
	asm15 scriptHelp.setTrigger2IfTriggers0And1Set
	scriptjump mermaidsCaveScript_updateTrigger2BasedOnTriggers0And1


; Creates a stair tile facing south when trigger 0 is activated
ancientTombScript_spawnSouthStairsWhenTrigger0Active:
	stopifroomflag40set
	checkmemoryeq wActiveTriggers, $01
	settilehere $50

ancientTombScript_finishMakingStairs:
	orroomflag $40
	asm15 objectCreatePuff
	playsound SND_SOLVEPUZZLE
	scriptend

; Creates a stair tile facing north when trigger 0 is activated
ancientTombScript_spawnNorthStairsWhenTrigger0Active:
	stopifroomflag40set
	checkmemoryeq wActiveTriggers, $01
	settilehere $52
	scriptjump ancientTombScript_finishMakingStairs


ancientTombScript_retractWallWhenTrigger0Active:
	stopifroomflag40set
	checkmemoryeq wActiveTriggers, $01 ; bit 0 activo = 0000 0001 = $01.
	disableinput
	wait 30
	asm15 scriptHelp.ancientTomb_startWallRetractionCutscene
	scriptend


ancientTombScript_spawnDownStairsWhenEnemiesKilled:
	stopifroomflag80set
	wait 30
	checknoenemies
	playsound SND_SOLVEPUZZLE
	asm15 objectCreatePuff
	settilehere $45
	orroomflag $80
	scriptend


ancientTombScript_spawnVerticalBridgeWhenTorchLit:
	checkmemoryeq wNumTorchesLit, $01
	settilehere $6a
	playsound SND_SOLVEPUZZLE
	createpuff
	scriptend



herosCaveScript_spawnChestWhen4TriggersActive:
	stopifitemflagset
	checkmemoryeq wActiveTriggers, $0f
	scriptjump spawnChestAfterPuff

herosCaveScript_spawnBridgeWhenTriggerPressed:
	stopifroomflag40set
	checkflagset $01, wActiveTriggers
	asm15 scriptHelp.herosCave_spawnBridge_roomc9
	scriptend

herosCaveScript_spawnNorthStairsWhenEnemiesKilled:
	stopifitemflagset
	checknoenemies
	settilehere $52
	playsound SND_SOLVEPUZZLE
	scriptend


; cuando se rompe el cristal suena un sonido, se agita la pantalla, se muestra un texto, se activa el bit 6 de los flags de la sala y se pasa al siguiente state.
moonlitGrottoScript_brokeCrystal:
	disableinput
	wait 30
	playsound SNDCTRL_STOPSFX ;detiene cualquier efecto de sonido que estuviese sonando
	shakescreen 180
	playsound SND_RUMBLE2
	wait 180
	showtext TX_1200
	orroomflag $40 ;activa el bit 6 de los flags de la sala
	setstate $ff ;indica que termine el script. Indica que pasa a su siguiente state.

moonlitGrottoScript_brokeAllCrystals:
	wait 30
	shakescreen 100
	playsound SND_BIG_EXPLOSION
	wait 90
	playsound SND_SOLVEPUZZLE
	wait 30
	showtext TX_1201
	setglobalflag GLOBALFLAG_D3_CRYSTALS ;marca el flag global que indica que se han roto todos los cristales
	enableinput
	asm15 scriptHelp.moonlitGrotto_enableControlAfterBreakingCrystal
	scriptend
