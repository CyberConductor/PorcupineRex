#!/bin/bash
LOG=/var/log/system/cache.log
CACHE_DIR=/var/cache/app

mkdir -p "$CACHE_DIR"

BEFORE=$(du -s "$CACHE_DIR" 2>/dev/null | awk '{print $1}')

find "$CACHE_DIR" -type f -mtime +7 -delete

AFTER=$(du -s "$CACHE_DIR" 2>/dev/null | awk '{print $1}')

echo "$(date '+%Y-%m-%d %H:%M:%S') cleaned cache: before=${BEFORE}KB after=${AFTER}KB" >> "$LOG"
