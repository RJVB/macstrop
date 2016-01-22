#!/bin/bash

# check if a display resolution has already been set:
XDPI="`xrdb -q | fgrep Xft.dpi`"
if [ "${XDPI}" = "" ] ;then
    # standard value would be 96dpi, but 72 works better with XQuartz
    XDPI="Xft.dpi:        72"
fi

XFT_SETTINGS="
Xft.antialias:  1
Xft.autohint:   0
${XDPI}
Xft.hinting:    1
Xft.hintstyle:  hintfull
Xft.lcdfilter:  lcddefault
Xft.rgba:       rgb
"

echo "$XFT_SETTINGS" | xrdb -merge > /dev/null 2>&1

# vim:ft=sh:
