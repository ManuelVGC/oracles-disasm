;;
runRoomSpecificCode:
	ld a,(wActiveRoom)

	;usa el grupo de la sala en la subtabla roomSpecificCodeGroupTable. 
	ld hl, roomSpecificCodeGroupTable
	call findRoomSpecificData ;; se entra con el grupo en la tabla y se salta a la función correspondiente.
	; Si encuentra el código de la sala en la lista, hace a = índice (el siguiente dígito después del código de la sala) y activa el carry.
	; Si no lo encuentra, retorna en el ret nc.
	ret nc 

	; Usa el índice obtenido para entrar en la función correspondiente.
	; Por ejemplo, la sala 460 (grupo 4, sala 60) entra en roomSpecificCodeGroup4Table y ahí ve que está listada la sala 60. Coge el siguiente dígito y lo usa
	; como índice, el 1, así que entra en roomSpecificCode1.
	rst_jumpTable
	.dw roomSpecificCode0
	.dw roomSpecificCode1
	.dw roomSpecificCode2
	.dw roomSpecificCode3
	.dw roomSpecificCode4
	.dw roomSpecificCode5
	.dw setDeathRespawnPoint
	.dw roomSpecificCode7
	.dw roomSpecificCode8
	.dw roomSpecificCode9
	.dw roomSpecificCodeA
	.dw roomSpecificCodeB
	.dw roomSpecificCodeC

	; Random stub not called by anything?
	ret

roomSpecificCodeGroupTable:
	.dw roomSpecificCodeGroup0Table
	.dw roomSpecificCodeGroup1Table
	.dw roomSpecificCodeGroup2Table
	.dw roomSpecificCodeGroup3Table
	.dw roomSpecificCodeGroup4Table
	.dw roomSpecificCodeGroup5Table
	.dw roomSpecificCodeGroup6Table
	.dw roomSpecificCodeGroup7Table


roomSpecificCodeGroup0Table:
	.db $93 $00
	.db $38 $06
	.db $39 $08
	.db $3a $09
	.db $00
roomSpecificCodeGroup1Table:
	.db $81 $03
	.db $38 $06
	.db $97 $07
	.db $0e $0a
	.db $00
roomSpecificCodeGroup2Table:
	.db $0e $05
	.db $00
roomSpecificCodeGroup3Table:
	.db $0f $0b
	.db $00
roomSpecificCodeGroup4Table:
	.db $60 $01
	.db $52 $02
	.db $e6 $0c
	.db $00
roomSpecificCodeGroup5Table:
	.db $d2 $04
roomSpecificCodeGroup6Table:
roomSpecificCodeGroup7Table:
	.db $00

;;
roomSpecificCode0:
	ld a,GLOBALFLAG_WON_FAIRY_HIDING_GAME
	call checkGlobalFlag
	ret nz
	ld hl,$cfd0
	ld b,$10
	jp clearMemory

;;
; Se crea el spinner en la sala del primer piso de MoonlitGrotto cuando los cristales aún no están rotos.
roomSpecificCode1:
	ld a, GLOBALFLAG_D3_CRYSTALS
	call checkGlobalFlag
	ret nz
---
	; Create spinner object
	call getFreeInteractionSlot ;reserva espacio para la interacción y si hay, le concede un adress para ella, la crea digamos.
	ret nz
	ld (hl),$7d ;la dirección de la interacción es h y l, siendo h la propia interacción y l los diferentes campos del struct que es la interacción.
	; Como al principio se empieza con el principio de la interacción en memoria pues el l es el primer campo, el id, así que le asignamos el id del spinner.
	ld l,Interaction.yh ;apuntamos ahora al campo correspondiente a la coordenada Y
	ld (hl),$57 ;asignamos a esa Y de esa interacción el valor $57
	ld l,Interaction.xh ;y lo mismo para la X
	ld (hl),$01
	ret

;;
; Se crea el spinner en la sala del segundo piso de MoonlitGrotto cuando los cristales ya se han roto y por tanto el spinner "ha caído" de un piso a otro.
roomSpecificCode2:
	ld a,GLOBALFLAG_D3_CRYSTALS
	call checkGlobalFlag
	ret z
	; Create spinner if the flag is UNset
	jr ---

;;
roomSpecificCode3:
	call getThisRoomFlags
	bit 6,a
	ret nz
	ld a,TREASURE_MYSTERY_SEEDS
	call checkTreasureObtained
	ret nc
	ld hl,wcc05
	res 1,(hl)
	call getFreeInteractionSlot
	ret nz
	ld (hl),$40
	inc l
	ld (hl),$0a
	ld a,$01
	ld (wDiggingUpEnemiesForbidden),a
	ret

;;
roomSpecificCode7:
	ld a,GLOBALFLAG_GAVE_ROPE_TO_RAFTON
	call checkGlobalFlag
	ret z
	call getThisRoomFlags
	bit 6,a
	ret nz
	ld a,MUS_RALPH
	ld (wActiveMusic2),a
	ret

;;
roomSpecificCode5:
	ld a,GLOBALFLAG_SAVED_NAYRU
	call checkGlobalFlag
	ret nz
	ld a,MUS_SADNESS
	ld (wActiveMusic2),a
	ret

;;
; Something in ambi's palace
roomSpecificCode4:
	ld a,$06
	ld (wMinimapRoom),a
	ld hl,wPastRoomFlags+$06
	set 4,(hl)
	ret

;;
; Check to play ralph music for ralph entering portal cutscene
roomSpecificCode8:
	ld a,(wScreenTransitionDirection)
	cp DIR_RIGHT
	ret nz
	ld a, GLOBALFLAG_RALPH_ENTERED_PORTAL
	call checkGlobalFlag
	ret nz
	ld a, MUS_RALPH
	ld (wActiveMusic2),a
	ret

;;
; Play nayru music on impa's house screen, for some reason
roomSpecificCode9:
	ld a,GLOBALFLAG_FINISHEDGAME
	call checkGlobalFlag
	ret z
	ld a, MUS_NAYRU
	ld (wActiveMusic2),a
	ret

;;
; Correct minimap in mermaid's cave present
roomSpecificCodeA:
	ld hl,wMinimapGroup
	ld (hl),$00
	inc l
	ld (hl),$3c
	ret

;;
; Correct minimap in mermaid's cave past
roomSpecificCodeB:
	ld hl,wMinimapGroup
	ld (hl),$01
	inc l
	ld (hl),$3c
	ret

;;
; Something happening on vire black tower screen
roomSpecificCodeC:
	ld hl,wActiveMusic
	ld a,(hl)
	or a
	ret nz
	ld (hl),$ff
	ret
