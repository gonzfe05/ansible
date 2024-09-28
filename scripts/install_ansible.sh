#!/usr/bin/env bash
# Ensure the script runs with root privileges
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root or use sudo."
    exit 1
fi

export DEBIAN_FRONTEND=noninteractive
apt update
apt install software-properties-common -y
apt-add-repository --yes --update ppa:ansible/ansible
apt install ansible -y
#pip3 install ansible-dev-tools
