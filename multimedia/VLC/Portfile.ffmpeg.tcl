# -*- coding: utf-8; mode: tcl; tab-width: 4; indent-tabs-mode: nil; c-basic-offset: 4 -*- vim:fenc=utf-8:ft=tcl:et:sw=4:ts=4:sts=4
# $Id: Portfile 148249 2016-05-01 01:08:24Z devans@macports.org $

PortSystem          1.0
PortGroup           xcodeversion 1.0
PortGroup           compiler_blacklist_versions 1.0
PortGroup           active_variants 1.1

version             2.8.6
revision            1
license             LGPL-2.1+
categories          multimedia
maintainers         gmail.com:rjvbertin openmaintainer

description         Custom FFMpeg build for port:VLC and port:libVLC.
long_description    Custom FFMpeg build for port:VLC and port:libVLC.

platforms           darwin
homepage            http://www.ffmpeg.org/
master_sites        http://www.ffmpeg.org/releases/

use_bzip2           yes
distname            ffmpeg-${version}

checksums           rmd160  5b61b6b0521d39ca31dcfb7fff1dfa26d9e7667a \
                    sha256  40611e329bc354592c6f8f1deb033c31b91f80e91f5707ca4f9afceca78d8e62

depends_build       port:pkgconfig \
                    port:gmake

# libvpx is static only so can be considered a build dependency (#47934)

depends_build-append \
                    port:libvpx

depends_lib         port:lame \
                    port:libiconv \
                    port:openjpeg15 \
                    port:xz \
                    port:zlib

# depends_lib-append  port:libvorbis \
#                     port:libopus \
#                     port:libogg \
#                     port:libtheora \
#                     port:libass \
#                     port:gnutls \
#                     port:fontconfig \
#                     port:freetype \
#                     port:bzip2

build.cmd           ${prefix}/bin/gmake
build.env-append    V=1

#
# enable auto configure of asm optimizations
# requires Xcode 3.1 or better on Leopard
#
minimum_xcodeversions {9 3.1}

if {[lsearch [get_canonical_archs] i386] != -1} {
    # clang-3.1 hits https://trac.macports.org/ticket/30137 (<rdar://problem/11542429>)
    # clang-139 hits https://trac.macports.org/ticket/38141
    compiler.blacklist-append {clang < 422.1.7}
}

configure.cflags-append -DHAVE_LRINTF ${configure.cppflags}
configure.args      --prefix=${FFMPEG_VLC_PREFIX} \
                    --progs-suffix=-VLC \
                    --build-suffix=-VLC \
                    --disable-doc \
                    --disable-encoder=vorbis \
                    --enable-libopenjpeg \
                    --disable-debug \
                    --disable-avdevice \
                    --disable-devices \
                    --disable-avfilter \
                    --disable-filters \
                    --disable-protocol=concat \
                    --disable-bsfs \
                    --disable-bzlib \
                    --enable-avresample \
                    --enable-libmp3lame \
                    --enable-libvpx \
                    --disable-libbluray \
                    --disable-sdl \
                    --disable-libxcb --disable-libxcb-shm --disable-libxcb-xfixes --disable-libxcb-shape \
                    --enable-shared --disable-static --enable-pthreads \
                    --enable-rpath \
                    --disable-stripping \
                    --cc=${configure.cc}

# this is the old gpl2 variant. VLC is GPL2'ed, so we can just as well build ffmpeg
# with these components.
configure.args-append \
                    --enable-gpl \
                    --enable-postproc
# configure.args-append \
#                     --enable-libx264 \
#                     --enable-libxvid
# depends_lib-append  port:XviD \
#                     port:x264

configure.args-append \
                    --arch=${configure.build_arch}
configure.env-append \
                    ASFLAGS='[get_canonical_archflags]'
if {${build_arch} eq "x86_64"} {
    depends_build-append \
                    port:yasm
    configure.args-append \
                    --enable-yasm
}

license             GPL-2+

platform darwin {
    if {${os.major} < 9} {
        configure.args-append --disable-asm
    }

    # VDA (video hardware acceleration, mostly H264) is only supported on 10.6.3+ up to (excluding) 10.11.
    #if {(${os.major} > 10 || (${os.major} == 10 && ${os.minor} >= 3)) && (${os.major} < 15)}
    # Due to a bug in ffmpeg(?), we have to enable VDA on 10.11 as well, even though it shouldn't be supported.
    # More information: https://github.com/mpv-player/mpv/issues/2299
    if {${os.major} > 10 || (${os.major} == 10 && ${os.minor} >= 3)} {
        configure.args-delete --disable-vda
        configure.args-append --enable-vda
    }

    # VideotoolBox, a new hardware acceleration framework, is supported on 10.8+ and "here to stay".
    # It provides support for H264, H263, MPEG1, MPEG2 and MPEG4.
    if {${os.major} > 11} {
        configure.args-delete --disable-videotoolbox
        configure.args-append --enable-videotoolbox
    }

    # Apple GCC has problems with SIMD intrinsics and -Werror=no-missing-prototypes.
    if {${os.major} < 11} {
        patchfiles-append patch-configure-no-error-on-missing-prototypes.diff
    }

    # kCVPixelFormatType_OneComponent8 used in avfoundation indev is only available on 10.8+
    if {${os.major} < 12} {
        configure.args-append --disable-indev=avfoundation
    }
}

#
# configure isn't autoconf and they do use a dep cache
#

platform darwin 8 {
    post-patch {
        reinplace "s:,-compatibility_version,$\(LIBMAJOR\)::" ${worksrcpath}/configure
    }
}

destroot.target     install-libs install-headers

post-destroot {
    file delete -force ${destroot}${prefix}/share/examples
    # We need to make sure that the linker will use our libraries and not one
    # from a location like ${prefix}/lib . That's why we use --build-suffix, but
    # that still requires us to provide pkg-config files with the standard names:
    foreach pc [glob ${destroot}${FFMPEG_VLC_PREFIX}/lib/pkgconfig/*.pc] {
        set standardname [strsed ${pc} "s/-VLC.pc/.pc/"]
        ln -s [file tail ${pc}] ${standardname}
    }
    # oblige dependent code to include files from our own renamed header file directories, so it
    # cannot include mismatching headers by accident (e.g. those from ffmpeg 3.x).
    foreach dir {libavcodec libavformat libavresample libavutil libpostproc libswresample libswscale} {
        file rename ${destroot}${FFMPEG_VLC_PREFIX}/include/${dir} ${destroot}${FFMPEG_VLC_PREFIX}/include/${dir}-VLC
    }
    foreach dir {libavcodec libavformat libavresample libavutil libpostproc libswresample libswscale} {
        foreach header [glob -nocomplain ${destroot}${FFMPEG_VLC_PREFIX}/include/*/*.h] {
            reinplace "s|${dir}/|${dir}-VLC/|g" ${header}
        }
    }
    # packageable: ${destroot}${FFMPEG_VLC_PREFIX}/{include,lib/lib*VLC.dylib,lib/pkgconfig}
}

livecheck.type      regex
livecheck.url       ${master_sites}
livecheck.regex     "${name}-(\\d+(?:\\.\\d+)*)${extract.suffix}"

# kate: backspace-indents true; indent-pasted-text true; indent-width 4; keep-extra-spaces true; remove-trailing-spaces modified; replace-tabs true; replace-tabs-save true; syntax Tcl/Tk; tab-indents true; tab-width 4;
