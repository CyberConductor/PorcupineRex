#!/bin/bash

sudo apt update -y
sudo apt install vsftpd -y
sudo systemctl enable --now vsftpd
sudo apt install python3 -y
sudo apt install python3-pip -y
sudo pip3 install -r requirements.txt
sudo apt install docker.io openssh-server -y
sudo systemctl enable --now ssh
sudo systemctl enable --now docker
sudo usermod -aG docker $USER
sudo docker build -t ubuntu_ho .
sudo cp scripts/ssh_alert.py /usr/local/bin/ssh_alert.py
sudo chmod +x /usr/local/bin/ssh_alert.py

if ! grep -q "ssh_alert.py" /etc/pam.d/sshd; then
    echo "session optional pam_exec.so /usr/bin/python3 /usr/local/bin/ssh_alert.py" | sudo tee -a /etc/pam.d/sshd
fi

cp scripts/vsftpd.conf /etc/vsftpd.conf
sudo systemctl restart vsftpd


