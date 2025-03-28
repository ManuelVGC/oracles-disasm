; This code goes right after the cutscene code in bank 3 (shares the same namespace)

;;
; CUTSCENE_BLACK_TOWER_ESCAPE
endgameCutsceneHandler_09:
	ld de,wGenericCutscene.cbc1 ;se usa como valor para ver qué stage hay que ejecutar. Al principio se supone que es 0.
	ld a,(de)
	rst_jumpTable
	.dw endgameCutsceneHandler_09_stage0
	.dw endgameCutsceneHandler_09_stage1


;Entra en endgameCutsceneHandler_09_stage0, se ejecuta updateStatusBar, se ejecuta @runStates, allí se mira cbc2 y se entra en el primer estado
;se hace state0 y dentro de él se incrementa cbc2, luego se ejecuta updateAllObjects. Siguiente frame, se ejecuta updateStatusBar, luego se entra en @runStates
;se lee cbc2, se hace state1, se incrementa dentro de él cbc2, se ejecuta updateAllObjects, ... y así.
endgameCutsceneHandler_09_stage0:
	call updateStatusBar ;updatea la status bar, esto no sé del todo por qué lo hace pero si lo hace es por algo. Al no usarlo desaparece la espada pero se mantiene el L-1, es raro.
	call @runStates
	jp updateAllObjects ;se ejecuta después de cada estado, es decir, cada frame. Si lo quitas los gráficos del juego se rompen por todas partes.


@runStates:
	ld de,wGenericCutscene.cbc2
	ld a,(de)
	rst_jumpTable
	.dw @state0
	.dw @state1
	.dw @state2
	.dw @state3
	.dw @state4
	.dw @state5
	.dw @state6
	.dw @state7
	.dw @state8
	.dw @state9
	.dw @stateA
	.dw @stateB
	.dw @stateC
	.dw @stateD
	.dw @stateE
	.dw @stateF
	.dw @state10
	.dw @state11
	.dw @state12
	.dw @state13
	.dw @state14
	.dw @state15



;después de que la escena esté blanca del todo cuando muere Veran, carga la sala de la Torre Negra, hace un fundido de la música, pone a Nayru, Ralph y los tiles
;que bloquean la puerta de la torre y luego ya hace el fadeout a normal otra vez. Además, va haciendo cosas para que todos los gráficos y la memoria funcionen correctamente
@state0:
	ld a,(wPaletteThread_mode)
	or a
	ret nz ;si no es 0 es que hay un fade, este código espera a que acabe el fade para seguir
	call cutscene_clearCFC0ToCFDF ;borra parte de la memoria
	call incCbc2 ;aumenta el valor del estado

	; Outside black tower
	;estas tres líneas básicamente cambian a la nueva sala con su música, y demás evitando errores gráficos
	ld bc,ROOM_AGES_176 ;carga la nueva sala (fuera de la Torre Negra) en bc
	call disableLcdAndLoadRoom ;setea la habitación actual en base al valor anterior de bc, apaga LCD para evitar problemas gráficos, limpia variables
	;y memoria carga todos los gráficos, música y datos de la habitación, setea el tipo de scroll y prepara la OAM
	call resetCamera

	;el juego hace un fast fadeout de la música
	ld a,SNDCTRL_FAST_FADEOUT
	call playSound

	call clearAllParentItems;limpias de pantalla todos los proyectiles y demás
	call dropLinkHeldItem ;le quitas el objeto activo a Link

	;pone a nayru y ralph en escena
	ld hl,objectData.objectData_blackTowerEscape_nayruAndRalph ;carga en hl la interacción de nayru y la interacción de ralph con el subid que queremos
	call parseGivenObjectData ;crea los objetos anteriores en la escena

	ld hl,wGenericCutscene.cbb3 ;es un contador
	ld (hl),60

	ld hl,blackTowerEscapeCutscene_doorBlockReplacement ;carga que quiere cambiar cuatro tiles en la escena,concretamente un bloqueo en la puerta de la Torre Negra
	call cutscene_replaceListOfTiles ;cambia los tiles anteriores
	;estas tres instrucciones siguientes se hacen para actualizar los gráficos que han cambiado ahora, Nayru, Ralph y los tiles de la puerta bloqueada. Luego se asegura que
	;toda la sala se actualice correctamente en general al haber habido esos cambios
	;cuando se reemplacen tiles o se carguen nuevos objetos habría que hacer esto
	call refreshObjectGfx ;se asegura que los gráficos correctos estén cargados en la vram. Limpia datos previos, mira a ver cuál necesitan actualización y carga
	;los necesarios. En este caso carga los gráficos de Nayru, Ralph y los tiles que bloquean la puerta
	ld a,$02 ;carga en a el estado gráfico que queremos settear en la siguiente instrucción
	call loadGfxRegisterStateIndex ;función que se llama después de cambiar los gráficos en la vram con la instrucción anterior. Se asegura que esté correcto el
	;estado gráfico de toda la pantalla después de hacer los cambios anteriores de añadir a Nayru y demás

	jp fadeinFromWhiteToRoom ;se hace un fadein desde la pantalla blanca que habíamos dejado al final de la muerte de Veran


;espera 60 segundos después del fade out y setea dos nuevos contadores
@state1:
	call cutscene_decCBB3IfNotFadingOut ;decrementa el contador anterior. Esto después del fadeout, es decir, hace 60 frames de espera después del fade out
	ret nz
	ld (hl),120 ;hl sigue apuntando a la dirección de wGenericCutscene.cbb3 (se hizo en el state0) y ahora se pone el contador a 120
	ld l,<wGenericCutscene.cbb6 ;aquí solo se modifica l porque: hl apuntaba a wGenericCutscene.cbb3, apuntando h a la estructura GenericCutscene y l apunta a
	;un byte específico de wGenericCutscene, en ese caso cbb3. Ahora h sigue apuntando a wGenericCutscene y solo queremos cambiar la l, así que solo cambiamos la l.
	;De esa forma el código es más eficiente
	ld (hl),$10 ;carga en wGenericCutscene.cbb6 el valor $10 (16 en decimal). Este valor lo lee también wTmpcbb6.
	jp incCbc2 ;incrementa el contador que hace pasar al state2

;durante 120 frames, cada 16 frames suena una explosión y se agita la pantalla, al terminar esos frames pasa al state3
@state2:
	call decCbb3
	jr nz,@updateExplosionSoundsAndScreenShake ;mientras que el contador de 120 no termine, se sigue llamando a esta función
	ld (hl),60 ;cbb3 se pone a 60. El cambio de hl en updateExplosionSoundsAndScreenShake solo afecta a dentro de la función. Es temporal.
	jp incCbc2

;cada 16 frames hay una explosión y se agita la pantalla (wTmpcbb6 se carga todo el rato a 16 y en 0 suena una explosión y se agita la pantalla)
@updateExplosionSoundsAndScreenShake:
	ld hl,wTmpcbb6 ;wTmpcbb6 empieza en 16 por lo que explico ahora: se carga la dirección de wTmpcbb6 en hl. wTmpcbb6 parece que apunta a la misma dirección que wGenericCutscene.cbb6 así que es 16 por el código
	;del state1. O sea parece que tanto wTmpcbb6 como wGenericCutscene.cbb6 tienen la misma posición en memoria. Parece que cuando se modifica una se modifica otra
	;al menos eso parece cumplirse en que wTmpcbb6 cambia cuando cambia el valor de cbb6. Por eso, en esta línea en concreto wTmpcbb6 empieza en 16.
	dec (hl) ;se decrementa su valor
	ret nz ;si no es 0 se sale
	ld (hl),$10 ;se pone a 16 wTmpcbb6
	ld a,SND_EXPLOSION 
	call playSound ;se reproduce sonido de explosión
	ld a,$08 
	call setScreenShakeCounter ;se shakea la pantalla
	xor a ;pone a a 0
	ret

;espera 60 frames antes de mostrar un texto
@state3:
	call decCbb3 
	ret nz ;espera 60 frames
	ld (hl),30 ;se recarga el contador a 30
	ld bc,TX_1d0a 
	call showText ;muestra texto
	jp incCbc2

;pone 30 frames donde no pasa nada después de que el texto desaparezca 
@state4:
	call cutscene_decCBB3IfTextNotActive ;decrementa cbb3 si no hay texto activo
	ret nz ;espera 30 frames después de que desaparezca el texto
	ld (hl),120 ;recarga el contador a 120.
	ld l,<wGenericCutscene.cbb6 ;se guarda en hl la dirección de cbb6
	ld (hl),$10 ;se carga cbb6 a 16
	jp incCbc2


