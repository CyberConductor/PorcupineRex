from datetime import datetime
from pymongo import MongoClient
import os
import time
import dotenv
dotenv.load_dotenv()

MONGO_URI = os.getenv("MONGO_URI")
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

#categorize severity(1-low, 10-high)
SEVERITY_MAP = {
    "Privilege Escalation": 9,
    "Privilege Escalation Attempt": 7,
    "System Info": 2,
    "User Info": 1,
    "Files Lookup": 3,
    "Suspicious Download": 6,
    "Lateral Movement": 8,
    "Compilation Activity": 4,
    "Script Execution": 5,
    "File Transfer": 6,
    "Unauthorized File Access": 10,
    "SUID Enumeration": 7,
    "Capabilities Enumeration": 6,
    "Unknown": 1,
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
    severity = SEVERITY_MAP.get(attack_type, 1)  # default to 1 if unknown

    doc = {
        "session_id": SESSION_ID,
        "timestamp": datetime.utcnow(),
        "command": line,
        "attack_type": attack_type,
        "severity": severity,
        "raw_line": line
    }

    collection.insert_one(doc)
    print(f"[+] Uploaded: {line} | Type: {attack_type} | Severity: {severity}")


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