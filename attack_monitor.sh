#!/bin/bash

LOGFILE="/var/log/attack_monitor.log"

### telegram config ###
TELEGRAM_TOKEN="8317853350:AAE77Qze7aCIv6oGwXiMQeg7ciWCDSgGbjc"
CHAT_ID="7444335759"


send_telegram()
{
    message="$1"
    curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_TOKEN}/sendMessage" \
        -d chat_id="${CHAT_ID}" \
        -d text="${message}" \
        >/dev/null 2>&1
}

log_alert()
{
    msg="$1"
    echo "[ALERT] $(date) $msg" | tee -a "$LOGFILE"
    send_telegram "Attack detected: $msg"
}


###########################################
### wait for command log
###########################################

COMMAND_LOG="/honeypot-logs/commands.log"

while [ ! -f "$COMMAND_LOG" ]; do
    sleep 1
done


###########################################
### background real time command monitor
###########################################

tail -F "$COMMAND_LOG" | while read -r line
do
    # Extract just the command part (everything after the timestamp)
    command=$(echo "$line" | sed 's/^#[0-9]* //')
    
    suspicious_patterns="
su
sudo
chmod
chown
id
whoami
uname
ls
wget
curl
ssh
gcc
python
scp
cat
shadow
root
ssh_host
    "

    for pattern in $suspicious_patterns; do
        if echo "$command" | grep -qw "$pattern"; then
            log_alert "Suspicious command: $command"
            break
        fi
    done
done &


###########################################
### MAIN LOOP FOR SYSTEM RULES
###########################################

while true
do

###########################################
### rule 1, detect new SUID files
###########################################

    find / -type f -perm -4000 -not -path "/proc/*" -not -path "/sys/*" 2>/dev/null > /tmp/suid_scan_new

    if [ ! -f /tmp/suid_scan_old ]; then
        cp /tmp/suid_scan_new /tmp/suid_scan_old
    else
        diff_output=$(diff /tmp/suid_scan_old /tmp/suid_scan_new)
        if [ "$diff_output" != "" ]; then
            log_alert "New SUID files discovered"
            log_alert "$diff_output"
            cp /tmp/suid_scan_new /tmp/suid_scan_old
        fi
    fi


###########################################
### rule 2, detect sudoers modification
###########################################

    if [ ! -f /tmp/sudoers_hash ]; then
        sha256sum /etc/sudoers > /tmp/sudoers_hash
    else
        old_hash=$(cat /tmp/sudoers_hash)
        new_hash=$(sha256sum /etc/sudoers)
        if [ "$old_hash" != "$new_hash" ]; then
            log_alert "/etc/sudoers modified"
            echo "$new_hash" > /tmp/sudoers_hash
        fi
    fi


###########################################
### rule 3, detect new admin user
###########################################

    current_admins=$(getent group sudo wheel 2>/dev/null | awk -F: '{print $4}' | tr ',' '\n' | sort | uniq)

    if [ ! -f /tmp/admin_users_old ]; then
        echo "$current_admins" > /tmp/admin_users_old
    else
        diff_output=$(diff /tmp/admin_users_old <(echo "$current_admins"))
        if [ "$diff_output" != "" ]; then
            log_alert "User added to sudo or wheel group"
            log_alert "$diff_output"
            echo "$current_admins" > /tmp/admin_users_old
        fi
    fi


###########################################
### rule 4, detect unexpected root shell
###########################################

    ps aux | grep "bash" | grep "root" | grep -v "grep" > /tmp/root_shells_new

    if [ ! -f /tmp/root_shells_old ]; then
        cp /tmp/root_shells_new /tmp/root_shells_old
    else
        diff_output=$(diff /tmp/root_shells_old /tmp/root_shells_new)
        if [ "$diff_output" != "" ]; then
            log_alert "Unexpected root shell detected"
            log_alert "$diff_output"
            cp /tmp/root_shells_new /tmp/root_shells_old
        fi
    fi


###########################################
### rule 5, detect cron modifications
###########################################

    for f in /etc/crontab /etc/cron.*/*; do
        if [ -f "$f" ]; then
            hash_file="/tmp/cron_hash_$(echo "$f" | sed 's,/,_,g')"
            current_hash=$(sha256sum "$f")

            if [ ! -f "$hash_file" ]; then
                echo "$current_hash" > "$hash_file"
            else
                old_hash=$(cat "$hash_file")
                if [ "$old_hash" != "$current_hash" ]; then
                    log_alert "Cron file changed, $f"
                    echo "$current_hash" > "$hash_file"
                fi
            fi
        fi
    done

    sleep 5
done


#!/bin/bash

LOGFILE="/var/log/attack_monitor.log"

### telegram config ###
TELEGRAM_TOKEN="8317853350:AAE77Qze7aCIv6oGwXiMQeg7ciWCDSgGbjc"
CHAT_ID="7444335759"

send_alert()
{
    msg="$1"
    curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_TOKEN}/sendMessage" \
        -d chat_id="${CHAT_ID}" \
        -d text="${msg}"
}

# write to log

# LOOP FOREVER
#while true
#do
    #send_alert "Alert 1, system check triggered."
    #send_alert "Alert 2, second notification."
    #send_alert "Alert 3, final test message."

    # Wait 60 seconds before sending again
    #sleep 60
#done
