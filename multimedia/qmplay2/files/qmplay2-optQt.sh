#!/bin/sh

HERE="@QTDIR@"

# insert libqextstandardpaths.dylib, must be built against the Qt from this library
#if [ "${DYLD_INSERT_LIBRARIES}" != "" ] ;then
#	export DYLD_INSERT_LIBRARIES="${DYLD_INSERT_LIBRARIES}:${HERE}/libqextstandardpaths.dylib"
#else
#	export DYLD_INSERT_LIBRARIES="${HERE}/libqextstandardpaths.dylib"
#fi

# export DYLD_FORCE_FLAT_NAMESPACE=1

export QTBINDIR="${HERE}/bin"

if [ "${LD_LIBRARY_PATH}" != "" ] ;then
	export LD_LIBRARY_PATH="${HERE}/gcc_64/lib:@PREFIX@/lib:${LD_LIBRARY_PATH}"
	#export LD_LIBRARY_PATH="@PREFIX@/lib:${LD_LIBRARY_PATH}"
else
	export LD_LIBRARY_PATH="${HERE}/gcc_64/lib:@PREFIX@/lib"
	#export LD_LIBRARY_PATH="@PREFIX@/lib"
fi
if [ "${QT_LD_LIBRARY_PATH}" != "" ] ;then
	export LD_LIBRARY_PATH="@PREFIX@/lib:${QT_LD_LIBRARY_PATH}"
fi

if [ "${LD_PRELOAD}" != "" ] ;then
	export LD_PRELOAD="${HERE}/gcc_64/lib/libQt5Core.so.5:@PREFIX@/lib/libdbus-1.so:${LD_PRELOAD}"
else
	export LD_PRELOAD="${HERE}/gcc_64/lib/libQt5Core.so.5:@PREFIX@/lib/libdbus-1.so"
fi
if [ "${QT_LD_PRELOAD}" != "" ] ;then
	export LD_PRELOAD="${HERE}/gcc_64/lib/libQt5Core.so.5:@PREFIX@/lib/libdbus-1.so:${QT_LD_PRELOAD}"
fi

if [ "${QT_PLUGIN_PATH}" != "" ] ;then
	export QT_PLUGIN_PATH="${HERE}/gcc_64/plugins:${QT_PLUGIN_PATH}"
else
	export QT_PLUGIN_PATH="${HERE}/gcc_64/plugins"
fi
export QT_PLUGIN_PATH="${QT_PLUGIN_PATH}:/opt/local/share/qt5/plugins"

# used by QSP in libqextstandardpaths.dylib:
if [ "${XDG_DATA_DIRS} = "" ] ;then
	export XDG_DATA_DIRS=@PREFIX@/share
fi
if [ "${XDG_CACHE_HOME} = "" ] ;then
	export XDG_CACHE_HOME=${HOME}/.cache
fi
if [ "${XDG_CONFIG_DIRS} = "" ] ;then
	export XDG_CONFIG_DIRS=@PREFIX@/etc/xdg
fi
if [ "${XDG_RUNTIME_DIR} = "" ] ;then
	export XDG_RUNTIME_DIR=${TMPDIR}/runtime-${USER}
fi

exec "@PREFIX@/bin/QMPlay2.bin" "$@"
