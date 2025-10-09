# DFSV Native Setup (No Docker)

This branch contains a native implementation of DFSV that runs without Docker containers.

## Installation

1. Make scripts executable and run the installation script:
```bash
chmod +x *.sh
sudo ./install.sh
```

This will:
- Install required packages (wget, unzip, nano, nfs-common)
- Download server files from dl.defrag.racing
- Set up directory structure
- Download default maps

## Configuration

Edit `sv.conf` to configure your server settings:
- `SV_BASE_HOSTNAME`: Base hostname for your servers
- `SV_RCON`: RCON password
- `SV_LOCATION`: Server location
- `ADMIN_NAME`: Administrator name
- Server type counts (mixed_count, cpm_count, etc.)

## Usage

### Starting Servers
```bash
./launch-native.sh
```

This will:
- Mount NFS maps directory from 173.212.241.188:/maps/bsp
- Start configured servers natively on the system
- Each server runs as a separate process

### Stopping Servers
```bash
./stop-native.sh
```

This will:
- Stop all running DFSV servers
- Unmount NFS maps directory
- Clean up PID files

### Server Management

- Server logs: `servers/base/logs/`
- Server configs: `servers/base/defrag/`
- PID files: `servers/base/logs/*.pid`

## Requirements

- Linux system with NFS support
- Root/sudo access for NFS mounting
- Network access to dl.defrag.racing and NFS server

## Differences from Docker Version

- No Docker containers - runs directly on host system
- NFS maps mounted directly to filesystem
- Process management via PID files
- Logs stored in `servers/base/logs/`
- Each server is a separate system process