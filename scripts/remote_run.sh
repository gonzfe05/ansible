#!/bin/bash
export DEBIAN_FRONTEND=noninteractive
echo $DEBIAN_FRONTEND

# The following two checks are necesary to copy to host's clipboard
# Check if DISPLAY environment variable is set
if [ -z "$DISPLAY" ]; then
    echo "The DISPLAY environment variable is not set."
    exit 1
fi

# Check if /tmp/.X11-unix directory exists
if [ ! -d "/tmp/.X11-unix" ]; then
    echo "The /tmp/.X11-unix directory does not exist."
    exit 1
fi

# Clone the repository into /tmp/
apt-get update
apt-get install -y git
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

