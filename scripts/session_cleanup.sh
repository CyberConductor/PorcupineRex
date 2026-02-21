#!/bin/sh

if [ -d /tmp ]; then
#מוחק קבצים ישנים בתיקיית /tmp שגילם מעל 90 דקות
  find /tmp -type f -mmin +90 -delete 2>/dev/null
fi
