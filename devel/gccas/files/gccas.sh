#!/bin/sh
# This is a wrapper around the clang assembler that allows to call it
# in lieu and place of the `as` command (= Apple's version of GNU as, gas).
# Its name is taken from the old gccas tool that mimicked gas for use by
# the llvm-gcc front-end. The purpose remains the same: being able to
# use GCC compilers as a front-end for the LLVM assembler/linker toolchain
# with the goal of having access to the full x86_64 instruction set from
# those compilers (which include gfortran).

HAS_INPUT_FILE=0 

if [ "${CLANG_ASSEMBLER}" = "" ] ;then
    CLANG_ASSEMBLER="@CLANG@ -x assembler -c"
fi
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
            echo
            CLARGS="${CLARGS} ${1}"
            ;;
        -c)
            # already included in the command
            ;;
        -*)
            # use generic options as assembler-specific
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
