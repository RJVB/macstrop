#!/bin/sh

HERE="`dirname $0`"

 if [ -r ~/.kf5.env ] ;then
 	. ~/.kf5.env
 else
 	export KDE_SESSION_VERSION=5
 fi

# export DYLD_FORCE_FLAT_NAMESPACE=1

PREFIX="/opt/local"
LIBDIRS=""

for d in ${PREFIX} ;do
	for sd in lib lib/x86_64-linux-gnu libexec/qt512/lib ;do
		if [ -d ${d}/${sd} ] ;then
			case ${LD_LIBRARY_PATH} in
				*${d}/${sd}*)
					# already included
					;;
				*)
					if [ "${LIBDIRS}" = "" ] ;then
						LIBDIRS="${d}/${sd}"
					else
						LIBDIRS="${LIBDIRS}:${d}/${sd}"
					fi
					;;
			esac
		fi
	done
done

if [ "${LD_LIBRARY_PATH}" != "" ] ;then
	export LD_LIBRARY_PATH="${LIBDIRS}:${LD_LIBRARY_PATH}"
else
	export LD_LIBRARY_PATH="${LIBDIRS}"
fi

if [ "${QT_PLUGIN_PATH}" != "" ] ;then
	export QT_PLUGIN_PATH="${HERE}/plugins:${QT_PLUGIN_PATH}:${PREFIX}/share/qt5/plugins"
else
	export QT_PLUGIN_PATH="${HERE}/plugins:${PREFIX}/share/qt5/plugins"
fi

# used by QSP in libqextstandardpaths.dylib:
if [ "${XDG_DATA_DIRS} = "" ] ;then
	export XDG_DATA_DIRS=/opt/local/share
fi
if [ "${XDG_CACHE_HOME} = "" ] ;then
	export XDG_CACHE_HOME=${HOME}/.cache
fi
if [ "${XDG_CONFIG_DIRS} = "" ] ;then
	export XDG_CONFIG_DIRS=/opt/local/etc/xdg
fi
if [ "${XDG_RUNTIME_DIR} = "" ] ;then
	export XDG_RUNTIME_DIR=${TMPDIR}/runtime-${USER}
fi

exec "$@"
