#!/bin/bash

JSON_FILE="/usr/local/etc/users.json"

if [ ! -f "$JSON_FILE" ]; then
    echo "json file missing"
    exit 1
fi

mapfile -t users < <(jq -r '.users[]' "$JSON_FILE")

for u in "${users[@]}"
do
    home_dir="/home/$u/private_docs"

    mkdir -p "$home_dir"

    echo "confidential for $u" > "$home_dir/info1.txt"
    echo "Secret is stored here" > "$home_dir/info2.txt"
    echo "restricted data" > "$home_dir/info3.txt"

    chown -R "$u:$u" "$home_dir"
    chmod -R 700 "$home_dir"
done

echo "fake files created"
