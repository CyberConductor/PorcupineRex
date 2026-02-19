#!/bin/bash

sleep 5

# start monitoring scripts in background
/usr/local/bin/attack_monitor.sh >/dev/null 2>&1 &
/usr/local/bin/del_detect.sh >/dev/null 2>&1 &
/usr/local/bin/dynamic_vuln.sh >/dev/null 2>&1 &
/usr/local/bin/detect_bruteforce.sh >/dev/null 2>&1 &
/usr/local/bin/liveLog.sh >/dev/null 2>&1 &
python3 /usr/local/bin/upload_attacks.py >/dev/null 2>&1 &

# keep bash alive as PID 1, ignore TERM/INT signals
exec /bin/bash -c "trap : TERM INT; wait"
