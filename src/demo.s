; This was from
; http://www.randomterrain.com/atari-2600-memories-tutorial-andrew-davie-08.html
; but needed to be adapted to ca65
.setcpu "6502"
.include "vcs.inc"
.segment "CODE"
;.org $F000
Reset:
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
.repeat 37
sta WSYNC
.endrepeat

; 192 scanlines of picture...

ldx #0
.repeat 192 ; scanlines
inx
stx COLUBK
sta WSYNC
.endrepeat

lda #%01000010
sta VBLANK                     ; end of screen - enter blanking
; 30 scanlines of overscan...
.repeat 30
sta WSYNC
.endrepeat
jmp StartOfFrame
; fill in the rest of the address space?
.org $FFFA
.segment "VECTORS" 
.addr Reset ; NMI: should never occur 
.addr Reset ; RESET 
.addr Reset ; IRQ: will only occur with brk 

