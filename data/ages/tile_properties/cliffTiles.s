; Determines which tiles function as cliffs which Link can jump down.
;
; Data format:
;   b0: Tile index ($00 for end of list)
;   b1: Angle value from which the tile can be jumped off of.
;
; See also "itemPassableTiles.s" which allows projectiles to pass through cliffs.

cliffTilesTable:
	.dw @overworld
	.dw @indoors
	.dw @dungeons
	.dw @sidescrolling
	.dw @underwater
	.dw @five
	.dw @placeholderTilesetFirstArea
	.dw @placeholderTilesetVillage

@placeholderTilesetVillage:
	.db $10, ANGLE_UP
	.db $11, ANGLE_UP
	.db $12, ANGLE_LEFT
	.db $13, ANGLE_RIGHT
	.db $20, ANGLE_LEFT
	.db $21, ANGLE_RIGHT
	.db $84, ANGLE_DOWN
	.db $ca, ANGLE_DOWN
	.db $cb, ANGLE_DOWN
	.db $cc, ANGLE_DOWN
	.db $cd, ANGLE_DOWN
	.db $00
@placeholderTilesetFirstArea:
	.db $10, ANGLE_UP
	.db $11, ANGLE_UP
	.db $12, ANGLE_LEFT
	.db $13, ANGLE_RIGHT
	.db $20, ANGLE_LEFT
	.db $21, ANGLE_RIGHT
	.db $22, ANGLE_LEFT
	.db $23, ANGLE_RIGHT
	.db $84, ANGLE_DOWN
	.db $ca, ANGLE_DOWN
	.db $cb, ANGLE_DOWN
	.db $cc, ANGLE_DOWN
	.db $cd, ANGLE_DOWN
	.db $ce, ANGLE_DOWN
	.db $00

@overworld:
@underwater:
	.db $05, ANGLE_DOWN
	.db $06, ANGLE_DOWN
	.db $07, ANGLE_DOWN
	.db $0a, ANGLE_LEFT
	.db $0b, ANGLE_RIGHT
	.db $64, ANGLE_DOWN
	.db $ff, ANGLE_DOWN
	.db $00

@indoors:
@dungeons:
@five:
	.db $b0, ANGLE_DOWN
	.db $b1, ANGLE_LEFT
	.db $b2, ANGLE_UP
	.db $b3, ANGLE_RIGHT
	.db $c1, ANGLE_DOWN
	.db $c2, ANGLE_LEFT
	.db $c3, ANGLE_UP
	.db $c4, ANGLE_RIGHT
@sidescrolling:
	.db $00
