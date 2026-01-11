#!/bin/sh

HOST="server1"

SYSLOG="/var/log/syslog"
AUTHLOG="/var/log/auth.log"
KERNLOG="/var/log/kern.log"

STATE_FILE="/tmp/.system_state"
[ ! -f "$STATE_FILE" ] && echo "normal" > "$STATE_FILE"

log()
{
    echo "$(date '+%b %d %H:%M:%S') $HOST $1" >> "$2"
}

while true
do
    sleep $((RANDOM % 25 + 10))

    STATE=$(cat "$STATE_FILE")

    case "$STATE" in
        normal)
            [ $((RANDOM % 5)) -eq 0 ] && \
                log "systemd[1]: Starting Daily apt download activities..." "$SYSLOG"

            [ $((RANDOM % 6)) -eq 0 ] && \
                log "CRON[$$]: (root) CMD (/usr/local/bin/backup.sh)" "$SYSLOG"

            r=$((RANDOM % 100))
            [ "$r" -lt 15 ] && echo "cpu" > "$STATE_FILE"
            [ "$r" -ge 15 ] && [ "$r" -lt 30 ] && echo "memory" > "$STATE_FILE"
            [ "$r" -ge 30 ] && [ "$r" -lt 45 ] && echo "network" > "$STATE_FILE"
            ;;
        cpu)
            log "kernel: CPU0: Core temperature above threshold, cpu clock throttled" "$KERNLOG"
            log "kernel: CPU1: Core temperature above threshold, cpu clock throttled" "$KERNLOG"

            log "systemd[1]: apache2.service: Scheduled restart job, restart counter is at 3." "$SYSLOG"
            log "systemd[1]: apache2.service: Start request repeated too quickly." "$SYSLOG"
            log "systemd[1]: apache2.service: Failed with result 'exit-code'." "$SYSLOG"

            [ $((RANDOM % 100)) -lt 40 ] && echo "normal" > "$STATE_FILE"
            ;;
        memory)
            log "kernel: Out of memory: Kill process 5678 (java) score 102 or sacrifice child" "$KERNLOG"
            log "kernel: Killed process 5678 (java) total-vm:3124000kB, anon-rss:1984000kB, file-rss:0kB" "$KERNLOG"
            log "kernel: Killed process 4444 (python3) total-vm:2048000kB, anon-rss:1024000kB, file-rss:0kB" "$KERNLOG"

            log "systemd[1]: docker.service: Main process exited, code=killed, status=9/KILL" "$SYSLOG"
            log "systemd[1]: docker.service: Failed with result 'signal'." "$SYSLOG"

            log "systemd[1]: Starting PostgreSQL Database Server..." "$SYSLOG"
            log "postgres[877]: FATAL: password authentication failed for user \"postgres\"" "$SYSLOG"
            log "systemd[1]: postgresql.service: Failed with result 'exit-code'." "$SYSLOG"
            log "systemd[1]: postgresql.service: Scheduled restart job, restart counter is at 2." "$SYSLOG"

            [ $((RANDOM % 100)) -lt 35 ] && echo "normal" > "$STATE_FILE"
            ;;
        network)
            IP="192.168.1.$((RANDOM % 255))"
            PORT=$((RANDOM % 60000))

            log "sshd[$$]: Failed password for invalid user admin from $IP port $PORT ssh2" "$AUTHLOG"
            log "sshd[$$]: error: maximum authentication attempts exceeded for invalid user admin from $IP port $PORT ssh2" "$AUTHLOG"

            log "NetworkManager[912]: <warn> dhcp4 (eth0): request timed out" "$SYSLOG"
            log "systemd[1]: NetworkManager.service: Failed with result 'timeout'." "$SYSLOG"
            log "systemd[1]: NetworkManager.service: Scheduled restart job, restart counter is at 1." "$SYSLOG"

            [ $((RANDOM % 100)) -lt 45 ] && echo "normal" > "$STATE_FILE"
            ;;
    esac
done
