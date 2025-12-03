#!/bin/sh

LOGFILE="/var/log/attack_monitor.log"

### telegram config ###
TELEGRAM_TOKEN="YOUR_BOT_TOKEN"
CHAT_ID="YOUR_CHAT_ID"

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
    send_telegram "Attack detected
Type: $msg"
}


###############################################
### rule 1:detect new SUID files
###############################################

find / -type f -perm -4000 -not -path "/proc/*" -not -path "/sys/*" 2>/dev/null > /tmp/suid_scan_new

if [ ! -f /tmp/suid_scan_old ]; then
    cp /tmp/suid_scan_new /tmp/suid_scan_old
else
    diff_output=$(diff /tmp/suid_scan_old /tmp/suid_scan_new)
    if [ "$diff_output" != "" ]; then
        log_alert "New SUID files discovered, possible privilege escalation"
        log_alert "$diff_output"
        cp /tmp/suid_scan_new /tmp/suid_scan_old
    fi
fi


###############################################
### rule 2:detect sudoers modification 
###############################################

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


###############################################
### rule 3:detect new admin user
###############################################

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


###############################################
### rule 4:detect unexpected root shell
###############################################

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


###############################################
### rule 5:detect cron modifications
###############################################

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


###############################################
### rule 6:detect su attempts
###############################################

grep "su:" /var/log/auth.log | grep -v "session opened" > /tmp/su_attempts_new 2>/dev/null

if [ ! -f /tmp/su_attempts_old ]; then
    cp /tmp/su_attempts_new /tmp/su_attempts_old
else
    diff_output=$(diff /tmp/su_attempts_old /tmp/su_attempts_new)
    if [ "$diff_output" != "" ]; then
        log_alert "Suspicious su attempt detected"
        log_alert "$diff_output"
        cp /tmp/su_attempts_new /tmp/su_attempts_old
    fi
fi


###############################################
### rule 7:detect unallowed files
###############################################

COMMAND_LOG="/honeypot-logs/commands.log"

if [ -f "$COMMAND_LOG" ]; then

    suspicious_files="
/etc/shadow
/root
/etc/ssh/ssh_host
"

    for file in $suspicious_files; do
        if grep -q "cat $file" "$COMMAND_LOG" 2>/dev/null; then
            log_alert "User attempted to read a restricted file, $file"
        fi
    done

fi


###############################################
### rule 8:analyse suspicious commands in honeypot
###############################################

if [ -f "$COMMAND_LOG" ]; then

    suspicious_patterns="
su
sudo
chmod 4000
chown root
id
whoami
uname -a
ls /
ls /root
wget
curl
ssh
gcc
python
scp
"

    for pattern in $suspicious_patterns; do
        if grep -q "$pattern" "$COMMAND_LOG" 2>/dev/null; then
            log_alert "Suspicious command detected from honeypot, command contained pattern, $pattern"
        fi
    done

fi

exit 0
