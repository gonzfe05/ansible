#!/bin/bash


# Check if the PROJECT_NAME argument is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <PROJECT_NAME>"
    exit 1
fi

PROJECT_NAME="$1"

# Print the current directory
echo "Current directory: $(pwd)"

# These permissions allow the sudo group for which the aleph user belongs to
sudo chown root:sudo personal
sudo chmod g+rwx personal

sudo chown root:sudo work
sudo chmod g+rwx work

# Allowing docker to use hsot's clipboard
xhost +
# Run the Docker container with volume mounting
echo "Running Docker container from $(pwd)"
docker run -it \
  -v /tmp/.X11-unix:/tmp/.X11-unix \
  -v "$(pwd)":/ansible \
  -v "$(pwd)/personal:/personal" \
  -v "$(pwd)/work:/work" \
  -e DISPLAY=$DISPLAY \
  --network="host" \
  -w /ansible \
  --rm \
  $PROJECT_NAME \
  bash -c "scripts/install_ansible.sh && ansible-playbook playbooks/container.yaml --ask-vault-pass; exec bash"

