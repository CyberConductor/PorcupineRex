#!/bin/bash

COMMAND_LOG="/honeypot-logs/attacker_activity.log"
PLAN_LOG="/honeypot-logs/vuln_plan.log"
STATE_DB="/honeypot-logs/attacker_state.db"

if [ -f /usr/local/bin/.env ]; then
    set -a
    source /usr/local/bin/.env
    set +a
elif [ -f .env ]; then
    set -a
    source .env
    set +a
fi

if [ -z "$TELEGRAM_TOKEN" ] || [ -z "$TELEGRAM_CHAT_ID" ]; then
    echo "[-] TELEGRAM_TOKEN or TELEGRAM_CHAT_ID not set"
    exit 1
fi

mkdir -p /honeypot-logs
touch "$PLAN_LOG"
touch "$STATE_DB"

log_plan()
{
    msg="$1"
    echo "[PLAN] $(date) $msg" | te
    
    
    
    
    
    
    e -a "$PLAN_LOG"
    
}

send_telegram()
{
    text="$1"
    curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_TOKEN/sendMessage" \
        -d chat_id="$TELEGRAM_CHAT_ID" \
        -d text="$text" > /dev/null
}

update_state()
{
    key="$1"
    echo "$key" >> "$STATE_DB"
}

check_state()
{
    key="$1"
    grep -q "$key" "$STATE_DB"
}

plant_fake_secret()
{
    mkdir -p /opt/backup
    echo "DB_PASSWORD=SuperSecret123!" > /opt/backup/.env
    log_plan "Fake secret deployed"
}

plant_fake_creds()
{
    mkdir -p /var/www/html
    echo "admin:admin123" > /var/www/html/creds.txt
    log_plan "Fake creds deployed"
}

plant_fake_pe()
{
    mkdir -p /usr/local/bin
    echo -e "#!/bin/bash\necho \"permission denied\"" > /usr/local/bin/sys-helper
    chmod 4755 /usr/local/bin/sys-helper
    log_plan "Fake SUID binary deployed"
}

plant_fake_ssh_keys()
{
    mkdir -p /home/ho/.ssh
    echo "ssh-rsa AAAAB3NzaFake attacker@host" > /home/ho/.ssh/id_rsa
    chmod 600 /home/ho/.ssh/id_rsa
    log_plan "Fake SSH key deployed"
}

delayed_action()
{
    sleep $((RANDOM % 10 + 5))
    "$@"
}

handle_command()
{
    cmd="$1"
    raw="$2"

    if [[ "$cmd" =~ ^(ls|whoami|id|uname|pwd)$ ]]; then
        if ! check_state "recon"; then
            update_state "recon"
            send_telegram "Recon activity detected: $raw"
        fi
    fi

    if [[ "$cmd" =~ ^(sudo|su|chmod|chown)$ ]]; then
        if ! check_state "privesc"; then
            update_state "privesc"
            send_telegram "Privilege escalation attempt: $raw"
            delayed_action plant_fake_pe &
        fi
    fi

    if [[ "$raw" =~ (shadow|passwd) ]]; then
        if ! check_state "creds"; then
            update_state "creds"
            send_telegram "Credential access attempt: $raw"
            delayed_action plant_fake_creds &
        fi
    fi

    if [[ "$cmd" =~ ^(wget|curl|nc|bash)$ ]]; then
        if ! check_state "payload"; then
            update_state "payload"
            send_telegram "Payload/download attempt: $raw"
            delayed_action plant_fake_secret &
        fi
    fi

    if [[ "$cmd" =~ ^(ssh|scp)$ ]]; then
        if ! check_state "lateral"; then
            update_state "lateral"
            send_telegram "Lateral movement attempt: $raw"
            delayed_action plant_fake_ssh_keys &
        fi
    fi
}

while [ ! -f "$COMMAND_LOG" ]; do
    sleep 1
done

tail -F "$COMMAND_LOG" | while read -r line
do
    raw=$(echo "$line" | sed 's/^#[0-9]* //')
    cmd=$(echo "$raw" | awk '{print $1}')

    handle_command "$cmd" "$raw"
done