#!/bin/bash

# Define the name of the Docker image
IMAGE_NAME="ansible-container"
CONTAINER_NAME="ansible-instance"

# Build the Docker image
docker build -t $IMAGE_NAME .

# Run the Docker container in interactive mode
docker run --rm -it --name $CONTAINER_NAME $IMAGE_NAME /bin/bash

