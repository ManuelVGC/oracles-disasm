; ==================================================================================================
; INTERAC_TRIGGER_TRANSLATOR
; ==================================================================================================
interactionCode24:
	call interactionDeleteAndRetIfEnabled02
	ld e,Interaction.subid
	ld a,(de)
	and $0f
	rst_jumpTable
	.dw @subid0
	.dw @subid1
	.dw @subid2

; Subid 0: control a bit in wActiveTriggers based on wToggleBlocksState.
@subid0:
	ld a,(wToggleBlocksState)
	ld c,a

;comprueba que el bit de wSwitchState o wToggleBlocksState que le indicamos con el subid esté activo. En ese caso, lo activa en wActiveTriggers.
@label_08_081:
	ld e,Interaction.subid
	ld a,(de)
	swap a ;se cambian los bits altos del subid por los bajos
	and $07 ;se queda solo con los tres bits más bajos.
	ld hl,bitTable ;carga bittable en hl (bittable es una tabla con ocho valores, y cada valor es un bitmask de un bit distinto de cada uno de los ocho de
	; un byte, es rollo 0000 0001, 0000 0010, etc. De ahí se cogerá un valor de la tabla u otro dependiendo de este valor que salga de hacer and $07)
	add l ;se hace a = a + l (donde l es la parte baja de hl)
	ld l,a ;se suma básicamente a a l haciendo que hl ahora apunta a donde queremos apuntar habiendo usado el subid. Es decir, con el subid indicamos el bit que
	;queremos comprobar que esté activo bien de wSwitchState o de wToggleBlocksState

	ld a,c ;a = wSwitchState
	and (hl) ;compruebas que el bit que le has indicado con el subid esté activo.
	ld b,a ;guardamos 0 o ese bit en b.

	;invertimos la máscara de bits y lo desactivamos en wActiveTriggers, volviéndolo a activar gracias a b si era != 0.
	ld a,(hl) ;cargamos la máscara de bits en a
	cpl ; la invertimos
	ld c,a ;y la cargamos en c
	ld a,(wActiveTriggers)
	and c ;desactivamos ese bit en wActiveTriggers gracias a la máscara invertida
	or b ;y lo volvemos a activar en caso de que estuviese activado en wSwitchState o wToggleBlocksState.
	ld (wActiveTriggers),a ;carga el nuevo wActiveTriggers.
	ret

; Subid 1: control a bit in wActiveTriggers based on wSwitchState.
@subid1:
	ld a,(wSwitchState)
	ld c,a
	jr @label_08_081

; Subid 2: check that [wNumLitTorches] == Y y activa un bit en wActiveTriggers
@subid2:
	ld e,Interaction.yh
	ld a,(de)
	ld b,a ; b = Y de la interacción

	ld e,Interaction.xh
	ld a,(de)
	ld c,a ; c = X de la interacción

	ld a,(wNumTorchesLit)
	cp b ;devuelve z si a = b 
	jr nz,++ ;si el número de antorchas encendidas es Y entonces sigue el código, sino, salta a ++

	ld a,(wActiveTriggers)
	or c ;activa un bit en wActiveTriggers
	ld (wActiveTriggers),a
	ret
++
	;si hay alguna antorcha apagada desactiva el bit c de wActiveTriggers
	ld a,c
	cpl
	ld c,a
	ld a,(wActiveTriggers)
	and c
	ld (wActiveTriggers),a
	ret
