#!/usr/bin/env python3
# saved as /usr/local/bin/sendtl.py

import requests
import os
from datetime import datetime
from dotenv import load_dotenv
import upload_dbs_to_mongo

load_dotenv()

TOKEN = os.getenv("TELEGRAM_TOKEN")
CHAT_ID = "-1003544348135"

def send(msg):
    try:
        requests.post(
            f"https://api.telegram.org/bot{TOKEN}/sendMessage",
            data={"chat_id": CHAT_ID, "text": msg},
            timeout=3
        )
    except:
        pass

user = os.getenv("PAM_USER", "unknown")
remote = os.getenv("PAM_RHOST", "unknown")
pam_type = os.getenv("PAM_TYPE", "")
now = datetime.now().strftime("%Y-%m-%d %H:%M:%S")

if pam_type == "open_session":
    send(
        f"SSH login detected\n"
        f"User: {user}\n"
        f"From: {remote}\n"
        f"Time: {now}"
    )

    upload_dbs_to_mongo.log_ssh_event(
        ip=remote,
        user=user,
        success=True
    )

else:
    failed_count = upload_dbs_to_mongo.log_ssh_event(
        ip=remote,
        user=user,
        success=False
    )

    if failed_count >= 5:
        send(
            f"Bruteforce attack detected\n"
            f"User: {user}\n"
            f"From: {remote}\n"
            f"Failed attempts: {failed_count}\n"
            f"Time: {now}"
        )
