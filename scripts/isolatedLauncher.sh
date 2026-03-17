#!/bin/bash
#/usr/local/bin/trigger-connection.sh
set -euo pipefail

#path to save logs:
LOGDIR="/var/log/honeypot"
mkdir -p "$LOGDIR"
#using recursive command -R in case that there are files in that fath
chown -R ho:sec123 "$LOGDIR" 2>/dev/null || true # user created

timestamp=$(date +%Y%m%d-%H%M%S)
session_id="session-$timestamp-$RANDOM"
logpath="$LOGDIR/$session_id.log"

#docker image to use(linux distro):
IMAGE="ubuntu:latest"

#resource and security limits
MEM_LIMIT="200m"
CPU_SHARES="512"
PIDS_LIMIT="64"

#run container:
container_id=$(docker run -d --rm \
  --name "$session_id" \
  --network none \
  --pids-limit "$PIDS_LIMIT" \
  --memory "$MEM_LIMIT" \
  --cpu-shares "$CPU_SHARES" \
  --read-only \
  --tmpfs /tmp:rw,mode=1777 \
  -v "$LOGDIR":/honeypot-logs:Z \
  --security-opt no-new-privileges \
  --cap-drop ALL \
  "$IMAGE" sleep 3600)

if command -v script >/dev/null 2>&1; then
  docker exec -it "$container_id" sh -lc "apk add --no-cache util-linux >/dev/null 2>&1 || true; script -q -c '/bin/sh' /honeypot-logs/$session_id.typescript" <&0 2>&1 | tee -a "$logpath"
else
  docker exec -i "$container_id" sh -lc '/bin/sh' <&0 2>&1 | tee -a "$logpath"
fi
docker stop "$container_id" >/dev/null 2>&1 || true
echo "session closed, logs: $logpath" >&2
exit 0
