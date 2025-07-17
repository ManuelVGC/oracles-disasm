objectTable2:
	.dw objectData7705
	.dw objectData7717
	.dw objectData771b
	.dw objectData7725
	.dw objectData7733
	.dw objectData7741
	.dw objectData774b
	.dw objectData7733
	.dw objectData5462 ;niños jugando
	.dw objectData5470 ;conejos
	.dw objectData_blackTowerEscape_ambiAndGuards
	.dw objectData55a2
	.dw objectData543c
	.dw objectData774f
	.dw objectData7761
	.dw objectData7765
	.dw objectData776f
	.dw objectData5492
	.dw objectData777c
	.dw objectData7792

objectData7705:
	obj_Interaction $3a $00 $42 $78
	obj_Interaction $44 $01 $42 $78
	obj_Interaction $3b $00 $42 $68
	obj_Interaction $6b $05 $48 $88
	obj_End

objectData7717:
	obj_Interaction $39 $01
	obj_End

objectData771b:
	obj_Interaction $3c $01 $48 $78
	obj_Interaction $3d $01 $28 $68
	obj_End

objectData7725:
	obj_Interaction $37 $02 $28 $48
	obj_Interaction $31 $01 $68 $38
	obj_Interaction $e1 $40 $28 $28
	obj_End

objectData7733:
	obj_Interaction $87 $03 $40 $50
	obj_Interaction $37 $04 $56 $38
	obj_Interaction $36 $02 $48 $50
	obj_End

objectData7741:
	obj_Interaction $3c $05 $48 $38
	obj_Interaction $3d $03 $48 $48
	obj_End

objectData774b:
	obj_Interaction $39 $04
	obj_End

objectData774f:
	obj_Interaction $3c $06 $48 $78
	obj_Interaction $95 $00 $4a $75
	obj_Interaction $3a $09 $48 $38
	obj_Interaction $43 $03 $28 $78
	obj_End

objectData7761:
	obj_Interaction $4b $02
	obj_End

objectData7765:
	obj_Interaction $4d $04 $4f $78
	obj_Interaction $84 $08 $4f $78
	obj_End

objectData776f:
	obj_Interaction $b0 $00 $60 $88
	obj_Interaction $b0 $01 $60 $68
	obj_Interaction $a9 $04
	obj_End

objectData777c:
	obj_Interaction $3c $0a $48 $48
	obj_Interaction $3a $0a $48 $38
	obj_Interaction $43 $04 $28 $78
	obj_Interaction $ad $05 $e8 $58
	obj_Interaction $31 $06 $e8 $68
	obj_End

objectData7792:
	obj_Interaction $93 $06 $43 $2d
	obj_End

objectData7798:
	obj_Interaction $dc $09
	obj_Interaction $dc $0a
	obj_Interaction $8a $00 $00 $00 $09
	obj_End

objectData77a5:
	obj_Part $27 $00 $24 $50 $00
	obj_Interaction $8d $02 $28 $50
	obj_End

objectData77b2:
	obj_Interaction $93 $04
	obj_End

objectData77b6:
	obj_Interaction $b0 $02 $50 $80
	obj_Interaction $b0 $03 $50 $70
	obj_Interaction $a9 $01
	obj_End

; part con id 03 y subid 04 en la posición (7,5). El subid indica el bit de wToggleBlocksState que se usará como comprobación para poner el orbe golpeado o no.
moonlitGrotto_orb:
	obj_Part $03 $04 $75
	obj_End

moonlitGrotto_onOrbActivation:
	obj_Interaction $12 $02 $68 $98 ;interacción dungeon stuff (id 12) con subid02. Esta interacción crea una cofre cuando el número de enemigos es 0.
	;$68 $98 es la posición en la sala.
	obj_SpecificEnemyA $00 $1d $00 $26 $a0 ;igual que en moonlitGrotto_onArmosSwitchPressed.
	obj_End

objectData77d4:
	obj_Interaction $1e $06 $a3 $00
	obj_End

;tabla que define ciertos elementos.
moonlitGrotto_onArmosSwitchPressed:
	obj_Interaction $12 $01 $58 $58 ;interacción dungeon stuff (id 12) con subid01. Esta interacción crea una llave cuando el número de enemigos es 0.
	;$58 $58 es la posición en la sala.
	obj_SpecificEnemyA $00 $1d $00 $26 $a0 ;genera el specificEnemyA Armos (1d). Este enemigo spawnea armos en todos los tiles del index que le especifiques.
	;la sintaxis es flags, parece que omisible, además que 00 parece ser sin flags especiales ;id del enemigo; subid; Y, tile index a reemplazar; X, tile
	; index que reemplaza a ese tileindex (por ejemplo con las estatuas se quita el tile index de las estatuas, se pone un suelo normal y encima de ese suelo
	;se spawnea el enemigo estatua).
	;El subid 00 hace que las estatuas sean rojas y se activen cuando cca2 sea distinto de 0.
	obj_End

