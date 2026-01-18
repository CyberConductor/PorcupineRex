#!/bin/bash

sleep 5

# =========================
# background sensors
# =========================

/usr/local/bin/attack_monitor.sh >/dev/null 2>&1 &
/usr/local/bin/detect_bruteforce.sh >/dev/null 2>&1 &
python3 /usr/local/bin/upload_attacks.py >/dev/null 2>&1 &


exec /bin/bash
