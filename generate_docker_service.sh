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
echo "Checking sv.conf for required settings..."
for CONFIGURABLE in SV_BASE_HOSTNAME SV_RCON SV_LOCATION ADMIN_NAME; do
	if [[ "${!CONFIGURABLE}" = "" ]] ; then
		read -p "Enter $CONFIGURABLE: " $CONFIGURABLE
	fi
done
printf "\nServer Hostname: $SV_BASE_HOSTNAME\nAdmin: $ADMIN_NAME\nRcon Password: $SV_RCON\nServer Location: $SV_LOCATION\n\n"

echo "Generating docker-compose.override.yml"
rm -rf docker-compose.override.yml &>/dev/null
# In sync mode the maps volume must be a local bind instead of the NFS
# volume defined in docker-compose.yml. Written FIRST because the
# demo-upload block at the bottom can exit the script early.
if [[ "${MAPS_MODE:-nfs}" == "sync" ]]; then
printf 'volumes:
  maps:
    driver_opts:
      type: none
      device: ${PWD}/game/nfs/maps/
      o: bind

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
      - maps:/server/nfs/maps/
      - ./game/.q3a/://.q3a/
    restart: always
    environment:
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