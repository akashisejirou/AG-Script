#!/bin/bash

# Prompt the user for input
read -p "Enter USER_DID: " USER_DID
read -p "Enter DEVICE_ID: " DEVICE_ID
read -p "Enter DEVICE_NAME: " DEVICE_NAME
read -p "Enter START_INSTANCE: " START_INSTANCE
read -p "Enter END_INSTANCE: " END_INSTANCE

# Variables
IMAGE_NAME="my-launcher-app:latest"

# Build the Docker image
docker build -t $IMAGE_NAME .

# Loop to create multiple instances
for i in $(seq $START_INSTANCE $END_INSTANCE); do
    CONTAINER_NAME="launcher-instance${i}"
    
    echo "Starting container $CONTAINER_NAME..."
    
    docker run -d --name $CONTAINER_NAME \
        -e USER_DID="$USER_DID" \
        -e DEVICE_ID="$DEVICE_ID" \
        -e DEVICE_NAME="$DEVICE_NAME" \
        $IMAGE_NAME
    
    if [ $? -eq 0 ]; then
        echo "Container $CONTAINER_NAME started successfully."
    else
        echo "Failed to start container $CONTAINER_NAME."
    fi
done
