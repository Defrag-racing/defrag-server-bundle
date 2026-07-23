#!/bin/bash

# Any failed download or extraction must abort loudly instead of printing
# "Installation done!" over a broken install.
set -euo pipefail

if [[ $EUID -eq 0 ]]; then
    echo "This script should NOT be run as root !!"
    exit 1
fi

installdir=$(pwd)
echo "Creating the required folders within $installdir ..."
basedir="$installdir/game"
tmpdir="/tmp/defraginstall"

mkdir -p "$basedir/baseq3"
mkdir -p "$basedir/nfs/maps"
mkdir -p "$basedir/nfs/pk3bsp"
mkdir -p "$basedir/defrag/serverdemos"

echo "Creating a temporary folder in /tmp/defraginstall for downloading assets..."
mkdir -p "$tmpdir"
cd "$tmpdir"

# --- Core bundle: engine + DeFRaG mod + recordsystem modules + qagame +
#     ip4db.dat + uglifix2.so. Small (~7 MB) and rebuilt by defrag.racing
#     whenever a new oDFe engine or mod appears, so always pull it fresh.
echo "Downloading the core server bundle (engine + mod + modules) from defrag.racing ..."
wget -O dfsv-core.tar https://dl.defrag.racing/downloads/dfsv-core.tar
tar -xf dfsv-core.tar -C "$basedir"
chmod +x "$basedir/oDFe.ded"

# --- baseq3: the original id-Quake3 paks (pak0-8, ~485 MB). Static forever,
#     so only download it when it isn't already in place. Extracted into a
#     staging dir first: unpacking a truncated tar straight into game/ would
#     leave a partial pak0.pk3 that makes this check skip the re-download
#     forever.
if [ ! -f "$basedir/baseq3/pak0.pk3" ]; then
    echo "Downloading the baseq3 data (one-time, ~485 MB) ..."
    wget -O dfsv-baseq3.tar https://dl.defrag.racing/downloads/dfsv-baseq3.tar
    mkdir -p baseq3-staging
    tar -xf dfsv-baseq3.tar -C baseq3-staging
    cp -r baseq3-staging/baseq3/. "$basedir/baseq3/"
else
    echo "baseq3 paks already present - skipping the big download."
fi

cd "$installdir"
rm -rf "$tmpdir"

echo "Installation done! You can now edit sv.conf to your likings."

echo "If you are using a Docker installation, generate the docker-compose file by running generate_docker_service.sh"
echo "If you are using a local installation, run start-servers.sh"

exit 0
