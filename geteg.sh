#!/bin/sh
#
# geteg.sh - web installer for eg
#
# Synopsis:
#    curl -Ls https://raw.githubusercontent.com/pdugas/multi-arch/main/geteg.sh | sh
# 
# Description:
#    `geteg.sh` is an example installer script for the `eg` binary onto a local
#    machine. It inspects the local environment to determine which binary is
#    needed then downloads it and installs it into `/usr/local/bin`.
#
#    Note that `uname`, `ldd`, and `curl` are currently required in PATH.
#
#    See https://github.com/pdugas/multi-arch/.
#

[ -n "$(which uname)" ] || { echo >&2 "error: missing uname in PATH"; exit 1; }
MACH=$(uname -m)
case $MACH in
    x86_64)
        ARCH=amd64
        ;;
    aarch64)
        ARCH=arm64
        ;;
    *)
        echo >&2 "error: unsupported machine type; $MACH"
        exit 1
        ;;
esac

[ -n "$(which ldd)" ] || { echo >&2 "error: missing ldd in PATH"; exit 1; }
if ldd --version 2>&1 | grep musl >/dev/null; then
    LIBC=musl
else
    LIBC=gnu
fi

LATEST=$(curl -s https://api.github.com/repos/pdugas/multi-arch/releases/latest)
TAG=$(echo ${LATEST} | sed 's/^.*"tag_name": "\([^"]*\)".*/\1/')

# - download it
# - move and chmod it
# - report results

