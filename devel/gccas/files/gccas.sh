#!/bin/sh
# This is a wrapper around the clang assembler that allows to call it
# in lieu and place of the `as` command (= Apple's version of GNU as, gas).
# Its name is taken from the old gccas tool that mimicked gas for use by
# the llvm-gcc front-end. The purpose remains the same: being able to
# use GCC compilers as a front-end for the LLVM assembler/linker toolchain
# with the goal of having access to the full x86_64 instruction set from
# those compilers (which include gfortran).

if [ "${GCCAS_SHUNT}" != "" ] ;then
    exec ${GCCAS_SHUNT} "$@"
elif [ "${CLANG_ASSEMBLER}" = "" ] ;then
#     CLANG_ASSEMBLER="@CLANG@ -x assembler -c"
    # it turns out `as` has an option to pull the trick we need:
    CLANG_ASSEMBLER="@PREFIX@/bin/as -q"
fi

case ${CLANG_ASSEMBLER} in
    "as "*|*"/as "*)
        if [ "$1" = "-help" -o "$1" = "--help" ] ;then
            echo "Usage: `basename $0` [options] <inputs>"
            echo "Default clang assembler command: \$CLANG_ASSEMBLER=\"${CLANG_ASSEMBLER}\""
            echo "Override by setting the CLANG_ASSEMBLER env. variable"
            echo "Bypass the clang assembler argument translation by setting GCCAS_SHUNT to the path of the desired assembler"
            echo
            exit 1
        fi

        exec ${CLANG_ASSEMBLER} "$@"
        ;;
esac

# assume we're being pointed to clang - obsolete code, possibly to be converted
# to support 3rd party assemblers like nasm?

HAS_INPUT_FILE=0 

CLARGS=""

# let's hope we never meet arguments with whitespace...
while [ $# -ne 0 ]; do 
     # Skip options 
    case ${1} in
        # filter out options known to cause warnings
        -I)
            shift
            ;;
        # any assembler-exclusive options should be caught here and
        # passed as "-Wa,${1} [-Wa,${2}]"
        # Also, filter the most obvious GNU-style arguments
        --32)
            CLARGS="${CLARGS} -arch i386"
            CLARGS="${CLARGS} -arch i386"
            ;;
        --64)
            CLARGS="${CLARGS} -arch x86_64"
            ;;
        -help|--help)
            echo "Usage: `basename $0` [options] <inputs>"
            echo "Default clang assembler command: \$CLANG_ASSEMBLER=\"${CLANG_ASSEMBLER}\""
            echo "Override by setting the CLANG_ASSEMBLER env. variable"
            echo "Bypass the clang assembler argument translation by setting GCCAS_SHUNT to the path of the desired assembler"
            echo
            CLARGS="${CLARGS} ${1}"
            ;;
        -c)
            # already included in the command
            ;;
        -force_cpusubtype_ALL|-mmacosx-version-min=*)
            # arguments that would be passed to the linker:
            ;;
        -o|-arch)
            CLARGS="${CLARGS} ${1} ${2}"
		  shift
            ;;
        -*)
            CLARGS="${CLARGS} ${1}"
            ;;
        *)
            HAS_INPUT_FILE=1
            CLARGS="${CLARGS} ${1}"
            ;;
    esac
    shift
done 

if [ $HAS_INPUT_FILE -eq 1 ]; then 
    exec ${CLANG_ASSEMBLER} ${CLARGS}
else 
    exec ${CLANG_ASSEMBLER} ${CLARGS} -
fi 
