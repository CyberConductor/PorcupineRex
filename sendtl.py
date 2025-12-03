#!/usr/bin/env python3

import requests
import os
from datetime import datetime, timedelta
import json


ATTEMPTS = 0
TOKEN = "8317853350:AAHD_Hhh6MvkTK2iJVlQxDhVQY1yj2qcVl8"
CHAT_ID = "7444335759"
def send(msg):
    try:
        requests.post(
            f"https://api.telegram.org/bot{TOKEN}/sendMessage",
            data={"chat_id": CHAT_ID, "text": msg}
        )
    except:
        pass

user = os.getenv("PAM_USER", "unknown")
remote = os.getenv("PAM_RHOST", "unknown")
pam_type = os.getenv("PAM_TYPE", "")
now = datetime.now().strftime("%Y %m %d, %H:%M:%S")

# Successful login
if pam_type == "open_session":
    send(f"SSH login detected.\nUser: {user}\nFrom: {remote}\nTime: {now}")

# Failed attempts come as pam_type == "auth"
else:
    attempts +=1

if (attempts == 5):
    send(f"Bruteforce attack detected!\nUser: {user}\nFrom: {remote}\nTime: {now}")
    attempts = 0