impaOctoroks:
	obj_Interaction $32 $00 $18 $48 $00
	obj_Interaction $32 $00 $38 $38 $01
	obj_Interaction $32 $00 $38 $58 $02
	obj_End

ambisPalaceEntranceGuards:
	obj_Interaction $40 $07 $28 $48
	obj_Interaction $40 $02 $28 $58
	obj_End

; Spawned in with the bear (ID $5d02, var03=0); animals on screen where Nayru is
; kidnapped, waiting for her to return.
animalsWaitingForNayru:
	obj_Interaction $39 $07 $28 $88 $00
	obj_Interaction $4b $07 $48 $78 $00
	obj_Interaction $39 $07 $38 $58 $02
	obj_End

goronDancers:
	obj_Interaction $66 $01 $40 $28 $00
	obj_Interaction $66 $01 $40 $78 $01
	obj_Interaction $66 $01 $68 $28 $02
	obj_Interaction $66 $01 $28 $28 $03
	obj_Interaction $66 $01 $28 $50 $04
	obj_Interaction $66 $01 $28 $78 $05
	obj_Interaction $66 $01 $68 $78 $06
	obj_End

; Subrosians take the place of goron dancers in the past (linked game)
subrosianDancers:
	obj_Interaction $4e $01 $40 $28 $00
	obj_Interaction $4e $01 $40 $78 $01
	obj_Interaction $4e $01 $68 $28 $02
	obj_Interaction $4e $01 $28 $28 $03
	obj_Interaction $4e $01 $28 $50 $04
	obj_Interaction $4e $01 $28 $78 $05
	obj_Interaction $4e $01 $68 $78 $06
	obj_End

targetCartCrystals:
	obj_Pointer @crystals
	obj_End

@crystals:
	obj_SpecificEnemyA $00 $63 $00 $00 $00
	obj_SpecificEnemyA     $63 $01 $00 $00
	obj_SpecificEnemyA     $63 $02 $00 $00
	obj_SpecificEnemyA     $63 $03 $00 $00
	obj_SpecificEnemyA     $63 $04 $00 $00
	obj_EndPointer

nayruAndAnimalsInIntro:
	obj_Interaction $36 $00 $18 $78
	obj_Interaction $37 $00 $30 $88
	obj_Interaction $5d $00 $28 $58
	obj_Interaction $39 $00 $50 $78
	obj_Interaction $4b $00 $50 $88
	obj_Interaction $3c $00 $48 $68
	obj_Interaction $4c $00 $2c $48
	obj_End

moblinsAttackingMakuSprout:
	obj_Interaction $96 $00 $30 $68
	obj_Interaction $96 $01 $30 $38
	obj_End

ambiAndNayruInPostD3Cutscene:
	obj_Interaction $4d $08 $28 $48
	obj_Interaction $36 $0e $28 $58
	obj_End

wildTokayObjectTable:
	.dw @tokayFromLeft
	.dw @tokayFromLeft
	.dw @tokayFromRight
	.dw @tokayOnBothSides

@tokayFromLeft:
	obj_Interaction $48 $0c $f8 $18
	obj_End

@tokayFromRight:
	obj_Interaction $48 $0c $f8 $88
	obj_End

@tokayOnBothSides:
	obj_Interaction $48 $0c $f8 $18
	obj_Interaction $48 $0c $f8 $88
	obj_End


; Los randomEnemy tienen tres dígitos: bits que indican respawn, uncounted, spawn anywhere y cantidad; id y subid.
; Ese primer dígito se divide de la siguiente forma:
; Bit más bajo (bit 0) --> respawn o no.
; Bit 1 --> uncounted o no.
; Bit 2 --> spawn anywhere o no.
; Bits 3 y 4 --> no parecen usarse.
; Bits 5, 6 y 7 --> cantidad de enemigos.
; Ejemplos prácticos:
; 0010 0000 --> no respawn, no uncounted, no spawn anywhere, 1.
; 0010 0001 --> respawn, no uncounted, no spawn anywhere, 1.
; 0010 0011 --> respawn, uncounted, no spawn anywhere, 1.
; 0100 0000 --> no respawn, no uncounted, no spawn anywhere, 2.
; 0100 0011 --> respawn, uncounted, no spawn anywhere, 2.
; 0110 0000 --> no respawn, no uncounted, no spawn anywhere, 3.
; 0110 0100 --> no respawn, no uncounted, spawn anywhere, 3.
; 1000 0000 --> no respawn, no uncounted, no spawn anywhere, 4.
; 1000 0100 --> no respawn, no uncounted, spawn anywhere, 4.
; 1010 0110 --> no respawn, uncounted, spawn anywhere, 5.
; 1100 0110 --> no respawn, uncounted, spawn anywhere, 6.
; Este código concreto define 4 ropes (id 10) con subid 01 (caen del techo).
objectData78db:
	obj_RandomEnemy $81 $10 $01
	obj_End

objectData_makeTorchesLightableForD6Room:
	obj_Pointer objectData_makeAllTorchesLightable
	obj_End

