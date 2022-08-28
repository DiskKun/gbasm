;*	Includes
	; system includes
	INCLUDE	"hardware.inc"
	INCLUDE "charmap.asm"	
;*	user data
	SECTION "wram vars",WRAM0
wVBlankID:
	db

; wSpritePos
wSprites:
wSpr1X:
	db
wSpr1Y:
	db
wSpr2X:
	db
wSpr2Y:
	db
wSprites_End:

	SECTION "OAM Buffer", WRAM0[$cf00]
wOAM_Buffer:
	ds 4*40

	SECTION "ram_pads", WRAM0
cur_keys: 
	ds 1
new_keys: 
	ds 1

	SECTION "data",ROM0
all_tiles:
scene_0_tiles:
	INCBIN "title.2bpp"
scene_0_tiles_end:
scene_0_sprites:
	dw `33333333
	dw `30000003
	dw `30000003
	dw `30000003
	dw `30000003
	dw `30000003
	dw `30000003
	dw `33333333
scene_0_sprites_end:

text_tiles:
	INCBIN "text.2bpp"
text_tiles_end:
all_tiles_end:

all_tile_maps:
scene_0_map:
	INCBIN "title.tilemap"
scene_0_map_end:
all_tile_maps_end:

; strings
teststring:
	db "NEW",255

;*	equates

	SECTION "Interrupts",ROM0[$40]
VBlank_INT:
	push af
  push bc
  push de
  push hl
	jp VBlankHandler
	
	SECTION	"Header",ROM0[$100]
	jp Start
	ds $150 - @, 0 ; rgbfix -v

	SECTION "Program Start",ROM0[$150]
	
Start:

;	Turn off LCD
.wait
	ld a, [rLY]
	cp 144
	jr c, .wait

	xor a
	ld [rLCDC], a

;	load palettes
	ld a, %11010000
	ld [rOBP0], a
	;ld a, %11100100
	xor a
	ld [rBGP], a

; clear OAM
	ld c, 0
	ld hl, wOAM_Buffer
	ld de, 4*40
	call memSet

	ld hl, text_tiles
	ld de, $8bb0
	ld bc, text_tiles_end - text_tiles
	call memCopy

; copy DMA code into HRAM
	ld hl, DMA_CODE
	ld bc, DMA_CODE_END - DMA_CODE
	ld de, $ff80
	call memCopy


; enable interrupts
  ei
  ld a, %00000001 ; VBlank only
  ldh [rIE], a

	ld a, 255
	ld [wVBlankID], a

; Turn on LCD
  ld a, %10010011 ; LCD & PPU Enable, BG & Tile Data $8000, OBJ Enable, BG & Window Enable
  ld [rLCDC], a

TitleLoad:
; Clear screen
	ld c, $0
	ld hl, $9800
	ld de, 32 * 32 * 2
	call vMemSet

;	LOAD SCENE 0
	ld hl, scene_0_tiles
	ld de, $8000
	ld bc, scene_0_tiles_end - scene_0_tiles
	call vMemCopy

	ld hl, scene_0_sprites
	ld bc, scene_0_sprites_end - scene_0_sprites
	ld de, $8240
	call vMemCopy

	ld hl, $9800
	ld de, scene_0_map
	ld b, 18
	call ScreenCopy
	
	ld b, 5
	ld d, %11100100
	call fadeInBG

	ld a, 96
	ld [wOAM_Buffer], a
	ld a, 64
	ld [wOAM_Buffer+1], a
	ld a, $24
	ld [wOAM_Buffer+2], a

	ld hl, teststring
	ld de, $9944
	call printString


;	ld b, 5
;	call fadeOutBG

deadloop:
	jr deadloop

;	hl: text location
; de: screen location
printString:
	ld a, [hli]
	cp 255
	ret z
	ld b, a
	call waitVRAM
	ld a, b
	ld [de], a
	inc de
	jr printString


; ==============
; VBLANK HANDLER
; ==============
;
; 0: Title screen cutscene
VBlankHandler:
	; copy oam buffer
	call $ff80

.end
	pop hl
  pop de
  pop bc
  pop af
	reti
	

DMA_CODE:
	ld a, HIGH(wOAM_Buffer)
	ldh [$FF46], a
	ld a, 40
	dec a
	jr nz, @-1
	ret
DMA_CODE_END:

; Used to load a full map of 20*18 regular tiles. LCD-Safe
; @ hl: Pointer to upper-left tile
; @ de: Pointer to source tile map
; @ b : Number of rows to copy
ScreenCopy:
    ld c, SCRN_X_B
