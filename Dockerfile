FROM ubuntu:latest

# התקן את הכלים הדרושים
RUN apt-get update && apt-get install -y --no-install-recommends \
    adduser \
    sudo \
 && rm -rf /var/lib/apt/lists/*

# צור קבוצה ומשתמש לא root והכן תיקיית logs
RUN addgroup --gid 2000 honeypot \
 && adduser --uid 2000 --ingroup honeypot --home /home/honeypot --disabled-password --gecos "" honeypot \
 && mkdir -p /honeypot-logs \
 && chown honeypot:honeypot /honeypot-logs

WORKDIR /home/honeypot
USER honeypot

# שומר את הקונטיינר רץ
ENTRYPOINT ["sleep", "3600"]
