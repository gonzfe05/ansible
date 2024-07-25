#!/bin/bash

# Set the project name (can be customized)
PROJECT_NAME="ansible"

# Print the current directory
echo "Current directory: $(pwd)"

# Run the Docker container with volume mounting
echo "Running Docker container..."
docker run -it -v /tmp/.X11-unix:/tmp/.X11-unix  -v "$(pwd)":/ansible -v "$(pwd)/personal:/personal" -v "$(pwd)/work:/work" -e DISPLAY=$DISPLAY -w /ansible $PROJECT_NAME bash