;reproduce explosiones y agita la pantalla cada 16 frames. Luego pone a Link en la posición detrás del muro bloqueado, hace que Link mire hacia abajo y se configura
; para que haga el input de salir de la Torre Negra en el siguiente ciclo. Además quita el muro.
@state5:
	call decCbb3
	jr nz,@explosions ;cada frame de 120 frames llama a la función. Cada 16 frames hay una explosión y se agita la pantalla.

	ld (hl),40 ;se recarga cbb3 a 40
	call incCbc2

	ld hl,w1Link.enabled
	ld (hl),$03  ;parece que habilita a Link

	;establece la posición de Link
	ld l,<w1Link.yh
	ld (hl),$48
	ld l,<w1Link.xh
	ld (hl),$50

	;establece la dirección de Link hacia abajo
	ld l,<w1Link.direction
	ld (hl),DIR_DOWN

	;realiza un input predefinidos de Link. En este caso el input es Link saliendo de la Torre Negra.
	ld hl,cutscenesBank10.blackTowerEscape_simulatedInput1
	ld a,:cutscenesBank10.blackTowerEscape_simulatedInput1
	call setSimulatedInputAddress

	ld hl,blackTowerEscapeCutscene_doorOpenReplacement ;carga que quiere cambiar los tiles de muro bloqueando la puerta por tiles de puerta abierta
	jp cutscene_replaceListOfTiles ;cambia los tiles anteriores

;cada 16 frames suena una explosión y se agita la pantalla. Después de cada 16 frames como updateExplosionSoundsAndScreenShake sale con 0 aparece una explosión en pantalla
@explosions:
	call @updateExplosionSoundsAndScreenShake
	ret nz
	call getFreeInteractionSlot
	ret nz
	ld (hl),INTERAC_EXPLOSION_WITH_DEBRIS
	inc l
	inc l
	inc (hl) 
	ld a,$01
	ld (wTmpcfc0.genericCutscene.cfd0),a ;esto pone a 1 cfd0. Sirve para iniciar cierto comportamiento de Nayru y Ralph. La cosa es que Nayru y Ralph son un objeto
	;interacción que tienen un código asociado (nayru.s --> nayruSubid03 y ralph.s --> ralphSubid05). Ese código espera a que cfd0 sea 1 para hacer cosas.
	ret

;cada 16 frames durante 40 frames hay una explosión y se agita la pantalla. Al terminar se procesa ya el movimiento de Link. Se hace después de las explosiones
;porque según parece estas tienen prioridad al seguir inmediatamente con las explosiones de antes. No se ejecuta el movimiento de Link por esa prioridad rara.
@state6:
	call decCbb3
	jr nz,@explosions ;cada frame de 40 frames se llama a explosions y cada 16 frames aparece una explosión y se agita la pantalla.
	jp incCbc2


;comprueba si Nayru y Ralph han terminado su diálogo con Link y si es así Link sale de la escena con ellos.
@state7:
	ld a,(wTmpcfc0.genericCutscene.cfd0) 
	cp $04 ;compara cfd0 con cuatro y mientras que no sea no avanza en el código. Si la comparación falla devuelve 0.
	;esa variable la pone a 4 Nayru cuando termina su segundo texto, es decir, el final del diálogo ya con Nayru y Ralph, pero antes de que abandonen la escena.
	ret nz

	call incCbc2
	xor a ;pone a a 0
	ld (wDisabledObjects),a
	ld (wScrollMode),a

	;hace un input predefinido de Link. En este caso es irse de la escena hacia abajo
	ld hl,cutscenesBank10.blackTowerEscape_simulatedInput2
	ld a,:cutscenesBank10.blackTowerEscape_simulatedInput2
	jp setSimulatedInputAddress

;cuando los tres han abandonado la escena, se hace un fadeout a blanco.
@state8:
	ld a,(wTmpcfc0.genericCutscene.cfd0)
	cp $05
	ret nz ;cuando cfd0 sea 5, el código sigue. cfd0 lo pone Ralph a 5 en scripts.s --> ralphSubid05Script cuando abandona la escena
	call incCbc2
	jp fadeoutToWhite


;como el state0 pero cambiando a otra sala. Mientras está la pantalla blanca aprovecha para hacer el cambio de sala, poner a Ambi y los guardias y demás.
@state9:
	;espera a que se termine el fadeout para seguir con el código
	ld a,(wPaletteThread_mode)
	or a
	ret nz 

	call incCbc2

	
	ld bc,ROOM_AGES_165 ;carga la nueva sala en bc
	call disableLcdAndLoadRoom ;setea la habitación actual en base al valor anterior de bc, apaga LCD para evitar problemas gráficos, limpia variables
	;y memoria carga todos los gráficos, música y datos de la habitación, setea el tipo de scroll y prepara la OAM

	call resetCamera
	ld a,MUS_DISASTER
	call playSound

	ld a,$02 ;carga en a el estado gráfico que queremos settear en la siguiente instrucción
	call loadGfxRegisterStateIndex ;función que se llama después de cambiar los gráficos en la vram con la instrucción anterior. Se asegura que esté correcto el
	;estado gráfico de toda la pantalla después de hacer los cambios anteriores de añadir a Nayru y demás

	ld hl,objectData.objectData_blackTowerEscape_ambiAndGuards ;carga en hl la interacción de ambi, los guardias, Nayru y Ralph con el subid que queremos
	call parseGivenObjectData ;crea los objetos anteriores en la escena

	ld hl,wTmpcbb3
	ld (hl),30 ;settea wTmpcbb3 a 30
	jp fadeinFromWhiteToRoom ;fade de blanco a la sala


;hacer que Link entre en la pantalla donde están Ambi y sus guardias.
@stateA:
	;30 frames después del fadeout sigue el código
	call cutscene_decCBB3IfNotFadingOut
	ret nz 

	call incCbc2

	;colocas a link en una posición específica y haces que mire hacia arriba
	ld hl,w1Link.enabled
	ld (hl),$03
	ld l,<w1Link.yh
	ld (hl),$88
	ld l,<w1Link.xh
	ld (hl),$50
	ld l,<w1Link.direction
	ld (hl),DIR_UP

	;hace un input predefinido de Link. En este caso es caminar hacia los guardias de Ambi. Link entra en pantalla.
	ld hl,cutscenesBank10.blackTowerEscape_simulatedInput3
	ld a,:cutscenesBank10.blackTowerEscape_simulatedInput3
	call setSimulatedInputAddress
	xor a
	ld (wScrollMode),a
	ret


;después del primer texto en esta sala (TX_2a12), Link se mueve un cuadro hacia arriba
@stateB:
	ld a,(wTmpcfc0.genericCutscene.cfd0) 
	cp $06 
	ret nz ;cuando cfd0 sea 6 se sigue el código. Esto lo cambia Ralph en scripts.s --> ralphSubid06Script_part1. Que es llamado en ralph.s --> initSubid06.
	;cada subID del objeto interacción de Ralph tiene dos fases, una inicialización y un run. Igual parece para Nayru y para Ambi.
	;este state se hace cuando termina el primer texto de esta cutscene, el TX_2a12.

	call incCbc2

	ld hl,cutscenesBank10.blackTowerEscape_simulatedInput4
	ld a,:cutscenesBank10.blackTowerEscape_simulatedInput4 
	jp setSimulatedInputAddress ;avanza un recuadro a Link


;modifica cfde y cfdf y hace un fade a blanco
@stateC:
	ld a,(wTmpcfc0.genericCutscene.cfd0)
	cp $0a ;Si es igual a 0a activa el flag z.
	ret nz ;cuando cfd0 sea 0a, sigue el código. Esto lo pone Ambi después de decir su segundo texto, justo antes del fadeout hacia los niños jugando.

	call incCbc2

	ld hl,wTmpcfc0.genericCutscene.cfde
	ld (hl),$08 ;pone cfde a 08, esto lo usa en la siguiente escena para cargar a los niños en la sala.
	inc l ;pasa a apuntar a cfdf 
	ld (hl),$00 ;pone cfdf a 0 ;no sé para qué lo usa porque luego en el siguiente state lo vuelve a poner a 0

	jp fadeoutToWhite


;A este estado se entra varias veces.
; La primera vez que se entra (cfde = 8) cambia la sala y pone a los niños jugando. Después hace un fade de blanco a la sala.
; La segunda vez (cfde = 9), cambia la sala y pone a unos conejos. Después hace un fade a blanco a la sala.
@stateD:
	ld a,(wPaletteThread_mode)
	or a
	ret nz ;cuando termine el fade sigue
	call incCbc2
	call cutscene_loadRoomObjectSetAndFadein ;settea la sala y los objetos interacción que le pasemos con cfde. En este caso los niños jugando con la pelota en su
	;sala correspondiente
	xor a ;pone a a 0
	ld (wTmpcfc0.genericCutscene.cfd1),a ;cfd1 a 0. Lo usa con los niños que vuelven de piedra.
	ld (wTmpcfc0.genericCutscene.cfdf),a ;cfdf a 0
	ld a,$02
	jp loadGfxRegisterStateIndex ;función que se llama después de cambiar los gráficos en la vram con la instrucción anterior. Se asegura que esté correcto el
	;estado gráfico de toda la pantalla después de hacer los cambios anteriores.


