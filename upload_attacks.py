import time
import os
from datetime import datetime
from pymongo import MongoClient



LOG_FILE = "/honeypot-logs/attacker_activity.log"

MONGO_URI = "mongodb+srv://kalaiboaz_db_user:XUV3rthRmubjnuHG@honeypot.nyvgpyd.mongodb.net/"
DB_NAME = "honeypot"
COLLECTION_NAME = "commands"

SESSION_ID = os.getenv("SESSION_ID", f"{os.uname().nodename}-{os.getpid()}")



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

with open(LOG_FILE, "r") as f:
    for line in follow(f):

        parts = line.split(" ", 1)
        command = parts[1] if len(parts) == 2 else line

        doc = {
            "session_id": SESSION_ID,
            "timestamp": datetime.utcnow(),
            "command": command,
            "raw_line": line
        }

        try:
            collection.insert_one(doc)
        except Exception:
            pass
