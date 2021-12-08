;*	Includes
	; system includes
	INCLUDE	"hardware.inc"
	
;*	user data
	SECTION "wram vars",WRAM0
	
	SECTION "ram_pads", WRAM0
cur_keys: 
	ds 1
new_keys: 
	ds 1
;*	equates

	SECTION "Interrupts",ROM0[$40]
VBlank_INT:
	reti
	
	SECTION	"Header",ROM0[$100]
	jp Start
	ds $150 - @, 0 ; rgbfix -v

	SECTION "Program Start",ROM0[$150]
	
Start:

;	Turn off LCD
waitVBlank:
	ld a, [rLY]
	cp 144
	jp c, waitVBlank

	xor a
	ld [rLCDC], a

; enable interrupts
  ei
  ld a, %00000001 ; VBlank only
  ldh [$ffff], a

; Turn on LCD
  ld a, %10010011 ; LCD & PPU Enable, BG & Tile Data $8000, OBJ Enable, BG & Window Enable
  ld [rLCDC], a

deadloop:
	jr deadloop


memCopy:
  ld a, [hli]
  ld [de], a
  inc de
  dec bc
  ld a, b
  or c
  jr nz, memCopy
  ret

memSet:
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
