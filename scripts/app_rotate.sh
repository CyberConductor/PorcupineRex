#!/bin/sh

LOG=/var/log/app.log
MAX_SIZE=1048576    # 1 MB
MAX_BACKUPS=5       # כמה עותקים לשמור

# אם הקובץ לא קיים, יוצאים
[ -f "$LOG" ] || exit 0

# בודקים את הגודל
SIZE=$(stat -c%s "$LOG")
if [ "$SIZE" -le "$MAX_SIZE" ]; then
    exit 0
fi

# מעבירים את העותקים הקיימים אחורה
i=$MAX_BACKUPS
while [ $i -gt 0 ]; do
    PREV=$((i - 1))
    if [ $PREV -eq 0 ]; then
        FILE="$LOG"
    else
        FILE="$LOG.$PREV"
    fi

    if [ -f "$FILE" ]; then
        mv -f "$FILE" "$LOG.$i"
    fi
    i=$PREV
done

# יוצרים קובץ לוג חדש
touch "$LOG"