; A este estado se entra varias veces.
; La primera vez que se entra, se espera a que termine el fade a blanco, luego se espera a que cfdf sea ff (lo pone a ff uno de los niños cuando termina su interacción)
; y luego aumenta el cfde en 1, pasando a ser 9 y volviendo al stateD al ser distinto de 0a.
; La segunda vez que se entra, se espera a que termine el fade a blanco, luego se espera a que cfdf sea ff (lo pone a ff uno de los conejos cuando termina su interacción)
; y luego aumenta el cfde en 1, pasando a ser 10 y volviendo al stateD al ser distinto de 0a.
@stateE:
	ld a,(wPaletteThread_mode)
	or a
	ret nz ;cuando termine el fade sigue
	ld hl,wTmpcfc0.genericCutscene.cfdf
	ld a,(hl)
	cp $ff 
	ret nz ;mientras cfdf sea distinto de ff sale. Esto lo pone a ff el pastGuy.s --> @@substate1. Es decir, cuando termina su interacción.
	xor a ;pone a a 0

	ldd (hl),a ; se pone cfdf a 0 y hl pasa a apuntar a cfde
	inc (hl) ; se aumenta en 1 cfde
	ld a,(hl)
	cp $0a ;compara cfde con 0a. Si es igual activa el flag z.
	ld a,$0d ;se pone a a 0d
	jr nz,+ ;mientras que a != 0a se salta a +
	ld a,$0f ;se pone a a 0f.
+
	;dependiendo de la comparación anterior a tendrá 0d o 0f.
	ld hl,wGenericCutscene.cbc2
	ld (hl),a 
	jp fadeoutToWhite

; Se espera a que termine el fade a blanco, se cambia a la sala correspondiente poniendo a Ambi, sus guardias, Ralph y Nayru y se coloca también a Link.
@stateF:
	ld a,(wPaletteThread_mode)
	or a
	ret nz ; cuando termine el fade a blanco el código sigue

	call incCbc2
	call cutscene_loadRoomObjectSetAndFadein ;settea la sala y los objetos interacción que le pasemos con cfde. En este caso Ambi, sus guardias, Nayru y
	; Ralph en la sala de justo antes del corte a la sala con los niños jugando con la pelota. Además, pasa de blanco a la sala.
	; es el mismo objeto interacción de los guardias, Ambi, Ralph y Nayru que la primera vez que se llega a esta sala, pero estos objetos tienen dos partes en el
	;script, una se hace cuando cdf0 != 0b y otra al revés. Aquí abajo setteamos cfd0 a 0b de forma que ahora se ponen a hacer cada uno su parte 2 del script.

	;Se coloca a Link en una posición y mirando hacia arriba
	ld hl,w1Link.enabled
	ld (hl),$03
	ld l,<w1Link.yh
	ld (hl),$48
	ld l,<w1Link.xh
	ld (hl),$60
	ld l,<w1Link.direction
	ld (hl),DIR_UP

	ld a,$0b
	ld (wTmpcfc0.genericCutscene.cfd0),a ;se pone cfd0 a 0b
	ld a,$02 ;carga en a el estado gráfico que queremos settear en la siguiente instrucción
	jp loadGfxRegisterStateIndex ;función que se llama después de cambiar los gráficos en la vram con la instrucción anterior. Se asegura que esté correcto el
	;estado gráfico de toda la pantalla después de hacer los cambios anteriores.

; se espera a que se haga todo el diálogo de la segunda vez que se va a la sala donde están Ambi y los guardias y cuando se termina se hace un fade a blanco.
@state10:
	call checkIsLinkedGame
	jr nz,@@linked

	ld a,(wTmpcfc0.genericCutscene.cfd0) 
	cp $10
	ret nz ;si cfd0 es 10 fade out a blanco. Esto lo pone Nayru a 10 cuando terminan se termina el diálogo con Ambi.
	call incCbc2
	jp fadeoutToWhite 

@@linked:
	ld a,(wTmpcfc0.genericCutscene.cfd0)
	cp $12
	ret nz
	ld hl,wGenericCutscene.cbc2
	ld (hl),$14
	ret

; pone la imagen de Link, Nayru y Ralph despidiéndose de Ambi y hace un fade de blanco a la imagen
@state11:
	ld a,(wPaletteThread_mode)
	or a
	ret nz ; se espera a que termine el fade.

	call incCbc2
	ld hl,wTmpcbb3 
	ld (hl),60 ;se settea el contador wTmpcbb3 a 60

	ld a,$ff 
	ld (wTilesetAnimation),a ; pone wTilesetAnimation a ff por algún tema de gráficos parece
	call disableLcd ;apaga el LCD de la Game Boy. Básicamente se usa para que al cargar una nueva sala o actualizar gráficos todo vaya bien. Para evitar problemas gráficos

	ld a,GFXH_LINK_WITH_ORACLE_END_SCENE ;gráficos que queremos cargar, en este caso la imagen de Link, Nayru y Ralph despidiéndose de Ambi.
	call loadGfxHeader ;carga los gráficos anteriores en la VRAM
	ld a,PALH_9d ;paleta de colores que se va a usar
	call loadPaletteHeader ;cargado de la paleta de colores

	call cutscene_clearObjects ;borra todas las interacciones y a Link. Básicamente a Ambi, todos sus guardias, a Nayru y a Ralph.
	call cutscene_resetOamWithSomething2 ; usa los gráficos y paleta que se han cargado antes en la VRAM y los coloca bien en pantalla
	ld a,$04 ;carga en a el estado gráfico que queremos settear en la siguiente instrucción
	call loadGfxRegisterStateIndex ;función que se llama después de cambiar los gráficos en la vram con la instrucción anterior. Se asegura que esté correcto el
	;estado gráfico de toda la pantalla después de hacer los cambios anteriores 
	jp fadeinFromWhite 

;después de 60 frames se muestra el texto TX_1312 (el primer texto de la imagen con Link, Nayru y Ralph despidiéndose de Ambi).
@state12:
	call cutscene_resetOamWithSomething2 ;por alguna razón algunos gráficos no se cargan del todo bien y lo vuelve a hacer para solucionarlo
	call cutscene_decCBB3IfNotFadingOut 
	ret nz ;después de que termine el fade a la imagen espera 60 frames 

	call incCbc2
	ld hl,wMenuDisabled ;teóricamente no deja que abras el menú pero igualmente al estar dentro de una cutscene parece que se encuentra desactivado ya
	ld (hl),$01
	ld hl,wTmpcbb3
	ld (hl),60 ;settea el contador wTmpcbb3 a 60

	ld bc,TX_1312

; A esta función se la llama varias veces.
; La primera vez muestra el primer texto de la imagen con Link, Nayru y Ralph despidiéndose de Ambi, el TX_1312
; La segunda vez muestra el segundo texto de las Twinrovas
@showTextDuringTwinrovaCutscene:
	ld a,TEXTBOXFLAG_NOCOLORS ;temas de que los gráficos funcionen bien al mostrar el texto. Parece que desactiva que ciertos objetos se puedan mostrar mientras se está
	;mostrando el cuadro de texto.
	ld (wTextboxFlags),a
	jp showText 

;espera 60 frames después de que termine el texto y hace un fade a blanco. Termina el stage0.
@state13:
	call cutscene_resetOamWithSomething2 ; de nuevo por alguna razón algunos gráficos no se cargan del todo bien y lo vuelve a hacer para solucionarlo
	call cutscene_decCBB3IfTextNotActive
	ret nz ;cuando termine el texto espera 60 frames y luego sigue
	call cutscene_clearTmpCBB3 ;limpia cbb3
	ld a,$01 
	ld (wGenericCutscene.cbc1),a ;se pasa al stage1
	jp fadeoutToWhite 


;tanto state 14 como state15 son del juego linked
;cuando haya terminado el texto y se pulse una tecla se hace un fade a blanco
@state14:
	ld a,(wTextIsActive)
	rlca
	ret nc ;cuando haya texto sigue
	ld a,(wKeysJustPressed)
	or a
	ret z ;cuando se presione una tecla se sigue
	call incCbc2
	ld a,$04
	jp fadeoutToWhiteWithDelay ;hace un fadeout a blanco con un delay marcado por a

@state15:
	ld a,(wPaletteThread_mode)
	or a
	ret nz ;cuando haya terminado el fade se sigue
	xor a ; se pone a = 0
	ld (wTextIsActive),a  ;wTextIsActive = 0
	ld a,CUTSCENE_ZELDA_KIDNAPPED 
	ld (wCutsceneTrigger),a ;se triggerea CUTSCENE_ZELDA_KIDNAPPED
	ret


; Twinrova appears just before credits
endgameCutsceneHandler_09_stage1:
	call @runStates
	jp updateAllObjects ;se ejecuta después de cada estado, es decir, cada frame. Si lo quitas los gráficos del juego se rompen por todas partes.

@runStates:
	ld de,wGenericCutscene.cbc2
	ld a,(de)
	rst_jumpTable
	.dw @state0
	.dw @state1
	.dw @state2
	.dw @state3
	.dw @state4
	.dw @state5
	.dw @state6
	.dw @state7
	.dw @state8
	.dw @state9


;cuando termine el fade a blanco carga la nueva imagen con su música correspondiente y hace un fade a la imagen
@state0:
	call cutscene_resetOamWithSomething2 ;temas gráficos
	ld a,(wPaletteThread_mode)
	or a
	ret nz ;cuando haya terminado el fade sigue

	call incCbc2
	ld hl,wTmpcbb3
	ld (hl),60 ;se settea el contador wTmpcbb3 a 60

	call disableLcd ;apaga el LCD de la Game Boy. Básicamente se usa para que al cargar una nueva sala o actualizar gráficos todo vaya bien. Para evitar problemas gráficos
	call clearOam ;limpia posibles residuos gráficos en la OAM

	ld a,GFXH_LINK_WITH_ORACLE_AND_TWINROVA_END_SCENE ;gráficos que queremos cargar, en este caso la imagen de Link, Nayru y Ralph despidiéndose de Ambi
	;con el fuego alrededor
	call loadGfxHeader ;carga los gráficos anteriores en la VRAM
	ld a,PALH_9e ;paleta de colores que se va a usar
	call loadPaletteHeader ;cargado de la paleta de colores
	ld a,$04 ;carga en a el estado gráfico que queremos settear en la siguiente instrucción
	call loadGfxRegisterStateIndex ;función que se llama después de cambiar los gráficos en la vram con la instrucción anterior. Se asegura que esté correcto el
	;estado gráfico de toda la pantalla después de hacer los cambios anteriores 

	ld a,MUS_DISASTER 
	call playSound ;cambia la música
	jp fadeinFromWhite ;fade desde blanco a la imagen

