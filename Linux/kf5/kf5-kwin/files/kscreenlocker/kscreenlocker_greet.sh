#!/bin/sh

xscreensaver-command -version >/dev/null
if [ $? = 0 ] ;then
    for a in "$@" ;do
        case ${a} in 
            --immediateLock)
                    (sleep 5 ; echo "Locked at `date +%s`") &
                    exec xscreensaver-command -lock
                ;;
            *)
                exec xscreensaver-command -activate
                ;;
        esac
    done
    exec xscreensaver-command -activate
else
    if [ -x ${0}.bin ] ;then
        exec ${0}.bin "$@"
    else
        # the KScreenLocker library should unlock gracefully when the greeter crashes
        kill -ABRT $$
    fi
fi
