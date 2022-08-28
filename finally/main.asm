;*	Includes
	; system includes
	INCLUDE	"hardware.inc"
	
;*	user data
	SECTION "wram vars",WRAM0
wPlayerVelocityX:
	ds 2
wPlayerVelocityY:
	ds 2
wPlayerX: ; First byte (at address) is high byte, next is low
	ds 2
wPlayerY:
	ds 2
wPlayerOAMY:
	db
wPlayerOAMX:
	db
wPlayerCheckY:
	db
wPlayerCheckX:
	db

	SECTION "wram oam",WRAM0[$c000]
wOAM:
	ds 40*4

	SECTION "OAM DMA",ROM0
OAMDMA:
	LOAD "OAM DMA code",HRAM
run_dma_hrampart:
	ldh [c], a
.wait
	dec b
	jr nz, .wait
	ret
	ENDL
OAMDMA_end:
	SECTION "graphics",ROM0
test_tiles:
	dw `03333330
	dw `31111113
	dw `31311313
	dw `31111113
	dw `31311313
	dw `31133113
	dw `31111113
	dw `03333330

	dw `33221100
	dw `32211003
	dw `22110033
	dw `21100332
	dw `11003322
	dw `10033221
	dw `00332211
	dw `03322110

	dw `32103210
	dw `21032103
	dw `10321032
	dw `03210321
	dw `32103210
	dw `21032103
	dw `10321032
	dw `03210321
test_tiles_end:

	SECTION "tables",ROM0
collision_table:
	db 2
collision_table_end:

	SECTION "ram_pads",WRAM0
cur_keys: 
	ds 1
new_keys: 
	ds 1
;*	equates
	def PLAYER_SPEED_ADD equ 32
	def PLAYER_SPEED_SUB equ -32
	def PLAYER_COLLIDE_OFFSET_1 equ 8;

	SECTION "Interrupts",ROM0[$40]
VBlank_INT:
	push af
	push bc
	push de
	push hl
	jp VBlank
	
	SECTION	"Header",ROM0[$100]
	jp Start
	ds $150 - @, 0 ; rgbfix -v

	SECTION "Program Start",ROM0[$150]
	
Start:
;	Turn off LCD
.wait:
	ldh a, [rLY]
	cp 144
	jp c, .wait
	xor a
	ldh [rLCDC], a

; load OAM DMA code into HRAM
	ld c, LOW(run_dma_hrampart)
	ld hl, OAMDMA
	ld d, OAMDMA_end - OAMDMA
.loop
	ld a, [hli]
	ldh [c], a
	inc c
	dec d
	jr nz, .loop

; clear all RAM
	ld hl, $c000
	ld de, $dfff - $c000
	ld c, 0
	call memSet

	ld hl, $fe00
	ld de, $fe9f - $fe00
	call memSet

; enable interrupts
  ei
  ld a, %00000001 ; VBlank only
  ldh [$ffff], a

; Palettes
	ld a, %11100100
	ldh [rBGP], a
	ld a, %11010000
	ldh [rOBP0], a

; Load in tiles
	ld hl, test_tiles
	ld de, $8000
	ld bc, test_tiles_end - test_tiles
	call memCopy

; tilemap
	ld c, 1
	ld hl, $9800
	ld de, 1024
	call memSet
	ld a, 2
	ld [$9a30], a

; Init sprite
	ld a, 76
	ld [wPlayerX], a
	ld a, 68
	ld [wPlayerY], a
	xor a
	ld [wOAM+2], a
	ld [wOAM+3], a

; Turn on LCD
  ld a, %10010011 ; LCD & PPU Enable, BG & Tile Data $8000, OBJ Enable, BG & Window Enable
  ldh [rLCDC], a

deadLoop:
	jr deadLoop

moveRoutine:
	call read_pad
	ld a, [cur_keys]
	ld d, a
	bit 7, d
	call nz, .increasePlayerVelocityY
	bit 6, d
	call nz, .decreasePlayerVelocityY
	bit 5, d
	call nz, .decreasePlayerVelocityX
	bit 4, d
	call nz, .increasePlayerVelocityX
	
	ld a, %11000000
	and d
	cp 0
	call z, slowDownY
	ld a, %00110000
	and d
	cp 0
	call z, slowDownX
	call applyPlayerVelocity
	ret

.increasePlayerVelocityY
	ld a, [wPlayerVelocityY]
	ld h, a
	ld a, [wPlayerVelocityY+1]
	ld l, a
	ld bc, PLAYER_SPEED_ADD
	add hl, bc
	ld a, h
	ld [wPlayerVelocityY], a
	ld a, l
	ld [wPlayerVelocityY+1], a
	ret
.decreasePlayerVelocityY
	ld a, [wPlayerVelocityY]
	ld h, a
	ld a, [wPlayerVelocityY+1]
	ld l, a
	ld bc, PLAYER_SPEED_SUB
	add hl, bc
	ld a, h
	ld [wPlayerVelocityY], a
	ld a, l
	ld [wPlayerVelocityY+1], a
	ret
