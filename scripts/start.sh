#!/bin/bash

sleep 5

# --- start monitoring scripts in background ---
nohup /usr/local/bin/attack_monitor.sh >/dev/null 2>&1 &
nohup /usr/local/bin/del_detect.sh >/dev/null 2>&1 &
nohup /usr/local/bin/dynamic_vuln.sh >/dev/null 2>&1 &
nohup /usr/local/bin/detect_bruteforce.sh >/dev/null 2>&1 &
nohup /usr/local/bin/liveLog.sh >/dev/null 2>&1 &

# --- start python uploader ---
nohup python3 /usr/local/bin/upload_attacks.py >/dev/null 2>&1 &

# --- start FTP server ---
/usr/sbin/vsftpd /etc/vsftpd.conf &

# --- keep bash alive as PID 1 ---
exec /bin/bash -c "trap : TERM INT; while true; do sleep 3600; done"
