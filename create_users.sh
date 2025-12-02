#!/bin/bash

JSON_FILE="/usr/local/etc/users.json"

if [ ! -f "$JSON_FILE" ]; then
    echo "json file not found"
    exit 1
fi

#read users from json
mapfile -t users < <(jq -r '.users[]' "$JSON_FILE")

for u in "${users[@]}"
do
    #create user with home directory and bash shell
    useradd -m -s /bin/bash "$u" 2>/dev/null

    #set default password
    echo "$u:Password123" | chpasswd

    mkdir -p /home/"$u"
    chown -R "$u":"$u" /home/"$u"

    #create a default .bashrc if missing
    if [ ! -f "/home/$u/.bashrc" ]; then
        cp /etc/skel/.bashrc /home/"$u"/.bashrc
        chown "$u":"$u" /home/"$u"/.bashrc
    fi

    #set prompt to user@host:dir$
    echo 'PS1="\u@\h:\w$ "' >> /home/"$u"/.bashrc

done

echo "users created successfully"
