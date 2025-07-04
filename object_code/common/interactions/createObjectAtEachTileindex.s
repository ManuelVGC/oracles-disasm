; ==================================================================================================
; INTERAC_CREATE_OBJECT_AT_EACH_TILEINDEX
; ==================================================================================================
interactionCodec7:
	ld e,Interaction.subid
	ld a,(de) ;carga el subid en a
	ld c,a ;c = subid
	ld hl,wRoomLayout ;carga la dirección de wRoomLayout en hl
	ld b,LARGE_ROOM_HEIGHT*$10 ;b = alto de la habitación * 10
--
	ld a,(hl) ;a = un tile de wRoomLayout
	cp c 
	call z,@createObject ;si subid = tile guardado en a, salta a createObject
	inc l ;sino es igual, pasa al siguiente tile
	dec b ;se decrementa el contador de tiles a mirar
	jr nz,-- ;mientras que siga habiendo tiles por mirar sigue comprobando. 
	jp interactionDelete ;Cuando termina de comprobar todos los tiles borra la interacción.

@createObject:
	push hl
	push bc ;guarda en la pila hl y bc para restaurarlos más adelante y no alterar el proceso de comprobación de tiles de la sala

	ld b,l ;se guarda el índice que tiene el tile en la sala
	ld e,Interaction.xh 
	ld a,(de) ; a = X de la interacción
	and $f0 ;se queda solo con los 4 bits altos
	swap a ;cambia los bits altos por los bajos
	call @spawnObjectType ;spawnea un tipo de objeto según a
	jr nz,@ret ;si no hay espacio para el objeto, no hace nada


	;a partir de aqui configura el objeto que acaba de crear:

	;hl apunta aquí al primer campo del objeto recién creado, que es el id. Hace id = Y de INTERAC_CREATE_OBJECT_AT_EACH_TILEINDEX
	ld e,Interaction.yh
	ld a,(de)
	ldi (hl),a 

	;hl apunta aquí al subid. Hace subid = bits bajos de X de INTERAC_CREATE_OBJECT_AT_EACH_TILEINDEX
	ld e,Interaction.xh
	ld a,(de)
	and $0f
	ld (hl),a 

	;configura la Y del nuevo objeto usando el índice del tile que guardamos en la función anterior en b
	ld a,l
	add Object.yh-Object.subid
	ld l,a
	ld a,b
	and $f0
	add $08
	ldi (hl),a

	;configura la X del nuevo objeto usando el índice del tile que guardamos en la función anterior en b
	inc l
	ld a,b
	and $0f
	swap a
	add $08
	ld (hl),a

@ret:
	pop bc
	pop hl
	ret

;;
; @param	a	0 for enemy; 1 for part; 2 for interaction
; @param[out]	hl	Spawned object
@spawnObjectType:
	or a
	jp z,getFreeEnemySlot
	dec a
	jp z,getFreePartSlot
	dec a
	jp z,getFreeInteractionSlot
	ret
