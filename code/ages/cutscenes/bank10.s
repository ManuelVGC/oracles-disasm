; TODO: Some code in this file is shared with "code/seasons/cutscenes/endgameCutscenes.s"

m_section_superfree Cutscenes_Bank10 NAMESPACE cutscenesBank10

; Input values for the intro cutscene in the temple
templeIntro_simulatedInput:
	dwb   45  $00
	dwb   16  BTN_UP
	dwb   48  $00
	dwb   32  BTN_UP
	dwb   24  $00
	dwb   32  BTN_UP
	dwb   48  $00
	dwb   34  BTN_UP
	dwb  112  $00
	dwb    5  BTN_UP
	dwb   32  $00
	dwb    5  BTN_UP
	dwb   36  $00
	dwb    5  BTN_UP
	dwb   36  $00
	dwb    5  BTN_UP
	dwb   36  $00
	dwb   12  BTN_UP
	.dw $ffff

; Exiting tower
blackTowerEscape_simulatedInput1:
	dwb  96 $00
	; Fall though

; Leaving screen
blackTowerEscape_simulatedInput2:
	dwb  33 BTN_DOWN
	dwb 256 $00
	.dw $ffff

; Walking up to ambi's guards
blackTowerEscape_simulatedInput3:
	dwb  48 BTN_UP
	dwb   4 $00
	dwb  16 BTN_RIGHT
	dwb   1 BTN_UP
	dwb 256 $00
	.dw $ffff

; Same room as above
; avanza un cuadro a Link
blackTowerEscape_simulatedInput4:
	dwb  16 BTN_UP
	dwb 256 $00
	.dw $ffff


agesFunc_10_70f6:
	xor a ;pone a = 0
	ldh (<hOamTail),a ;limpia hOam
	ld de,$cbc2
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

;cuando la pantalla está blanca se limpian ciertos valores, se carga la imagen de los créditos verticales, se hace un fade a la imagen y se carga
;la interacción de los créditos verticales
@substate0:
	ld a,(wPaletteThread_mode)
	or a
	ret nz ;si no es 0 es que hay un fade, este código espera a que acabe el fade para seguir
	call incCbc2 

	call disableLcd
	call clearDynamicInteractions
	call clearOam


	xor a ;pone a = 0
	ld ($cfde),a ;limpia cfde


	ld a,GFXH_CREDITS_SCROLL ;gráficos que queremos cargar, en este caso la imagen que está por debajo cuando sales los créditos verticales.
	call loadGfxHeader ;carga los gráficos anteriores en la VRAM
	ld a,PALH_a0 ;paleta de colores que se va a usar
	call loadPaletteHeader ;cargado de la paleta de colores

	ld a,$09 ;carga en a el estado gráfico que queremos settear en la siguiente instrucción
	call loadGfxRegisterStateIndex ;función que se llama después de cambiar los gráficos en la vram con la instrucción anterior. Se asegura que esté correcto el
	;estado gráfico de toda la pantalla después de hacer los cambios anteriores 

	call fadeinFromWhite
	call getFreeInteractionSlot ;mira si hay espacio para crear una interacción
	ret nz
	ld (hl),INTERAC_CREDITS_TEXT_VERTICAL

	;se indica la posición y de los créditos en pantalla
	ld l,Interaction.yh ;carga la coordenada y de la interacción
	ld (hl),$e8 ;la parte alta de la coordenada y será $e8
	inc l
	inc l
	ld (hl),$50 ;y la parte baja será $50
	ret

;cuando hayan terminado los créditos verticales, inicializa dos contadores
@substate1:
	ld a,($cfdf)
	or a
	ret z ;cuando cfdf sea != 0 el código sigue. Esto lo pone != 0 el objeto interacción de los créditos verticales cuando terminan de mostrarse
	ld hl,wTmpcbb3 
	ld (hl),$e0 ;carga wTmpcbb3 con $e0
	inc hl
	ld (hl),$01 ;carga wTmpcbb4 con $01
	jp incCbc2

;después de terminen los créditos se espera a que wTmpcbb3 llegue a 0 y luego se hace un fade a blanco
@substate2:
	ld hl,wTmpcbb3
	call decHlRef16WithCap
	ret nz ;cuando wTmpcbb3 llegue a 0 el código sigue
	call checkIsLinkedGame
	jr nz,@func_7174 ;si es linked game entra en func7174
	callab bank3Cutscenes.cutscene_clearTmpCBB3 ;limpia wTmpcbb3
	ld a,$02
	ld ($cbc1),a ;carga cbc1 a 3, es decir, pasamos al state3 del endgameCutsceneHandler_0a (endgameCutscenes.s) para mostrar ya la pantalla de The
	;end (;originalmente estaba a 3 pero al comentar states en el cutscene de credtis, queda en 1)
	ld a,$04 ; a = 4
	jp fadeoutToWhiteWithDelay ;hace fade a blanco


;a partir de aquí se entra si el juego está linked

@func_7174:
	ld a,$04
	ld (wTmpcbb3),a
	ld a,(wGfxRegs1.SCY)
	ldh (<hCameraY),a
	ld a,UNCMP_GFXH_01
	call loadUncompressedGfxHeader
	ld a,PALH_0b
	call loadPaletteHeader
	ld b,$03
-
	call getFreeInteractionSlot
	jr nz,+
	ld (hl),INTERAC_INTRO_SPRITES_1
	inc l
	ld (hl),$09
	inc l
	dec b
	ld (hl),b
	jr nz,-
+
	jp incCbc2

@substate3:
	ld a,(wGfxRegs1.SCY)
	or a
	jr nz,@func_71aa
	ld a,$78
	ld (wTmpcbb3),a
	jp incCbc2
@func_71aa:
	call decCbb3
	ret nz
	ld (hl),$04
	ld hl,wGfxRegs1.SCY
	dec (hl)
	ld a,(hl)
	ldh (<hCameraY),a
	ret
@substate4:
	call decCbb3
	ret nz
	ld a,$ff
	ld (wTmpcbba),a
	jp incCbc2
@substate5:
	ld hl,wTmpcbb3
	ld b,$01
	call flashScreen
	ret z
	call disableLcd
	ld a,GFXH_CREDITS_LINKED_WAVING_GOODBYE
	call loadGfxHeader
	ld a,PALH_9f
	call loadPaletteHeader
	call clearDynamicInteractions
	ld b,$03
-
	call getFreeInteractionSlot
	jr nz,+
	ld (hl),INTERAC_cf
	inc l
	dec b
	ld (hl),b
	jr nz,-
+
	ld a,$04
	call loadGfxRegisterStateIndex
	ld a,$04
	call fadeinFromWhiteWithDelay
	call incCbc2
	ld a,$f0
	ld (wTmpcbb3),a
@func_71fd:
	xor a
	ldh (<hOamTail),a
	ld a,(wGfxRegs1.SCY)
	cp $60
	jr nc,+
	cpl
	inc a
	ld b,a
	ld a,(wFrameCounter)
	and $01
	jr nz,+
	ld c,a
	ld hl,bank16.oamData_4ed8
	ld e,:bank16.oamData_4ed8
	call addSpritesFromBankToOam_withOffset
+
	ld a,(wGfxRegs1.SCY)
	cpl
	inc a
	ld b,$c7
	add b
	ld b,a
	ld c,$38
	ld hl,bank16.oamData_4f21
	ld e,:bank16.oamData_4f21
	push bc
	call addSpritesFromBankToOam_withOffset
	pop bc
	ld a,(wGfxRegs1.SCY)
	cp $60
	ret c
	ld hl,bank16.oamData_4f56
	ld e,:bank16.oamData_4f56
	jp addSpritesFromBankToOam_withOffset
@substate6:
	call @func_71fd
	ld a,(wPaletteThread_mode)
	or a
	ret nz
	call decCbb3
	ret nz
	ld a,$04
	ld (wTmpcbb3),a
	jp incCbc2
@substate7:
	ld a,(wGfxRegs1.SCY)
	cp $98
	jr nz,@func_7262
	ld a,$f0
	ld (wTmpcbb3),a
	call incCbc2
	jr ++
@func_7262:
	call decCbb3
	jr nz,++
	ld (hl),$04
	ld hl,wGfxRegs1.SCY
	inc (hl)
	ld a,(hl)
	ldh (<hCameraY),a
	cp $60
	jr nz,++
	call clearDynamicInteractions
	ld a,UNCMP_GFXH_2c
	call loadUncompressedGfxHeader
++
	jp @func_71fd
@substate8:
	call @func_71fd
	call decCbb3
	ret nz
	callab bank3Cutscenes.cutscene_clearTmpCBB3
	ld a,$02
	ld ($cbc1),a ;originalmente estaba a 3 pero al comentar states en el cutscene de credtis, queda en 1
	ld a,$04
	jp fadeoutToWhiteWithDelay


;pantalla de the end
agesFunc_10_7298:
	ld de,$cbc2
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
.ifndef REGION_JP
	.dw @substate9
	.dw @substateA
	.dw @substateB
.endif

;limpia memoria y hace fade a la imagen ya de The End
@substate0:
	ld a,(wPaletteThread_mode)
	or a
	ret nz ;cuando no haya fade activo sigue
	call disableLcd ;apaga la pantalla
	call incCbc2 
	callab bank3Cutscenes.func_60f1 ;temas de información relativa a Link, rollo vida actual e inventario
	call clearDynamicInteractions ;se limpian interacciones
	call clearOam ;se limpia la OAM
	jp @func_72ec

