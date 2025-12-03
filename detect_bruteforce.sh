#!/bin/bash

LOG_FILE="/var/log/auth.log"
BOT_TOKEN="8317853350:AAHD_Hhh6MvkTK2iJVlQxDhVQY1yj2qcVl8"
CHAT_ID="7444335759"
THRESHOLD=2 # for each 30 seconds

echo "Bruteforce detector started"

# continuously monitor auth.log
tail -F "$LOGFILE" | while read line
do
    # check for failed password attempts
    if echo "$line" | grep -q "Failed password"
    then
        ip=$(echo "$line" | awk '{print $11}')

        # count failures from this IP in last 30 seconds
        count=$(grep "Failed password" "$LOGFILE" | grep "$ip" | tail -n 20 | wc -l)

        if [ "$count" -gt "$THRESHOLD" ]
        then
            curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" \
            -d "chat_id=$CHAT_ID" \
            -d "text=Bruteforce detected from IP $ip, $count failed attempts."

            echo "Alert sent for IP $ip"
        fi
    fi
done