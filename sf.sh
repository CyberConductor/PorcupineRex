#!/bin/bash

#set safe mode
sudo apt install openssh-server -y
sudo apt install ftp -y

sudo systemctl enable ssh
sudo systemctl enable ftp

sudo systemctl start ssh
sudo systemctl start ftp

