#!/bin/bash

# start monitoring scripts
/usr/local/bin/attack_monitor.sh &
/usr/local/bin/detect_bruteforce.sh &

# start ftp
/usr/sbin/vsftpd /etc/vsftpd.conf &

# start ssh daemon (foreground)
/usr/sbin/sshd -D
