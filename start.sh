#!/bin/bash

sleep 5
#monitoring scripts:
nohup /usr/local/bin/attack_monitor.sh >/dev/null 2>&1 &
nohup /usr/local/bin/detect_bruteforce.sh >/dev/null 2>&1 &

/usr/sbin/vsftpd /etc/vsftpd.conf &

#shell:
exec /bin/bash
