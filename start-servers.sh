#!/bin/bash

if [[ $EUID -eq 0 ]]; then
    echo "This script should NOT be run as root !!"
    exit 1
fi

source sv.conf

COUNTER=0
echo "Checking sv.conf for required settings..."
for CONFIGURABLE in SV_BASE_HOSTNAME SV_RCON SV_LOCATION ADMIN_NAME; do
	if [[ "${!CONFIGURABLE}" = "" ]]
	then
		read -p "Enter $CONFIGURABLE: " $CONFIGURABLE
	fi
done
printf "\nServer Hostname: $SV_BASE_HOSTNAME\nAdmin: $ADMIN_NAME\nRcon Password: $SV_RCON\nServer Location: $SV_LOCATION\n\n"

echo "Setting up native server environment..."

currdir=$(pwd)
echo "Starting servers natively..."

for sv_type in mixed cpm vq3 fastcaps teamruns freestyle;do
	i=0
	sv_qty="${sv_type}_count"
	sv_sfx="${sv_type}_sfx"
	while [[ $i -lt "${!sv_qty}" ]]
	do
		# Always come back here
		cd $currdir

		curr_id="rs${SERVER_STARTPORT}"
		i=$(($i+1))
		curr_name="${sv_type}_${i}"
		curr_hostname="${SV_BASE_HOSTNAME} ${!sv_sfx} ${i}"

		echo "Starting server: ${curr_name} on port ${SERVER_STARTPORT}"

		# Create server-specific directory
		mkdir -p ./game/defrag/$curr_name

		# Start the server in background
		export MDD_ENABLED=${MDD_ENABLED}
		export RS_ID=${!curr_id}
		export NAME_ID=${curr_name}
		export SV_TYPE=${sv_type}
		export SV_HOSTNAME="${curr_hostname}"
		export SV_RCON=${SV_RCON}
		export SV_LOCATION=${SV_LOCATION}
		export SV_PORT=${SERVER_STARTPORT}
		export ADMIN_NAME=${ADMIN_NAME}
		export ADMIN_MAIL=${ADMIN_MAIL}
		export ADMIN_DISCORD=${ADMIN_DISCORD}
		export ADMIN_IRC=${ADMIN_IRC}
		export SV_MAPBASE=${SV_MAPBASE}
		export SV_HOMEPAGE=${SV_HOMEPAGE}
		export SV_PRIVATE=${SV_PRIVATE}
		export SV_PASSWORD=${SV_PASSWORD}
		export SV_CONFIG=${sv_type}
		(cd game && screen -mdS "${sv_type}_${i}" ./start.sh)

		SERVER_STARTPORT=$(($SERVER_STARTPORT+1))
	done
done

echo "All servers started! Check server connections with /connect $(hostname -I | cut -d' ' -f1) through a defrag client"