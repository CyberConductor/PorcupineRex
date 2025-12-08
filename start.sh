#!/bin/bash

sleep 5

#silence all:
/usr/local/bin/attack_monitor.sh > /dev/null 2>&1 &
/usr/local/bin/detect_bruteforce.sh > /dev/null 2>&1 &

exec su - ho -s /bin/bash
