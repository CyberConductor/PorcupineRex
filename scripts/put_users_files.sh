#!/bin/bash

JSON_FILE="/usr/local/etc/users.json"

if [ ! -f "$JSON_FILE" ]; then
    echo "json file not found"
    exit 1
fi

mapfile -t users < <(jq -r '.users[]' "$JSON_FILE")

#create fake files per user
for u in "${users[@]}"
do
    HOME_DIR="/home/$u"

    if [ -d "$HOME_DIR" ]; then
        echo "planting files for $u"

        #create realistic folders
        mkdir -p "$HOME_DIR/Documents"
        mkdir -p "$HOME_DIR/Downloads"
        mkdir -p "$HOME_DIR/Desktop"
        mkdir -p "$HOME_DIR/.ssh"

        echo "username: $u" > "$HOME_DIR/Documents/credentials.txt"
        echo "password: $(openssl rand -hex 6)" >> "$HOME_DIR/Documents/credentials.txt"

        echo "Important finance report" > "$HOME_DIR/Documents/finance_report.txt"
        echo "confidential" > "$HOME_DIR/Desktop/notes.txt"

        echo "-----BEGIN RSA PRIVATE KEY-----" > "$HOME_DIR/.ssh/id_rsa"
        echo "$(openssl rand -base64 32)" >> "$HOME_DIR/.ssh/id_rsa"
        echo "-----END RSA PRIVATE KEY-----" >> "$HOME_DIR/.ssh/id_rsa"

        head -c $((RANDOM % 4096)) /dev/urandom > "$HOME_DIR/Downloads/random.bin"

        chown -R "$u":"$u" "$HOME_DIR"
    fi
done

echo "fake data planted"