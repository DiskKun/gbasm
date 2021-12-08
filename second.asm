INCLUDE "hardware.inc"
SECTION "header", ROM0[$100]

EntryPoint:
	jp Title
	ds $150 - @, 0

SECTION "title_data", ROM0
title_data:
INCBIN "title.chr"
title_data_end:

SECTION "title_map", ROM0
title_map:
INCBIN "title.map"
title_map_end:

SECTION "tiledata", ROM0
tile_data:
INCBIN "tiles.chr"
tile_data_end:

SECTION "WRAM Things", WRAM0
wOldJoypad:
	db
wNewJoypad:
	db

SECTION "game code", ROM0[$150]

Title:
	call disableLCD

	ld a, %11100100
	ld [rBGP], a
	ld a, %11100000
	ld [rOBP0], a

	ld hl, $8000
	ld d, $f
	ld bc, $7ff
	call memset

	ld bc, title_data_end - title_data
	ld de, $8000
	ld hl, title_data
	call memCopy

	ld bc, title_map_end - title_map
	ld de, $9800
	ld hl, title_map
	call memCopy

	call enableLCD

	ld a, [$ff00]
	set 4, a
	res 5, a
	ld [$ff00], a

.loop
	ld a, [$ff00]
	bit 3, a
	jp z, .next
	jp .loop

.next
	ld a, [$ff00]
	bit 3, a
	jp nz, .next2
	jp .next

.next2
	call disableLCD

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

testButtons:
	call waitVBlank

	ld c, LOW(rP1)
	ld a, $10
	ldh [c], a
	ldh a, [c]
	or $F0
	swap a
	ld b, a
	ld a, $20
	ldh [c], a
	ldh a, [c]
	or $F0
	xor b
	ld [wNewJoypad], a
	
	bit	4, a
	jr nz, .a
	bit 5, a
	jr nz, .b
	bit 7, a
	jr nz, .start
	
	bit 0, a
	jr nz, .right
	bit 1, a
	jp nz, .left
	bit 2, a
	jp nz, .up
	bit 3, a
	jp nz, .down

	ld a, 0
	ld [wOldJoypad], a

	jp z, testButtons

.a
	call checkControl
	cp 1
	jp z, testButtons
	ld a, [$fe02]
	cp $17
	jp z, testButtons
	inc a
	ld [$fe02], a
	jp testButtons

.b
	call checkControl
	cp 1
	jp z, testButtons
	ld a, [$fe02]
	cp 0
	jp z, testButtons
	dec a
	ld [$fe02], a
	jp testButtons

.start
	call checkControl
	cp 1
	jp z, testButtons

	ld a, [$fe00]; In screen pixel coords, NOT oam coords!
	sub a, 16
	rlca
	rlca
	ld h, a
	ld a, [$fe01]; Screen pixel coords as well
	sub a, 8
	and $F8 ; To ensure we can use `rra`, overall faster than `srl a`
	rra
	rra
	rra
	xor h
	and SCRN_VX_B - 1 ; $1F
	xor h
	ld l, a ; Got low byte of address!
	ld a, h ; Get back vertical position
	and $03 ; We only care about the "high byte" bits
	or HIGH($9800) ; $98, for example. Works with any base, as long as its low byte is $00
	ld h, a
	
	ld a, [$fe02]
	ld [hl], a
	jp testButtons

.right
	call checkControl
	cp 1
	jp z, testButtons
	ld b, 8
	ld a, [$fe01]
	cp 160
	jp z, testButtons
	add a, b
	ld [$fe01], a
	jp testButtons

.left
	call checkControl
	cp 1
	jp z, testButtons
	ld b, 8
	ld a, [$fe01]
	cp 8
	jp z, testButtons
	sub a, b
	ld [$fe01], a
	jp testButtons

.up
	call checkControl
	cp 1
	jp z, testButtons
	ld b, 8
	ld a, [$fe00]
	cp 16
	jp z, testButtons
	sub a, b
	ld [$fe00], a
	jp testButtons

.down
	call checkControl
	cp 1
	jp z, testButtons
	ld b, 8
	ld a, [$fe00]
	cp 152
	jp z, testButtons
	add a, b
	ld [$fe00], a
	jp testButtons

checkControl:
	;ret
; checks to see if previous control input is the same as the last one; if so, pass
	ld a, [wNewJoypad]
	ld b, a
	ld a, [wOldJoypad]
	cp b
	jp z, .next
	ld a, b
	ld [wOldJoypad], a
	ld a, 0
	ret
.next
	ld a, 1
	ret

wait:
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
