; This was from
; http://www.randomterrain.com/atari-2600-memories-tutorial-andrew-davie-08.html
; but needed to be adapted to ca65
.setcpu "6502"
.include "vcs.inc"

.segment "CODE"
Reset:
; clear all the ram
ldx $80
lda #0
clear_ram:
sta 0, x
inx
bne clear_ram

; initialize the frame counter
FRAME_COUNT := $80
ldx #0
stx FRAME_COUNT
; configure port a for input
ldx #0
stx SWACNT
BK_COLOR := $81
ldx #$00
stx BK_COLOR
; player color
ldx #$06
stx COLUP0
; digit color
ldx #$36
stx COLUP1

; TODO load these from level data
; a gap to fly through
LEVEL := $8c
ldx #0
stx LEVEL
GAP1_Y := $83
GAP2_Y := $84
GAP1_H := $85
GAP2_H := $86
jsr load_level

; player 0 sprite
GRP0_X := $89
ldx #4
stx GRP0_X
GRP0_Y := $8a
ldx #25
stx GRP0_Y
; GRP0_X := $90
; ldx #%00000000
; stx GRP0_X

; missile 0
MISSILE_Y := $8b
ldx #0
stx MISSILE_Y

MISC := $8d

ldx BK_COLOR
stx COLUBK

; reflect playfield
lda #$01
sta CTRLPF
;ldx #$10
ldx #$00
stx PF0
lda #$04  ; PF_COLOR
sta COLUPF

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
StartOfFrame:
; Start of vertical blank processing
lda #0
sta VBLANK
lda #2
sta VSYNC

; need 3 scanlines of VSYNCH signal...
sta WSYNC
sta WSYNC
; third WSYNC
sta WSYNC

lda #0
sta VSYNC
; 37 scanlines of vertical blank...
LINE_COUNT := $82
ldx #35
stx LINE_COUNT

verticalblank:
dec LINE_COUNT
sta WSYNC
bne verticalblank

; draw number in first 8 scan lines
lda #20 ; the desired position
ldx #$1 ; player 1
; this generates two WSYNCs, 36th and 37th vertical blank
jsr PositionASpriteSubroutine

; 192 scanlines of picture...
; 9 scan lines of digit
lda LEVEL
and #$0f
cmp #10
bcc under_10
sbc #10
under_10:
tax
lda #0

;jmp init_draw_digit
find_digit:
; TODO handle 10-15
cpx #0
beq init_draw_digit
dex
clc
adc #8
jmp find_digit

init_draw_digit:
sta MISC
ldx #0
draw_digit:
txa
adc MISC
tay
lda digit_0, y
sta GRP1
inx
txa
cmp #9
bcs setup_player
sta WSYNC
jmp draw_digit

setup_player:
; clear player 2
ldy #$00
sty GRP1
; 9th and 10th scan line
position_player_0:
lda GRP0_X ; the desired position
ldx #$0 ; player 0
; this generates two WSYNCs
jsr PositionASpriteSubroutine

inc FRAME_COUNT ; $80 will increment every frame
; initialize the line counter $82
ldx #181
stx LINE_COUNT
ldx FRAME_COUNT
scanline:
sta WSYNC
; change the color as the line advances
;ldx #2
;stx $83
;linechange:
;ldx $83
;adc $81, x
;sta COLUBK
;dec $83
;bne linechange

