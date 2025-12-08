FROM ubuntu:latest

# install required tools
RUN apt-get update \
 && apt-get install -y openssh-server rsyslog curl ca-certificates jq sudo \
 && mkdir /var/run/sshd

# create honeypot user and logs directory
RUN groupadd honeypot \
 && useradd -m -g honeypot -d /home/honeypot -s /bin/bash honeypot

# create user ho for SSH login
RUN useradd -m -s /bin/bash ho \
 && mkdir -p /home/ho \
 && chown -R ho:ho /home/ho

# honeypot logs directory
RUN mkdir -p /honeypot-logs \
 && touch /honeypot-logs/commands.log \
 && chown root:root /honeypot-logs \
 && chmod 733 /honeypot-logs \
 && chown root:root /honeypot-logs/commands.log \
 && chmod 622 /honeypot-logs/commands.log

# attack monitor log file
RUN touch /var/log/attack_monitor.log \
 && chmod 644 /var/log/attack_monitor.log

# configure bash history logging for ho
RUN cp /etc/skel/.bashrc /home/ho/.bashrc \
 && cp /etc/skel/.profile /home/ho/.profile \
 && echo 'shopt -s histappend' >> /home/ho/.bashrc \
 && echo 'export HISTFILE=/honeypot-logs/commands.log' >> /home/ho/.bashrc \
 && echo 'export HISTSIZE=50000' >> /home/ho/.bashrc \
 && echo 'export HISTFILESIZE=50000' >> /home/ho/.bashrc \
 && echo 'export HISTTIMEFORMAT="#%s "' >> /home/ho/.bashrc \
 && echo 'export PROMPT_COMMAND="history -a; history -c; history -r"' >> /home/ho/.bashrc \
 && chown ho:ho /home/ho/.bashrc /home/ho/.profile

# copy JSON and scripts
COPY users.json /usr/local/etc/users.json
COPY create_users.sh /usr/local/bin/create_users.sh
COPY put_users_files.sh /usr/local/bin/put_users_files.sh
COPY detect_bruteforce.sh /usr/local/bin/detect_bruteforce.sh
COPY attack_monitor.sh /usr/local/bin/attack_monitor.sh
COPY start.sh /start.sh

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
