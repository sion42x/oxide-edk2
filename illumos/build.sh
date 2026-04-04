#!/bin/bash

# Copyright 2020 OmniOS Community Edition (OmniOSce) Association.

usage() {
	echo "Usage: $0 [-csm] [-v] <clean|RELEASE|DEBUG>"
	exit 1
}

verbose=0
csm=0
while [[ "$1" = -* ]]; do
	[ "$1" = -v ] && shift && verbose=1
done

clean=0
case "$1" in
	DEBUG)		flavour=DEBUG
			level=INFO
			 ;;
	RELEASE)	flavour=RELEASE
			level=CRIT
			;;
	clean)		clean=1 ;;
	*)		usage ;;
esac
shift
[ -n "$1" ] && usage

: "${GCCVER:=7}"
: "${GCCPATH:=/opt/gcc-$GCCVER}"
: "${GCC:=$GCCPATH/bin/gcc}"
: "${GXX:=$GCCPATH/bin/g++}"
: "${GMAKE:=/usr/bin/gmake}"
: "${GAS:=/usr/bin/gas}"
: "${GAR:=/usr/bin/gar}"
: "${GLD:=/usr/bin/gld}"
: "${GOBJCOPY:=/usr/bin/gobjcopy}"

export GCCVER GCCPATH GCC GXX GMAKE GAS GAR GLD GOBJCOPY

MAKE_ARGS="
    AS=$GAS
    AR=$GAR
    LD=$GLD
    OBJCOPY=$GOBJCOPY
    CC=$GCC BUILD_CC=$GCC
    CXX=$GXX BUILD_CXX=$GXX
    GCCPATH=$GCCPATH
"

# Check for bins:
# iasl -> developer/acpi
# nasm -> developer/nasm

ILLGCC_BIN=$GCCPATH/bin/
#BUILD_ARGS="-DDEBUG_ON_SERIAL_PORT=TRUE -DFD_SIZE_2MB -DHTTP_BOOT_ENABLE=TRUE"
BUILD_ARGS="-DFD_SIZE_2MB -DTPM_ENABLE=TRUE"
PYTHON3_ENABLE=TRUE
[ $verbose -eq 1 ] && BUILD_ARGS+=" -v"

export MAKE_ARGS ILLGCC_BIN BUILD_ARGS PYTHON3_ENABLE

if [[ ! -f Conf/tools_def.txt ]]; then
	gmake -j16 $MAKE_ARGS HOST_ARCH=X64 ARCH=X64 -C BaseTools \
	    || exit 1
fi

set -e


# edksetup.sh uses the linux-utils whereis(1). which(1) will do in a pinch
export PATH="$PWD/illumos/compat-bin:$PATH"
alias whereis=which

source edksetup.sh

if [ "$csm" -eq 1 ]; then
	BUILD_ARGS+=" -DCSM_ENABLE=TRUE"
	gmake $MAKE_ARGS -C BhyvePkg/Csm/BhyveCsm16 clean all
fi

echo `which build`

BUILD_ARGS="$BUILD_ARGS -DMPT_SCSI_ENABLE=FALSE -DSECURE_BOOT_ENABLE=TRUE"

`which build` \
	-t ILLGCC -a X64 -b $flavour \
	-p OvmfPkg/OvmfPkgX64.dsc $BUILD_ARGS