.rowLoop
;        ldh a, [rSTAT]
;        and STATF_BUSY
;        jr nz, .rowLoop
	call waitVRAM
    ld a, [de]
    ld [hli], a
    inc de
    dec c
    jr nz, .rowLoop
    dec b
    ret z
    ld a, SCRN_VX_B - SCRN_X_B
    ; Add `a` to `hl`
    add a, l
    ld l, a
    adc a, h
    sub a, l
    ld h, a
    jr ScreenCopy

vMemCopy:
	call waitVRAM
  ld a, [hli]
  ld [de], a
  inc de
  dec bc
  ld a, b
  or c
  jr nz, memCopy
  ret

memCopy:
	call waitVRAM
  ld a, [hli]
  ld [de], a
  inc de
  dec bc
  ld a, b
  or c
  jr nz, memCopy
  ret

vMemSet:
	call waitVRAM
  ld a, c
  ld [hli], a
  dec de
  ld a, d
  or e
  cp 0
  jp nz, memSet
  ret

memSet:
	call waitVRAM
  ld a, c
  ld [hli], a
  dec de
  ld a, d
  or e
  cp 0
  jp nz, memSet
  ret

waitVRAM:
	ldh a, [rSTAT]
	and STATF_BUSY
	jr nz, waitVRAM
	ret

fadeOutBG:
; b: time
	ld c, b
.fadeLoop
	ldh a, [rLY]
	cp 144
	jr nz, .fadeLoop
	dec b
	jr nz, .fadeLoop
	ld b, c
	ld a, [rBGP]
	sla a
	sla a
	ld [rBGP], a
	cp 0
	ret z
	jr .fadeLoop

fadeInBG:
; b: time
; d: palette to fade to
	ld c, b
	ld h, 4 ; counter
	ld l, 0 ; palette shifteage
.fadeLoop
	ldh a, [rLY]
	cp 144
	jr nz, .fadeLoop
	dec b
	jr nz, .fadeLoop
	ld b, c
	srl d
	rr l
	srl d
	rr l
	ld a, l
	ld [rBGP], a
	dec h
	ret z
	jr .fadeLoop


	

;
; Controller reading for Game Boy and Super Game Boy
;
; Copyright 2018, 2020 Damian Yerrick
; 
; This software is provided 'as-is', without any express or implied
; warranty.  In no event will the authors be held liable for any damages
; arising from the use of this software.
; 
; Permission is granted to anyone to use this software for any purpose,
; including commercial applications, and to alter it and redistribute it
; freely, subject to the following restrictions:
; 
; 1. The origin of this software must not be misrepresented; you must not
;    claim that you wrote the original software. If you use this software
;    in a product, an acknowledgment in the product documentation would be
;    appreciated but is not required.
; 2. Altered source versions must be plainly marked as such, and must not be
;    misrepresented as being the original software.
; 3. This notice may not be removed or altered from any source distribution.
;
; This controller reading routine is optimized for size.
; It stores currently pressed keys in cur_keys (1=pressed) and
; keys newly pressed since last read in new_keys, with the same
; nibble ordering as the Game Boy Advance.
; 76543210
; |||||||+- A
; ||||||+-- B
; |||||+--- Select
; ||||+---- Start
; |||+----- Right
; ||+------ Left
; |+------- Up
; +-------- Down
;           R
;           L (just kidding)

read_pad:
  ; Poll half the controller
  ld a,P1F_GET_BTN
  call .onenibble
  ld b,a  ; B7-4 = 1; B3-0 = unpressed buttons

  ; Poll the other half
  ld a,P1F_GET_DPAD
  call .onenibble
  swap a   ; A3-0 = unpressed directions; A7-4 = 1
  xor b    ; A = pressed buttons + directions
  ld b,a   ; B = pressed buttons + directions

  ; And release the controller
  ld a,P1F_GET_NONE
  ld [rP1],a

  ; Combine with previous cur_keys to make new_keys
  ld a,[cur_keys]
  xor b    ; A = keys that changed state
  and b    ; A = keys that changed to pressed
  ld [new_keys],a
  ld a,b
  ld [cur_keys],a
  ret

.onenibble:
  ldh [rP1],a     ; switch the key matrix
  call .knownret  ; burn 10 cycles calling a known ret
  ldh a,[rP1]     ; ignore value while waiting for the key matrix to settle
  ldh a,[rP1]
  ldh a,[rP1]     ; this read counts
  or $F0   ; A7-4 = 1; A3-0 = unpressed keys
.knownret:
  ret






;*** End Of File ***
