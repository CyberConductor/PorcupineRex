import csv
from pymongo import MongoClient
from datetime import datetime

def ip_to_int(ip):
    parts = ip.split(".")
    if len(parts) != 4:
        raise ValueError("Invalid IP: " + ip)
    total = 0
    for i, part in enumerate(parts):
        octet = int(part)
        if octet < 0 or octet > 255:
            raise ValueError("Invalid octet in IP: " + ip)
        total += octet << (8 * (3 - i))
    return total

def int_to_ip(num):
    return ".".join(str((num >> (8 * i)) & 0xFF) for i in reversed(range(4)))

def ip_in_range(ip, start_ip, end_ip):
    ip_num = ip_to_int(ip)
    return ip_to_int(start_ip) <= ip_num <= ip_to_int(end_ip)

def load_ip_ranges(file_path, fields):
    ranges = []
    with open(file_path, newline="") as f:
        reader = csv.DictReader(f)
        for row in reader:
            ranges.append({
                "start": ip_to_int(row["start_ip"]),
                "end": ip_to_int(row["end_ip"]),
                **{k: row[k] for k in fields}
            })
    return ranges

def load_ip_set(file_path):
    with open(file_path) as f:
        return set(line.strip() for line in f if line.strip())

def enrich_ip(ip, sessions, asn_db, vpn_db, tor_set):
    ip_num = ip_to_int(ip)

    asn_info = next((r for r in asn_db if r["start"] <= ip_num <= r["end"]), None)
    vpn_info = next((r for r in vpn_db if r["start"] <= ip_num <= r["end"]), None)

    return {
        "ip": ip,
        "asn": asn_info["asn"] if asn_info else None,
        "org": asn_info["org"] if asn_info else None,
        "country": asn_info["country"] if asn_info else None,
        #"is_tor": ip in tor_set,
        "is_vpn": vpn_info["type"] == "VPN" if vpn_info else False,
        #"is_proxy": vpn_info["type"] == "Proxy" if vpn_info else False,
        "provider": vpn_info["provider"] if vpn_info else None,
        "sessions": sessions
    }

def time_score(ip_a_sessions, ip_b_sessions, window_hours=24):
    score = 0
    for s_a in ip_a_sessions:
        t_a = s_a.get("time")
        if not t_a:
            continue
        for s_b in ip_b_sessions:
            t_b = s_b.get("time")
            if not t_b:
                continue
            delta_hours = abs((t_a - t_b).total_seconds()) / 3600
            if delta_hours <= window_hours:
                score += 20
                break
    return score

def connection_score(a, b, window_hours=24):
    score = 0
    if a["asn"] and a["asn"] == b["asn"]:
        score += 40
    if a["org"] and a["org"] == b["org"]:
        score += 20
    if a["country"] and a["country"] == b["country"]:
        score += 10
    #if a["is_tor"] and b["is_tor"]:
        #score += 50
    #if a["is_vpn"] and b["is_vpn"]:
        #score += 30
    if a["provider"] and a["provider"] == b["provider"]:
        score += 20

    score += time_score(a.get("sessions", []), b.get("sessions", []), window_hours)
    return score

def detect_connections(hackers_list, asn_db, vpn_db, tor_set, threshold=60, window_hours=24):
    enriched_ips = []
    for h in hackers_list:
        ip = h["ip"]
        sessions = h.get("sessions", [])
        enriched_ips.append(enrich_ip(ip, sessions, asn_db, vpn_db, tor_set))

    connections = []
    for i in range(len(enriched_ips)):
        for j in range(i + 1, len(enriched_ips)):
            score = connection_score(enriched_ips[i], enriched_ips[j], window_hours)
            if score >= threshold:
                connections.append({
                    "ip_a": enriched_ips[i]["ip"],
                    "ip_b": enriched_ips[j]["ip"],
                    "score": score
                })
    return connections

def main():
    MONGO_URI = "mongodb+srv://kalaiboaz_db_user:XUV3rthRmubjnuHG@honeypot.nyvgpyd.mongodb.net/"
    client = MongoClient(MONGO_URI)
    db = client["honeypot"]
    hackers_col = db["hackers"]

    hackers_list = list(hackers_col.find({}, {"ip": 1, "sessions": 1}))

    vpn_db = load_ip_ranges("ProxyList_db.csv", ["type", "provider"])

    connections = detect_connections(hackers_list, vpn_db, threshold=60, window_hours=24)

    for c in connections:
        print(f"{c['ip_a']} <--> {c['ip_b']}  | score: {c['score']}")

if __name__ == "__main__":
    main()
