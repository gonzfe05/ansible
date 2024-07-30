#!/bin/bash


# Check if the PROJECT_NAME argument is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <PROJECT_NAME>"
    exit 1
fi

PROJECT_NAME="$1"

# Print the current directory
echo "Current directory: $(pwd)"

# Allowing docker to use hsot's clipboard
xhost +
# Run the Docker container with volume mounting
echo "Running Docker container..."
docker run -it \
  -v /tmp/.X11-unix:/tmp/.X11-unix \
  -v "$(pwd)":/ansible \
  -v "$(pwd)/personal:/personal" \
  -v "$(pwd)/work:/work" \
  -e DISPLAY=$DISPLAY \
  -w /ansible \
  --rm \
  $PROJECT_NAME \
  bash -c "ansible-playbook playbooks/all.yaml --ask-vault-pass; exec bash"

