FROM ubuntu:latest

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
