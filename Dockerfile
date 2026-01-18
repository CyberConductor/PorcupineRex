FROM ubuntu:latest

# install required tools (first logic + safe extra packages)
RUN apt-get update \
 && apt-get install -y \
    openssh-server rsyslog curl ca-certificates jq sudo \
    vsftpd libpam0g python3 python3-pip \
 && mkdir /var/run/sshd \
 && ssh-keygen -A

RUN pip3 install pymongo --break-system-packages


# create honeypot user and logs directory
RUN groupadd honeypot \
 && useradd -m -g honeypot -d /home/honeypot -s /bin/bash honeypot

# create user ho for SSH login
RUN useradd -m -s /bin/bash ho \
 && mkdir -p /home/ho \
 && chown -R ho:ho /home/ho

# honeypot logs directory (safe permissions)
RUN mkdir -p /honeypot-logs \
 && chown root:root /honeypot-logs \
 && chmod 755 /honeypot-logs \
 && touch /honeypot-logs/commands.log /honeypot-logs/attacker_activity.log \
 && chown ho:ho /honeypot-logs/commands.log /honeypot-logs/attacker_activity.log \
 && chmod 644 /honeypot-logs/commands.log /honeypot-logs/attacker_activity.log

# attack monitor log file
RUN touch /var/log/attack_monitor.log \
 && chmod 644 /var/log/attack_monitor.log

# configure bash history logging for ho (save + mirror commands)
RUN cp /etc/skel/.bashrc /home/ho/.bashrc \
 && cp /etc/skel/.profile /home/ho/.profile \
 && echo 'shopt -s histappend' >> /home/ho/.bashrc \
 && echo 'export HISTFILE=/honeypot-logs/commands.log' >> /home/ho/.bashrc \
 && echo 'export HISTSIZE=50000' >> /home/ho/.bashrc \
 && echo 'export HISTFILESIZE=50000' >> /home/ho/.bashrc \
 && echo 'export HISTTIMEFORMAT="#%s "' >> /home/ho/.bashrc \
 && echo 'export PROMPT_COMMAND="history -a; history -c; history -r; history 1 | sed \"s/^ *[0-9]\\+ *//\" >> /honeypot-logs/attacker_activity.log"' >> /home/ho/.bashrc \
 && chown ho:ho /home/ho/.bashrc /home/ho/.profile

# copy original files
COPY users.json /usr/local/etc/users.json
COPY upload_attacks.py /usr/local/bin/upload_attacks.py
COPY create_users.sh /usr/local/bin/create_users.sh
COPY put_users_files.sh /usr/local/bin/put_users_files.sh
COPY detect_bruteforce.sh /usr/local/bin/detect_bruteforce.sh
COPY attack_monitor.sh /usr/local/bin/attack_monitor.sh
COPY start.sh /start.sh

# copy additional files (no logic changes)
COPY .env /usr/local/bin/.env
COPY vsftpd.conf /etc/vsftpd.conf
COPY errors.log /usr/local/share/errors.log
COPY inject_errors.sh /usr/local/bin/inject_errors.sh

# ensure PAM config exists (non intrusive)
RUN mkdir -p /etc/pam.d \
 && echo "auth    required pam_unix.so" > /etc/pam.d/vsftpd \
 && echo "account required pam_unix.so" >> /etc/pam.d/vsftpd

# make scripts executable
RUN chmod +x /usr/local/bin/create_users.sh \
 && chmod +x /usr/local/bin/put_users_files.sh \
 && chmod +x /usr/local/bin/detect_bruteforce.sh \
 && chmod +x /usr/local/bin/attack_monitor.sh \
 && chmod +x /usr/local/bin/upload_attacks.py \
 && chmod +x /usr/local/bin/inject_errors.sh \
 && chmod +x /start.sh

# run user creation and place fake files
RUN /usr/local/bin/create_users.sh \
 && /usr/local/bin/put_users_files.sh

# working directory
WORKDIR /home/ho

# entrypoint unchanged
ENTRYPOINT ["/start.sh"]
