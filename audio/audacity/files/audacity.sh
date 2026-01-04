#!/bin/bash

if launchctl list | egrep -i '^[0-9].*audacityteam.audacity|^[0-9].*anonymous.audacity' > /dev/null ;then
	# on Mac, we need to open via LaunchServices if Audacity is already running, or else the process will hang.
	# NB: we do need to check if launchctl returns a PID (a number) in the 1st column, because phantom
	# labels can remain with a '-' to indicate that the application isn't running.
	exec open -W -a "@APPDIR@/Audacity.app" "$@"
else
	exec "@APPDIR@/Audacity.app/Contents/MacOS/Wrapper" "$@"
fi