@func_72ec:
	ld a,GFXH_CREDITS_THE_END 
	call loadGfxHeader ;carga los gráficos de the end
	ld a,PALH_a9
	call loadPaletteHeader ;carga la paleta correspondiente
++
	ld a,$04
	call loadGfxRegisterStateIndex ;función que se llama después de cambiar los gráficos en la vram con la instrucción anterior. Se asegura que esté correcto el
	;estado gráfico de toda la pantalla después de hacer los cambios anteriores

	;centra la cámara
	xor a 
	ld hl,hCameraY
	ldi (hl),a
	ldi (hl),a
	ldi (hl),a
	ld (hl),a

	ld hl,wTmpcbb3 
	ld (hl),$f0 ;se carga el contador wTmpcbb3 a 240
	ld (hl),a ;luego carga 0 en wTmpcbb3 parece
	ld a,SNDCTRL_MEDIUM_FADEOUT
	call playSound ;hace fade de la música
	ld a,$04
	jp fadeinFromWhiteWithDelay ;fade a la imagen

;cuando haya terminado el fade a la imagen sigue
@substate1:
	ld a,(wPaletteThread_mode)
	or a
	ret nz
	call incCbc2
	ret

;;
; Called from playWaveSoundAtRandomIntervals in bank 0.
;
; Part of the cutscene where tokays steal your stuff? "SND_WAVE" gets played at random
; intervals?
;
; @param	hl	Place to write a counter to (how many frames until calling this
;			again)
@playWaveSoundAtRandomIntervals_body:
	push hl
	ld a,SND_WAVE
	call playSound
	pop hl
	call getRandomNumber
	and $03
	ld bc,@@data
	call addAToBc
	ld a,(bc)
	ld (hl),a
	ret

@@data:
	.db $a0 $c8 $10 $f0

;después de que el fade a la imagen haya terminado, espera 240 frames
@substate2:
	call decCbb3
	ret nz ;cuando wTmpcbb3 sea 0 sigue
	call incCbc2

;cuando el jugador pulsa A, B o START, se hace un fade a blanco
@substate3:
	ld a,(wKeysJustPressed) ;botón que presiona el jugador
	and (BTN_A|BTN_B|BTN_START)
	ret z
	call incCbc2
	jp fadeoutToWhite ;cuando pulsa alguno de los botones anteriores se hace fade a blanco

;genera el código secreto a Holodrum, limpia memorias y hace un fade a ese código
@substate4:
	ld a,(wPaletteThread_mode)
	or a
	ret nz

	jp resetGame

	;call incCbc2 ;cuando termina el fade a blanco sigue
	;call disableLcd ;apaga la pantalla
	;callab bank3.generateGameTransferSecret ;genera el código de Holodrum
	;ld a,$ff 
	;ld (wTmpcbba),a ;carga wTmpcbba con ff

	;cambia de banco para conseguir los gráficos del secreto
	;ld a,($ff00+R_SVBK)
	;push af
	;ld a,TEXT_BANK
	;ld ($ff00+R_SVBK),a
	;ld hl,w7SecretText1
	;ld de,w7d800
	;ld bc,$1800
-
	ldi a,(hl)
	call copyTextCharacterGfx
	dec b
	jr nz,-

	;vuelve al banco anterior
	pop af
	ld ($ff00+R_SVBK),a
	
	ld a,GFXH_SECRET_FOR_LINKED_GAME 
	call loadGfxHeader ;carga los gráficos
	ld a,PALH_05 
	call loadPaletteHeader ;carga la paleta
	ld a,UNCMP_GFXH_2b
	call loadUncompressedGfxHeader ;carga más gráficos

	;si el juego es linked
	call checkIsLinkedGame
	ld a,GFXH_HEROS_SECRET_TEXT
	call nz,loadGfxHeader

	call clearDynamicInteractions ;borra las interacciones
	call clearOam ;limpia la Oam
	ld a,$04
	call loadGfxRegisterStateIndex ;función que se llama después de cambiar los gráficos en la vram con la instrucción anterior. Se asegura que esté correcto el
	;estado gráfico de toda la pantalla después de hacer los cambios anteriores
	ld hl,wTmpcbb3
	ld (hl),$3c ;carga el contador wTmpcbb3 a 60
	call fileSelect_redrawDecorations ;limpia la Oam y pone algunos gráficos en pantalla
	jp fadeinFromWhite ;se muestra el secreto de Holodrum

