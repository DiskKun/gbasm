	INCLUDE "hardware.inc"
	INCLUDE "input.asm"
	SECTION "WRAM Variables",WRAM0
wPlayerX:
	ds 2
wPlayerY:
	ds 2
wXVel:
	ds 2
wYVel:
	ds 2
wColLoop:
	db
wTimer:
	ds 4
wCollected:
	ds 2
wToCollect:
	ds 2
wLevelIndex:
	db

	SECTION "Tile Data",ROM0
tile_data:
	INCBIN "tiles.2bpp"
tile_data_end:

	SECTION "Level Data",ROM0
level0:
	ret
level1:
	ld a, 2
	ld [$9820], a
	ret
	SECTION "Header",ROM0[$100]
Entry:
	jp Start
	ds $150 - @, 0

	SECTION "VBlank Interrupt",ROM0[$40]
VBlankInterrupt:
	;ld a, [wTimer+3]
	;add a, 1
	;daa
	;ld [wTimer+3], a
	;ld a, [wTimer+2]
	;adc 0
	;daa
	;ld [wTimer+2], a
	reti

	SECTION "Main",ROM0[$150]
Start:
.wait
	ld a, [rLY]
    cp 144
    jr c, .wait
	
	ld a, [rLCDC]
    res 7, a
    ld [rLCDC], a

	; Palettes
	ld a, %11100100
	ld [rBGP], a
	ld a, %11010000
	ld [rOBP0], a

	xor a
	ld [wLevelIndex], a
	;ld a, 2
	;ld [$9800+132], a
	;ld [$9800+143], a
	;ld [$9800+420], a
	;ld [$9800+431], a

	; clear OAM
	ld d, 0
	ld hl, $fe00
	ld bc, 40 * 4
	call memSet


    ld a, IEF_VBLANK
    ldh [rIE], a
	xor a
	ldh [rIF], a

	ei

	ld a, LCDCF_ON|LCDCF_BG8000|LCDCF_BGON|LCDCF_OBJ8|LCDCF_OBJON
    ldh [rLCDC], a

loadLevel:
	ld a, [rLY]
	cp 144
	jr c, .wait
	ld a, [rLCDC]
	res 7, a
	ld [rLCDC], a

	xor a
	ld [wXVel], a
	ld [wYVel], a
	ld [wXVel+1], a
	ld [wYVel+1], a
	ld [wColLoop], a
	ld [wCollected], a
	ld [wCollected+1], a
	ld [wTimer], a
	ld [wTimer+1], a
	ld [wLevelIndex], a

	; set default player position and attribs
	ld a, 84
	ld [wPlayerX], a
	ld a, 84
	ld [wPlayerY], a
	ld a, 1
	ld [$fe02], a
	xor a
	ld [$fe03], a
	ld [wPlayerX+1], a
	ld [wPlayerY+1], a

	; Copy tile data
	ld hl, tile_data
	ld de, $8000
	ld bc, tile_data_end - tile_data
	call memCopy

	; clear tile map
	ld d, $0d
	ld hl, $9800
	ld bc, 1024
	call memSet

	ld a, LCDCF_ON|LCDCF_BG8000|LCDCF_BGON|LCDCF_OBJ8|LCDCF_OBJON
    ldh [rLCDC], a

Main:
	; read joypad, apply velocity
	
	call UpdateInput
	ld a, [hCurrentKeys]
	bit 4, a
	call nz, .right
	ld a, [hCurrentKeys]
	bit 5, a
	call nz, .left
	ld a, [hCurrentKeys]
	bit 6, a
	call nz, .up
	ld a, [hCurrentKeys]
	bit 7, a
	call nz, .down
	bit 3, a
	jp nz, Start

.applyV
	ld a, [wXVel]
	ld b, a
	ld a, [wXVel+1]
	ld c, a
	ld a, [wPlayerX]
	ld h, a
	ld a, [wPlayerX+1]
	ld l, a
	add hl, bc
	ld a, h
	ld [wPlayerX], a
	ld a, l
	ld [wPlayerX+1], a

	ld a, [wYVel]
	ld b, a
	ld a, [wYVel+1]
	ld c, a
	ld a, [wPlayerY]
	ld h, a
	ld a, [wPlayerY+1]
	ld l, a
	add hl, bc
	ld a, h
	ld [wPlayerY], a
	ld a, l
	ld [wPlayerY+1], a

	ld a, [wPlayerX]
	cp 8
	jr c, .stopL
	cp 160
	jr z, .testV
	jr c, .testV
	jr .stopR
.stopL
	ld a, 8
	ld [wPlayerX], a
	xor a
	ld [wPlayerX+1], a
	ld [wXVel], a
	ld [wXVel+1], a
	jr .testV
