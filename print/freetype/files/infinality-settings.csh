###          freetype2-infinality-ultimate settings          ###
###           rev. 0.4.8.3, for freetype2 v.2.5.x            ###
###                                                          ###
###                Copyright (c) 2014 bohoomil               ###
###                Copyright (c) 2014 rjvbertin              ###
### The MIT License (MIT) http://opensource.org/licenses/MIT ###
###      part of infinality-bundle  http://bohoomil.com      ###


xrdb -q | fgrep -i Xft.dpi >& /dev/null
if ( $status != 0 ) then
	echo "Xft.dpi:        72" | xrdb -merge >& /dev/null
endif
echo " \
Xft.antialias:  1 \
Xft.autohint:   0 \
Xft.hinting:    1 \
Xft.hintstyle:  hintfull \
Xft.lcdfilter:  lcddefault \
Xft.rgba:       rgb" | xrdb -merge >& /dev/null

### Available styles:
### 1 <> extra sharp
### 2 <> sharper & lighter ultimate
### 3 <> ultimate: well balanced (default)
### 4 <> darker & smoother
### 5 <> darkest & heaviest ("MacIsh")

setenv INFINALITY_ULTIMATE_STYLE "3"

switch ( $INFINALITY_ULTIMATE_STYLE )
	case "2":
 		setenv INFINALITY_FT_FILTER_PARAMS "06 22 36 22 06"
		breaksw
	case "3":
		setenv INFINALITY_FT_FILTER_PARAMS "08 24 36 24 08"
		breaksw
	case "4":
		setenv INFINALITY_FT_FILTER_PARAMS "10 25 37 25 10"
		breaksw
	case "5":
		setenv INFINALITY_FT_FILTER_PARAMS "12 28 42 28 12"
		breaksw
	default:
	case "1":
		setenv INFINALITY_FT_FILTER_PARAMS "04 22 38 22 04"
		breaksw
endsw

setenv INFINALITY_FT_FRINGE_FILTER_STRENGTH "25"
setenv INFINALITY_FT_USE_VARIOUS_TWEAKS "true"
setenv INFINALITY_FT_WINDOWS_STYLE_SHARPENING_STRENGTH "25"
setenv INFINALITY_FT_STEM_ALIGNMENT_STRENGTH "15"
setenv INFINALITY_FT_STEM_FITTING_STRENGTH "15"
setenv INFINALITY_FT_CHROMEOS_STYLE_SHARPENING_STRENGTH "20"

setenv PANGOCAIRO_BACKEND "fontconfig"

# vim:ft=sh:
