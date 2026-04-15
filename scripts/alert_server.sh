#!/bin/bash

#Add this file in data/alerts.txt with the IPs or hostnames of the alert servers:
ALERT_SERVERS="alerts.txt"


LOG_FILE="/var/log/attack_monitor.log"
RISK_SCORE=0
THRESHOLD=8

#Choose mode: "ssh" or "http"
MODE="ssh"

echo "[*] monitoring attacker behaviour..."

mapfile -t SERVERS < "$ALERT_SERVERS"

tail -F "$LOG_FILE" | while read line
do
    if [[ "$line" =~ whoami|id|uname|ps\ aux|pwd ]]; then
        RISK_SCORE=$((RISK_SCORE + 1))
        echo "[info] reconnaissance detected"
    fi

    if [[ "$line" =~ ifconfig|ip\ a|netstat|ss\ -tulpn ]]; then
        RISK_SCORE=$((RISK_SCORE + 2))
        echo "[info] network probing detected"
    fi

    if [[ "$line" =~ sudo\ -l|find\ /.*-perm|getcap ]]; then
        RISK_SCORE=$((RISK_SCORE + 3))
        echo "[info] privilege escalation attempt"
    fi

    if [[ "$line" =~ wget|curl|scp ]]; then
        RISK_SCORE=$((RISK_SCORE + 4))
        echo "[warning] payload download attempt"
    fi

    if [[ "$line" =~ chmod\ \+x|\./|bash\ .*\.sh ]]; then
        RISK_SCORE=$((RISK_SCORE + 5))
        echo "[danger] payload execution attempt"
    fi

    echo "[score] current risk score: $RISK_SCORE"

    if [ "$RISK_SCORE" -ge "$THRESHOLD" ]; then
        echo "[!!!] attacker likely preparing an attack"

        for SERVER in "${SERVERS[@]}"; do
            if [ "$MODE" = "ssh" ]; then
                #SSH option (requires keys set up)
                ssh -i /home/ho/.ssh/id_rsa -o StrictHostKeyChecking=no "$SERVER" "echo '[ALERT] Attack detected on $(hostname) at $(date)' >> /tmp/alerts.log" &
            else
                #HTTP POST option (requires listener)
                curl -s -X POST "http://$SERVER:5000/alert" \
                     -d "host=$(hostname)&time=$(date)&score=$RISK_SCORE" &
            fi
        done

        RISK_SCORE=0
    fi
done