#!/bin/bash

if [[ $EUID -ne 0 ]]; then
    echo "You need to run this script as root."
    exit 1
fi

echo "QUAKE 3: DEFRAG SERVER INSTALL"
echo "Installing required packages: unzip, wget, nano, nfs-common, screen"
apt update && apt -y install unzip wget nano nfs-common screen 

echo "Enabling i386 architecture and installing required libraries"
dpkg --add-architecture i386
apt update
apt -y install libc6:i386 libstdc++6:i386 libgcc1:i386 libncurses5:i386 libtinfo5:i386 zlib1g:i386 libxml2:i386

echo "Installing libmysqlclient20 (i386)"
dpkg --unpack .install/libmysqlclient20_5.7.21-1ubuntu1_i386.deb

echo "Required packages installed!"
echo "Now, you can run `./download_defrag.sh` as the non-root user to continue the installation."