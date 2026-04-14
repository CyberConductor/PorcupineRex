#!/bin/bash

set -e


GREEN="\033[0;32m"
RED="\033[0;31m"
YELLOW="\033[1;33m"
BLUE="\033[0;34m"
NC="\033[0m"


clear

echo -e "${BLUE}"
echo "========================================"
echo "        PorcupineRex Installer"
echo "========================================"
echo -e "${NC}"
echo ""

sleep 1


spinner()
{
    local pid=$1
    local msg=$2
    local spin='-\|/'

    echo -ne "${YELLOW}[*] $msg... ${NC}"

    while kill -0 $pid 2>/dev/null
    do
        for i in 0 1 2 3
        do
            echo -ne "\b${spin:$i:1}"
            sleep 0.1
        done
    done

    echo -e "\b${GREEN}✓${NC}"
}

run()
{
    "$@" > /dev/null 2>&1 &
    spinner $! "$1"
}


echo -e "${YELLOW}Starting installation...${NC}"
echo ""

run sudo apt update -y
run sudo apt install -y vsftpd python3 python3-pip docker.io openssh-server git
run sudo systemctl enable --now vsftpd
run sudo systemctl enable --now ssh
run sudo systemctl enable --now docker

if [ -f "requirements.txt" ]; then
    run sudo pip3 install -r requirements.txt
fi

if [ -f "Dockerfile" ]; then
    run sudo docker build -t ubuntu_honeypot .
fi

if [ -f "scripts/ssh_alert.py" ]; then
    run sudo cp scripts/ssh_alert.py /usr/local/bin/ssh_alert.py
    run sudo chmod +x /usr/local/bin/ssh_alert.py
fi

if ! grep -q "ssh_alert.py" /etc/pam.d/sshd 2>/dev/null; then
    echo "session optional pam_exec.so /usr/bin/python3 /usr/local/bin/ssh_alert.py" | sudo tee -a /etc/pam.d/sshd > /dev/null
fi

if [ -f "scripts/vsftpd.conf" ]; then
    run sudo cp scripts/vsftpd.conf /etc/vsftpd.conf
    run sudo systemctl restart vsftpd
fi

run sudo apt autoremove -y

echo ""
echo -e "${GREEN}========================================"
echo "        Installation Complete!"
echo "========================================"
echo -e "${NC}"

echo -e "${BLUE}PorcupineRex is now ready to use.${NC}"
echo ""