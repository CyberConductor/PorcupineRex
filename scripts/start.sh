#!/bin/bash

sleep 5


/usr/local/bin/attack_monitor.sh >/dev/null 2>&1 &
/usr/local/bin/del_detect.sh >/dev/null 2>&1 &
/usr/local/bin/dynamic_vuln.sh >/dev/null 2>&1 &
/usr/local/bin/detect_bruteforce.sh >/dev/null 2>&1 &
/usr/local/bin/liveLog.sh >/dev/null 2>&1 &
/usr/local/bin/alert_server.sh >/dev/null 2>&1 &
/usr/local/bin/check_awareness.sh >/dev/null 2>&1 &
python3 /usr/local/bin/upload_attacks.py >/dev/null 2>&1 &


exec /bin/bash
