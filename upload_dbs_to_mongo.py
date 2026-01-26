import os
import csv
import datetime
from pymongo import MongoClient
import datetime

MONGO_URI = "mongodb+srv://kalaiboaz_db_user:XUV3rthRmubjnuHG@honeypot.nyvgpyd.mongodb.net/"
client = MongoClient(MONGO_URI)

db = client["honeypot"]
hackers_col = db["hackers"]

LOG_DIR = "/var/log/auth.log"


def parse_timestamp(ts_str):
    return datetime.datetime.strptime(ts_str, "%Y%m%d_%H%M%S")


def Upload_or_Insert_Hacker(ip):
    hacker = hackers_col.find_one({"ip": ip})
    if hacker:
        return hacker["_id"]

    result = hackers_col.insert_one({
        "ip": ip,
        "first_seen": datetime.datetime.utcnow(),
        "sessions": []
    })
    return result.inserted_id


def process_csv_file(csv_path):
    with open(csv_path, newline="", encoding="utf-8", errors="ignore") as f:
        reader = csv.DictReader(f)
        row = next(reader)

    ip = row["ip"]
    session_time = parse_timestamp(row["session_timestamp"])
    session_content = row["session"]

    hacker_id = Upload_or_Insert_Hacker(ip)

    hackers_col.update_one(
        {"_id": hacker_id},
        {
            "$push": {
                "sessions": {
                    "time": session_time,
                    "session": session_content
                }
            }
        }
    )



def log_ssh_event(ip, user, success):
    hacker = hackers_col.find_one({"ip": ip})

    if not hacker:
        hacker_id = hackers_col.insert_one({
            "ip": ip,
            "first_seen": datetime.datetime.utcnow(),
            "sessions": [],
            "failed_attempts": 0
        }).inserted_id
    else:
        hacker_id = hacker["_id"]

    event = {
        "time": datetime.datetime.utcnow(),
        "user": user,
        "success": success
    }

    update = {"$push": {"sessions": event}}

    if not success:
        update["$inc"] = {"failed_attempts": 1}

    hackers_col.update_one(
        {"_id": hacker_id},
        update
    )

    return hackers_col.find_one({"_id": hacker_id})["failed_attempts"]



def main():
    if not os.path.isdir(LOG_DIR):
        return

    for filename in os.listdir(LOG_DIR):
        if not filename.endswith(".csv"):
            continue

        file_path = os.path.join(LOG_DIR, filename)
        if not os.path.isfile(file_path):
            continue

        try:
            process_csv_file(file_path)
            os.remove(file_path)  # delete only after successful upload
        except Exception as e:
            pass


if __name__ == "__main__":
    main()
