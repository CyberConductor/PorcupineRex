#!/bin/bash

# 1. Start required system services
echo "Starting rsyslog and openssh-server..."
service rsyslog start
service ssh start

# 2. Start monitoring scripts robustly in the background
# We explicitly invoke the interpreter and use 'disown' to ensure the jobs 
# are not tied to the current shell, making them safe from the 'exec' command.

/bin/bash /usr/local/bin/attack_monitor.sh >/var/log/attack_monitor.log 2>&1 &
PROCESS_PID=$! # Get the PID of the last background command
disown $PROCESS_PID

/bin/bash /usr/local/bin/detect_bruteforce.sh >/var/log/bruteforce.log 2>&1 &
PROCESS_PID=$!
disown $PROCESS_PID

echo "Background monitors launched and disowned. Dropping to 'ho' shell."

# 3. Replace the current process with the user shell (PID 1 is replaced)
exec su - ho -s /bin/bash