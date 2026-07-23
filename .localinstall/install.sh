#!/bin/bash

if [[ $EUID -ne 0 ]]; then
    echo "You need to run this script as root."
    exit 1
fi

echo "QUAKE 3: DEFRAG SERVER INSTALL"
echo "Installing required packages: unzip, wget, nano, nfs-common, screen, jq"
apt update && apt -y install unzip wget nano nfs-common screen jq

echo "Enabling i386 architecture and installing required libraries"
dpkg --add-architecture i386
apt update
# libncurses5/libtinfo5 were dropped in Ubuntu 24.04 (noble) and neither
# oDFe.ded nor qagamei386.so links against them (checked via ldd) - use the
# ncurses6 variants so one missing package can't abort the whole batch.
# libgcc1 is a transitional name gone in noble; libgcc-s1 is the real package.
# mysql-common is needed by libmysqlclient20 below.
apt -y install mysql-common libc6:i386 libstdc++6:i386 libgcc-s1:i386 zlib1g:i386 libncurses6:i386 libtinfo6:i386 libxml2:i386

echo "Installing libmysqlclient20 (i386)"
# apt (not dpkg --unpack) so dependencies get resolved and the package
# doesn't stay half-installed in the "iU" state blocking later apt runs
apt -y install ./.install/libmysqlclient20_5.7.21-1ubuntu1_i386.deb

echo "Required packages installed!"
echo "Now, you can run ./download_defrag.sh as the non-root user to continue the installation."