.stopR
	ld a, 160
	ld [wPlayerX], a
	xor a
	ld [wPlayerX+1], a
	ld [wXVel], a
	ld [wXVel+1], a
	jr .testV
.testV
	ld a, [wPlayerY]
	cp 16
	jr c, .stopU
	cp 152
	jr z, tileCheck
	jr c, tileCheck
	jr .stopD
.stopU
	ld a, 16
	ld [wPlayerY], a
	xor a
	ld [wPlayerY+1], a
	ld [wYVel], a
	ld [wYVel+1], a
	jr tileCheck
.stopD
	xor a
	ld [wPlayerY+1], a
	ld [wYVel], a
	ld [wYVel+1], a
	ld a, 152
	ld [wPlayerY], a
	jr tileCheck

.right
	ld a, [wXVel]
	ld h, a
	ld a, [wXVel+1]
	ld l, a
	ld bc, 16
	add hl, bc
	ld a, h
	ld [wXVel], a
	ld a, l
	ld [wXVel+1], a
	ret
.left
	ld a, [wXVel]
	ld h, a
	ld a, [wXVel+1]
	ld l, a
	ld bc, -16
	add hl, bc
	ld a, h
	ld [wXVel], a
	ld a, l
	ld [wXVel+1], a
	ret
.up
	ld a, [wYVel]
	ld h, a
	ld a, [wYVel+1]
	ld l, a
	ld bc, -16
	add hl, bc
	ld a, h
	ld [wYVel], a
	ld a, l
	ld [wYVel+1], a
	ret
.down
	ld a, [wYVel]
	ld h, a
	ld a, [wYVel+1]
	ld l, a
	ld bc, 16
	add hl, bc
	ld a, h
	ld [wYVel], a
	ld a, l
	ld [wYVel+1], a
	ret

tileCheck:
	ld d, 0
	ld e, 0
	ld a, [wColLoop]
	cp 0
	jr z, colLoop
	cp 1
	jr z, .one
	cp 2
	jr z, .two
	cp 3
	jr z, .three
	xor a
	ld [wColLoop], a
	jp applyP
.one
	ld d, 7
	jr colLoop
.two
	ld e, 7
	jr colLoop
.three
	ld d, 7
	ld e, 7
	jr colLoop

colLoop:
	ld a, [wPlayerX]
	sub 8
	add a, d
	srl a
	srl a
	srl a
	ld c, a
	ld a, [wPlayerY]
	sub 16
	add a, e
	and $f8
	ld l, a
	ld h, 0
	add hl, hl
	add hl, hl
	ld d, h
	ld e, l

	ld b, 0
	ld hl, $9800
	add hl, de
	add hl, bc

	ld a, [hl]
	cp 0
	jp z, .pass
	cp 2
	jp z, lose
	ld [hl], 0
	ld a, [wCollected]
	ld h, a
	ld a, [wCollected+1]
	ld l, a
	inc hl
	ld a, h
	ld [wCollected], a
	ld a, l
	ld [wCollected+1], a
	cp 104
	;cp 5
	jr nz, .pass
	ld a, h
	cp 1
	;cp 0
	jr nz, .pass
	jp win
.pass
	ld a, [wColLoop]
	inc a
	ld [wColLoop], a
	jp tileCheck

applyP:
	; apply player position
	halt
	ld a, [wPlayerY]
	;add 16
	ld [_OAMRAM], a
	ld a, [wPlayerX]
	;add 8
	ld [_OAMRAM+1], a
	
	ld a, [wTimer+1]
	add 1
	daa
	ld [wTimer+1], a
	ld a, [wTimer]
	adc 0
	daa
	ld [wTimer], a

	jp Main

win:
	ld hl, $9821
	ld a, [wTimer]
	and $F0
	swap a
	add 3
	;daa
	ld [hli], a
	ld a, [wTimer]
	and $0F
	add 3
	;daa
	ld [hli], a
	ld a, [wTimer+1]
	and $F0
	swap a
	add 3
	;daa
	ld [hli], a
	ld a, [wTimer+1]
	and $0F
	add 3
	;daa
	ld [hl], a
.waitForStart
	call UpdateInput
	bit 3, a
	jp nz, Start
	jp .waitForStart

lose:
	call UpdateInput
	bit 3, a
	jp nz, Start
	jp lose

; Functions

memCopy:
	;   Copy memory from ROM to RAM. Load HL with the memory address to start copying from. Load DE with the address to start copying to. Load BC with the size of the copied area in bytes.
    ld a, [hli]
    ld [de], a
    inc de
    dec bc
    ld a, b
    or c
    jr nz, memCopy
    ret

; HL - destination
; D - byte to store
; BC - number of bytes to set
memSet:
    ld a, d
    ld [hli], a
    dec bc
    ld a, b
    or c
    jr nz, memSet
    ret

