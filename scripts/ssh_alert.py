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

# --- Config ---
TOKEN = os.getenv("TELEGRAM_TOKEN")
CHAT_ID = os.getenv("TELEGRAM_CHAT_ID", "-1003544348135")
MONGO_URI = os.getenv("MONGO_URI")

BLOCK_THRESHOLD = int(os.getenv("SSH_BLOCK_THRESHOLD", 5))
DEFAULT_BLOCK_TIME = int(os.getenv("SSH_BLOCK_TIME", 600))

# --- Mongo ---
client = MongoClient(MONGO_URI)
DB = client["honeypot"]
BLOCKED_DB = DB["blocked_ips"]

# --- Telegram ---
def send(msg):
    if not TOKEN:
        return
    try:
        requests.post(
            f"https://api.telegram.org/bot{TOKEN}/sendMessage",
            data={"chat_id": CHAT_ID, "text": msg},
            timeout=3
        )
    except Exception:
        pass

# --- Restore blocked IPs on restart ---
def restore_blocks():
    now = int(time.time())
    for entry in BLOCKED_DB.find():
        ip = entry.get("ip")
        expires_at = entry.get("expires_at")

        if not ip or not expires_at:
            continue

        if expires_at <= now:
            BLOCKED_DB.delete_one({"_id": entry["_id"]})
            continue

        if not ip_blocker.is_ip_blocked(ip):
            ip_blocker.block_ip_temporarily(ip, expires_at - now)

restore_blocks()

# --- PAM variables ---
user = os.getenv("PAM_USER", "unknown")
remote = os.getenv("PAM_RHOST", "unknown")
pam_type = os.getenv("PAM_TYPE", "")
now_str = datetime.now().strftime("%Y-%m-%d %H:%M:%S")

if not remote or remote == "unknown":
    exit(0)

# --- Successful login ---
if pam_type == "open_session":

    send(
        f"SSH login detected\n"
        f"User: {user}\n"
        f"From: {remote}\n"
        f"Time: {now_str}"
    )

    upload_dbs_to_mongo.log_ssh_event(
        ip=remote,
        user=user,
        success=True
    )

# --- Failed login ---
else:

    failed_count = upload_dbs_to_mongo.log_ssh_event(
        ip=remote,
        user=user,
        success=False
    )

    if failed_count >= BLOCK_THRESHOLD and not ip_blocker.is_ip_blocked(remote):

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
            f"Bruteforce detected\n"
            f"User: {user}\n"
            f"From: {remote}\n"
            f"Failed attempts: {failed_count}\n"
            f"Blocked for: {DEFAULT_BLOCK_TIME} seconds\n"
            f"Time: {now_str}"
        )