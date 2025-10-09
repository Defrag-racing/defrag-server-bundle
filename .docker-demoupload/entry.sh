#!/bin/bash

echo "Setup backup cron job with cron expression DEMO_SFTP_CRONTAB: ${DEMO_SFTP_CRONTAB}"

echo "${DEMO_SFTP_CRONTAB} /bin/backup" > /etc/crontabs/root

# Make sure the file exists before we start tail
touch /var/log/cron.log

# Make at least ONE backup at start.
/bin/backup

# start the cron deamon
crond -f -l 2 -L /dev/sdtout

#exec "$@"

#/bin/backup