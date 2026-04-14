#!/bin/bash

if [ "$EUID" -eq 0 ]; then
    echo "[+] Running as root"
    SUDO=""
else
    if sudo -v >/dev/null 2>&1; then
        echo "[+] Sudo access confirmed"
        SUDO="sudo"
    else
        echo "[-] This script requires sudo privileges"
        exit 1
    fi
fi

set -e

# =========================
# Colors
# =========================
GREEN="\033[0;32m"
RED="\033[0;31m"
YELLOW="\033[1;33m"
BLUE="\033[0;34m"
NC="\033[0m"


if ! grep -qiE "ubuntu|kali|debian" /etc/os-release; then
    echo -e "${RED}Unsupported OS${NC}"
    exit 1
fi


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
        for i in {0..3}
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

run $SUDO apt update -y
run $SUDO apt install -y vsftpd python3 python3-pip docker.io openssh-server git
run $SUDO systemctl enable --now vsftpd
run $SUDO systemctl enable --now ssh
run $SUDO systemctl enable --now docker

if [ -f "requirements.txt" ]; then
    python3 -m pip install --upgrade pip > /dev/null 2>&1 || true
    run python3 -m pip install -r requirements.txt
fi

if [ -f "Dockerfile" ]; then
    run $SUDO docker build -t ubuntu_honeypot . || true
fi

if [ -f "scripts/ssh_alert.py" ]; then
    run $SUDO cp scripts/ssh_alert.py /usr/local/bin/ssh_alert.py
    run $SUDO chmod +x /usr/local/bin/ssh_alert.py
fi

if ! grep -q "ssh_alert.py" /etc/pam.d/sshd 2>/dev/null; then
    echo "session optional pam_exec.so /usr/bin/python3 /usr/local/bin/ssh_alert.py" | $SUDO tee -a /etc/pam.d/sshd > /dev/null
fi

$SUDO usermod -aG docker "$USER" || true

if [ -f "scripts/vsftpd.conf" ]; then
    run $SUDO cp scripts/vsftpd.conf /etc/vsftpd.conf
    run $SUDO systemctl restart vsftpd
fi

run $SUDO apt autoremove -y

echo ""
echo -e "${GREEN}========================================"
echo "        Installation Complete!"
echo "========================================"
echo -e "${NC}"

echo -e "${BLUE}PorcupineRex is now ready to use.${NC}"
echo ""