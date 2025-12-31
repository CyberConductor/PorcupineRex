import os
import csv
import datetime
from pymongo import MongoClient

# --- MongoDB config ---
MONGO_URI = "mongodb+srv://kalaiboaz_db_user:XUV3rthRmubjnuHG@honeypot.nyvgpyd.mongodb.net/"
client = MongoClient(MONGO_URI)

db = client["honeypot"]
hackers_col = db["hackers"]

# --- paths ---
LOG_DIR = "/var/log/attack_monitor.log"


def parse_timestamp(ts_str):
    # example: "20250101_153012"
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