lda LINE_COUNT
sbc GRP0_Y
cmp #17
bcc draw_player0
; clear the player bits (don't draw a player)
ldx #0
stx GRP0
jmp check_missile

draw_player0:
lda LINE_COUNT
sbc GRP0_Y
tax
; load the memory at the current accumulator value
ldy player_sprite_0, x
sty GRP0

; skip missile for now
jmp draw_playfield

check_missile:
lda LINE_COUNT
sbc MISSILE_Y
beq draw_missile
lda #$0
sta ENAM0
jmp draw_playfield

draw_missile:
lda #$2
sta ENAM0

;;;;;;;;;;;;;;;
draw_playfield:
; jmp draw_playfield2
; draw the gap if it is here
; only

; TODO(lucasw) instead of writing to
; the playfield every frame, only update
; it when it changes
ldx #1
clc
lda LINE_COUNT
sbc GAP1_Y, x
beq draw_wall
sbc GAP1_H, x
beq draw_gap
jmp loop_end
draw_wall:
ldy #$e0
sty PF1, x
jmp loop_end
; jmp draw_playfield2
draw_gap:
ldy #$00
sty PF1, x

loop_end:
;dex
;beq finish_pf_line
;inx
;cpx #2
;bcs finish_pf_line
jmp finish_pf_line
;jmp gap_loop

finish_pf_line:
; start with a different color on every line
dec LINE_COUNT
bne scanline
;inc BK_COLOR

;lda #%01000010
lda #%01000010
sta VBLANK                     ; end of screen - enter blanking
; 30 scanlines of overscan...

; spend first line checking input
; the bit will be 0 when the direction is pressed
check_up:
lda #$10
and SWCHA ; if up is not pressed, this will store 1 in accumulator, zero flag will be 0
beq p0_up ; if zero flag is 1, that means up was pressed, then branch
bne check_down ; TODO(lucasw) how to just go straight to a label without condition?
p0_up:
inc GRP0_Y
inc GRP0_Y

check_down:
lda #$20
and SWCHA
beq p0_down
bne check_left ; TODO(lucasw) how to just go straight to a label without condition?
p0_down:
dec GRP0_Y
dec GRP0_Y

check_left:
lda #$40
and SWCHA
beq p0_left
jmp check_right ; TODO(lucasw) how to just go straight to a label without condition?
p0_left:
dec GRP0_X
; can't move left and right at same time
jmp finish_move

check_right:
lda #$80
and SWCHA
beq p0_right
; don't move left/right
; lda #%00000000
; sta HMP0
jmp finish_move
p0_right:
inc GRP0_X

finish_move:
inc GRP0_X
inc GRP0_X
sta WSYNC

lda GRP0_Y
cmp #2
bcs limit_max
lda #2
sta GRP0_Y
jmp test_next_screen
limit_max:
lda GRP0_Y
cmp #178
bcc test_next_screen
lda #178
sta GRP0_Y

test_next_screen:
; go to next screen if on right edge
lda GRP0_X
sbc #160 ; the screen is 159 pixels wide
bcc check_trigger
; reset position to zero
lda #0
sta GRP0_X
; update the level
inc LEVEL
jsr load_level

check_trigger:
lda INPT4
;bmi check_collision
;bmi finish_collision
bmi check_player_wall_collision
; fire is pressed
lda #%11100000
sta HMM0
; fire missile
lda GRP0_Y
adc #$8
sta MISSILE_Y
lda #$2
sta RESMP0
lda #$0
sta RESMP0

check_collision:
; missile edge of screen
sta WSYNC
lda CXM0FB
and #$80
beq check_player_wall_collision
lda #$2
sta RESMP0

check_player_wall_collision:
lda CXP0FB
and #$80
beq no_collision
ldx #$04
stx GRP0_X
lda #0
sta LEVEL
jsr load_level
lda #$1e
sta COLUBK
lda #$0e
sta COLUPF
jmp finish_collision

no_collision:
lda BK_COLOR
sta COLUBK
lda #$04  ; PF_COLOR
sta COLUPF

finish_collision:
; clear collisions
sta CXCLR


finish_lines:
ldx #28
stx LINE_COUNT
overscan:
dec LINE_COUNT
sta WSYNC
bne overscan

jmp StartOfFrame

load_level:
lda LEVEL
and #$0f
tax
ldy level_data, x
sty GAP1_Y
; inx
ldy level_data, x
sty GAP2_Y
ldy #50
sty GAP1_H
ldy #40
sty GAP2_H
rts

; http://atariage.com/forums/topic/75971-new-2600-programmer-confused-by-player-positioning/
; a - x position
; x - which player
;   PLAYER0 := 0
;   PLAYER1 := 1
;   MISSILE0 := 2
;   MISSILE1 := 3
;   BALL := 4

PositionASpriteSubroutine:
   sta HMCLR
   sec
   sta WSYNC         ;                      begin line 1
DivideLoop:
   sbc #15
   bcs DivideLoop    ;+4/5    4/ 9.../54

   eor #7            ;+2      6/11.../56
   asl
   asl
   asl
   asl               ;+8     14/19.../64

   sta HMP0,X     ;+5     19/24.../69
   sta RESP0,X       ;+4     23/28/33/38/43/48/53/58/63/68/73
   sta WSYNC         ;+3      0              begin line 2
   sta HMOVE         ;+3
   rts               ;+6      9

.segment "RODATA"
digit_0:
.byte %00000000
.byte %00110000
.byte %01001000
.byte %10000100
.byte %10000100
.byte %10000100
.byte %01001000
.byte %00110000
digit_1:
.byte %00000000
.byte %00010000
.byte %00110000
.byte %01110000
.byte %00010000
.byte %00010000
.byte %00010000
.byte %01111100
digit_2:
.byte %00000000
.byte %00110000
.byte %01001000
.byte %00000100
.byte %00000100
.byte %00001000
.byte %00110000
.byte %01111100
digit_3:
.byte %00000000
.byte %00110000
.byte %01001000
.byte %00000100
.byte %00000100
.byte %00011000
.byte %00000100
.byte %01001000
.byte %00110000
digit_4:
.byte %00000000
.byte %01000100
.byte %01000100
.byte %01111100
.byte %00000100
.byte %00000100
.byte %00000100
.byte %00000100
digit_5:
.byte %00000000
.byte %01111100
.byte %01000000
.byte %01110000
.byte %00001000
.byte %00000100
.byte %01000100
.byte %01111000
digit_6:
.byte %00000000
.byte %00011000
.byte %00100100
.byte %01000000
.byte %01111000
.byte %01000100
.byte %01000100
.byte %00111000
digit_7:
.byte %00000000
.byte %01111100
.byte %01000100
.byte %00001000
.byte %00010000
.byte %00010000
.byte %00010000
.byte %00010000
digit_8:
.byte %00000000
.byte %00111000
.byte %01000100
.byte %01000100
.byte %00111000
.byte %01000100
.byte %01000100
.byte %00111000
digit_9:
.byte %00000000
.byte %00111000
.byte %01000100
.byte %00110100
.byte %00000100
.byte %00001000
.byte %01001000
.byte %00110000

player_sprite_0:
.byte $ff ; 0
.byte $ff ; 1
.byte $18 ; 2
.byte $18 ; 3
.byte $18 ; 4
.byte $24 ; 5
.byte $4a ; 6
.byte $52 ; 7
.byte $52 ; 8
.byte $4a ; 9
.byte $24 ; a
.byte $18 ; b
.byte $18 ; c
.byte $18 ; d
.byte $ff ; e
.byte $ff ; f
.byte $ff ; 0


level_data:
.byte 100 ; 0
.byte 100 ; 1
.byte 120 ; 2
.byte 50  ; 3
.byte 80  ; 4
.byte 30  ; 5
.byte 100 ; 6
.byte 90 ; 7
.byte 53  ; 8
.byte 80  ; 9
.byte 30  ; a
.byte 5   ; b
.byte 30  ; c
.byte 50  ; d
.byte 70  ; e
.byte 90  ; f

.org $FFFA
; fill in the rest of the address space?
.segment "VECTORS"
.addr Reset ; NMI: should never occur
.addr Reset ; RESET
.addr Reset ; IRQ: will only occur with brk

