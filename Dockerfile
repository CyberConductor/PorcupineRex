 use a small base image
FROM alpine:3.19

#create a non-root user and a honeypot logs dir
RUN addgroup -g 1000 honeypot \
 && adduser -u 1000 -G honeypot -D -h /home/honeypot honeypot \
 && mkdir -p /honeypot-logs \
 && chown honeypot:honeypot /honeypot-logs
RUN apk add --no-cache util-linux
#set working directory and set user to non-root
WORKDIR /home/honeypot
USER honeypot

#keeps the container running
ENTRYPOINT [ "sleep", "3600" ]