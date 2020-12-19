INCLUDE "hardware.inc"
SECTION "header", ROM0[$100]

EntryPoint:
	jp Start
	ds $150 - @, 0

SECTION "city tiles", ROM0

city_tile_data:
INCBIN "city.chr"
city_tile_data_end:

SECTION "city map", ROM0

city_map_data:
INCBIN "city.map"
city_map_data_end:

SECTION "sprite", ROM0
opt g0123
sprite_data:
dw `00000000
dw `00000000
dw `00300300
dw `00000000
dw `03000030
dw `00333300
dw `00000000
dw `00000000
sprite_data_end:

SECTION "game code", ROM0[$150]

Start:
	call disableLCD

	ld a, %11100100
	ld [rBGP], a

	ld bc, city_tile_data_end - city_tile_data
	ld de, $8000
	ld hl, city_tile_data
	call memCopy
	ld bc, city_map_data_end - city_map_data
	ld de, $9800
	ld hl, city_map_data
	call memCopy

	ld bc, sprite_data - sprite_data_end
	ld de, $8000 + city_tile_data_end - city_tile_data
	ld hl, sprite_data
	call memCopy
	;ld a, 

	ld a, LCDCF_ON|LCDCF_BG8000|LCDCF_BGON|LCDCF_OBJ8|LCDCF_OBJON
	ldh [rLCDC], a

.deadloop:
	jr .deadloop

memCopy:
.loop
	ld a, [hli]
	ld [de], a
	inc de
	dec bc
	ld a, b
	or c
	jr nz, .loop
	ret

disableLCD:
	ld   a, [rLY]
	cp   144
	jr   c, disableLCD
	
	ld a, [rLCDC]
	res 7, a
	ld [rLCDC], a
	ret