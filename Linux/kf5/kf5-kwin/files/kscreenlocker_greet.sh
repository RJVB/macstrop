#!/bin/sh

for a in "$@" ;do
	case ${a} in 
		--immediateLock)
			exec xscreensaver-command -lock
			;;
		*)
			exec xscreensaver-command -activate
			;;
	esac
done
exec xscreensaver-command -activate