;después de 60 frames se muestra el primer texto de las Twinrova
@state1:
	ld a,TEXTBOXFLAG_NOCOLORS ;temas de que los gráficos funcionen bien al mostrar el texto. Parece que desactiva que ciertos objetos se puedan mostrar mientras se
	;está mostrando el cuadro de texto.
	ld (wTextboxFlags),a
	ld a,60
	ld bc,TX_280b
	call cutscene_decCBB3IfNotFadingOut
	ret nz  ;60 frames después del fade a la imagen sigue
	call incCbc2
	ld a,e
	ld (wTmpcbb3),a ;recarga el contador wTmpcbb3 con 60
	jp showText ;muestra el primer texto de las Twinrova

;espera 60 frames después del texto antes de continuar, carga los nuevos datos de sprites y los actualiza en pantalla
@state2:
	call cutscene_decCBB3IfTextNotActive
	ret nz ;espera 60 frames después del texto para seguir
	call incCbc2

	ld hl,wTmpcbb5
	ld (hl),$d0 ;carga d0 en Tmpcbb5. Se usa como temporizador para mover a las Twinrova. Primero la de la izquierda, luego la de la derecha.

@loadCertainOamData1:
	ld hl,bank16.oamData_4d05
	ld e,:bank16.oamData_4d05 ;carga los datos de los sprites situados en esa posición de memoria, que serán la Twinrova izquierda.

@loadOamData:
	ld b,$30
	push de
	ld de,wTmpcbb5
	ld a,(de)
	pop de
	ld c,a
	jp cutscene_resetOamWithData ;actualiza los nuevos datos de la OAM en pantalla (se usa el valor de wTmpcbb5)

; Aparece la Twinrova izquierda
@state3:
	ld hl,wTmpcbb5
	inc (hl)
	jr nz,@loadCertainOamData1 ;se incrementa wTmpcbb5 hasta que llegue a 0 y mientras no, se van actualizando los datos de la OAM en pantalla
	call clearOam ;se limpia la OAM
	ld a,UNCMP_GFXH_0a
	call loadUncompressedGfxHeader ;se carga un nuevo gráfico
	ld hl,wTmpcbb3
	ld (hl),30 ;se settea el contador wTmpcbb3 a 30
	jp incCbc2

; Se espera 30 frames y se recarga el temporizador que mueve el sprite de la Twinrova
@state4:
	call decCbb3
	ret nz ;después de 30 frames se sigue
	call incCbc2
	ld hl,wTmpcbb5
	ld (hl),$d0 ;vuelve a settear wTmpcbb5 a d0

@loadCertainOamData2:
	ld hl,bank16.oamData_4d9e
	ld e,:bank16.oamData_4d9e  ;carga los datos de los sprites situados en esa posición de memoria, que serán la Twinrova derecha.
	jr @loadOamData

; Aparece la Twinrova derecha.
@state5:
	call @loadCertainOamData2 ;carga nuevos datos en la OAM
	ld hl,wTmpcbb5
	dec (hl)
	ld a,(hl)
	sub $a0
	ret nz ;se decrementa wTmpcbb5 hasta que llege a 0, entonces sigue

	;se ponen a 0 los valores de desplazamiento  de pantalla después de haber movido ya a las dos Twinrova.
	ld (wScreenOffsetY),a 
	ld (wScreenOffsetX),a 

	ld a,30
	ld (wTmpcbb3),a ;se recarga el contador wTmpcbb3 a 30
	;ld (wOpenedMenuType),a ;hace algo con el menú
	jp incCbc2

; Con las Twinrovas ya colocadas en pantalla, dicen un texto
@state6:
	call @loadCertainOamData2 ;carga nuevos datos en la OAM
	call decCbb3
	ret nz ;espera 30 frames luego sigue
	ld hl,wTmpcbb3
	ld (hl),20 ;recarga el contador wTmpcbb3 a 20
	ld bc,TX_280c
	call endgameCutsceneHandler_09_stage0@showTextDuringTwinrovaCutscene ;se muestra el segundo texto de las Twinrovas
	jp incCbc2

; Después de 20 frames suena un rayo
@state7:
	call @loadCertainOamData2 ;carga nuevos datos en la OAM
	call cutscene_decCBB3IfTextNotActive
	ret nz ;20 frames después del texto se sigue
	xor a ; a = 0
	ld (wOpenedMenuType),a
	dec a
	ld (wTmpcbba),a ; wTmpcbba = $0FF
	ld a,SND_LIGHTNING
	call playSound ;suena un rayo
	jp incCbc2

@state8:
	call @loadCertainOamData2 ;carga nuevos datos en la OAM
	ld hl,wTmpcbb3 
	ld b,$02 
	call flashScreen ;la pantalla flashea
	ret z ;cuando sea != 0 (ha terminado el flash) se sigue el código

	call incCbc2
	ld hl,wTmpcbb3
	ld (hl),30 ; se recarga el contador wTmpcbb3 a 30

	call disableLcd ;apaga el LCD de la Game Boy. Básicamente se usa para que al cargar una nueva sala o actualizar gráficos todo vaya bien. Para evitar problemas gráficos
	call clearOam ;limpia la OAM

	;limpia zonas de memoria para evitar glitches (quitándolo parece que tampoco supone problemas pero lo dejo porque si está es por algo)
	xor a ; a = 0
	ld ($ff00+R_VBK),a
	ld hl,$8000
	ld bc,$2000
	call clearMemoryBc

	xor a
	ld ($ff00+R_VBK),a
	ld hl,$9c00
	ld bc,$0400
	call clearMemoryBc

	ld a,$01
	ld ($ff00+R_VBK),a
	ld hl,$9c00
	ld bc,$0400
	call clearMemoryBc

	ld a,GFXH_TWINROVA_CLOSEUP ;gráficos que queremos cargar, en este caso la del close up de la Twinrova
	call loadGfxHeader ;carga los gráficos anteriores en la VRAM
	ld a,PALH_9c ;paleta de colores que se va a usar
	call loadPaletteHeader ;cargado de la paleta de colores
	ld a,$04 ;carga en a el estado gráfico que queremos settear en la siguiente instrucción
	call loadGfxRegisterStateIndex ;función que se llama después de cambiar los gráficos en la vram con la instrucción anterior. Se asegura que esté correcto el
	;estado gráfico de toda la pantalla después de hacer los cambios anteriores 

	ld a,SND_LIGHTNING
	call playSound ; Suena otra vez el rayo

	jp clearPaletteFadeVariablesAndRefreshPalettes ;refresca la paleta de colores asegurando que los gráficos se muestren correctamente en pantalla

; Se espera 30 frames y se hace un fundido a negro. Se pasa a los créditos.
@state9:
	call decCbb3
	ret nz ;después de 30 frames sigue
	ld a,CUTSCENE_CREDITS
	ld (wCutsceneIndex),a ;se cambia el wCutsceneIndex al de los créditos. Parece que se usa wCutsceneIndex al ver ya de una cutscene. Al final de la muerte de
	; Veran quizá se usa wCutsceneTrigger porque se inicia una cutscene después de gameplay.
	call cutscene_clearTmpCBB3 ;se limpia wTmpcbb3

	; Se limpia la memoria de la habitación
	ld hl,wRoomLayout
	ld bc,$00c0
	call clearMemoryBc
	ld hl,wRoomCollisions
	ld bc,$00c0
	call clearMemoryBc

	; Se reinicia la posición de la cámara
	ldh (<hCameraY),a
	ldh (<hCameraX),a

	ld hl,wTmpcbb3
	ld (hl),60 ; Se settea el contador wTmpcbb3 a 60

	ld a,$03
	jp fadeoutToBlackWithDelay ;fadeout a negro

;;
; CUTSCENE_FLAME_OF_DESPAIR ;escena que pertenece ya a la parte del juego linked
endgameCutsceneHandler_20:
	call @runStates
	jp updateAllObjects

@runStates:
	ld de,$cbc1
	ld a,(de)
	rst_jumpTable
	.dw @state0
	.dw @state1
	.dw @state2
	.dw @state3
	.dw @state4
	.dw @state5
	.dw @state6
	.dw @state7
	.dw @state8
	.dw @state9
	.dw @stateA
	.dw @stateB
	.dw @stateC
	.dw @stateD
	.dw @stateE
	.dw @stateF
	.dw @state10
	.dw @state11
	.dw @state12
	.dw @state13
	.dw @state14
	.dw @state15
	.dw @state16