;después de que termine el fade, espera 60 frames y reestablece en contador a 60
@substate5:
	call fileSelect_redrawDecorations ;limpia la Oam y pone algunos gráficos en pantalla
	ld a,(wPaletteThread_mode)
	or a
	ret nz ;cuando termine el fade sigue
	call decCbb3 
	ret nz ;después de 60 frames sigue
	ld hl,wTmpcbb3
	ld b,$3c 
	call checkIsLinkedGame
	jr z,+ ;si no está linked salta a +
	ld b,$b4
+
	ld (hl),b ;carga wTmpcbb3 a 60
	jp incCbc2

;espera 60 frames y luego crea la interacción del texto para guardar al final del juego
@substate6:
	call fileSelect_redrawDecorations ;limpia la Oam y pone algunos gráficos en pantalla
	call decCbb3 
	ret nz ;después de 60 frames sigue
	call checkIsLinkedGame
	jr nz,+ ;si está linkado salta a +
	call getFreeInteractionSlot ;crea una ranura para interacción
	jr nz,+
	ld (hl),$d1 ;escribe d1 en la interacción especial que se crea. Es la interacción del texto de juego completado ("Save and quit?")
	;en esa interacción d1 se ve cómo crear un texto con opciones y guardado (INTERAC_GAME_COMPLETE_DIALOG). En esta interacción se marca
	;también el juego como completado si se guarda la partida.
	xor a
	ld ($cfde),a ;pone cfde a 0 (lo usa la interacción como marca de si ya has guardado/no guardado ya la partida). Esto se pone a 0 aquí porque es
	;en el frame siguiente cuando ya sea empieza a ejecutar la interacción y ya usa el cfde partido de cfde = 0.
+
	jp incCbc2

;cuando el jugador termine de guardar/no guardar, se hace fade a blanco
@substate7:
	call fileSelect_redrawDecorations ;limpia la Oam y pone algunos gráficos en pantalla
	call checkIsLinkedGame
	jr z,@func_7407 ;si no está linked salta a func_7407
	ld a,(wKeysJustPressed)
	and $01
	jr nz,++
	ret
@func_7407:
	ld a,($cfde)
	or a
	ret z ;cuando sea cfde sea distinto de 0, el código sigue (esto lo pone a 1 la interacción cuando terminas de guardar/no guardar al terminar el
	;juego)
++
	call incCbc2
	ld a,SNDCTRL_FAST_FADEOUT 
	call playSound ;hace un fade de la música
	jp fadeoutToWhite ;fundido a blanco


;cuando se haya terminado el fade se limpia la memoria, se carga la imagen de To be continued y se hace fade a la imagen
@substate8:
	call fileSelect_redrawDecorations ;limpia la Oam y pone algunos gráficos en pantalla
	ld a,(wPaletteThread_mode)
	or a
	ret nz ;cuando haya terminado el fade sigue

.ifdef REGION_JP
	jp resetGame
.else
	call checkIsLinkedGame
	jp nz,resetGame ;si el juego no está vinculado, sigue
	call disableLcd ;apaga la pantalla
	call clearOam ;limpia la Oam
	call incCbc2
	ld a,GFXH_TO_BE_CONTINUED 
	call loadGfxHeader ;carga el gráfico de continuará
	ld a,PALH_a7
	call loadPaletteHeader ;carga la paleta
	call fadeinFromWhite ;fade a la imagen
	ld a,$04
	jp loadGfxRegisterStateIndex ;función que se llama después de cambiar los gráficos en la vram con la instrucción anterior. Se asegura que esté correcto el
	;estado gráfico de toda la pantalla después de hacer los cambios anteriores

;cuando termina el fade a la imagen carga el contador a 180
@substate9:
	call @func_7450
	ld a,(wPaletteThread_mode)
	or a
	ret nz ;cuando termine el fade sigue
	ld hl,wTmpcbb3
	ld (hl),$b4 ;carga el contador wTmpcbb3 a 180
	jp incCbc2
@func_7450:
	ld hl,bank16.oamData_4fec
	ld e,:bank16.oamData_4fec
	ld bc,$3038
	xor a
	ldh (<hOamTail),a
	jp addSpritesFromBankToOam_withOffset ;limpia sprites anteriores y carga unos nuevos en la Oam

;durante 180 frames, si pulsa el jugador pulsa el botón A se funde a blanco, sino, al final de los 180 frames
@substateA:
	call @func_7450
	ld hl,wTmpcbb3
	ld a,(hl)
	or a
	jr z,@func_746a
	dec (hl)
	ret
@func_746a:
	ld a,(wKeysJustPressed)
	and BTN_A
	ret z
	call incCbc2
	jp fadeoutToWhite

;cuando termine el fade resetea el juego
@substateB:
	call @func_7450
	ld a,(wPaletteThread_mode)
	or a
	ret nz
	jp resetGame

.endif ; !REGION_JP

.ends
