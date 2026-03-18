#!/bin/bash

# path to the attacker log
LOG_FILE="/honeypot-logs/attacker_activity.log"

# file containing alert server addresses (IP or hostname)
ALERT_SERVERS="/usr/local/bin/alerts.txt"

# risk scoring
risk_score=0
threshold=8

echo "[*] monitoring attacker behaviour..."

mapfile -t servers < "$ALERT_SERVERS"

while IFS= read -r line
do
    if [[ "$line" =~ whoami|id|uname|ps\ aux|pwd ]]; then
        ((risk_score++))
        echo "[info] reconnaissance detected"
    fi

    if [[ "$line" =~ ifconfig|ip\ a|netstat|ss\ -tulpn ]]; then
        ((risk_score+=2))
        echo "[info] network probing detected"
    fi

    #privilege escalation attempts
    if [[ "$line" =~ sudo\ -l|find\ /.*-perm|getcap ]]; then
        ((risk_score+=3))
        echo "[info] privilege escalation attempt"
    fi

    if [[ "$line" =~ wget|curl|scp ]]; then
        ((risk_score+=4))
        echo "[warning] payload download attempt"
    fi

    if [[ "$line" =~ chmod\ \+x|\./|bash\ .*\.sh ]]; then
        ((risk_score+=5))
        echo "[danger] payload execution attempt"
    fi

    echo "[score] current risk score: $risk_score"
    if [ "$risk_score" -ge "$threshold" ]; then
        echo "[!!!] attacker likely preparing an attack, sending alerts..."

        for server in "${servers[@]}"; do
            curl -s -X POST "http://$server:5000/alert" \
                -d "host=$(hostname)&time=$(date +'%Y-%m-%d %H:%M:%S')&score=$risk_score" &
        done

        #reset risk score after alert
        risk_score=0
    fi

#read log
done < <(tail -F "$LOG_FILE")