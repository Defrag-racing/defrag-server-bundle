# DFSV Native Setup (No Docker)

Runs the defrag servers directly on the host system, without Docker containers.

> **Important:** the systemd units in `.localinstall/` have the installation
> path hardcoded to `/home/q3df/dfsv`. For a native install, create a `q3df`
> user and clone this repository to `/home/q3df/dfsv`. If you install anywhere
> else, you must edit `.localinstall/dfsv.service` and
> `.localinstall/home-q3df-dfsv-game-nfs-maps.mount` accordingly (the .mount
> file name itself must match the mount path, systemd requires it).

## Installation

1. As root, install the required packages and 32-bit libraries:
```bash
sudo .localinstall/install.sh
```

2. As the non-root user (`q3df`), download the server files:
```bash
chmod +x *.sh
./download_defrag.sh
```

This downloads the oDFe engine, the defrag mod and the community modules
from dl.defrag.racing / q3defrag.org.

## Configuration

Edit `sv.conf` and fill in **at least** the required settings **before
starting anything** (a systemd start with an empty sv.conf fails on purpose):
- `SV_BASE_HOSTNAME`: Base hostname for your servers
- `SV_RCON`: RCON password
- `SV_LOCATION`: Server location
- `ADMIN_NAME`: Administrator name
- Server type counts (`mixed_count`, `cpm_count`, ...)

## Usage

### Recommended: systemd

```bash
sudo cp .localinstall/home-q3df-dfsv-game-nfs-maps.mount /etc/systemd/system/
sudo cp .localinstall/dfsv.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now home-q3df-dfsv-game-nfs-maps.mount
sudo systemctl enable --now dfsv.service
```

The mount unit attaches the community map pool (NFS from
173.212.241.188:/maps/bsp) to `game/nfs/maps`; the service starts every
server configured in `sv.conf` on boot.

### Manual

```bash
./start-servers.sh   # start all configured servers
./stop-servers.sh    # stop them all again
```

### Server Management

- Each server runs in its own `screen` session named `<type>_<n>`
  (e.g. `mixed_1`); attach with `screen -r mixed_1`, detach with `Ctrl-A D`
- Server logs: `game/defrag/<type>_<n>/<type>_<n>.log`
- Server configs: `game/defrag/cfgs/` (global + per-gamemode) and
  `game/defrag/<type>_<n>/main.cfg` (generated per server on start)

## Requirements

- Linux system with NFS support (`nfs-common`)
- i386 multiarch libraries (installed by `.localinstall/install.sh`)
- Root/sudo access for installing packages and the NFS mount
- Network access to dl.defrag.racing, q3defrag.org and the NFS server

## Differences from Docker Version

- No Docker containers — runs directly on the host system
- NFS maps mounted by a systemd mount unit instead of inside the container
- Process management via named `screen` sessions
- Servers start on boot via `dfsv.service`
