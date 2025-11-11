 use a small base image
FROM ubuntu:latest

#create a non-root user and a honeypot logs dir
RUN addgroup -g 1000 honeypot \
 && adduser -u 1000 -G honeypot -D -h /home/honeypot honeypot \
 && mkdir -p /honeypot-logs \
 && chown honeypot:honeypot /honeypot-logs
RUN apt-get update && apt-get install -y --no-install-recommends util-linux \
 && rm -rf /var/lib/apt/lists/*
#set working directory and set user to non-root
WORKDIR /home/honeypot
USER honeypot

#keeps the container running
ENTRYPOINT [ "sleep", "3600" ]