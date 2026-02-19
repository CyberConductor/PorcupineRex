#!/bin/bash

TELEGRAM_TOKEN="8317853350:AAE77Qze7aCIv6oGwXiMQeg7ciWCDSgGbjc"
CHAT_ID="-1003544348135"

send_alert() {
    curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_TOKEN/sendMessage" \
        -d chat_id="$CHAT_ID" \
        -d text="$1" > /dev/null
}

monitor_tty() {
    TTY="$1"

    stdbuf -o0 cat "$TTY" 2>/dev/null | while IFS= read -r line
    do
        echo "$line" >> /honeypot-logs/live_tty.log

        case "$line" in
            *wget*|*curl*|*tftp*|*nc*|*ncat*|*bash*|*sh*|*python*|*perl*|*php*|*busybox*|*base64*|*/tmp/*|*chmod*|*>\ /dev/tcp/*)
                send_alert "Honeypot command: $line"
                ;;
        esac
    done
}

declare -A monitored

while true
do
    for tty in /dev/pts/*
    do
        [[ -e "$tty" ]] || continue
        [[ -n "${monitored[$tty]}" ]] && continue

        monitored[$tty]=1
        monitor_tty "$tty" &
    done

    sleep 1
done
