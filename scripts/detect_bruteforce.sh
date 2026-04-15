#!/bin/bash

LOG_FILE="/var/log/auth.log"
BOT_TOKEN="8317853350:AAE77Qze7aCIv6oGwXiMQeg7ciWCDSgGbjc"
CHAT_ID="-1003544348135"
THRESHOLD=2
WINDOW=30

echo "Bruteforce detector started"

# make sure log exists
touch "$LOG_FILE"

tail -F "$LOG_FILE" | while read -r line
do
    if echo "$line" | grep -q "Failed password"
    then
        ip=$(echo "$line" | awk '{print $11}')

        # count recent failures from this IP
        count=$(grep "Failed password" "$LOG_FILE" | grep "$ip" | tail -n 20 | wc -l)

        if [ "$count" -gt "$THRESHOLD" ]
        then
            curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" \
                -d "chat_id=$CHAT_ID" \
                -d "text=Bruteforce detected from IP $ip, $count failed attempts in short time."

            echo "$(date) alert sent for $ip" >> /var/log/attack_monitor.log
        fi
    fi
done
