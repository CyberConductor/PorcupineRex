import os
import requests
import time
from pymongo import MongoClient
from dotenv import load_dotenv
import ip_info

load_dotenv()

BOT_TOKEN = os.getenv("TELEGRAM_TOKEN")
BASE_URL = f"https://api.telegram.org/bot{BOT_TOKEN}"

MONGO_URI = os.getenv("MONGO_URI")
client = MongoClient(MONGO_URI)

DB = client["honeypot"]
INFO_DB = DB["hackers"]
COMMANDS_DB = DB["commands"]
BLOCKED_DB = DB["blocked_ips"]


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
        hackers = INFO_DB.find().sort("first_seen", -1).limit(5)
        msgs = [format_hacker(h) for h in hackers]

        if not msgs:
            send_message(chat_id, "No attackers found")
        else:
            send_message(chat_id, "\n\n".join(msgs))

    elif text.startswith("/attacker "):
        ip = text.split(" ", 1)[1]
        h = INFO_DB.find_one({"ip": ip})

        if not h:
            send_message(chat_id, f"No result for {ip}")
            return

        send_message(chat_id, format_hacker(h))

        try:
            result = ip_info.ip_details(ip)
            geo_msg = (
                f"IP: {result.get('query','N/A')}\n"
                f"Country: {result.get('country','N/A')}\n"
                f"City: {result.get('city','N/A')}\n"
                f"ISP: {result.get('isp','N/A')}\n"
                f"Latitude: {result.get('lat','N/A')}\n"
                f"Longitude: {result.get('lon','N/A')}"
            )
            send_message(chat_id, geo_msg)
        except Exception:
            send_message(chat_id, "Failed to retrieve IP details")

    elif text == "/attacks":
        pipeline = [
            {"$group": {"_id": "$attack_type", "count": {"$sum": 1}}},
            {"$sort": {"count": -1}}
        ]

        results = list(INFO_DB.aggregate(pipeline))

        if not results:
            send_message(chat_id, "No attacks recorded yet")
            return

        msg_lines = ["Attack statistics:\n"]
        for r in results:
            attack_type = r["_id"] if r["_id"] else "unknown"
            msg_lines.append(f"{attack_type}: {r['count']}")

        send_message(chat_id, "\n".join(msg_lines))

    elif text == "/commands":
        docs = list(COMMANDS_DB.find().sort("timestamp", 1))

        if not docs:
            send_message(chat_id, "No commands found")
            return

        for doc in docs:
            msg = (
                f"Session: {doc.get('session_id')}\n"
                f"Command: {doc.get('command')}\n"
                f"Time: {doc.get('timestamp')}"
            )
            send_message(chat_id, msg)

    elif text.startswith("/block "):
        ip = text.split(" ", 1)[1]
        now = int(time.time())
        block_duration = 600

        BLOCKED_DB.update_one(
            {"ip": ip},
            {"$set": {
                "ip": ip,
                "added_at": now,
                "expires_at": now + block_duration,
                "source": "telegram"
            }},
            upsert=True
        )

        send_message(chat_id, f"IP {ip} blocked for {block_duration//60} minutes")

    elif text.startswith("/unblock "):
        ip = text.split(" ", 1)[1]
        BLOCKED_DB.delete_one({"ip": ip})
        send_message(chat_id, f"IP {ip} removed from block list")

    elif text == "/blocklist":
        now = int(time.time())
        blocked_ips = list(BLOCKED_DB.find({"expires_at": {"$gt": now}}))

        if not blocked_ips:
            send_message(chat_id, "No IPs are currently blocked")
            return

        msg_lines = ["Currently blocked IPs:\n"]
        for entry in blocked_ips:
            expires_in = entry["expires_at"] - now
            msg_lines.append(f"{entry['ip']} (expires in {expires_in//60} minutes)")

        send_message(chat_id, "\n".join(msg_lines))

    elif text == "/help":
        help_text = (
            "/attackers\n"
            "/attacker <IP>\n"
            "/attacks\n"
            "/commands\n"
            "/block <IP>\n"
            "/unblock <IP>\n"
            "/blocklist"
        )
        send_message(chat_id, help_text)

    else:
        send_message(chat_id, "Unknown command. Use /help")


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
