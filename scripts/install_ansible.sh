#!/usr/bin/env bash
apt install software-properties-common
apt-add-repository --yes --update ppa:ansible/ansible
apt install ansible
#pip3 install ansible-dev-tools
