#!/bin/bash

if [[ $EUID -eq 0 ]]; then
    echo "This script should NOT be run as root !!"
    exit 1
fi

echo "Stopping DFSV native servers..."

# Stop all servers by reading PID files
for pidfile in servers/base/logs/*.pid; do
    if [ -f "$pidfile" ]; then
        pid=$(cat "$pidfile")
        server_name=$(basename "$pidfile" .pid)
        echo "Stopping server: $server_name (PID: $pid)"

        if kill -0 "$pid" 2>/dev/null; then
            kill -TERM "$pid"
            # Wait a bit for graceful shutdown
            sleep 2
            # Force kill if still running
            if kill -0 "$pid" 2>/dev/null; then
                echo "Force killing server $server_name"
                kill -KILL "$pid"
            fi
        else
            echo "Server $server_name was not running"
        fi

        rm -f "$pidfile"
    fi
done

# Unmount NFS if mounted
if mountpoint -q ./game/baseq3/maps; then
    echo "Unmounting NFS maps directory..."
    sudo umount ./game/baseq3/maps
    if [ $? -eq 0 ]; then
        echo "NFS maps unmounted successfully"
    else
        echo "Warning: Failed to unmount NFS maps"
    fi
fi

echo "All servers stopped."