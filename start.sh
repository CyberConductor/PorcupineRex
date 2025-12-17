#!/bin/bash

sleep 5

# monitoring scripts
nohup /usr/local/bin/attack_monitor.sh >/dev/null 2>&1 &
nohup /usr/local/bin/detect_bruteforce.sh >/dev/null 2>&1 &

# ftp
/usr/sbin/vsftpd /etc/vsftpd.conf &

# keep bash alive as pid 1
exec /bin/bash -c "trap : TERM INT; while true; do sleep 3600; done"
