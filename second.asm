INCLUDE "hardware.inc"
SECTION "header", ROM0[$100]

EntryPoint:
	jp Start
	ds $150 - @, 0

SECTION "tiledata", ROM0
tile_data:
INCBIN "tiles.chr"
tile_data_end:

SECTION "WRAM Things", WRAM0
old_jp:
	db
new_jp:
	db

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

testButtons:
	ld hl, $ff00
	set 4, [hl]
	res 5, [hl]
	
.loop
	ld a, [$ff00]
	bit	0, a
	jr z, .a
	bit 1, a
	jr z, .b
	bit 3, a
	jr z, .start
	jr nz, testDPad

.a
	call checkControl
	call waitVBlank
	ld a, [$fe02]
	cp $17
	jp z, testDPad
	inc a
	ld [$fe02], a
	jp testDPad

.b
	call checkControl
	call waitVBlank
	ld a, [$fe02]
	cp 0
	jp z, testDPad
	dec a
	ld [$fe02], a
	jp testDPad

.start
	call waitVBlank
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

testDPad:
	ld b, 8
	ld hl, $ff00
	set 5, [hl]
	res 4, [hl]

.loop
	ld a, [$ff00]
	bit 0, a
	jr z, .right
	bit 1, a
	jr z, .left
	bit 2, a
	jr z, .up
	bit 3, a
	jr z, .down
	jp nz, testButtons

.right
	call checkControl
	call waitVBlank
	ld b, 8
	ld a, [$fe01]
	cp 160
	jp z, testButtons
	add a, b
	ld [$fe01], a
	jp testButtons

.left
	call checkControl
	call waitVBlank
	ld b, 8
	ld a, [$fe01]
	cp 8
	jp z, testButtons
	sub a, b
	ld [$fe01], a
	jp testButtons

.up
	call checkControl
	call waitVBlank
	ld b, 8
	ld a, [$fe00]
	cp 16
	jp z, testButtons
	sub a, b
	ld [$fe00], a
	jp testButtons

.down
	call checkControl
	call waitVBlank
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
	ld a, [$ff00]
	ld b, a
	ld a, [old_jp]
	cp b
	jp z, testButtons
	ld a, b
	ld [old_jp], a
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
