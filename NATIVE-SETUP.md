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

Maps first - pick ONE of the two modes (`MAPS_MODE` in `sv.conf`):

**A) NFS mount (default, `MAPS_MODE=nfs`)** - attaches the community map
pool (NFS from 173.212.241.188:/maps/bsp) to `game/nfs/maps`:

```bash
sudo cp .localinstall/home-q3df-dfsv-game-nfs-maps.mount /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now home-q3df-dfsv-game-nfs-maps.mount
```

**B) Local map sync (`MAPS_MODE=sync`)** - keeps a full local copy of the
map pool as bsp-only pk3s in `game/baseq3` instead. The first run
downloads the whole pool (~15 GB - it prints the exact size first, make
sure the disk fits it), then the timer checks every ~10 minutes and
downloads new maps right away:

```bash
sudo cp .localinstall/dfsv-mapsync.service .localinstall/dfsv-mapsync.timer /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now dfsv-mapsync.timer
```

**C) NFS-thin maps (`MAPS_MODE=nfspk3`, EXPERIMENTAL)** - mounts the
bsp-only pk3 pool over NFS and the engine loads each map's pk3 on demand:
no local pool, no scanning of ~19k pk3s. Requires an oDFe build with
`fs_mapPakDir` support (not yet in the official release):

```bash
sudo cp .localinstall/home-q3df-dfsv-game-nfs-pk3bsp.mount /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now home-q3df-dfsv-game-nfs-pk3bsp.mount
```

Then the servers themselves:

```bash
sudo cp .localinstall/dfsv.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now dfsv.service
```

The service starts every server configured in `sv.conf` on boot.

### Manual

```bash
./start-servers.sh   # start all configured servers
./stop-servers.sh    # stop them all again
./sync-maps.sh       # one map-sync pass (MAPS_MODE=sync only)
```

Instead of the systemd timer, the map sync can also run from cron
(as `q3df`, via `crontab -e`):

```
*/10 * * * * cd ~/dfsv && bash ./sync-maps.sh
```

### Server Management

- Each server runs in its own `screen` session named `<type>_<n>`
  (e.g. `mixed_1`); attach with `screen -r mixed_1`, detach with `Ctrl-A D`
- Server logs: `game/defrag/<type>_<n>/<type>_<n>.log`
- Server configs: `game/defrag/cfgs/` (global + per-gamemode) and
  `game/defrag/<type>_<n>/main.cfg` (generated per server on start)

## Requirements

- Linux system with NFS support (`nfs-common`) - only for `MAPS_MODE=nfs`
- `jq` for the map sync script - only for `MAPS_MODE=sync` (installed by
  `.localinstall/install.sh`), plus enough disk for the whole map pool
  (~15 GB)
- i386 multiarch libraries (installed by `.localinstall/install.sh`)
- `sshpass` for the demo upload cron (`upload_demos.sh` uses it for SFTP)
- Root/sudo access for installing packages and the NFS mount
- Network access to dl.defrag.racing, q3defrag.org and the NFS server

## Differences from Docker Version

- No Docker containers — runs directly on the host system
- NFS maps mounted by a systemd mount unit instead of inside the container
- Process management via named `screen` sessions
- Servers start on boot via `dfsv.service`