@state0:
	ld a,$0b
	ld ($cfde),a
	call cutscene_loadRoomObjectSetAndFadein
	call hideStatusBar
	ld a,PALH_ac
	call loadPaletteHeader
	xor a
	ld (wPaletteThread_mode),a
	call clearFadingPalettes2
	ld hl,wTmpcbb3
	ld (hl),$1e
	ld a,$13
	call loadGfxRegisterStateIndex
	ld hl,wGfxRegs1.SCY
	ldi a,(hl)
	ldh (<hCameraY),a
	ld a,(hl)
	ldh (<hCameraX),a
	ld a,$00
	ld (wScrollMode),a
	jp incCbc1

@state1:
	call decCbb3
	ret nz
	call incCbc1
	ld hl,wTmpcbb3
	ld (hl),$28
	ld a,TEXTBOXFLAG_ALTPALETTE1
	ld (wTextboxFlags),a
	ld bc,TX_2825
	jp showText

@state2:
	call cutscene_decCBB3IfTextNotActive
	ret nz
	call incCbc1
	ld a,$20
	ld hl,wTmpcbb3
	ldi (hl),a
	xor a
	ld (hl),a
	ret

@state3:
	call cutscene_decCBB3IfNotFadingOut
	ret nz
	ld hl,wTmpcbb3
	ld (hl),$20
	inc hl
	ld a,(hl)
	cp $03
	jr nc,+
	ld b,a
	push hl
	ld a,SND_LIGHTTORCH
	call playSound
	pop hl
	ld a,b
+
	inc (hl)
	ld hl,@table_5932
	rst_addAToHl
	ld a,(hl)
	or a
	ld b,a
	jr nz,@func_5920
	call fadeinFromBlack
	ld a,$01
	ld (wDirtyFadeSprPalettes),a
	ld (wFadeSprPaletteSources),a
	ld hl,wTmpcbb3
	ld (hl),$3c
	ld a,MUS_ROOM_OF_RITES
	call playSound
	jp incCbc1
;;
; @param	b	values in @table_5932 one at a time
@func_5920:
	call fastFadeinFromBlack
	ld a,b
	ld (wDirtyFadeSprPalettes),a
	ld (wFadeSprPaletteSources),a
	xor a
	ld (wDirtyFadeBgPalettes),a
	ld (wFadeBgPaletteSources),a
	ret
@table_5932:
	.db $40 $10 $80 $28 $06
	.db $00

@state4:
	ld e,$28
	ld bc,TX_2826
	call @func_5943
	jp cutscene_decCBB3IfNotFadingOut_incState_setCBB3_showText

@func_5943:
	ld a,TEXTBOXFLAG_DONTCHECKPOSITION
	ld (wTextboxFlags),a
	ld a,$03
	ld (wTextboxPosition),a
	ret

@state5:
	ld e,$28
	ld bc,TX_2827
@func_5953:
	call cutscene_decCBB3IfTextNotActive
	ret nz
	call incCbc1
	ld hl,wTmpcbb3
	ld (hl),e
	call @func_5943
	jp showText

@state6:
	ld e,$3c
	ld bc,TX_2828
	jr @func_5953

@state7:
	ld e,$b4
@func_596d:
	call cutscene_decCBB3IfTextNotActive
	ret nz
	call incCbc1
	ld hl,wTmpcbb3
	ld (hl),e
	ret

@state8:
	call @func_5995
	call cutscene_rumbleSoundWhenFrameCounterLowerNibbleIs0
	call decCbb3
	ret nz
	ld a,SNDCTRL_STOPSFX
	call playSound
	ld a,SNDCTRL_MEDIUM_FADEOUT
	call playSound
	call incCbc1
	ld a,$04
	jp fadeoutToWhiteWithDelay
@func_5995:
	ld hl,wGfxRegs1.SCY
	ldh a,(<hCameraY)
	ldi (hl),a
	ldh a,(<hCameraX)
	ldi (hl),a
	ld hl,@table_59ab
	ld de,wGfxRegs1.SCY
	call @func_59b3
	inc de
	jp @func_59b3
@table_59ab:
	.db $ff $01 $00 $01
	.db $00 $00 $ff $00
@func_59b3:
	push hl
	call getRandomNumber
	and $07
	rst_addAToHl
	ld a,(hl)
	ld b,a
	ld a,(de)
	add b
	ld (de),a
	pop hl
	ret

@state9:
	call @func_5995
	ld a,(wPaletteThread_mode)
	or a
	ret nz
	call incCbc1
	ld a,$0c
	ld ($cfde),a
	call cutscene_loadRoomObjectSetAndFadein
	ld hl,w1Link.enabled
	ld (hl),$03
	ld l,<w1Link.yh
	ld (hl),$48
	ld l,<w1Link.xh
	ld (hl),$60
	ld l,<w1Link.direction
	ld (hl),DIR_UP
	ld a,$81
	ld (wDisabledObjects),a
	ld (wMenuDisabled),a
	call cutscene_clearCFC0ToCFDF
	call showStatusBar
	ld a,SNDCTRL_STOPSFX
	call playSound
	ld a,SNDCTRL_STOPMUSIC
	call playSound
	ld a,$02
	jp loadGfxRegisterStateIndex

@stateA:
	call updateStatusBar
	ld a,($cfd0)
	cp $01
	ret nz
	call incCbc1
	ld c,$40
	ld a,$29
	call giveTreasure
	ld a,$08
	call setLinkIDOverride
	ld l,<w1Link.subid
	ld (hl),$0c
	ld hl,wTmpcbb3
	ld (hl),$5a
	ld a,MUS_PRECREDITS
	jp playSound

@stateB:
	call updateStatusBar
	call decCbb3
	ret nz
	call incCbc1
	ld hl,wTmpcbb3
	ld (hl),$b4
	ld bc,$4860
	ld a,$ff
	jp createEnergySwirlGoingOut

@stateC:
	call updateStatusBar
	call decCbb3
	ret nz
	call incCbc1
	ld hl,wTmpcbb3
	ld (hl),$3c
	jp fadeoutToWhite

@stateD:
	call cutscene_decCBB3IfNotFadingOut
	ret nz
	call incCbc1
	call disableLcd
	call clearOam
	call clearScreenVariablesAndWramBank1
	call refreshObjectGfx
	call hideStatusBar
	ld a,$02
	ld ($ff00+R_SVBK),a
	ld hl,$de90
	ld b,$08
	ld a,$ff
	call fillMemory
	xor a
	ld ($ff00+R_SVBK),a
	ld a,$07
	ldh (<hDirtyBgPalettes),a
	call getFreeInteractionSlot
	jr nz,+
	ld (hl),INTERAC_NAYRU
	inc l
	ld (hl),$12
	call getFreeInteractionSlot
	jr nz,+
	ld (hl),INTERAC_DIN
	inc l
	ld (hl),$02
+
	ld a,$02
	ld (wOpenedMenuType),a
	call func_6e9a
	ld a,$02
	call func_6ed6
	ld hl,wTmpcbb3
	ld (hl),$1e
	ld a,$04
	call loadGfxRegisterStateIndex
	ld a,$10
	ldh (<hCameraY),a
	xor a
	ldh (<hCameraX),a
	ld a,$00
	ld (wScrollMode),a
	ld bc,TX_1d1a
	jp showText

@stateE:
	call cutscene_decCBB3IfTextNotActive
	ret nz
	call incCbc1
	ld b,$04
@func_5ac2:
	call fadeinFromWhite
	ld a,b
	ld (wDirtyFadeSprPalettes),a
	ld (wFadeSprPaletteSources),a
	xor a
	ld (wDirtyFadeBgPalettes),a
	ld (wFadeBgPaletteSources),a
	ld hl,wTmpcbb3
	ld (hl),$3c
	ret

@stateF:
	ld e,$1e
	ld bc,TX_1d1b
	jp cutscene_decCBB3IfNotFadingOut_incState_setCBB3_showText

@state10:
	call cutscene_decCBB3IfTextNotActive
	ret nz
	call incCbc1
	ld b,$12
	jp @func_5ac2

@state11:
	ld e,$1e
	ld bc,TX_1d1c
	jp cutscene_decCBB3IfNotFadingOut_incState_setCBB3_showText

@state12:
	ld e,$3c
	jp @func_596d

@state13:
	call decCbb3
	ret nz
	call incCbc1
	ld hl,wTmpcbb3
	ld (hl),$f0
	ld a,$ff
	ld bc,$4850
	jp createEnergySwirlGoingOut

@state14:
	call decCbb3
	ret nz
	ld hl,wTmpcbb3
	ld (hl),$5a
	call fadeoutToWhite
	ld a,$fc
	ld (wDirtyFadeBgPalettes),a
	ld (wFadeBgPaletteSources),a
	jp incCbc1

@state15:
	call cutscene_decCBB3IfNotFadingOut
	ret nz
	call incCbc1
	call clearDynamicInteractions
	call clearParts
	call clearOam
	ld hl,wTmpcbb3
	ld (hl),$3c
	ld bc,TX_1d1d
	jp showTextNonExitable

@state16:
	ld a,(wTextIsActive)
	rlca
	ret nc
	call decCbb3
	ret nz
	call showStatusBar
	xor a
	ld (wOpenedMenuType),a
	dec a
	ld (wActiveMusic),a
	ld a,SNDCTRL_FAST_FADEOUT
	call playSound
	ld hl,@warpDest
	jp setWarpDestVariables

@warpDest:
	m_HardcodedWarpA ROOM_AGES_5f4, $0f, $57, $03


;;
; CUTSCENE_ROOM_OF_RITES_COLLAPSE ;escena que pertenece ya a la parte del juego linked
endgameCutsceneHandler_0f:
	ld de,$cbc1
	ld a,(de)
	rst_jumpTable
	.dw @state0
	.dw @state1

@state0:
	call updateStatusBar
	call @@runSubstates
	jp updateAllObjects

@@runSubstates:
	ld de,$cbc2
	ld a,(de)
	rst_jumpTable
	.dw @@substate0
	.dw @@substate1
	.dw @@substate2
	.dw @@substate3
	.dw @@substate4
	.dw @@substate5
	.dw @@substate6
	.dw @@substate7
	.dw @@substate8
	.dw @@substate9
	.dw @@substateA
	.dw @@substateB
	.dw @@substateC
	.dw @@substateD

@@substate0:
	ld a,$01
	ld (de),a
	ld hl,wActiveRing
	ld (hl),$ff
	xor a
	ldh (<hActiveObjectType),a
	ld de,$d000
	ld bc,$f8f0
	ld a,$28
	call objectCreateExclamationMark
	ld a,$28
	call objectCreateExclamationMark
	ld l,Interaction.yh
	ld (hl),$30
	inc l
	inc l
	ld (hl),$78
	ld hl,wTmpcbb3
	ld (hl),$0a
	ret
@@substate1:
	call decCbb3
	ret nz
	ld hl,wTmpcbb3
	ld (hl),$1e
	ld a,SNDCTRL_STOPMUSIC
	call playSound
	jp incCbc2
@@substate2:
	call cutscene_setScreenShakeCounterTo4RumbleAt0
	call decCbb3
	ret nz
	call incCbc2
	ld hl,wTmpcbb3
	ld (hl),$96
	jp @@func_5cb0
@@substate3:
	call cutscene_setScreenShakeCounterTo4RumbleAt0
	call decCbb3
	ret nz
	call incCbc2
	ld a,SNDCTRL_STOPSFX
	call playSound
	ld hl,wTmpcbb3
	ld (hl),$3c
	ld bc,TX_3d0e
	jp showText
@@substate4:
	call cutscene_decCBB3IfTextNotActive
	ret nz
	call incCbc2
	ld a,MUS_DISASTER
	call playSound
	ld hl,wTmpcbb3
	ld (hl),$3c
	jp @@func_5cb0
@@substate5:
	call cutscene_setScreenShakeCounterTo4RumbleAt0
	call decCbb3
	ret nz
	ld hl,wTmpcbb3
	ld (hl),$5a
	jp incCbc2
@@substate6:
	call cutscene_setScreenShakeCounterTo4RumbleAt0
	call decCbb3
	ret nz
	call incCbc2
	ld hl,wTmpcbb3
	ld (hl),$3c
	ld a,SNDCTRL_STOPSFX
	jp playSound
@@substate7:
	call decCbb3
	ret nz
	call incCbc2
	ld hl,wTmpcbb3
	ld (hl),$3c
	ld bc,TX_3d0f
	jp showText
@@substate8:
	call cutscene_decCBB3IfTextNotActive
	ret nz
	call incCbc2
	ld hl,wTmpcbb3
	ld (hl),$68
	inc hl
	ld (hl),$01
	jp @@func_5cb7
@@substate9:
	ld hl,wTmpcbb3
	call decHlRef16WithCap
	ret nz
	call incCbc2
	ld hl,wTmpcbb3
	ld (hl),$3c
	ld bc,TX_0563
	jp showText
@@substateA:
	ld e,$1e
	jp cutscene_incCBC2setCBB3whenCBB3is0
@@substateB:
	call cutscene_setScreenShakeCounterTo4RumbleAt0
	call decCbb3
	ret nz
	call incCbc2
	call @@func_5cb0
	ld a,$8c
	ld (wTmpcbb3),a
	ld a,$ff
	ld bc,$4478
	jp createEnergySwirlGoingOut
@@substateC:
	call cutscene_setScreenShakeCounterTo4RumbleAt0
	call decCbb3
	ret nz
	call incCbc2
	ld hl,wTmpcbb3
	ld (hl),$3c
	jp @@func_5cb0
@@substateD:
	call cutscene_setScreenShakeCounterTo4RumbleAt0
	call decCbb3
	ret nz
	call incCbc1
	inc l
	xor a
	ld (hl),a
	ld a,$03
	jp fadeoutToWhiteWithDelay
@@func_5cb0:
	call getFreePartSlot
	ret nz
	ld (hl),PART_ROOM_OF_RITES_FALLING_BOULDER
	ret
@@func_5cb7:
	call getFreeInteractionSlot
	ret nz
	ld (hl),INTERAC_MAKU_CONFETTI
	ret

@state1:
	call updateStatusBar
	call @@runSubstates
	jp updateAllObjects

@@runSubstates:
	ld de,$cbc2
	ld a,(de)
	rst_jumpTable
	.dw @@substate0
	.dw @@substate1
	.dw @@substate2
	.dw @@substate3
	.dw @@substate4
	.dw @@substate5
	.dw @@substate6
	.dw @@substate7
	.dw @@substate8
	.dw @@substate9
	.dw @@substateA
@@substate0:
	call cutscene_setScreenShakeCounterTo4RumbleAt0
	ld a,(wPaletteThread_mode)
	or a
	ret nz
	call incCbc2
	ld a,$11
	ld ($cfde),a
	call cutscene_loadRoomObjectSetAndFadein
	ld a,$04
	ld b,$02
	call cutscene_loadAObjectGfxBTimes_andReload
	ld a,SNDCTRL_STOPSFX
	call playSound
	ld a,SNDCTRL_FAST_FADEOUT
	call playSound
	ld hl,wTmpcbb3
	ld (hl),$3c
	ld a,$02
	jp loadGfxRegisterStateIndex
@@substate1:
	call cutscene_decCBB3IfNotFadingOut
	ret nz
	call incCbc2
	ld a,$3c
	ld (wTmpcbb3),a
	ld a,$64
	ld bc,$4850
	jp createEnergySwirlGoingIn
@@substate2:
	call decCbb3
	ret nz
	xor a
	ld (wTmpcbb3),a
	dec a
	ld (wTmpcbba),a
	jp incCbc2
@@substate3:
	ld hl,wTmpcbb3
	ld b,$01
	call flashScreen
	ret z
	call incCbc2
	ld hl,wTmpcbb3
	ld (hl),$3c
	ld a,$01
	ld ($cfc0),a
	ld a,$03
	jp fadeinFromWhiteWithDelay
@@substate4:
	call cutscene_decCBB3IfNotFadingOut
	ret nz
	call refreshObjectGfx
	ld a,$04
	ld b,$02
	call cutscene_loadAObjectGfxBTimes
	ld a,MUS_CREDITS_1
	call playSound
	ld hl,wTmpcbb3
	ld (hl),$3c
	jp incCbc2
@@substate5:
	call decCbb3
	ret nz
	call incCbc2
	ld hl,wTmpcbb3
	ld (hl),$1e
	ret
@@substate6:
	call decCbb3
	ret nz
	call refreshObjectGfx
	ld a,$04
	ld b,$02
	call cutscene_loadAObjectGfxBTimes
	ld hl,wTmpcbb3
	ld (hl),$3c
	ld hl,$cfc0
	ld (hl),$02
	jp incCbc2
@@substate7:
	ld a,($cfc0)
	cp $09
	ret nz
	call incCbc2
	ld a,$03
	jp fadeoutToWhiteWithDelay
@@substate8:
	ld a,(wPaletteThread_mode)
	or a
	ret nz
	call incCbc2
	call disableLcd
	call clearScreenVariablesAndWramBank1
	call hideStatusBar
	ld a,GFXH_SCENE_CREDITS_MAKUTREE
	call loadGfxHeader
	ld a,PALH_c9
	call loadPaletteHeader
	ld hl,wTmpcbb3
	ld (hl),$f0
	ld a,$04
	call loadGfxRegisterStateIndex
	call cutscene_resetOamWithSomething1
	ld a,$03
	jp fadeinFromWhiteWithDelay
@@substate9:
	call cutscene_resetOamWithSomething1
	call cutscene_decCBB3IfNotFadingOut
	ret nz
	call incCbc2
	ld hl,wTmpcbb3
	ld (hl),$10
	ld a,$03
	jp fadeoutToBlackWithDelay
@@substateA:
	call cutscene_resetOamWithSomething1
	call cutscene_decCBB3IfNotFadingOut
	ret nz
	ld a,CUTSCENE_CREDITS
	ld (wCutsceneIndex),a
	call cutscene_clearTmpCBB3
	ld hl,wRoomLayout
	ld bc,$00c0
	call clearMemoryBc
	ld hl,wRoomCollisions
	ld bc,$00c0
	call clearMemoryBc
	xor a
	ldh (<hCameraY),a
	ldh (<hCameraX),a
	ld hl,wTmpcbb3
	ld (hl),$3c
	ld a,SNDCTRL_MEDIUM_FADEOUT
	jp playSound

