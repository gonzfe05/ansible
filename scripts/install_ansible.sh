#!/usr/bin/env bash

export DEBIAN_FRONTEND=noninteractive
apt update
apt install software-properties-common -y
apt-add-repository --yes --update ppa:ansible/ansible
apt install ansible -y
#pip3 install ansible-dev-tools
