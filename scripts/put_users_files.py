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
import pwd   # מודול מערכת לקריאת מידע על משתמשים בלינוקס

# מיקום קובץ המשתמשים
JSON_FILE = "/usr/local/etc/users.json"

# ספריית home בסיסית
BASE_HOME = "/home"

# מכסה מינימלית ומקסימלית של קבצים למשתמש
MAX_FILES_PER_USER = 15
MIN_FILES_PER_USER = 3

# סיומות קבצים אפשריות
EXTENSIONS = [".txt", ".log", ".dat", ".cfg", ".bak"]


def random_name(min_len=5, max_len=12):
    """
    יוצר שם רנדומלי באורך משתנה.
    משתמש באותיות קטנות בלבד כדי להיראות כמו קבצי מערכת טיפוסיים.
    """
    length = random.randint(min_len, max_len)
    return ''.join(random.choices(string.ascii_lowercase, k=length))


def user_exists(username):
    """
    בודק אם המשתמש קיים באמת במערכת.
    pwd.getpwnam זורק KeyError אם המשתמש לא קיים.
    """
    try:
        pwd.getpwnam(username)
        return True
    except KeyError:
        return False


def create_random_files(user):
    """
    מייצר קבצים רנדומליים למשתמש ספציפי.
    הלוגיקה:
    - קובע כמה קבצים לייצר
    - בכל איטרציה מחליט אם ליצור קובץ רגיל או סדרה ממוספרת
    """

    user_home = os.path.join(BASE_HOME, user)
    target_dir = os.path.join(user_home, "data")

    # יוצר את התיקייה אם לא קיימת
    os.makedirs(target_dir, exist_ok=True)

    # כמה קבצים ליצור למשתמש הזה
    total_files = random.randint(MIN_FILES_PER_USER, MAX_FILES_PER_USER)

    created = 0

    while created < total_files:

        # 30% סיכוי ליצור סדרת קבצים ממוספרת
        # לדוגמה: report1.log, report2.log, report3.log
        if random.random() < 0.3 and (total_files - created) > 1:

            base = random_name()

            # כמה קבצים יהיו בסדרה (2 עד 5, בלי לעבור את המכסה)
            series_count = random.randint(2, min(5, total_files - created))

            for i in range(1, series_count + 1):
                filename = f"{base}{i}{random.choice(EXTENSIONS)}"
                path = os.path.join(target_dir, filename)

                # יצירת קובץ ריק (לא כותבים תוכן)
                open(path, "a").close()

                created += 1

        else:
            # יצירת קובץ בודד עם שם רנדומלי
            name = random_name()
            filename = f"{name}{random.choice(EXTENSIONS)}"
            path = os.path.join(target_dir, filename)

            open(path, "a").close()

            created += 1

    # שינוי בעלות והרשאות כך שהתיקייה שייכת למשתמש בלבד
    # chown משנה בעלות
    # chmod 700 נותן הרשאה רק לבעלים (קריאה, כתיבה והרצה)
    os.system(f"chown -R {user}:{user} {target_dir}")
    os.system(f"chmod 700 {target_dir}")


def main():
    """
    פונקציה ראשית:
    - טוענת את קובץ המשתמשים
    - עוברת על כל המשתמשים
    - מייצרת להם קבצים אם הם קיימים במערכת
    """

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
