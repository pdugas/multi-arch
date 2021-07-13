#!/bin/sh
#
# geteg.sh - web installer for eg
#
# Synopsis:
#    curl -Ls https://raw.githubusercontent.com/pdugas/multi-arch/main/bin/geteg.sh | sh
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
LDD=$(ldd --version 2>&1)
if echo $LDD | grep musl >/dev/null; then
    LIBC=musl
else
    LIBC=gnu
fi

[ -n "$(which curl)" ] || { echo >&2 "error: missing curl in PATH"; exit 1; }
RELEASES=https://api.github.com/repos/pdugas/multi-arch/releases
LATEST=$(curl -s ${RELEASES}/latest)
TAG=$(echo ${LATEST} | sed 's/^.*"tag_name": "\([^"]*\)".*/\1/')
DOWNLOAD=https://github.com/pdugas/multi-arch/releases/download
if [ -w /usr/local/bin ]; then
    DEST=/usr/local/bin/eg
else
    DEST=/tmp/eg
fi
curl -Lso $DEST ${DOWNLOAD}/${TAG}/eg-${ARCH}-${LIBC} && chmod a+x $DEST

echo "Installed eg-${ARCH}-${LIBC} to $DEST"