;;
; CUTSCENE_CREDITS
endgameCutsceneHandler_0a:
	call @runStates
	jp func_3539 ;similar a UpdateAllObjects

@runStates:
	ld de,$cbc1
	ld a,(de)
	rst_jumpTable
	.dw @state0
	.dw @state1
	.dw @state2
	.dw @state3
@state0:
	ld de,$cbc2
	ld a,(de)
	rst_jumpTable
	.dw @@substate0
	.dw @@substate1
	.dw @@substate2

;después de que termine el fade anterior a negro limpia la OAM, crea el título (aunque aún no se ve), inicia música de los créditos e inicia un contador de 180 frames
@@substate0:
	call cutscene_decCBB3IfNotFadingOut
	ret nz ;sigue cuando termine el fade anterior del state 9 del stage1.
	call func_60e0 ;se resetean ciertos aspectos del jugador antes de mostrar los créditos (vida, inventario y anillo equipado)
	call incCbc2
	call clearOam ;limpia la OAM
	ld hl,wTmpcbb3 
	ld (hl),$b4 ;pone wTmpcbb3 a b4 (180)
	inc hl ;apunta a el byte algo de wTmpcbb3
	ld (hl),$00 ;pone la parte alta de wTmpcbb3 (creo que es para que sea bien 180, que sea 0x00B4, quizá por si en el 00 antes había quedado algún residuo?)
	ld hl,wGfxRegs1.LCDC 
	set 3,(hl) ;activa el bit tres de wGfxRegs1.LCDC. Si lo quitas no sale el "The Legend of Zelda: Oracle of Ages" en los créditos. Entiendo que lo pone en pantalla.
	ld a,MUS_CREDITS_2 
	jp playSound ;suena la música de los créditos

; después de 180 frames se carga la nueva paleta, se hace un fade al título que hemos puesto en el estado anterior y se crea un contador de 14 segundos
@@substate1:
	ld hl,wTmpcbb3
	call decHlRef16WithCap
	ret nz ;decrementa wTmpcbb3 hasta 0 y cuando llega el código sigue
	call incCbc2 
	ld hl,wTmpcbb3
	ld (hl),$48 ;se pone wTmpcbb3 a 48
	inc hl  ;apunta a el byte alto de wTmpcbb3
	ld (hl),$03 ;se pone 03 la parte alta, esto crea un contador de 0x0348 (840 frames, 14 segundos). Esto entiendo que es para que esté el
	;"The Legend of Zelda: Oracle of Ages" un rato largo en pantalla

	ld a,PALH_04 
	call loadPaletteHeader ;se carga una nueva paleta
	ld a,$06
	jp fadeinFromBlackWithDelay ;se hace el fade desde negro a "The Legend of Zelda: Oracle of Ages"

; después de 14 segundos si el juego no está linkado, resetea un par de variables, hace un fade a blanco y sigue en el state1.
@@substate2:
	ld hl,wTmpcbb3
	call decHlRef16WithCap
	ret nz ;espera 14 segundos luego el código sigue
	call incCbc1 ;incrementa cbc1 para pasar al state1
	inc l ;apunta a wTmpcbb4
	ld (hl),a ;pone wTmpcbb4 a 0 (supuestamente era 6 al final del substate1 pero parece que se usa esta instrucción normalmente para limpiar variables y que
	;lo normal es que aquí sea 0)
	ld b,$00 ; b = 0
	call checkIsLinkedGame
	jr z,+
	ld b,$04 ;no se hace porque no está el juego linkado
+
	ld hl,$cfde
	ld (hl),b ;pone cfde a 0
	inc l ;apunta ahora a cfdf
	ld (hl),$00 ;pone cfdf a 0
	jp fadeoutToWhite

@state1:
	ld de,$cbc2
	ld a,(de)
	rst_jumpTable
	.dw @@substate0
	.dw @@substate1
	.dw @@substate2
	.dw @@substate3
	.dw @@substate4

; mientras la pantalla está en blanco, carga la nueva sala y todos los gráficos y objetos corrrespondientes, luego hace un fade a la sala
@@substate0:
	xor a
	ldh (<hOamTail),a ;pone a 0 hOamTail, que es "Where to put the next OAM object (low byte for wOam)". Parece ser el número de sprites en la OAM.

	ld a,(wPaletteThread_mode) 
	or a
	ret nz ;cuando haya terminado el fade anterior, sigue el código

	;prepara la pantalla para el nuevo fondo
	call disableLcd ;apaga el LCD de la Game Boy. Básicamente se usa para que al cargar una nueva sala o actualizar gráficos todo vaya bien. Para evitar problemas gráficos
	call incCbc2
	call clearDynamicInteractions ;limpiamos todas las interacciones
	call clearOam ;limpiamos la OAM. Limpia sprites.

	;limpia datos de la cutscene
	ld a,$10 
	ldh (<hOamTail),a ;pone OamTail a 10 (supuestamente está reservando espacio para nuevos sprites)
	ld a,($cfde) ;guarda el valor de cfde
	ld c,a 
	call cutscene_clearCFC0ToCFDF ;limpia CFC0 - CFDF
	ld a,c

	;carga la sala correspondiente
	ld ($cfde),a ;vuelve a poner cfde a su valor anterior
	cp $04
	jr nc,+ ;si cfde < 04 --> c; si cfde > 04 --> nc. Al principio cdfe es 0 así que el código sigue. Cfde va a funcionar como contador de escenas de los créditos.
	ld hl,@@table_5f1c 
	rst_addDoubleIndex ;se recorre table_5f1c con el valor de cfde para seleccionar una habitación a cargar. Cada entrada de la tabla son dos bytes.
	;Al principio devuelve la primera sala ROOM_AGES_038.

	;se guarda la sala en b y c. b = wActiveGroup, c = wActiveRoom.
	ld b,(hl)
	inc hl
	ld c,(hl)

	;se carga la nueva sala
	ld a,$00
	call forceLoadRoom ;se fuerza la nueva sala con b = wActiveGroup, c = wActiveRoom y a = wRoomStateModifier. En otros casos se ha cargado la sala con
	;disableLcdAndLoadRoom_body que es un poco lo mismo.

	;se cargan unos gfx
	ld a,($cfde) ; a = cfde (0 al principio)
	ld hl,@@table_5f24 
	rst_addAToHl ;se usa cfde para apuntar a la entrada correspondiente de la tabla
	ldi a,(hl) ;cargas en a el valor de la tabla
	call loadUncompressedGfxHeader ;cargas el gfx

+
	;se cargan los gráficos de la scene1 de los créditos con su paleta correspondiente
	ld a,($cfde) 
	add a ;se multiplica el valro cfde por 2 para hacerlo de 16 bits, que es lo que necesitamos ahora
	add GFXH_CREDITS_SCENE1 ;selecciona el gráfico de los créditos scene1
	call loadGfxHeader ;cargas esos gráficos
	ld a,PALH_0f ;cambias la paleta
	call loadPaletteHeader ;cargas la nueva paleta
	;ejemplo de lo anterior sería cfde = 1, a = 2, add $50 --> a = 52, que sería la hipotética dirección de los gráficos de la segunda escena de los créditos

	ld a,($cfde) ; a = cfde
	ld b,$ff ; b = ff
	or a 
	jr z,+ ;si a = 0 se salta a +
	cp $07 ;compara a con 07
	jr z,+ ;si a = 7 saltas a +
	ld b,$01 ;sino, b = 1
+
	ld c,a ; c = a
	ld a,b ; a = b
	ld (wTilesetAnimation),a ; wTilesetAnimation = a
	call loadAnimationData ; carga la animación del tileset
	ld a,c ; a vuelve a su valor anterior

	ld hl,@@table_5f28 
	rst_addAToHl ; se apunta a la tabla 5f28 con el valor de a (al principio 0)
	ldi a,(hl)
	call loadPaletteHeader ;se carga la paleta

	call reloadObjectGfx ;recarga los gráficos de la pantalla
	ld a,$01
	ld (wScrollMode),a ; scrollmode = 1
	xor a ; a = 0
	ldh (<hCameraX),a ; se reinicia la posición de la cámara
	ld hl,$cfde 
	ld b,(hl) ; b = cfde
	call cutscene_parseObjectData_andLoadObjectGfx ;carga sprites y objetos de la escena. Primero carga los del índice 0 de la tabla: Impa, Nayru, Ralph, la estatua
	;de Link, el árbol Maku y Link
	ld a,$04
	call loadGfxRegisterStateIndex ;función que se llama después de cambiar los gráficos en la vram con la instrucción anterior. Se asegura que esté correcto el
	;estado gráfico de toda la pantalla después de hacer los cambios anteriores 
	jp fadeinFromWhite ;fade a la sala desde blanco

; se accede cuatro veces aquí con cdfe como índice
@@table_5f1c:
	dwbe ROOM_AGES_038
	dwbe ROOM_AGES_03a
	dwbe ROOM_AGES_04a
	dwbe ROOM_AGES_116

@@table_5f24:
	.db $2d $0f
	.db $2d $0f

@@table_5f28:
	.db $30 $2d
	.db $2d $27
	.db $ca $ca
	.db $ca $ae

