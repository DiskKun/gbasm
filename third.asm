INCLUDE "hardware.inc"
SECTION "header", ROM0[$100]

EntryPoint:
	jp initialize
	ds $150 - @, 0

SECTION "verts_tile", ROM0

sprite_data:
	opt g.123
	dw `...33...
	dw `..3223..
	dw `.321123.
	dw `32111123
	dw `32111123
	dw `.321123.
	dw `..3223..
	dw `...33...
sprite_data_end:

SECTION "verts", WRAM0

; 2D X and Y coordinates of each vert
wVert1:
	ds 2
wVert2:
	ds 2
wVert3:
	ds 2
wVert4:
	ds 2
wVert5:
	ds 2
wVert6:
	ds 2
wVert7:
	ds 2
wVert8:
	ds 2

; 3D coordinates of each vert
w3D1:
	ds 3
w3D2:
	ds 3
w3D3:
	ds 3
w3D4:
	ds 3
w3D5:
	ds 3
w3D6:
	ds 3
w3D7:
	ds 3
w3D8:
	ds 3

SECTION "game code", ROM0[$150]

initialize:
	call disableLCD

; fill OAM with 0
	ld hl, $fe00
	xor a
	ld bc, $a0
	call memset

; Copy sprite data to VRAM
	ld de, $8000
	ld hl, sprite_data
	ld bc, sprite_data_end - sprite_data
	call memCopy

; Set palettes
	ld a, %11100100
	ld [rBGP], a
	ld a, %11100000
	ld [rOBP0], a

; fill Tilemap with blank tiles
	ld hl, $9800
	ld a, $1a
	ld bc, $400
	call memset

;	Loading 3D coordinates into w3D[n]
;	w3D1
	ld hl, w3D1
	ld a, 50
	ld [hli], a
	ld [hli], a
	ld [hli], a
;	w3D2
	ld [hli], a
	ld [hli], a
	ld a, 100
	ld [hli], a
;	w3D3
	ld a, 50
	ld [hli], a
	ld a, 100
	ld [hli], a
	ld a, 50
	ld [hli], a
;	w3D4
	ld [hli], a
	ld a, 100
	ld [hli], a
	ld [hli], a
;	w3D5
	ld [hli], a
	ld a, 50
	ld [hli], a
	ld [hli], a
;	w3D6
	ld a, 100
	ld [hli], a
	ld a, 50
	ld [hli], a
	ld a, 100
	ld [hli], a
;	w3D7
	ld [hli], a
	ld [hli], a
	ld a, 50
	ld [hli], a
;	w3D8
	ld a, 100
	ld [hli], a
	ld [hli], a
	ld [hli], a

; Load tile numbers into OAM
	xor a
	ld [$fe02], a
	ld [$fe06], a
	ld [$fe0a], a
	ld [$fe0e], a
	ld [$fe12], a
	ld [$fe16], a
	ld [$fe1a], a
	ld [$fe1e], a

; load other attribs into OAM
	ld a, OAMF_PAL0|OAMF_BANK0
	ld [$fe03], a
	ld [$fe07], a
	ld [$fe0b], a
	ld [$fe0f], a
	ld [$fe13], a
	ld [$fe17], a
	ld [$fe1b], a
	ld [$fe1f], a

	call enableLCD

main:
	call load3Dinto2D
	call updateVerts
	jp main

load3Dinto2D:
	ld a, [w3D1]
	ld [wVert1], a
	ld a, [w3D1 + 1]
	ld [wVert1 + 1], a
	ld a, [w3D2]
	ld [wVert2], a
	ld a, [w3D2 + 1]
	ld [wVert2 + 1], a
	ld a, [w3D3]
	ld [wVert3], a
	ld a, [w3D3 + 1]
	ld [wVert3 + 1], a
	ld a, [w3D4]
	ld [wVert4], a
	ld a, [w3D4 + 1]
	ld [wVert4 + 1], a
	ld a, [w3D5]
	ld [wVert5], a
	ld a, [w3D5 + 1]
	ld [wVert5 + 1], a
	ld a, [w3D6]
	ld [wVert6], a
	ld a, [w3D6 + 1]
	ld [wVert6 + 1], a
	ld a, [w3D7]
	ld [wVert7], a
	ld a, [w3D7 + 1]
	ld [wVert7 + 1], a
	ld a, [w3D8]
	ld [wVert8], a
	ld a, [w3D8 + 1]
	ld [wVert8 + 1], a
	ret

updateVerts:
	call waitVBlank
	ld a, [wVert1 + 1]
	ld [$fe00], a
	ld a, [wVert1]
	ld [$fe01], a
	ld a, [wVert2 + 1] 
	ld [$fe04], a
	ld a, [wVert2]
	ld [$fe05], a
	ld a, [wVert3 + 1]
	ld [$fe08], a
	ld a, [wVert3]
	ld [$fe09], a
	ld a, [wVert4 + 1]
	ld [$fe0c], a
	ld a, [wVert4]
	ld [$fe0d], a
	ld a, [wVert5 + 1]
	ld [$fe10], a
	ld a, [wVert5]
	ld [$fe11], a
	ld a, [wVert6 + 1]
	ld [$fe14], a
	ld a, [wVert6]
	ld [$fe15], a
	ld a, [wVert7 + 1]
	ld [$fe18], a
	ld a, [wVert7]
	ld [$fe19], a
	ld a, [wVert8 + 1]
	ld [$fe1c], a
	ld a, [wVert8]
	ld [$fe1d], a
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
