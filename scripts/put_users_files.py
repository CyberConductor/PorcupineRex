#!/usr/bin/env python3

"""
הסקריפט:
- קורא רשימת משתמשים מתוך users.json
- בודק שהמשתמשים קיימים במערכת
- יוצר לכל משתמש תיקיית data בתוך ה-home שלו
- מייצר כמות רנדומלית של קבצים ריקים
- לפעמים יוצר סדרות ממוספרות (file1, file2, file3...)
- שומר הרשאות מתאימות כך שרק המשתמש יוכל לגשת לתיקייה
"""

import os
import json
import random
import string
import pwd 

JSON_FILE = "/usr/local/etc/users.json"

BASE_HOME = "/home"

MAX_FILES_PER_USER = 15
MIN_FILES_PER_USER = 3

EXTENSIONS = [".txt", ".log", ".dat", ".cfg", ".bak"]


def random_name(min_len=5, max_len=12):
    length = random.randint(min_len, max_len)
    return ''.join(random.choices(string.ascii_lowercase, k=length))


def user_exists(username):
    try:
        pwd.getpwnam(username)
        return True
    except KeyError:
        return False


def create_random_files(user):
    user_home = os.path.join(BASE_HOME, user)
    target_dir = os.path.join(user_home, "data")

    os.makedirs(target_dir, exist_ok=True)

    total_files = random.randint(MIN_FILES_PER_USER, MAX_FILES_PER_USER)

    created = 0

    while created < total_files:

        if random.random() < 0.3 and (total_files - created) > 1:

            base = random_name()

            series_count = random.randint(2, min(5, total_files - created))

            for i in range(1, series_count + 1):
                filename = f"{base}{i}{random.choice(EXTENSIONS)}"
                path = os.path.join(target_dir, filename)

                open(path, "a").close()

                created += 1

        else:
            name = random_name()
            filename = f"{name}{random.choice(EXTENSIONS)}"
            path = os.path.join(target_dir, filename)

            open(path, "a").close()

            created += 1

    os.system(f"chown -R {user}:{user} {target_dir}")
    os.system(f"chmod 700 {target_dir}")


def main():

    if not os.path.isfile(JSON_FILE):
        print("users.json not found")
        return

    with open(JSON_FILE) as f:
        data = json.load(f)

    users = data.get("users", [])

    for user in users:
        if user_exists(user):
            create_random_files(user)

    print("user files created")


if __name__ == "__main__":
    main()
