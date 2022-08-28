
	SECTION "vblank int",ROM0[$40]
VBlankInterrupt:
	reti

	SECTION "header",ROM0[$100]
EntryPoint:
	jp Initialize
	ds $150 - @, 0

	SECTION "includes",ROM0
	INCLUDE "functions.asm"
	INCLUDE "hardware.inc"
tile_data:
	INCBIN "tiles.2bpp"
tile_data_end:

	SECTION "WRAM Variables",WRAM0
cur_keys:
	db
new_keys:
	db

	SECTION "main code",ROM0[$150]
Initialize:
.wait
	ld a, [rLY]
	cp 144
	jr c, .wait
	ld a, [rLCDC]
	res 7, a
	ld [rLCDC], a

;	Clear all RAM
	ld d, 0
	ld hl, $8000
	ld bc, $cfff - $8000
	call memSet

	ld d, 0
	ld hl, $fe00
	ld bc, $fe9f - $fe00
	call memSet

;	Set palettes
	ld a, %11100100
	ld [rBGP], a
	ld a, %11010000
	ld [rOBP0], a

	ld hl, tile_data
	ld de, $8000
	ld bc, tile_data_end - tile_data
	call memCopy

;	Init sprites
	===========

;	Enable VBlank
	ld a, IEF_VBLANK
	ldh [rIE], a
	xor a
	ldh [rIF], a
	ei

;	Enable LCD
	ld a, LCDCF_ON|LCDCF_BG8000|LCDCF_BGON|LCDCF_OBJ8|LCDCF_OBJON
	ldh [rLCDC], a

GameStart:

	


