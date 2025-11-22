FROM ubuntu:latest

<<<<<<< HEAD
#create honeypot user and logs directory
RUN groupadd honeypot \
 && useradd -m -g honeypot -d /home/honeypot honeypot \
 && mkdir -p /honeypot-logs \
 && chown honeypot:honeypot /honeypot-logs

#create user ho to match the ssh username
RUN useradd -m ho \
 && mkdir -p /home/ho \
 && chown -R ho:ho /home/ho

#install small tools
RUN apt-get update \
 && apt-get install -y --no-install-recommends util-linux \
 && rm -rf /var/lib/apt/lists/*

#set default working directory and user
WORKDIR /home/ho
USER ho

CMD [ "/bin/bash" ]
=======
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
>>>>>>> 78ef928a0d937801cf24e8679052405bd86f7c1b
