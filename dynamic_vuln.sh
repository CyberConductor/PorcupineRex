#!/bin/bash

COMMAND_LOG="/honeypot-logs/attacker_activity.log"
PLAN_LOG="/honeypot-logs/vuln_plan.log"

mkdir -p /honeypot-logs
touch "$PLAN_LOG"

log_plan()
{
    msg="$1"
    echo "[PLAN] $(date) $msg" | tee -a "$PLAN_LOG"
}

plant_fake_secret()
{
    mkdir -p /opt/backup
    echo "DB_PASSWORD=SuperSecret123!" > /opt/backup/.env
    log_plan "Planted fake secret file in /opt/backup/.env"
}

plant_fake_creds()
{
    mkdir -p /var/www/html
    echo "admin:admin123" > /var/www/html/creds.txt
    log_plan "Planted fake credential file in web root"
}

plant_fake_pe()
{
    mkdir -p /usr/local/bin
    echo -e "#!/bin/bash\necho \"permission denied\"" > /usr/local/bin/sys-helper
    chmod 4755 /usr/local/bin/sys-helper
    log_plan "Planted fake SUID binary /usr/local/bin/sys-helper"
}

plant_fake_kernel_vuln()
{
    echo "Linux version 5.4.0-vuln" > /etc/fake_kernel_version
    log_plan "Planted fake vulnerable kernel fingerprint"
}

plant_fake_ssh_keys()
{
    mkdir -p /home/ho/.ssh
    echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDfakekey attacker@host" > /home/ho/.ssh/id_rsa
    chmod 600 /home/ho/.ssh/id_rsa
    log_plan "Planted fake SSH private key"
}

handle_command()
{
    cmd="$1"

    case "$cmd" in
        ls|find|cat)
            plant_fake_secret
            ;;
        shadow|passwd)
            plant_fake_creds
            ;;
        su|sudo|chmod|chown)
            plant_fake_pe
            ;;
        getcap|-4000|-2000)
            plant_fake_pe
            ;;
        uname|id|whoami)
            plant_fake_kernel_vuln
            ;;
        wget|curl)
            log_plan "Attacker attempting payload fetch, prepare fake writable service"
            ;;
        ssh|scp)
            plant_fake_ssh_keys
            ;;
        *)
            ;;
    esac
}

while [ ! -f "$COMMAND_LOG" ]; do
    sleep 1
done

tail -F "$COMMAND_LOG" | while read -r line
do
    raw=$(echo "$line" | sed 's/^#[0-9]* //')
    cmd=$(echo "$raw" | awk '{print $1}')
    handle_command "$cmd"
done
