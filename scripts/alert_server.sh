#!/bin/bash

LOG_FILE="/var/log/attack_monitor.log"

risk_score=0
threshold=8

echo "[*] monitoring attacker behaviour..."

tail -F "$LOG_FILE" | while read line
do

    #recon commands
    if [[ "$line" =~ whoami|id|uname|ps\ aux|pwd ]]
    then
        risk_score=$((risk_score + 1))
        echo "[info] reconnaissance detected"
    fi

    #network discovery
    if [[ "$line" =~ ifconfig|ip\ a|netstat|ss\ -tulpn ]]
    then
        risk_score=$((risk_score + 2))
        echo "[info] network probing detected"
    fi

    #privilege escalation checks
    if [[ "$line" =~ sudo\ -l|find\ /.*-perm|getcap ]]
    then
        risk_score=$((risk_score + 3))
        echo "[info] privilege escalation attempt"
    fi

    #download payload
    if [[ "$line" =~ wget|curl|scp ]]
    then
        risk_score=$((risk_score + 4))
        echo "[warning] payload download attempt"
    fi

    #execution attempts
    if [[ "$line" =~ chmod\ \+x|\./|bash\ .*\.sh ]]
    then
        risk_score=$((risk_score + 5))
        echo "[danger] payload execution attempt"
    fi

    echo "[score] current risk score: $risk_score"

    if [ "$risk_score" -ge "$threshold" ]
    then
        echo "[!!!] attacker likely preparing an attack"
    fi

done