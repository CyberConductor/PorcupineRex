import os
import csv
import datetime
from pymongo import MongoClient, ASCENDING
from dotenv import load_dotenv

HALF_DAY = 33200
load_dotenv()

MONGO_URI = os.getenv("MONGO_URI")
if not MONGO_URI:
    raise ValueError("MONGO_URI is not set")

LOG_DIR = os.getenv("HONEYPOT_LOG_DIR", "./honeypot_sessions")

client = MongoClient(MONGO_URI)
db = client["honeypot"]
hackers_col = db["hackers"]
hackers_col.create_index([("ip", ASCENDING)], unique=True)


def parse_timestamp(ts_str):
    try:
        return datetime.datetime.strptime(ts_str, "%Y%m%d_%H%M%S")
    except Exception:
        return datetime.datetime.utcnow()


def get_or_create_hacker(ip):
    hacker = hackers_col.find_one({"ip": ip})
    if hacker:
        return hacker["_id"]

    result = hackers_col.insert_one({
        "ip": ip,
        "first_seen": datetime.datetime.utcnow(),
        "failed_attempts": 0,
        "sessions": []
    })
    return result.inserted_id


def process_csv_file(csv_path):
    with open(csv_path, newline="", encoding="utf-8", errors="ignore") as f:
        reader = csv.DictReader(f)
        row = next(reader, None)

    if not row:
        print(f"[WARN] Empty CSV: {csv_path}")
        return

    ip = row.get("ip")
    session_timestamp = row.get("session_timestamp")
    session_content = row.get("session")

    if not ip or not session_timestamp:
        print(f"[WARN] Invalid row in {csv_path}")
        return

    session_time = parse_timestamp(session_timestamp)
    hacker_id = get_or_create_hacker(ip)

    event = {
        "type": "full_session",
        "time": session_time,
        "data": {
            "session": session_content
        }
    }

    hackers_col.update_one(
        {"_id": hacker_id},
        {"$push": {"sessions": event}}
    )

    print(f"[OK] Uploaded session from {ip}")



def log_ssh_event(ip, user, success):
    hacker_id = get_or_create_hacker(ip)
    now = int(time.time())

    hacker = hackers_col.find_one({"_id": hacker_id})
    failed_attempts = hacker.get("failed_attempts", 0)
    last_failed_at = hacker.get("last_failed_at", 0)

    if last_failed_at and (now - last_failed_at > HALF_DAY):
        failed_attempts = 0

    event = {
        "type": "ssh_attempt",
        "time": datetime.datetime.utcnow(),
        "data": {
            "user": user,
            "success": success
        }
    }

    update = {
        "$push": {"sessions": event}
    }

    if success:
        update["$set"] = {
            "failed_attempts": 0,
            "last_failed_at": None
        }
        hackers_col.update_one({"_id": hacker_id}, update)
        return 0

    else:
        failed_attempts += 1

        update["$set"] = {
            "failed_attempts": failed_attempts,
            "last_failed_at": now
        }

        hackers_col.update_one({"_id": hacker_id}, update)
        return failed_attempts

def main():
    if not os.path.isdir(LOG_DIR):
        print(f"[ERROR] Directory not found: {LOG_DIR}")
        return

    for filename in os.listdir(LOG_DIR):
        if not filename.endswith(".csv"):
            continue

        file_path = os.path.join(LOG_DIR, filename)
        if not os.path.isfile(file_path):
            continue

        try:
            process_csv_file(file_path)
            os.remove(file_path)
        except Exception as e:
            print(f"[ERROR] Failed processing {file_path}: {e}")


if __name__ == "__main__":
    main()
