;*	Includes
	; system includes
	INCLUDE	"hardware.inc"

	; project includes

	SECTION "header",ROM0[$100]
	jp Start
	ds $150 - @, 0

;*	user data (constants)

	def SPIN_WAIT equ 2

	SECTION "tile data",ROM0
tile_data:
	INCBIN "gbbg.2bpp"
	INCBIN "selector.2bpp"
	dw `33333333
	dw `31000013
	dw `30300303
	dw `30000003
	dw `30300303
	dw `30033003
	dw `31000013
	dw `33333333
tile_data_end:
tile_map:
	INCBIN "gbbg.tilemap"
tile_map_end:
sprite_tiles:
	INCBIN "selector.tilemap"
sprite_tiles_end:
;*	equates

;* Variables
	SECTION "Variables",WRAM0
spin_cycle:
	db
spin_wait:
	db

;* Interrupt handlers
	SECTION "Interrupt",ROM0[$40]
	jp spin
	;reti

;*	Program Start

	SECTION "Program Start",ROM0[$0150]
Start:
; Wait for VBlank
WaitVB:
	ld a, [rLY]
	cp 144
	jp c, WaitVB

	; Turn the LCD off
	ld a, 0
	ld [rLCDC], a

	; DO ALL INITIAL VRAM LOADS HERE

; Palettes
	ld a, %11100100
	ld [$ff47], a
	
	ld a, %11100100
	ld [$ff48], a

; Copy tile data
	ld de, $8000
	ld hl, tile_data
	ld bc, tile_data_end - tile_data
	call memCopy

;	Copy tile map
	ld de, $9800
	ld hl, tile_map
	ld bc, tile_map_end - tile_map
	call memCopy

	ld hl, $fe00
	ld de, $fe9f - $fe00
	ld c, 0
	call memSet

;	Initialize selector sprite
	ld hl, $fe00
	ld a, 60
	ld [hli], a
	ld [hli], a
	ld a, $41
	ld [hli], a
	xor a
	ld [hl], a
	ld a, 1
	ld [spin_cycle], a

	ld a, SPIN_WAIT
	ld [spin_wait], a

;	enable interrupts
	ei
	ld a, %00000001
	ldh [$ffff], a

; Turn on LCD
	ld a, %10010011
	ld [$ff40], a

; time to do some crazy scrolling stuff
ld c, 1
scloop:
	ld a, [$ff41]	
	and %00000011
	cp 0
	jr nz, .unsetb
	ld a, b
	cp 1
	jr z, scloop
	jr .scroll
.unsetb
	ld b, 0
	jr scloop
.scroll
	ld a, [$ff43]
;	add 7
	add 15
	;add c
	ld [$ff43], a
	ld b, 1
	inc c
	jr scloop
	
deadloop:
	jp deadloop

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

spin:
	ld a, [spin_wait]
	cp 0
	jr nz, .dec
	jr .spin
.dec
	dec a
	ld [spin_wait], a
	reti
.spin
	ld a, SPIN_WAIT
	ld [spin_wait], a
	ld a, [spin_cycle]
	cp 12
	jr nz, .pass
	ld a, 1
	jr .pass2
.pass
	inc a
.pass2
	ld [spin_cycle], a
	
	ld b, a
	ld hl, sprite_tiles
	ld a, l
	add b
	ld l, a
	adc h
	sub l
	ld h, a
	ld a, [hl]
	add $41
	ld [$fe02], a
	reti

;*** End Of File ***
