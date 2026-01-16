#!/bin/bash

sleep 5

# start monitoring scripts in background
nohup /usr/local/bin/attack_monitor.sh >/dev/null 2>&1 &
nohup /usr/local/bin/detect_bruteforce.sh >/dev/null 2>&1 &

# drop attacker into shell, must be last
exec /bin/bash


# start FTP
/usr/sbin/vsftpd /etc/vsftpd.conf &

# start SSH
exec /usr/sbin/sshd -D
