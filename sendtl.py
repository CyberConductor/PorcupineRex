#!/usr/bin/env python3

import requests
import os
from datetime import datetime

TOKEN = "8317853350:AAHD_Hhh6MvkTK2iJVlQxDhVQY1yj2qcVl8"
CHAT_ID = "7444335759"

user = os.getenv("PAM_USER", "unknown")
remote_host = os.getenv("PAM_RHOST", "unknown")
time_now = datetime.now().strftime("%Y %m %d, %H:%M:%S")

message = f"SSH login detected.\nUser: {user}\nFrom: {remote_host}\nTime: {time_now}"

url = f"https://api.telegram.org/bot{TOKEN}/sendMessage"
data = {"chat_id": CHAT_ID, "text": message}

try:
    requests.post(url, data=data)
except Exception as e:
    pass