.increasePlayerVelocityX
	ld a, [wPlayerVelocityX]
	ld h, a
	ld a, [wPlayerVelocityX+1]
	ld l, a
	ld bc, PLAYER_SPEED_ADD
	add hl, bc
	ld a, h
	ld [wPlayerVelocityX], a
	ld a, l
	ld [wPlayerVelocityX+1], a
	ret
.decreasePlayerVelocityX
	ld a, [wPlayerVelocityX]
	ld h, a
	ld a, [wPlayerVelocityX+1]
	ld l, a
	ld bc, PLAYER_SPEED_SUB
	add hl, bc
	ld a, h
	ld [wPlayerVelocityX], a
	ld a, l
	ld [wPlayerVelocityX+1], a
	ret

slowDownX:
	ld a, [wPlayerVelocityX]
	ld h, a
	ld a, [wPlayerVelocityX+1]
	ld l, a
	or h
	cp 0
	ret z
	bit 7, h
	jr z, .xPos
	ld bc, PLAYER_SPEED_ADD
	add hl, bc
	jr .loadBackX
.xPos
	ld bc, PLAYER_SPEED_SUB
	add hl, bc
.loadBackX
	ld a, h
	ld [wPlayerVelocityX], a
	ld a, l
	ld [wPlayerVelocityX+1], a
	ret
slowDownY:
	ld a, [wPlayerVelocityY]
	ld h, a
	ld a, [wPlayerVelocityY+1]
	ld l, a
	or h
	cp 0
	jr z, .end
	bit 7, h
	jr z, .yPos
	ld bc, PLAYER_SPEED_ADD
	add hl, bc
	jr .loadBackY
.yPos
	ld bc, PLAYER_SPEED_SUB
	add hl, bc
.loadBackY
	ld a, h
	ld [wPlayerVelocityY], a
	ld a, l
	ld [wPlayerVelocityY+1], a
.end
	ret

applyPlayerVelocity:
	ld a, [wPlayerY]
	ld b, a
	ld a, [wPlayerY+1]
	ld c, a
	ld a, [wPlayerVelocityY]
	ld h, a
	ld a, [wPlayerVelocityY+1]
	ld l, a
	add hl, bc
	ld a, h
	ld [wPlayerY], a
	ld a, l
	ld [wPlayerY+1], a	

	ld a, [wPlayerX]	
	ld b, a
	ld a, [wPlayerX+1]
	ld c, a
	ld a, [wPlayerVelocityX]
	ld h, a
	ld a, [wPlayerVelocityX+1]
	ld l, a
	add hl, bc
	ld a, h
	ld [wPlayerX], a
	ld a, l
	ld [wPlayerX+1], a
	ret

tileInteraction:
	ld b, 0
	ld h, 0
	ld a, [wPlayerX]
	add 4
	or a
	rra
	or a
	rra
	or a
	rra
	ld l, a
	ld a, [wPlayerY]
	add 4
	or a
	rra
	or a
	rra
	or a
	rra
	or a ; reset carry
	rla
	rl b
	rla
	rl b
	rla
	rl b
	rla
	rl b
	rla
	rl b
	ld c, a
	add hl, bc
	ld bc, $9800
	add hl, bc
	ld bc, collision_table
	ld d, collision_table_end - collision_table
.loop
	ld a, [bc]
	ld e, a
	inc bc
	ld a, [hl]
	cp e
	jr z, .test
	dec d
	jr nz, .loop
	ret
.test
	ld a, 0
	ld [rLCDC], a
	ret

VBlank:
	ldh a, [LOW(run_dma_hrampart)]
	cp $e2
	jr nz, .end
	call run_dma
	call moveRoutine
	call tileInteraction
	ld a, [wPlayerY]
	ld b, 68
	ld c, $42
	ld d, 112
	ld hl, wPlayerOAMY
	call update_player
	ld a, [wPlayerX]
	ld b, 76
	ld c, $43
	ld d, 96
	ld hl, wPlayerOAMX
	call update_player
.end
	pop hl
	pop de
	pop bc
	pop af
	reti

run_dma:
	ld a, HIGH(wOAM)
	ld bc, $2846
	jp run_dma_hrampart

; a = player position y or x
; b = 68 y or 76 x
; d = 112 y or 96 x
; c = $42 y or $43 x
; hl = wPlayerOAMY or wPlayerOAMX
update_player:
	sub b
	jr nc, .yPos
	add 84 
	ld [hl], a
	xor a
	ldh [c], a
	jr .update
.yPos
	sub d ; d
	jr nc, .yPosPos
	add d ; d
	ldh [c], a
	ld a, 84
	ld [hl], a
	jr .update
.yPosPos
	add 84 ; c
	ld [hl], a
	ld a, d ; d
	ldh [c], a
	jr .update
.update
	ld a, [wPlayerOAMY]
	ld [wOAM], a
	ld a, [wPlayerOAMX]
	ld [wOAM+1], a
	ret

memCopy:
; HL: starting address to copy from
; DE: starting address to copy to
; BC: number of bytes to copy
  ld a, [hli]
  ld [de], a
  inc de
  dec bc
  ld a, b
  or c
  jr nz, memCopy
  ret

memSet:
; C: byte to set to
; HL: memory address
; DE: number of bytes
  ld a, c
  ld [hli], a
  dec de
  ld a, d
  or e
  cp 0
  jp nz, memSet
  ret

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
