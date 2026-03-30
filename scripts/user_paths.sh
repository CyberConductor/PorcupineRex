#!/bin/bash

last_dir="$PWD"

echo "Starting directory tracker..."
echo "Current: $last_dir"

while true
do
    if [ "$PWD" != "$last_dir" ]; then
        echo "User moved to: $PWD"
        last_dir="$PWD"
    fi
    sleep 1
done
