from datetime import datetime
from pymongo import MongoClient
import os
import time

MONGO_URI = "mongodb+srv://kalaiboaz_db_user:XUV3rthRmubjnuHG@honeypot.nyvgpyd.mongodb.net/"
DB_NAME = "honeypot"
COLLECTION_NAME = "commands"

LOG_FILE = "/honeypot-logs/attacker_activity.log"

SESSION_ID = os.getenv("SESSION_ID", "live-session")

ATTACK_PATTERNS = {
    "su": "Privilege Escalation",
    "sudo": "Privilege Escalation",
    "chmod": "Privilege Escalation Attempt",
    "chown": "Privilege Escalation Attempt",
    "id": "System Info",
    "whoami": "User Info",
    "uname": "System Info",
    "ls": "Files Lookup",
    "wget": "Suspicious Download",
    "curl": "Suspicious Download",
    "ssh": "Lateral Movement",
    "gcc": "Compilation Activity",
    "python": "Script Execution",
    "scp": "File Transfer",
    "cat /etc/shadow": "Unauthorized File Access",
    "find / -perm -4000": "SUID Enumeration",
    "getcap -r /": "Capabilities Enumeration",
}

client = MongoClient(MONGO_URI)
db = client[DB_NAME]
collection = db[COLLECTION_NAME]


def detect_attack_type(command):
    for pattern, attack_type in ATTACK_PATTERNS.items():
        if pattern in command:
            return attack_type
    return "Unknown"


def process_line(line):
    line = line.strip()
    if not line:
        return

    attack_type = detect_attack_type(line)

    doc = {
        "session_id": SESSION_ID,
        "timestamp": datetime.utcnow(),
        "command": line,
        "attack_type": attack_type,
        "raw_line": line
    }

    collection.insert_one(doc)
    print(f"[+] Uploaded: {line} | Type: {attack_type}")


def monitor_log():
    print("[*] Monitoring log file...")

    while not os.path.exists(LOG_FILE):
        time.sleep(1)

    with open(LOG_FILE, "r") as f:
        f.seek(0, os.SEEK_END) 

        while True:
            line = f.readline()
            if not line:
                time.sleep(0.5)
                continue

            process_line(line)


if __name__ == "__main__":
    monitor_log()