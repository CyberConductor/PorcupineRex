FROM ubuntu:latest

# create honeypot user and logs directory
RUN groupadd honeypot \
 && useradd -m -g honeypot -d /home/honeypot honeypot

# create user ho to match the ssh username
RUN useradd -m ho \
 && mkdir -p /home/ho \
 && chown -R ho:ho /home/ho

# create honeypot logs directory
RUN mkdir -p /honeypot-logs \
 && touch /honeypot-logs/commands.log \
 && chown -R ho:ho /honeypot-logs

# configure bash history logging
RUN echo 'export PROMPT_COMMAND="history -a"' >> /home/ho/.bashrc \
 && echo 'export HISTFILE=/honeypot-logs/commands.log' >> /home/ho/.bashrc \
 && echo 'export HISTSIZE=50000' >> /home/ho/.bashrc \
 && echo 'export HISTFILESIZE=50000' >> /home/ho/.bashrc \
 && echo 'export HISTTIMEFORMAT="%Y-%m-%d %H:%M:%S "' >> /home/ho/.bashrc \
 && chown ho:ho /home/ho/.bashrc

# install required tools

RUN apt-get update \
 && apt-get install -y openssh-server rsyslog curl ca-certificates jq \
 && mkdir /var/run/sshd

# copy JSON and scripts
COPY users.json /usr/local/etc/users.json
COPY create_users.sh /usr/local/bin/create_users.sh
COPY put_users_files.sh /usr/local/bin/put_users_files.sh
COPY detect_bruteforce.sh /usr/local/bin/detect_bruteforce.sh
# set executable permissions
RUN chmod +x /usr/local/bin/create_users.sh \
 && chmod +x /usr/local/bin/put_users_files.sh

RUN chmod +x /usr/local/bin/detect_bruteforce.sh
# run scripts during build
RUN ["/usr/local/bin/create_users.sh"]
RUN ["/usr/local/bin/put_users_files.sh"]


# set default working directory and user
WORKDIR /home/ho

# run bruteforce detection in background and then switch to ho
CMD bash -c "/usr/local/bin/detect_bruteforce.sh & exec su - ho"