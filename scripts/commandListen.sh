#!/bin/bash

# timestamp for log file naming
timestamp=$(date +%Y%m%d_%H%M%S)

# directory for storing session logs on the host
LOG_DIR="/var/honeypot-session-logs"
mkdir -p "$LOG_DIR"

# extract client IP (first field in SSH_CONNECTION)
client_ip=$(echo "$SSH_CONNECTION" | awk '{print $1}')

# final csv file (one session per file)
CSV_FILE="$LOG_DIR/$session_${timestamp}.csv"

# run honeypot container and capture full session to variable
session_content=$(
docker run -it --rm \
    -v "$LOG_DIR":/session-logs \
    ubuntu_honeypot_image \
    /usr/bin/script -q -f /dev/stdout /bin/bash
)

# escape quotes and newlines for csv
session_content=$(printf "%s" "$session_content" \
    | sed 's/"/""/g' \
    | awk '{printf "%s\\n", $0}')

# write CSV
{
    echo 'ip,session_timestamp,session'
    echo "\"$client_ip\",\"$timestamp\",\"$session_content\""
} > "$CSV_FILE"

exit 0
