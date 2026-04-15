import time
import os
from datetime import datetime
from pymongo import MongoClient



LOG_FILE = "/honeypot-logs/attacker_activity.log"

MONGO_URI = "mongodb+srv://kalaiboaz_db_user:XUV3rthRmubjnuHG@honeypot.nyvgpyd.mongodb.net/"
DB_NAME = "honeypot"
COLLECTION_NAME = "commands"

SESSION_ID = os.getenv("SESSION_ID", f"{os.uname().nodename}-{os.getpid()}")

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
    "cat": "File Access",
    "shadow": "Unauthorized File Access",
    "root": "Privilege Related",
    "ssh_host": "SSH Configuration Access",
    "find / -perm": "SUID Enumeration",
    "getcap": "Capabilities Enumeration",
    "-4000": "SUID Enumeration",
    "-2000": "SGID Enumeration",
}

client = MongoClient(
    MONGO_URI,
    serverSelectionTimeoutMS=2000
)

db = client[DB_NAME]
collection = db[COLLECTION_NAME]



def follow(file):
    file.seek(0, os.SEEK_END)
    while True:
        line = file.readline()
        if not line:
            time.sleep(0.2)
            continue
        yield line.rstrip("\n")


print("[*] command shipper started")

def detect_attack_type(command):
    for pattern, attack_type in ATTACK_PATTERNS.items():
        if pattern in command:
            return attack_type
    return "Unknown"



with open(LOG_FILE, "r") as f:
    for line in follow(f):

        parts = line.split(" ", 1)
        command = parts[1] if len(parts) == 2 else line
        attack_type = detect_attack_type(command)
        doc = {
            "session_id": SESSION_ID,
            "timestamp": datetime.utcnow(),
            "command": command,
            "attack_type": attack_type,
            "raw_line": line
        }

        try:
            collection.insert_one(doc)
        except Exception:
            pass
