#! /bin/bash

# To set up an Ubuntu system like we need for this workshop,
# copy this script the the target system:
#    wget https://raw.githubusercontent.com/OtherDevOpsGene/intro-to-docker/main/install-docker.sh
# and run it as root:
#    sudo bash ./install-docker.sh

# You'll also need the following ports open:
# * 22 for SSH traffic if the system is in the cloud
# * 80, 4444, and 8080 open for HTTP traffic

# Prerequisite software for Docker
apt-get update
apt-get install -y apt-transport-https ca-certificates curl software-properties-common

# Use the Docker repository directly for the latest and greatest version
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
apt-get update

# Install Docker Community Edition
apt-get install -y docker-ce

# Install the Compose CLI plugin for Docker
DOCKER_CONFIG=${DOCKER_CONFIG:-$HOME/.docker}
mkdir -p ${DOCKER_CONFIG}/cli-plugins
curl -fsSL https://github.com/docker/compose/releases/download/v2.14.0/docker-compose-linux-x86_64 -o ${DOCKER_CONFIG}/cli-plugins/docker-compose
chmod +x ${DOCKER_CONFIG}/cli-plugins/docker-compose

# Give the default ubuntu user permission to use Docker
usermod -a -G docker ubuntu
# If you aren't using an AWS image with the ubuntu user, just replace the username with
# the appropriate user or users on your system

echo
echo
echo Done. Log out and log back in to pick up the changes.
