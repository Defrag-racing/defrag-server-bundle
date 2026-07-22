#!/bin/bash

# Keeps a local copy of the defrag.racing community map pool in
# game/baseq3 - the MAPS_MODE=sync alternative to the NFS mount.
# Local maps must be pk3s (loose .bsp only works over the NFS share;
# pk3s over NFS make the engine index them all and hang), so this mirrors
# the bsp-only pk3 repacks (one pk3 per map, no textures - packed on the
# storage by Storage-defrag-map-daemon/packbsp.py) into the same folder
# where owners already drop custom maps. Existing files are never touched
# unless the pool has a same-named pk3 with a different size.
#
# - Downloads every map that is missing locally or whose size differs.
# - Each download goes to <map>.part first and is renamed only after the
#   size checks out, so an interrupted download never looks like a
#   finished map.
# - Never deletes anything: a broken or empty listing must not be able to
#   wipe a working map pool. Local extras are only reported.
# - Safe to run from a timer or cron: a flock guard makes overlapping
#   runs no-ops.

set -euo pipefail

if [[ $EUID -eq 0 ]]; then
    echo "This script should NOT be run as root !!"
    exit 1
fi

cd "$(dirname "$(readlink -f "$0")")"

LISTING_URL="${MAPSYNC_LISTING_URL:-https://dl.defrag.racing/pk3bsp/}"
BASE_URL="${MAPSYNC_BASE_URL:-https://dl.defrag.racing/pk3bsp/}"
DEST_DIR="$(pwd)/game/baseq3"
NFS_MAPS_DIR="$(pwd)/game/nfs/maps"
LOCK_FILE="$(pwd)/.mapsync.lock"

source sv.conf

if [[ "${MAPS_MODE:-nfs}" != "sync" ]]; then
    echo "MAPS_MODE is not 'sync' in sv.conf - nothing to do (NFS mode)."
    exit 0
fi

command -v jq >/dev/null || { echo "ERROR: jq is required (apt install jq)." >&2; exit 1; }

if mountpoint -q "$NFS_MAPS_DIR"; then
    echo "ERROR: $NFS_MAPS_DIR is an active NFS mount - both map modes are on at once." >&2
    echo "Unmount it and disable the .mount unit before using MAPS_MODE=sync." >&2
    exit 1
fi

mkdir -p "$DEST_DIR"

# One sync at a time; the run that is already busy simply wins.
exec 200>"$LOCK_FILE"
if ! flock -n 200; then
    echo "Another map sync is already running - skipping."
    exit 0
fi

# Leftovers from an interrupted run are never valid.
find "$DEST_DIR" -maxdepth 1 -name '*.part' -delete

echo "Fetching the map listing..."
listing=$(wget -qO- --timeout=30 "$LISTING_URL") || {
    echo "ERROR: could not fetch $LISTING_URL" >&2
    exit 1
}

# nginx autoindex JSON -> TSV: name <TAB> url-encoded name <TAB> size
remote=$(jq -r '
    map(select(.type == "file" and (.name | endswith(".part") | not)))
    | .[] | [.name, (.name | @uri), (.size | tostring)] | @tsv
' <<<"$listing" 2>/dev/null) || {
    echo "ERROR: the listing is not valid autoindex JSON." >&2
    exit 1
}

if [[ -z "$remote" ]]; then
    echo "ERROR: the listing contains no maps - refusing to continue." >&2
    exit 1
fi

human() {
    awk -v b="$1" 'BEGIN {
        if (b >= 1073741824)   printf "%.1f GB", b / 1073741824
        else if (b >= 1048576) printf "%.1f MB", b / 1048576
        else                   printf "%d KB", b / 1024
    }'
}

# Pass 1: what is missing or has a different size?
queue=()
total_bytes=0
remote_count=0
while IFS=$'\t' read -r name uri size; do
    remote_count=$((remote_count + 1))
    local_file="$DEST_DIR/$name"
    if [[ ! -f "$local_file" ]] || [[ "$(stat -c%s "$local_file")" != "$size" ]]; then
        queue+=("$name"$'\t'"$uri"$'\t'"$size")
        total_bytes=$((total_bytes + size))
    fi
done <<<"$remote"

echo "Remote pool: $remote_count maps."

if [[ ${#queue[@]} -eq 0 ]]; then
    echo "Everything is up to date."
    exit 0
fi

echo "To download: ${#queue[@]} map(s), $(human "$total_bytes") total."

# Pass 2: download to .part, rename only on a verified size.
i=0
failed=0
for entry in "${queue[@]}"; do
    IFS=$'\t' read -r name uri size <<<"$entry"
    i=$((i + 1))
    echo "[$i/${#queue[@]}] $name ($(human "$size"))"

    part="$DEST_DIR/$name.part"
    if ! wget -q --timeout=60 --tries=2 -O "$part" "$BASE_URL$uri"; then
        echo "  FAILED: download error, will retry on the next run." >&2
        rm -f "$part"
        failed=$((failed + 1))
        continue
    fi

    if [[ "$(stat -c%s "$part")" != "$size" ]]; then
        echo "  FAILED: size mismatch, will retry on the next run." >&2
        rm -f "$part"
        failed=$((failed + 1))
        continue
    fi

    mv "$part" "$DEST_DIR/$name"
done

echo "Done: $((i - failed)) downloaded, $failed failed."
[[ $failed -eq 0 ]] || exit 1
