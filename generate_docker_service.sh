#!/bin/bash

if [[ $EUID -eq 0 ]]; then
    echo "This script should NOT be run as root !!"
    exit 1
fi

installdir=$(pwd)
basedir="$installdir/game"
echo "Generating docker-compose.override.yml"
COUNTER=0
source sv.conf

# Same sv.conf backup as start-servers.sh does for native installs: a new
# numbered .bak only when the config changed, keep the last 20.
latest_bak=$(ls sv.conf.bak.* 2>/dev/null | sort -t. -k4 -n | tail -1)
if [ -z "$latest_bak" ] || ! cmp -s sv.conf "$latest_bak"; then
	if [ -n "$latest_bak" ]; then
		next_bak=$(( ${latest_bak##*.bak.} + 1 ))
	else
		next_bak=1
	fi
	cp sv.conf "sv.conf.bak.$next_bak"
	ls sv.conf.bak.* 2>/dev/null | sort -t. -k4 -n | head -n -20 | xargs -r rm --
fi

echo "Checking sv.conf for required settings..."
for CONFIGURABLE in SV_BASE_HOSTNAME SV_RCON SV_LOCATION ADMIN_NAME; do
	if [[ "${!CONFIGURABLE}" = "" ]] ; then
		read -p "Enter $CONFIGURABLE: " $CONFIGURABLE
	fi
done
printf "\nServer Hostname: $SV_BASE_HOSTNAME\nAdmin: $ADMIN_NAME\nRcon Password: $SV_RCON\nServer Location: $SV_LOCATION\n\n"

echo "Generating docker-compose.override.yml"
rm -rf docker-compose.override.yml &>/dev/null
# The maps volume depends on MAPS_MODE - written FIRST because the
# demo-upload block at the bottom can exit the script early.
# - sync:   local bind instead of the NFS volume from docker-compose.yml
# - nfspk3: NFS volume of the bsp-only pk3 pool, mounted at nfs/pk3bsp
MAPS_VOLUME_TARGET="/server/nfs/maps/"
if [[ "${MAPS_MODE:-nfs}" == "sync" ]]; then
printf 'volumes:
  maps:
    driver_opts:
      type: none
      device: ${PWD}/game/nfs/maps/
      o: bind

' > docker-compose.override.yml 2>&1
elif [[ "${MAPS_MODE:-nfs}" == "nfspk3" ]]; then
MAPS_VOLUME_TARGET="/server/nfs/pk3bsp/"
printf 'volumes:
  maps:
    driver_opts:
      type: "nfs"
      o: "addr=173.212.241.188,ro,nolock,noresvport,soft,timeo=30"
      device: ":/maps/pk3bsp"

' > docker-compose.override.yml 2>&1
fi
printf 'services:' >> docker-compose.override.yml 2>&1
for sv_type in mixed cpm vq3 fastcaps teamruns freestyle;do
	i=0
	sv_qty="${sv_type}_count"
        sv_sfx="${sv_type}_sfx"
	while [[ $i -ne "${!sv_qty}" ]]
	do
	  curr_id="rs${SERVER_STARTPORT}"
		i=$(($i+1))
		curr_name="${sv_type}_${i}"
		curr_hostname="${SV_BASE_HOSTNAME} ${!sv_sfx} ${i}"
		printf "
  ${curr_name}:
    image: q3df
    container_name: ${curr_name}
    network_mode: host
    user: \"$(id -u):$(id -g)\"
    volumes:
      - base_baseq3:/server/baseq3/
      - base_defrag:/server/defrag/
      - maps:${MAPS_VOLUME_TARGET}
      - ./game/.q3a/://.q3a/
    restart: always
    environment:
      - MAPS_MODE=${MAPS_MODE}
      - MDD_ENABLED=${MDD_ENABLED}
      - RS_ID=${!curr_id}
      - NAME_ID=${curr_name}
      - SV_TYPE=${sv_type}
      - SV_HOSTNAME=${curr_hostname}
      - SV_RCON=${SV_RCON}
      - SV_LOCATION=${SV_LOCATION}
      - SV_PORT=${SERVER_STARTPORT}
      - ADMIN_NAME=${ADMIN_NAME}
      - ADMIN_MAIL=${ADMIN_MAIL}
      - ADMIN_DISCORD=${ADMIN_DISCORD}
      - ADMIN_IRC=${ADMIN_IRC}
      - SV_MAPBASE=${SV_MAPBASE}
      - SV_HOMEPAGE=${SV_HOMEPAGE}
      - SV_PRIVATE=${SV_PRIVATE}
      - SV_PASSWORD=${SV_PASSWORD}" >> docker-compose.override.yml 2>&1
	sudo mkdir game/defrag/$curr_name &>/dev/null
	#sudo cp cfgs/${sv_type}.cfg servers/base/defrag/$curr_name/main.cfg
        SERVER_STARTPORT=$(($SERVER_STARTPORT+1))
	done
done

# Check if .env file exists and has required variables
if [[ -z ${DEMO_SFTP_ENABLED} || ${DEMO_SFTP_ENABLED} -eq 0 ]] ; then
    exit 1
fi

if [[ -z ${DEMO_SFTP_USER} || -z ${DEMO_SFTP_PASS} ]] ; then
    echo "Missing credentials for automatic demo uploading, skipping..."
    exit 1
fi

if [[ -z ${DEMO_SFTP_REMOTEDIR} ]] ; then
    echo "Missing Remote directory for SFTP, skipping..."
    exit 1
fi

printf "
  q3df-demoupload:
    build: ./.docker-demoupload
    restart: always
    volumes:
      - base_baseq3:/server/baseq3/
      - base_defrag:/server/defrag/
    environment:
      - DEMO_SFTP_ENABLED=${DEMO_SFTP_ENABLED}
      - DEMO_SFTP_HOST=${DEMO_SFTP_HOST}
      - DEMO_SFTP_PORT=${DEMO_SFTP_PORT}
      - DEMO_SFTP_USER=${DEMO_SFTP_USER}
      - DEMO_SFTP_PASS=${DEMO_SFTP_PASS}
      - DEMO_SFTP_REMOTEDIR=${DEMO_SFTP_REMOTEDIR}
    ">> docker-compose.override.yml 2>&1