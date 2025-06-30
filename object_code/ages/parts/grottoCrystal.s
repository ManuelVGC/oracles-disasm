; ==================================================================================================
; PART_GROTTO_CRYSTAL
; ==================================================================================================


; Este código cambia el wSwitchState cuando se rompe el cristal de la sala y cambia el sprite de cristal no roto a roto. Además, cuando se entra en la sala del cristal
; comprueba si el bit 6 está activado (ya se había roto antes el cristal) y actualiza el cristal para que se vea ya roto al entrar en la sala.
 
partCode24:
	jr z,@normalStatus ;el z problablemente lo inicia el dungeon event que está siempre en la primera sala de la mazmorra.

	;cuando rompes el cristal se hace la animación de pasar de cristal sin romper a roto y se modifica el wSwitchState.

	;modifica el wSwitchState
	ld a,(wSwitchState)
	ld h,d ;d apunta al propio PART
	ld l,$c2 ;este d:$c2 es un bitmask que se usa luego para hacer el xor
	xor (hl) ;este xor invierte el valor de un bit de A según el bit que esté activado en el bitmask.
	ld (wSwitchState),a

	;pasa de cristal no roto a roto
	ld l,$e4
	res 7,(hl) ;hace que el sprite del cristal sin romper sea invisible
	ld a,$01
	call partSetAnimation ;pasa a cristal roto

	;partículas de romperse el cristal
	; sarcophagus when it breaks
	ldbc, INTERAC_SARCOPHAGUS $80 ;esto es el sarcophagus subid80, que es básicamente la animación de un sarcófago rompiéndose, simplemente se usa como vfx de
	; trozos azules saliendo volando.
	jp objectCreateInteraction 

; Código que comprueba el bit 6 de los flags de la sala cuando vuelves a entrar en ella, y pone el cristal ya roto en caso de que esté activado, porque el cambio
; visual que haces al romper el cristal es temporal, solo existe mientras sigas en la sala.
@normalStatus:
	ld e,$c4 ;$c4 = 0 cada vez que se entra en la sala y por tanto se crea la PART. Al acabarse de crear todas las variables están a 0.
	ld a,(de) 
	or a
	ret nz ;si c4 ya se ha inicializado antes, sale.
	inc a ;incrementa a a 1. 
	ld (de),a ;pone c4 a 1 para que de esta forma como el normalStatus se ejecuta todo el rato mientras estás en la sala, no se vuelva a ejecutar el código
	; de comprobar el bit 6 de los flags de la sala hasta que no vuelvas a salir y entrar de nuevo. Es decir, el código que está debajo de este solo se ejecuta una
	; vez cuando entras en la sala, mientras estás en ella no para de salir con el ret nz anterior al haber cambiado el $c4 a 1 y cuando salgas y entres de la sala
	; otra vez, se resetea el $c4 a 0 y vuelve a ejecutar una vez la comprobación del bit 6 de los flags de la sala.

	call getThisRoomFlags
	bit 6,(hl)
	jr z,+ ;comprueba los flags de la habitación a ver si ya está roto el cristal (si el bit 6 está a 1, ya había sido roto previamente). Esto lo marca el dungeon
	; event subid0d

	;mismo de antes, pasa de cristal sin romper a roto
	ld h,d
	ld l,$e4
	res 7,(hl) ;si estaba roto, borra la visibilidad del cristal sin romperse 
	ld a,$01
	call partSetAnimation ;pasa a cristal roto. De esta forma el cristal aparece ya roto cuando entras en la sala.
+
	call objectMakeTileSolid ;marca el tile como sólido para que Link no pueda pasar a través de él.
	ld h,$cf
	ld (hl),$0a
	jp objectSetVisible83
