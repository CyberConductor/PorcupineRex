#!/bin/bash

JSON_FILE="/usr/local/etc/users.json"

if [ ! -f "$JSON_FILE" ]; then
    echo "json file not found"
    exit 1
fi

# read users from json
mapfile -t users < <(jq -r '.users[]' "$JSON_FILE")

for u in "${users[@]}"
do
    useradd -m "$u" 2>/dev/null
    echo "$u:Password123" | chpasswd
done

echo "users created from json"
