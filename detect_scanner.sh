#!/bin/bash

# הגדרות
LOG_FILE="/var/log/auth.log"
BOT_TOKEN="8317853350:AAE77Qze7aCIv6oGwXiMQeg7ciWCDSgGbjc"
CHAT_ID="7444335759"
THRESHOLD=10
TIME_WINDOW=30

STATE_DIR="/var/lib/scanner-detector"
ATTEMPTS_FILE="$STATE_DIR/attempts.db"

if [ "$EUID" -ne 0 ]; then 
    echo "Error: Must run as root"
    exit 1
fi

mkdir -p "$STATE_DIR"
> "$ATTEMPTS_FILE"


send_telegram() {
    local message=$1
    curl -s -X POST "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage" \
        -d "chat_id=${CHAT_ID}" \
        -d "text=${message}" > /dev/null
}


count_attempts() {
    local ip=$1
    local current_time=$(date +%s)
    local count=0
    
    while IFS=':' read -r stored_ip timestamp; do
        if [ "$stored_ip" = "$ip" ] && [ $((current_time - timestamp)) -lt "$TIME_WINDOW" ]; then
            ((count++))
        fi
    done < "$ATTEMPTS_FILE" 2>/dev/null
    
    echo "$count"
}

cleanup_attempts() {
    local current_time=$(date +%s)
    local temp_file="${ATTEMPTS_FILE}.tmp"
    
    while IFS=':' read -r ip timestamp; do
        [ $((current_time - timestamp)) -lt "$TIME_WINDOW" ] && echo "${ip}:${timestamp}" >> "$temp_file"
    done < "$ATTEMPTS_FILE" 2>/dev/null
    
    mv "$temp_file" "$ATTEMPTS_FILE" 2>/dev/null
}

process_line() {
    local line=$1
    local ip=""
    local attack_type=""
    
    if echo "$line" | grep -q "Did not receive identification string"; then
        ip=$(echo "$line" | grep -oP '\d+\.\d+\.\d+\.\d+' | tail -1)
        attack_type="Port Scanner"
    elif echo "$line" | grep -q "Failed password for"; then
        ip=$(echo "$line" | grep -oP 'from \K\d+\.\d+\.\d+\.\d+')
        attack_type="Brute Force"
    elif echo "$line" | grep -q "Invalid user"; then
        ip=$(echo "$line" | grep -oP 'from \K\d+\.\d+\.\d+\.\d+')
        attack_type="Invalid User"
    fi
    
    [ -z "$ip" ] && return
    
    echo "${ip}:$(date +%s)" >> "$ATTEMPTS_FILE"

    local count=$(count_attempts "$ip")
    echo "[ATTEMPT] $ip ($count/$THRESHOLD) - $attack_type"

    if [ "$count" -eq "$THRESHOLD" ]; then
        send_telegram "⚠️ Scanner Alert: IP $ip reached $THRESHOLD attempts ($attack_type)"
        echo "[ALERT SENT] $ip"
    fi

    local lines=$(wc -l < "$ATTEMPTS_FILE")
    [ "$lines" -gt 100 ] && cleanup_attempts
}

cleanup_exit() {
    echo "Shutting down..."
    exit 0
}

trap cleanup_exit SIGINT SIGTERM
echo "Scanner Detector Started"
echo "Threshold: $THRESHOLD attempts in $TIME_WINDOW seconds"

tail -F "$LOG_FILE" 2>/dev/null | while read -r line; do
    process_line "$line"
done