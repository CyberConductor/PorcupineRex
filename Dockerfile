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
RUN cp /etc/skel/.bashrc /home/ho/.bashrc \
 && cp /etc/skel/.profile /home/ho/.profile \
 && echo 'shopt -s histappend' >> /home/ho/.bashrc \
 && echo 'export HISTSIZE=50000' >> /home/ho/.bashrc \
 && echo 'export HISTFILESIZE=50000' >> /home/ho/.bashrc \
 && chown ho:ho /home/ho/.bashrc /home/ho/.profile

# copy JSON and scripts
COPY users.json /usr/local/etc/users.json
COPY create_users.sh /usr/local/bin/create_users.sh
COPY put_users_files.sh /usr/local/bin/put_users_files.sh
COPY detect_bruteforce.sh /usr/local/bin/detect_bruteforce.sh
COPY attack_monitor.sh /usr/local/bin/attaּck_monitor.sh
COPY start.sh /start.sh
COPY vsftpd.conf /etc/vsftpd.conf


# ensure PAM directory and vsftpd PAM config exist
RUN mkdir -p /etc/pam.d \
 && echo "auth    required pam_unix.so" > /etc/pam.d/vsftpd \
 && echo "account required pam_unix.so" >> /etc/pam.d/vsftpd
# make scripts executable
RUN chmod +x /usr/local/bin/create_users.sh \
 && chmod +x /usr/local/bin/put_users_files.sh \
 && chmod +x /usr/local/bin/detect_bruteforce.sh \
 && chmod +x /usr/local/bin/attack_monitor.sh \
 && chmod +x /start.sh

# run user creation and place fake files
RUN /usr/local/bin/create_users.sh \
 && /usr/local/bin/put_users_files.sh

# working directory
WORKDIR /home/ho

# entrypoint script to start background scripts and drop into ho
ENTRYPOINT ["/start.sh"]

# save the hacker info
RUN echo '
CLIENT_IP=$(echo "$SSH_CONNECTION" | awk "{print \$1}")

trap "
trap - DEBUG
echo \"\$(date +%s)|\$CLIENT_IP|\$\$|\$(id -u)|\$PWD|\$BASH_COMMAND\" >> /honeypot-logs/attacker_activity.log
trap DEBUG
" DEBUG
' >> /home/ho/.bashrc