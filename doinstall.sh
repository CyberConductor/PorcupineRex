#!/bin/bash
echo "Installing docker image for honeypot..."

sudo apt install docker -y

sudo docker pull alpine:latest

sudo docker pull ubuntu:latest

echo "Installation complete."