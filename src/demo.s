; This was from
; http://www.randomterrain.com/atari-2600-memories-tutorial-andrew-davie-08.html
; but needed to be adapted to ca65
.setcpu "6502"
.include "vcs.inc"
.segment "CODE"
;.org $F000
Reset:
; initialize the frame counter
ldx #0
stx $80
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
ldx #37
stx $82
verticalblank:
dec $82
sta WSYNC
bne verticalblank

; 192 scanlines of picture...

inc $80 ; $80 will increment every frame
; initialize the line counter $82
ldx #192
stx $82
ldx $80
stx $81
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
ldx $81
stx COLUBK
; start with a different color on every line
inc $81
dec $82
bne scanline

lda #%01000010
sta VBLANK                     ; end of screen - enter blanking
; 30 scanlines of overscan...
; TODO(lucasw) replace with loop
ldx #30
stx $82
overscan:
dec $82
sta WSYNC
bne overscan

jmp StartOfFrame
.org $FFFA
; fill in the rest of the address space?
.segment "VECTORS" 
.addr Reset ; NMI: should never occur 
.addr Reset ; RESET 
.addr Reset ; IRQ: will only occur with brk 

