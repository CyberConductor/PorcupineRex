#!/usr/bin/env python3


#should be saved in /usr/local/bin/sendtl.py
import requests
import os
from datetime import datetime, timedelta
import json
from dotenv import load_dotenv

ATTEMPTS = 0
load_dotenv()

TOKEN = os.getenv("TELEGRAM_TOKEN")
CHAT_ID = "-1003544348135"
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

#
if pam_type == "open_session":
    send(f"SSH login detected.\nUser: {user}\nFrom: {remote}\nTime: {now}")

#failed 
else:
    attempts +=1

if (attempts == 5):
    send(f"Bruteforce attack detected!\nUser: {user}\nFrom: {remote}\nTime: {now}")
    attempts = 0