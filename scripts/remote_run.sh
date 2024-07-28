#!/bin/bash
export DEBIAN_FRONTEND=noninteractive

# Clone the repository into /tmp/
apt update && apt install git
echo "Cloning the repository..."
git clone https://github.com/gonzfe05/ansible /tmp/ansible

# Check if the clone was successful
if [ $? -ne 0 ]; then
    echo "Failed to clone the repository."
    exit 1
fi

# Change directory to /tmp/ansible
cd /tmp/ansible

# Run the install_ansible.sh script
echo "Running install_ansible.sh..."
./scripts/install_ansible.sh

# Check if the script ran successfully
if [ $? -ne 0 ]; then
    echo "Failed to run install_ansible.sh."
    exit 1
fi

# Run the ansible-playbook command
echo "Running ansible-playbook..."
ansible-playbook playbooks/all.yaml --ask-vault-pass

