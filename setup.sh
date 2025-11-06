#!/bin/bash

#bash script to setup a honeypot base vm


sudo apt update && sudo apt upgrade -y

#install SSH server and utilities
sudo apt install -y openssh-server auditd vim wget curl sudo iptables-persistent

#enable sshd
sudo systemctl enable --now ssh

#create decoy users
sudo useradd -m -s /bin/bash admin
echo 'admin:Admin123!' | sudo chpasswd

sudo useradd -m -s /bin/bash ubuntu
echo 'ubuntu:ubuntu' | sudo chpasswd

#create fake files
sudo -u admin mkdir -p /home/admin/documents
sudo -u admin bash -c 'for i in {1..10}; do echo "invoice $i" > /home/admin/documents/invoice_$i.txt; done'

#enable auditing/logging
sudo systemctl enable --now auditd

#fake SSH key for realism
sudo -u ubuntu mkdir -p /home/ubuntu/.ssh
sudo -u ubuntu bash -c 'echo "ssh-rsa AAAA... fakekey" > /home/ubuntu/.ssh/authorized_keys || true'

#clean logs history
cat /dev/null > ~/.bash_history
sudo truncate -s 0 /var/log/auth.log /var/log/syslog /var/log/wtmp || true


echo "Done! This base vm is now set up as a honeypot."