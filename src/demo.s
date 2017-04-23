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
.repeat 37
sta WSYNC
.endrepeat

; 192 scanlines of picture...

inc $80 ; $80 will increment every frame
; initialize the line counter $82
ldx #192
stx $82
ldx $80
stx $81
scanline:
sta WSYNC
ldx $81
stx COLUBK
; show a different color on every line
inc $81
dec $82
bne scanline

lda #%01000010
sta VBLANK                     ; end of screen - enter blanking
; 30 scanlines of overscan...
; TODO(lucasw) replace with loop
.repeat 30
sta WSYNC
.endrepeat
jmp StartOfFrame
.org $FFFA
; fill in the rest of the address space?
.segment "VECTORS" 
.addr Reset ; NMI: should never occur 
.addr Reset ; RESET 
.addr Reset ; IRQ: will only occur with brk 

