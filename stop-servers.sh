#!/bin/bash

if [[ $EUID -eq 0 ]]; then
    echo "This script should NOT be run as root !!"
    exit 1
fi

source sv.conf

echo "Stopping DFSV native servers..."

for sv_type in mixed cpm vq3 fastcaps teamruns freestyle; do
    sv_qty="${sv_type}_count"
    i=0
    while [[ $i -lt "${!sv_qty}" ]]; do
        i=$(($i+1))
        sv_name="${sv_type}_${i}"
        if screen -ls | grep -q "\.${sv_name}[[:space:]]"; then
            echo "Stopping server: $sv_name"
            screen -S "$sv_name" -X quit
        fi
    done
done

sleep 2

# Catch any oDFe.ded that survived (e.g. screen died but process detached)
if pgrep -u "$USER" oDFe.ded > /dev/null; then
    echo "Force killing leftover oDFe.ded processes..."
    pkill -u "$USER" oDFe.ded
    sleep 1
    pkill -9 -u "$USER" oDFe.ded 2>/dev/null
fi

screen -wipe > /dev/null 2>&1

# NFS stays mounted on purpose - it is managed by the systemd mount unit
# (.localinstall/home-q3df-dfsv-game-nfs-maps.mount), not by this script.

echo "All servers stopped."