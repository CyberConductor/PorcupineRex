FROM ubuntu:latest

# install required tools
RUN apt-get update \
 && apt-get install -y openssh-server rsyslog curl ca-certificates jq sudo vsftpd libpam0g \
 && mkdir /var/run/sshd

# create honeypot user and logs directory
RUN groupadd honeypot \
 && useradd -m -g honeypot -d /home/honeypot -s /bin/bash honeypot

# create user ho for SSH login
RUN useradd -m -s /bin/bash ho \
 && mkdir -p /home/ho \
 && chown -R ho:ho /home/ho

#honeypot logs directory
RUN mkdir -p /honeypot-logs \
 && touch /honeypot-logs/attacker_activity.log \
 && chown root:root /honeypot-logs \
 && chmod 755 /honeypot-logs \
 && chown ho:ho /honeypot-logs/attacker_activity.log \
 && chmod 644 /honeypot-logs/attacker_activity.log

 #attack monitor log file
RUN touch /var/log/attack_monitor.log \
 && chmod 644 /var/log/attack_monitor.log

# configure bash history logging for ho
# configure bash history logging for ho
RUN cp /etc/skel/.bashrc /home/ho/.bashrc \
 && cp /etc/skel/.profile /home/ho/.profile \
 && echo 'shopt -s histappend' >> /home/ho/.bashrc \
 && echo 'export HISTSIZE=50000' >> /home/ho/.bashrc \
 && echo 'export HISTFILESIZE=50000' >> /home/ho/.bashrc \
 && echo 'export PROMPT_COMMAND='\''history 1 | sed "s/^ *[0-9]\+ *//" >> /honeypot-logs/attacker_activity.log'\''' >> /home/ho/.bashrc \
 && chown ho:ho /home/ho/.bashrc /home/ho/.profile

# copy JSON and scripts
COPY users.json /usr/local/etc/users.json
COPY create_users.sh /usr/local/bin/create_users.sh
COPY put_users_files.sh /usr/local/bin/put_users_files.sh
COPY attack_monitor.sh /usr/local/bin/attack_monitor.sh
COPY .env /usr/local/bin/.env
COPY start.sh /start.sh
COPY vsftpd.conf /etc/vsftpd.conf
COPY errors.log /usr/local/share/errors.log
COPY inject_errors.sh /usr/local/bin/inject_errors.sh


# ensure PAM directory and vsftpd PAM config exist
RUN mkdir -p /etc/pam.d \
 && echo "auth    required pam_unix.so" > /etc/pam.d/vsftpd \
 && echo "account required pam_unix.so" >> /etc/pam.d/vsftpd
# make scripts executable
RUN chmod +x /usr/local/bin/create_users.sh \
 && chmod +x /usr/local/bin/put_users_files.sh \
 && chmod +x /usr/local/bin/attack_monitor.sh \
 && chmod +x /usr/local/bin/inject_errors.sh \
 && chmod +x start.sh

# run user creation and place fake files
RUN /usr/local/bin/create_users.sh \
 && /usr/local/bin/put_users_files.sh

 RUN chown -R root:root /usr/local/bin \
 && chmod 750 /usr/local/bin \
 && chmod 600 /usr/local/bin/.env
# working directory
WORKDIR /home/ho

# entrypoint script to start background scripts and drop into ho
ENTRYPOINT ["/start.sh"]

# save the hacker info
RUN cat <<'EOF' >> /home/ho/.bashrc
# log successful ssh login
if [ -n "$SSH_CLIENT" ]; then
    IP=$(echo "$SSH_CLIENT" | awk '{print $1}')
    PORT=$(echo "$SSH_CLIENT" | awk '{print $3}')
    echo "$(date '+%b %d %H:%M:%S') server1 sshd[$$]: Accepted password for ho from $IP port $PORT ssh2" >> /var/log/auth.log
fi
EOF