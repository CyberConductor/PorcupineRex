#!/bin/bash

# timestamp for log file naming
timestamp=$(date +%Y%m%d_%H%M%S)

# directory for storing session logs on the host
LOG_DIR="/var/honeypot-session-logs"
mkdir -p "$LOG_DIR"

# record SSH client IP
client_ip="$SSH_CONNECTION"
echo "$timestamp Login from: $client_ip" >> "$LOG_DIR/connection.log"

# launch the docker honeypot and record full session
docker run -it --rm \
    -v "$LOG_DIR":/session-logs \
    ubuntu_honeypot_image \
    /usr/bin/script -q -f "/session-logs/session_$timestamp.txt" /bin/bash

exit 0
