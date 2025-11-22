#!/bin/bash

#set safe mode
set -euo pipefail

#create dockerfile for ubuntu_ho image
cat << 'EOF' > /tmp/Dockerfile_ubuntu_ho
FROM ubuntu:latest

RUN useradd -m ho
USER ho

CMD ["/bin/bash"]
EOF

#build the docker image
docker build -t ubuntu_ho -f /tmp/Dockerfile_ubuntu_ho /tmp

#create wrapper script that drops ssh users into the container
cat << 'EOF' > /usr/local/bin/docker-shell.sh
#!/bin/bash
#drop the ssh user into the container as ho, non root
exec docker run -it --rm --user ho ubuntu_ho /bin/bash
EOF

#make it executable
chmod +x /usr/local/bin/docker-shell.sh

#create group for users who should be forced into container
groupadd --force docker-shell

#add user ho to that group
usermod -aG docker-shell ho

#configure sshd to use the script when group docker-shell logs in
if ! grep -q "Match Group docker-shell" /etc/ssh/sshd_config
then
    cat << 'EOF' >> /etc/ssh/sshd_config

Match Group docker-shell
    ForceCommand /usr/local/bin/docker-shell.sh
EOF
fi

#restart sshd
systemctl restart ssh || systemctl restart sshd

echo "Setup complete. Logging in as user ho via ssh will open a shell inside the docker container."
