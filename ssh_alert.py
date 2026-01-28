#!/usr/bin/env python3
import os
import time
import requests
from datetime import datetime
from pymongo import MongoClient
from dotenv import load_dotenv
import ip_blocker
import upload_dbs_to_mongo

load_dotenv()

# MongoDB
MONGO_URI = os.getenv("MONGO_URI")
client = MongoClient(MONGO_URI)
DB = client["honeypot"]
BLOCKED_DB = DB["blocked_ips"]

# Telegram
TOKEN = os.getenv("TELEGRAM_TOKEN")
CHAT_ID = "-1003544348135"

BLOCK_COUNT = 5
DEFAULT_BLOCK_TIME = 500  # fallback duration in seconds

def send(msg):
    try:
        requests.post(
            f"https://api.telegram.org/bot{TOKEN}/sendMessage",
            data={"chat_id": CHAT_ID, "text": msg},
            timeout=3
        )
    except:
        pass

def block_from_db():
    now = int(time.time())
    for entry in list(BLOCKED_DB.find()):
        ip = entry["ip"]
        expires_at = entry.get("expires_at", now + DEFAULT_BLOCK_TIME)

        # skip expired
        if expires_at <= now:
            BLOCKED_DB.delete_one({"_id": entry["_id"]})
            continue

        # block if not already
        if not ip_blocker.is_ip_blocked(ip):
            duration = expires_at - now
            ip_blocker.block_ip_temporarily(ip, duration)

# Run this at start to block all queued IPs
block_from_db()

# --- SSH alert environment variables ---
user = os.getenv("PAM_USER", "unknown")
remote = os.getenv("PAM_RHOST", "unknown")
pam_type = os.getenv("PAM_TYPE", "")
now_str = datetime.now().strftime("%Y-%m-%d %H:%M:%S")

if pam_type == "open_session":
    send(
        f"SSH login detected\nUser: {user}\nFrom: {remote}\nTime: {now_str}"
    )

    upload_dbs_to_mongo.log_ssh_event(ip=remote, user=user, success=True)

else:
    failed_count = upload_dbs_to_mongo.log_ssh_event(ip=remote, user=user, success=False)

    # automatic block after bruteforce
    if failed_count >= BLOCK_COUNT and not ip_blocker.is_ip_blocked(remote):
        ip_blocker.block_ip_temporarily(remote, DEFAULT_BLOCK_TIME)
        BLOCKED_DB.update_one(
            {"ip": remote},
            {"$set": {
                "ip": remote,
                "added_at": int(time.time()),
                "expires_at": int(time.time()) + DEFAULT_BLOCK_TIME,
                "source": "ssh_alert"
            }},
            upsert=True
        )
        send(
            f"Bruteforce detected\nUser: {user} From {remote} blocked\nFailed attempts: {failed_count}\nTime: {now_str}"
        )
