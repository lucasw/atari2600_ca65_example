; This was from
; http://www.randomterrain.com/atari-2600-memories-tutorial-andrew-davie-08.html
; but needed to be adapted to ca65
.setcpu "6502"
.include "vcs.inc"

.segment "CODE"
Reset:
; initialize the frame counter
FRAME_COUNT := $80
ldx #0
stx FRAME_COUNT
; configure port a for input
ldx #0
stx SWACNT
BK_COLOR := $81
ldx #0
stx BK_COLOR

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
ldx #5  ; PF_COLOR
stx COLUPF

; playfield
ldx PFA0
stx PF0
ldx PFA1
stx PF1
ldx PFA2
stx PF2

ldx BK_COLOR
stx COLUBK
; start with a different color on every line
dec LINE_COUNT
bne scanline
;inc BK_COLOR

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
;inc BK_COLOR

check_down:
lda #$20
and SWCHA
beq p0_down
bne finish_line ; TODO(lucasw) how to just go straight to a label without condition?
p0_down:
;dec BK_COLOR

finish_line:
sta WSYNC

ldx #29
stx LINE_COUNT
overscan:
dec LINE_COUNT
sta WSYNC
bne overscan

jmp StartOfFrame

.org $FFFA
; fill in the rest of the address space?
.segment "VECTORS"
.addr Reset ; NMI: should never occur 
.addr Reset ; RESET 
.addr Reset ; IRQ: will only occur with brk 

