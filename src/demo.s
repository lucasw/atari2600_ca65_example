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
ldx #$89
stx BK_COLOR
ldx #$6F
stx COLUP0

; TODO(lucasw) shouldn't store these in ram unless
; they will be modified, how to store values- just := ?
PFA0 := $83
ldx #$10
stx PFA0
PFA1 := $84
ldx #$18
stx PFA1
PFA2 := $85
ldx #$80
stx PFA2

PFB0 := $86
ldx #$10
stx PFB0
PFB1 := $87
ldx #$24
stx PFB1
PFB2 := $88
ldx #$82
stx PFB2

; player 0 sprite
GRP0_Y := $89
ldx #25
stx GRP0_Y
; GRP0_X := $90
; ldx #%00000000
; stx GRP0_X

; missile 0
MISSILE_Y := $90
ldx #0
stx MISSILE_Y

ldx BK_COLOR
stx COLUBK

StartOfFrame:
; Start of vertical blank processing
lda #0
sta VBLANK
lda #2
sta VSYNC

; 3 scanlines of VSYNCH signal...
.repeat 3
sta WSYNC
.endrepeat
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
tax
; load the memory at the current accumulator value
ldy player_sprite_0, x
sty GRP0

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
;lda LINE_COUNT
; and #$04 ; draw alternating pf
; sbc GRP0_Y ; draw pf on single line
;beq playfielda
; clear playfield
ldx #$80
stx PF2
ldx #$00
stx PF0
stx PF1
jmp finish_pf_line

playfielda:
;lda #$02
;and LINE_COUNT
ldx #0  ; PF_COLOR
stx COLUPF
lda PFA0
sta PF0
lda PFA1
sta PF1
lda PFA2
sta PF2
jmp finish_pf_line

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
lda #%00010000
sta HMP0
; can't move left and right at same time
jmp finish_line

check_right:
lda #$80
and SWCHA
beq p0_right
; don't move left/right
lda #%00000000
sta HMP0
jmp finish_line ;
p0_right:
lda #%11110000
sta HMP0

finish_line:
sta WSYNC
sta HMOVE

; check joystick button
lda INPT4
bmi finish_lines
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

finish_lines:
ldx #29
stx LINE_COUNT
overscan:
dec LINE_COUNT
sta WSYNC
bne overscan

jmp StartOfFrame

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

.org $FFFA
; fill in the rest of the address space?
.segment "VECTORS"
.addr Reset ; NMI: should never occur 
.addr Reset ; RESET 
.addr Reset ; IRQ: will only occur with brk 

