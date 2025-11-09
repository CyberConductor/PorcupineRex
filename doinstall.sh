#!/bin/bash
echo "Installing docker image for honeypot..."

sudo apt install -y docker.io

sudo docker pull alpine:latest

echo "Installation complete."