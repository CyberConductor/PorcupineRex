#!/bin/bash

LOGFILE="/var/log/attack_monitor.log"
LAST_ALERT_FILE="/tmp/last_root_alert"

if [ -f /usr/local/bin/.env ]; then
    source /usr/local/bin/.env
elif [ -f .env ]; then
    export $(grep -v '^#' .env | xargs)
fi

CHAT_ID="-1003544348135"

send_telegram()
{
    local message="$1"
    curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_TOKEN}/sendMessage" \
        -d chat_id="${TELEGRAM_CHAT_ID}" \
        -d text="${message}" \
        >/dev/null 2>&1
}

log_alert()
{
    local msg="$1"
    echo "[ALERT] $(date) $msg" | tee -a "$LOGFILE"
    send_telegram "Attack detected:\n$msg"
}


COMMAND_LOG="/honeypot-logs/attacker_activity.log"

while [ ! -f "$COMMAND_LOG" ]; do
    sleep 1
done


declare -A categories=(
    ["su"]="Privilege Escalation"
    ["sudo"]="Privilege Escalation"
    ["chmod"]="Privilege Escalation Attempt"
    ["chown"]="Privilege Escalation Attempt"
    ["id"]="System Info"
    ["whoami"]="User Info"
    ["uname"]="System Info"
    ["ls"]="Files Lookup"
    ["cat"]="File Access"
    ["shadow"]="Unauthorized File Access"
    ["wget"]="Suspicious Download"
    ["curl"]="Suspicious Download"
    ["scp"]="File Transfer"
    ["ssh"]="Lateral Movement"
    ["gcc"]="Compilation Activity"
    ["python"]="Script Execution"
    ["getcap"]="Capabilities Enumeration"
    ["-4000"]="SUID Enumeration"
    ["-2000"]="SGID Enumeration"
)


tail -F "$COMMAND_LOG" | while read -r line
do
    [[ -z "$line" ]] && continue
    [[ "$line" =~ ^# ]] && continue

    command="$line"

    #category based detection
    for pattern in "${!categories[@]}"
    do
        if echo "$command" | grep -qw "$pattern"; then
            log_alert "Suspicious command detected
Type: ${categories[$pattern]}
Command: $command"
            break
        fi
    done

    #PATH hijacking detection
    if echo "$command" | grep -Eq '(^| )export PATH=|PATH=.*:|PATH=/tmp'; then
        log_alert "Possible PATH hijacking attempt
Command: $command"
    fi

    if echo "$command" | grep -Eq 'LD_PRELOAD|LD_LIBRARY_PATH'; then
        log_alert "SUID environment abuse detected (LD_*)
Command: $command"
    fi

done &


while true
do


    find / -type f -perm -4000 \
        -not -path "/proc/*" \
        -not -path "/sys/*" \
        -not -path "/dev/*" 2>/dev/null > /tmp/suid_scan_new

    if [ ! -f /tmp/suid_scan_old ]; then
        cp /tmp/suid_scan_new /tmp/suid_scan_old
    else
        diff_output=$(diff /tmp/suid_scan_old /tmp/suid_scan_new)
        if [ -n "$diff_output" ]; then
            log_alert "New SUID files discovered
$diff_output"
            cp /tmp/suid_scan_new /tmp/suid_scan_old
        fi
    fi


    current_hash=$(sha256sum /etc/sudoers)

    if [ ! -f /tmp/sudoers_hash ]; then
        echo "$current_hash" > /tmp/sudoers_hash
    else
        old_hash=$(cat /tmp/sudoers_hash)
        if [ "$old_hash" != "$current_hash" ]; then
            log_alert "/etc/sudoers modified"
            echo "$current_hash" > /tmp/sudoers_hash
        fi
    fi


    current_admins=$(getent group sudo wheel 2>/dev/null |
        awk -F: '{print $4}' |
        tr ',' '\n' |
        sort -u)

    if [ ! -f /tmp/admin_users_old ]; then
        echo "$current_admins" > /tmp/admin_users_old
    else
        diff_output=$(diff /tmp/admin_users_old <(echo "$current_admins"))
        if [ -n "$diff_output" ]; then
            log_alert "User added to sudo or wheel group
$diff_output"
            echo "$current_admins" > /tmp/admin_users_old
        fi
    fi

    ps -eo pid,user,cmd | awk '
    $2=="root" &&
    $3 ~ /bash/ &&
    $1 != 1 &&
    $3 !~ /(sshd|vsftpd|start.sh)/
    ' > /tmp/root_shells_new

    if [ ! -f /tmp/root_shells_old ]; then
        cp /tmp/root_shells_new /tmp/root_shells_old
    else
        diff_output=$(diff /tmp/root_shells_old /tmp/root_shells_new)
        if [ -n "$diff_output" ]; then
            now=$(date +%s)
            last=$(cat "$LAST_ALERT_FILE" 2>/dev/null || echo 0)

            if [ $((now - last)) -gt 30 ]; then
                log_alert "Unexpected root shell detected
$diff_output"
                echo "$now" > "$LAST_ALERT_FILE"
            fi
            cp /tmp/root_shells_new /tmp/root_shells_old
        fi
    fi

    for f in /etc/crontab /etc/cron.*/*; do
        [ ! -f "$f" ] && continue

        hash_file="/tmp/cron_hash_$(echo "$f" | sed 's,/,_,g')"
        current_hash=$(sha256sum "$f")

        if [ ! -f "$hash_file" ]; then
            echo "$current_hash" > "$hash_file"
        else
            old_hash=$(cat "$hash_file")
            if [ "$old_hash" != "$current_hash" ]; then
                log_alert "Cron file changed: $f"
                echo "$current_hash" > "$hash_file"
            fi
        fi
    done

    sleep 5
done