;después de que se termine el fade a la sala y cuando se termine la escena del árbol Maku, Link, Nayru, Ralph, Impa y la estatua de Link tras la colleja
;a Link, se hace un fade out a blanco 
@@substate1:
	ld a,(wPaletteThread_mode)
	or a
	ret nz ;cuando haya terminado el fade, continúa el código

	ld a,($cfdf) ;a = 0
	or a
	ret z ;mientras cfdf sea 0 no sigue el código. cfcf lo pone a ff Link al terminar su animación tras la colleja de Impa.
	call incCbc2
	ld a,$ff ; a = ff
	ld (wTilesetAnimation),a ; settea wTilesetAnimation a ff
	jp fadeoutToWhite


@@substate2:
	ld a,(wPaletteThread_mode)
	or a
	ret nz
	call incCbc2
	call disableLcd
	call clearWramBank1
	ld a,($cfde)
	add a
	add GFXH_CREDITS_IMAGE1
	call loadGfxHeader
	ld hl,wTmpcbb3
	ld (hl),$5a
	ld a,PALH_a1
	call loadPaletteHeader
	ld a,$04
	call loadGfxRegisterStateIndex
	ld a,($cfde)
	ld hl,@@table_5f81
	rst_addAToHl
	ld a,(hl)
	ld (wGfxRegs1.SCX),a
	ld a,$10
	ldh (<hCameraX),a
	xor a
	ld ($cfdf),a
	jp fadeinFromWhite
@@table_5f81:
	.db $00 $d0 $00 $d0
	.db $00 $d0 $00 $d0
@@substate3:
	ld a,(wPaletteThread_mode)
	or a
	ret nz
	call decCbb3
	ret nz
	call incCbc2
	call getFreeInteractionSlot
	ret nz
	ld (hl),INTERAC_CREDITS_TEXT_HORIZONTAL
	inc l
	ld a,($cfde)
	ldi (hl),a
	ld (hl),$00
	ret
@@substate4:
	ld a,(wPaletteThread_mode)
	or a
	ret nz
	xor a
	ldh (<hOamTail),a
	ld a,($cfdf)
	or a
	ret z
	ld b,$03
	call checkIsLinkedGame
	jr z,+
	ld b,$07
+
	ld hl,$cfde
	ld a,(hl)
	cp b
	jr nc,@@func_5fc7
	inc (hl)
	xor a
	ld ($cbc2),a
	jr ++
@@func_5fc7:
	call cutscene_clearTmpCBB3
	call cutscene_clearCFC0ToCFDF
	ld a,$02
	ld ($cbc1),a
++
	jp fadeoutToWhite

@state2:
	jpab cutscenesBank10.agesFunc_10_70f6

@state3:
	jpab cutscenesBank10.agesFunc_10_7298

;;
; Called from disableLcdAndLoadRoom in bank 0.
;
;setea la habitación actual, apaga LCD para evitar problemas gráficos, limpia variables y memoria carga todos los gráficos, música y datos de la habitación,
;setea el tipo de scroll y prepara la OAM
disableLcdAndLoadRoom_body: ;a esta función se le pasa bc. Será un byte o algo así y la parte de b indica el grupo de la sala y la parte de la c indica la sala que queremos de ese grupo
	ld a,b 
	ld (wActiveGroup),a ;se setea el grupo actual al que queremos
	ld a,c
	ld (wActiveRoom),a ;ponemos como sala activa la que queremos
	call disableLcd ;apaga el LCD de la Game Boy. Básicamente se usa para que al cargar una nueva sala o actualizar gráficos todo vaya bien. Para evitar problemas gráficos
	call clearScreenVariablesAndWramBank1 ;limpia ciertas variables y la RAM del banco 1
	ld hl,wLinkInAir
	ld b,wcce9-wLinkInAir
	call clearMemory ;se borra cierta sección de la RAM
	call initializeVramMaps ;inicializa vram con un tileset parece
	call loadScreenMusicAndSetRoomPack ;cambia la música a la música de la habitación en cuestión y carga comportamientos específicos de la sala en cuestión
	call loadTilesetData ;carga el tileset de la sala
	call loadTilesetGraphics ;carga ese tileset en la VRAM
	call func_131f
	ld a,$01
	ld (wScrollMode),a ;indica que la habitación permite scroll normal
	call loadCommonGraphics ;recarga los gráficos que siempre están en la vram como el HUD, la espada de Link, tec
	call clearOam ;limpia posibles residuos gráficos en la OAM
	ld a,$10
	ldh (<hOamTail),a
	ret


cutscene_parseObjectData_andLoadObjectGfx:
	call getEntryFromObjectTable1
	call parseGivenObjectData
	call refreshObjectGfx
	jp cutsceneFunc_6026

cutsceneFunc_6026:
	ld a,($cfde)
	cp $00
	jr z,cutscene_load_04_ObjectGfx2Times_andReload
	cp $01
	jr z,cutscene_load_26_ObjectGfx2Times_andReload
	cp $02
	jr z,cutscene_load_24_ObjectGfx2Times_andReload
	cp $04
	jr z,cutscene_load_26_ObjectGfx2Times_andReload
	ret

cutscene_loadAObjectGfxBTimes:
	ld hl,wLoadedObjectGfx
cutscene_loadAintoHL_BTimes:
	ldi (hl),a
	inc a
	ld (hl),$01
	inc l
	dec b
	jr nz,cutscene_loadAintoHL_BTimes
	ret

cutscene_load_24_ObjectGfx2Times_andReload:
	ld a,$24
	ld b,$02
	jr cutscene_loadAObjectGfxBTimes_andReload
cutscene_load_26_ObjectGfx2Times_andReload:
	ld a,$26
	ld b,$02
	jr cutscene_loadAObjectGfxBTimes_andReload
cutscene_load_04_ObjectGfx2Times_andReload:
	ld a,$04
	ld b,$02

cutscene_loadAObjectGfxBTimes_andReload:
	call cutscene_loadAObjectGfxBTimes
	jp reloadObjectGfx

cutscene_incCBC2setCBB3whenCBB3is0:
	call cutscene_decCBB3IfTextNotActive
	ret nz
	call incCbc2
	ld hl,wTmpcbb3
	ld (hl),e
	ret

;;
cutscene_decCBB3IfTextNotActive:
	ld a,(wTextIsActive)
	or a
	ret nz
	jp decCbb3

;;
cutscene_decCBB3IfNotFadingOut:
	ld a,(wPaletteThread_mode) 
	or a
	ret nz ;si wPaletteThread_mode = 0, es decir, si ya no hay fadeout
	jp decCbb3 ;decrementa cbb3


cutscene_decCBB3IfNotFadingOut_incState_setCBB3_showText:
	call cutscene_decCBB3IfNotFadingOut
	ret nz
	call incCbc1
	ld a,e
	ld (wTmpcbb3),a
	jp showText

;;
cutscene_clearTmpCBB3:
	ld hl,wTmpcbb3
	ld b,$10
	jp clearMemory

;;
cutscene_clearCFC0ToCFDF:
	ld b,$20
	ld hl,$cfc0
	jp clearMemory

cutscene_setScreenShakeCounterTo4RumbleAt0:
	ld a,$04
	call setScreenShakeCounter
cutscene_rumbleSoundWhenFrameCounterLowerNibbleIs0:
	ld a,(wFrameCounter)
	and $0f
	ld a,SND_RUMBLE2
	jp z,playSound
	ret


;;
cutscene_resetOamWithSomething1:
	ld hl,bank16.oamData_4f73
	ld e,:bank16.oamData_4f73
	ld bc,$3038
	jr cutscene_resetOamWithData

;;
cutscene_resetOamWithSomething2: ;coloca los gráficos cargados en VRAM
	ld hl,bank16.oamData_4e37
	ld e,:bank16.oamData_4e37
	ld bc,$3038

;;
; @param	bc	Sprite offset
; @param	hl	OAM data to load
cutscene_resetOamWithData:
	xor a
	ldh (<hOamTail),a
	jp addSpritesFromBankToOam_withOffset

;;
; @param	hl	List of tiles (see below for example of format)
cutscene_replaceListOfTiles:
	ld b,(hl)
	inc hl
@loop:
	ld c,(hl)
	inc hl
	ldi a,(hl)
	push bc
	push hl
	call setTile
	pop hl
	pop bc
	dec b
	jr nz,@loop
	ret

blackTowerEscapeCutscene_doorBlockReplacement:
	.db $04     ; # of entries (cuatro tiles cambiados)
	.db $44 $83 ; Position del tile a cambiar, nuevo tile (en este caso el nuevo tile es el 83 del overworld, un muro)
	.db $45 $83
	.db $54 $83
	.db $55 $83

blackTowerEscapeCutscene_doorOpenReplacement:
	.db $04
	.db $44 $df
	.db $45 $ed
	.db $54 $80
	.db $55 $80

;;
func_60e0:
	ld hl,wLinkHealth
	ld (hl),$04
	ld l,<wInventoryB
	ldi a,(hl)
	ld b,(hl)
	ld hl,wcde3
	ldi (hl),a
	ld (hl),b
	jp disableActiveRing

;;
func_60f1:
	ld hl,wLinkMaxHealth
	ldd a,(hl)
	ld (hl),a
	ld hl,wcde3
	ldi a,(hl)
	ld b,(hl)
	ld hl,wInventoryB
	ldi (hl),a
	ld (hl),b
	jp enableActiveRing
