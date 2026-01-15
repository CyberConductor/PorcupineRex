#!/bin/bash

sleep 5



# Start monitoring scripts (already executable from Dockerfile)
nohup /usr/local/bin/attack_monitor.sh >/dev/null 2>&1 &

# Start FTP
/usr/sbin/vsftpd /etc/vsftpd.conf &

# Keep container alive
exec /bin/bash -c "trap : TERM INT; while true; do sleep 3600; done"