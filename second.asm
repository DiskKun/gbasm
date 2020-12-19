INCLUDE "hardware.inc"
SECTION "header", ROM0[$100]

EntryPoint:
	jp Start
	ds $150 - @, 0

SECTION "tiledata", ROM0
tile_data:
INCBIN "tiles.chr"
tile_data_end:

SECTION "game code", ROM0[$150]

Start:
	call disableLCD

	ld a, %11100100
	ld [rBGP], a
	ld a, %11100000
	ld [rOBP0], a

	ld bc, tile_data_end - tile_data
	ld de, $8000
	ld hl, tile_data
	call memCopy

	ld hl, $9800
	ld a, $17
	ld bc, $400
	call memset

	ld hl, $fe00
	xor a
	ld c, $a0
	call memset_small

	ld a, 16
	ld [$fe00], a
	ld a, 8
	ld [$fe01], a
	ld a, $00
	ld [$fe02], a
	ld a, OAMF_PAL0|OAMF_BANK0
	ld [$fe03], a

	call enableLCD

mainGame:
	ld hl, $ff00
	res 5, [hl]
	set 4, [hl]
.loop
	bit 0, [hl]
	jr z, .a
	bit 1, [hl]
	jr z, .b
	jr nz, .loop

.a
	call checkControl
	call waitVBlank
	ld a, [$fe02]
	inc a
	ld [$fe02], a
	jp pass

.b
	call checkControl
	call waitVBlank
	ld a, [$fe02]
	dec a
	ld [$fe02], a

pass:
	
	jp mainGame

checkControl:
; checks to see if previous control input is the same as the last one; if so, pass
	ld a, [$ff00]
	ld b, a
	ld a, [$c000]
	cp b
	jr z, pass
	ld a, b
	ld [$c000], a

wait:
	ld a, $ff
	ld b, $ff
.loop
	dec a
	cp 0
	jr nz, .loop
	ld a, b
.loop2
	dec a
	cp 0
	jr nz, .loop2
	ret
enableLCD:
	ld a, LCDCF_ON|LCDCF_BG8000|LCDCF_BGON|LCDCF_OBJ8|LCDCF_OBJON
	ldh [rLCDC], a
	ret

memCopy:
	ld a, [hli]
	ld [de], a
	inc de
	dec bc
	ld a, b
	or c
	jr nz, memCopy
	ret

waitVBlank:
	ld   a, [rLY]
	cp   144
	jr c, waitVBlank
	ret

disableLCD:
	ld   a, [rLY]
	cp   144
	jr   c, disableLCD
	
	ld a, [rLCDC]
	res 7, a
	ld [rLCDC], a
	ret

; HL - destination
; A - byte to store
; C - number of bytes to set
memset_small:
  ld [hli], a
  dec c
  jr nz, memset_small
  ret

; HL - destination
; D - byte to store
; BC - number of bytes to set
memsetLoop:
	ld a, d
memset::
	ld [hli], a
	ld d, a
	dec bc
	ld a, b
	or c
	jr nz, memsetLoop
	ret
