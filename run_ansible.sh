#!/bin/bash

# Set the project name (can be customized)
PROJECT_NAME="ansible"

# Print the current directory
echo "Current directory: $(pwd)"

# Run the Docker container with volume mounting
echo "Running Docker container..."
docker run -it -v "$(pwd)":/app $PROJECT_NAME zsh
