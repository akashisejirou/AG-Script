#!/bin/bash

# Function to install Docker
install_docker() {
    echo "Installing Docker..."

    # Add Docker's official GPG key
    sudo apt-get update
    sudo apt-get install -y ca-certificates curl
    sudo install -m 0755 -d /etc/apt/keyrings
    sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc

    # Add the repository to Apt sources
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
      $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
      sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt-get update
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    echo "Docker installation complete."
}

# Install Docker
install_docker

# Name of the Dockerfile to be created
DOCKERFILE="Dockerfile"

# Check if Dockerfile already exists
if [ -f "$DOCKERFILE" ]; then
    echo "Dockerfile already exists. Skipping creation."
else
    # Create the Dockerfile with the following contents
    echo "Creating Dockerfile..."

    cat <<EOF > $DOCKERFILE
# Use Ubuntu 22.04 as the base image
FROM ubuntu:22.04

# Install necessary packages
RUN apt-get update && \\
    apt-get install -y bash curl jq make gcc bzip2 lbzip2 vim git lz4 telnet build-essential net-tools wget tcpdump

WORKDIR /root

# Download and prepare the launcher and worker binaries
RUN curl -L https://github.com/Impa-Ventures/coa-launch-binaries/raw/main/linux/amd64/compute/launcher -o launcher && \\
    curl -L https://github.com/Impa-Ventures/coa-launch-binaries/raw/main/linux/amd64/compute/worker -o worker && \\
    chmod +x launcher worker

# Set CMD to run launcher with environment variables
CMD ./launcher --user_did="\${USER_DID}" --device_id="\${DEVICE_ID}" --device_name="\${DEVICE_NAME}" && while true; do sleep 3600; done
EOF

    echo "Dockerfile created successfully."
fi

# Check for running containers and set START_INSTANCE
RUNNING_CONTAINERS=$(docker ps -q)

if [ -n "$RUNNING_CONTAINERS" ]; then
    echo "There are running Docker containers."
    read -p "Enter START_INSTANCE: " START_INSTANCE
else
    echo "No running Docker containers found."
    START_INSTANCE=1
fi

# Prompt the user for input
read -p "Enter USER_DID: " USER_DID
read -p "Enter DEVICE_ID: " DEVICE_ID
read -p "Enter DEVICE_NAME: " DEVICE_NAME
read -p "Enter END_INSTANCE: " END_INSTANCE

# Variables
IMAGE_NAME="my-launcher-app:latest"

# Build the Docker image
echo "Building Docker image $IMAGE_NAME..."
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

echo "Script execution complete."
