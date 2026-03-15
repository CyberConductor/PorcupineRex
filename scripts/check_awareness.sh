#!/bin/bash
#!/bin/bash

#log file that stores executed commands
LOG_FILE="/var/log/attack_monitor.log"

#max score before alerting about honeypot detection
SCORE_LIMIT=5

score=0

#honeypot detection commands and their score weight
declare -A rules
rules["/\.dockerenv"]=3
rules["/proc/1/cgroup"]=3
rules["docker"]=2
rules["lscpu"]=1
rules["lsmod"]=1
rules["dmidecode"]=2
rules["ps aux"]=1
rules["uname -a"]=1
rules["mount"]=1
rules["netstat"]=1

echo "[*] monitoring honeypot log..."

tail -F "$LOG_FILE" | while read line
do
    for rule in "${!rules[@]}"
    do
        if [[ "$line" =~ $rule ]]
        then
            points=${rules[$rule]}
            score=$((score + points))

            echo "[!] suspicious command detected: $line"
            echo "[!] +$points score, current score: $score"

            if [ "$score" -ge "$SCORE_LIMIT" ]
            then
                echo "[!!!] attacker likely detected honeypot"
            fi
        fi
    done
done