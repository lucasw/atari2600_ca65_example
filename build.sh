#!/bin/bash
mkdir -p obj
set -e
$HOME/other/cc65/bin/ca65 -g -o obj/demo.o src/demo.s -Isrc
$HOME/other/cc65/bin/ld65 -Csrc/atari2600.cfg -m obj/demo.map -Ln obj/demo.labels -vm obj/demo.o -o obj/demo.bin
# TODO(lucasw) are the map and labels files something stella emu can load?
# $HOME/other/cc65/bin/ld65 -Csrc/atari2600.cfg -m obj/demo.map -Ln obj/demo.sym -vm obj/demo.o -o obj/demo.bin
# this is to put the config in the default location stella looks for
cp src/atari2600.cfg obj/demo.cfg
