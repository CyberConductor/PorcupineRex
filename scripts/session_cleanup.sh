#!/bin/sh

if [ -d /tmp ]; then
  find /tmp -type f -mmin +90 -delete 2>/dev/null
fi
