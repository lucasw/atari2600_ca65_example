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
ldx #$06
stx COLUP0

; TODO load these from level data
; a gap to fly through
GAP1_Y := $83
lda #25
sta GAP1_Y
GAP2_Y := $84
lda #30
sta GAP2_Y

GAP1_H := $85
lda #30
sta GAP1_H
GAP2_H := $86
lda #80
sta GAP2_H

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

ldx BK_COLOR
stx COLUBK

LEVEL := $8c
ldx #80
stx LEVEL

; reflect playfield
lda #$01
sta CTRLPF
;ldx #$10
ldx #$00
stx PF0
lda #$04  ; PF_COLOR
sta COLUPF

StartOfFrame:
; Start of vertical blank processing
lda #0
sta VBLANK
lda #2
sta VSYNC

; 3 scanlines of VSYNCH signal...
sta WSYNC

position_player_0:
lda GRP0_X ; the desired position
ldx #$0 ; player 0
jsr PositionASpriteSubroutine

lda #0
sta VSYNC
; 37 scanlines of vertical blank...
; TODO(lucasw) replace with loop
LINE_COUNT := $82
ldx #37
stx LINE_COUNT

verticalblank:
dec LINE_COUNT
sta WSYNC
bne verticalblank

; 192 scanlines of picture...

inc FRAME_COUNT ; $80 will increment every frame
; initialize the line counter $82
ldx #192
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

draw_playfield:
; draw the gap if it is here
; only 

; TODO(lucasw) instead of writing to
; the playfield every frame, only update
; it when it changes
ldx #0
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
; jmp loop_end
jmp draw_playfield2
draw_gap:
ldy #$00
sty PF1, x

draw_playfield2:
clc
lda LINE_COUNT
sbc GAP2_Y
beq draw_wall2
sbc GAP2_H
beq draw_gap2
jmp loop_end
draw_wall2:
ldy #$e0
sty PF2
jmp loop_end
draw_gap2:
ldy #$00
sty PF2

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
;inc GRP0_X
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
; TODO(lucasw) update the screen
jsr load_next_level

check_trigger:
lda INPT4
;bmi check_collision
bmi finish_collision
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
beq finish_collision
ldx #$04
stx GRP0_X

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

load_next_level:
inc LEVEL
lda LEVEL
and #$0f
tax
ldy level_data, x
sty GAP1_Y
inx
ldy level_data, x
sty GAP2_Y
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
.byte 100
.byte 100
.byte 150
.byte 50
.byte 80
.byte 30
.byte 100
.byte 150
.byte 53
.byte 80
.byte 30
.byte 5
.byte 30
.byte 50
.byte 70
.byte 90
.byte 110

.org $FFFA
; fill in the rest of the address space?
.segment "VECTORS"
.addr Reset ; NMI: should never occur
.addr Reset ; RESET
.addr Reset ; IRQ: will only occur with brk

