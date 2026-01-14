import os
import requests
import time
from pymongo import MongoClient
import datetime
from dotenv import load_dotenv
import ip_info

load_dotenv()

BOT_TOKEN = os.getenv("TELEGRAM_TOKEN")
BASE_URL = f"https://api.telegram.org/bot{BOT_TOKEN}"

MONGO_URI = os.getenv("MONGO_URI")
client = MongoClient(MONGO_URI)
db = client["honeypot"]
hackers_col = db["hackers"]


def get_updates(offset=None):
    params = {"timeout": 30}
    if offset is not None:
        params["offset"] = offset

    r = requests.get(f"{BASE_URL}/getUpdates", params=params, timeout=10)
    return r.json()

def send_message(chat_id, text):
    payload = {
        "chat_id": chat_id,
        "text": text
    }
    requests.post(f"{BASE_URL}/sendMessage", json=payload, timeout=10)



def format_hacker(h):
    last_session = h["sessions"][-1] if h.get("sessions") else None

    msg = (
        f"IP: {h['ip']}\n"
        f"First seen: {h.get('first_seen')}\n"
        f"Failed attempts: {h.get('failed_attempts', 0)}"
    )

    if last_session:
        msg += (
            f"\nLast user: {last_session.get('user')}"
            f"\nLast success: {last_session.get('success')}"
            f"\nLast time: {last_session.get('time')}"
        )

    return msg


def handle_message(message):
    chat_id = message["chat"]["id"]
    text = message.get("text", "").strip()

    if text == "/attackers":
        hackers = hackers_col.find().sort("first_seen", -1).limit(5)

        msgs = []
        for h in hackers:
            msgs.append(format_hacker(h))

        if not msgs:
            send_message(chat_id, "No attackers found")
        else:
            send_message(chat_id, "\n\n".join(msgs))

    elif text.startswith("/attacker "):
        ip = text.split(" ", 1)[1]
        h = hackers_col.find_one({"ip": ip})
        ip_info.ip_details(ip)
        if not h:
            send_message(chat_id, f"No result for {ip}")
        else:
            send_message(chat_id, format_hacker(h))
            result = ip_info.ip_details(ip)
            print("IP:", result["query"])
            print("Country:", result["country"])
            print("City:", result["city"])
            print("ISP:", result["isp"])
            print("Latitude:", result["lat"])
            print("Longitude:", result["lon"])

    else:
        send_message(chat_id, "Unknown command")

def main():
    offset = None

    while True:
        updates = get_updates(offset)

        if updates.get("ok"):
            for update in updates.get("result", []):
                offset = update["update_id"] + 1

                if "message" in update:
                    handle_message(update["message"])

        time.sleep(1)

if __name__ == "__main__":
    main()
