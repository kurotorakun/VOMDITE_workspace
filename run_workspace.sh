#!/bin/bash 

# Workspace name: Virtualization and Orchestration as a Mean to Deploy an Infrastructure Test Environment
# Acronym: VOMDITE

# [ Variables ]
VOMDITE_CONTAINER='spaceVOMDITE'

# [ Requirements ]
# .- Install git?
# It is needed to install it? Repo can be downloaded.

# .- Install docker
#   NOTE: most of these steps are based on recommendations from:
#         https://docs.docker.com/engine/install/ubuntu/
#   Uninstall old version
sudo apt-get remove docker docker-engine docker.io containerd runc

# Update apt and install dependencies
sudo apt-get update

sudo apt-get install \
  ca-certificates \
  curl \
  gnupg \
  lsb-release

# Add official Docker GPG
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Install docker stable repository
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install docker engine
sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io

# [ INITIAL STEPS ]

# 1.- Create workspace-home directory with permissions as 777
mkdir --mode=777 workspace-home

# 2.- Create docker container
sudo docker create --name $VOMDITE_CONTAINER \
  -p 8020-8035:8020-8035 \
  -p 9000:9000 \
  -v $(pwd)/workspace-home/:/home/project \
  -v $(pwd)/static-server/:/home/static-server/ \
  --restart unless-stopped \
  alnoda/ansible-terraform-workspace

sudo docker start $VOMDITE_CONTAINER

# .- Wait for container being up&running
echo "Waiting container to be loaded..."
sleep 30

# .- Generate ssh keys on VOMDITE container ~/.ssh/
sudo docker exec -ti $VOMDITE_CONTAINER ssh-keygen

# .- Clone VOMDITE repository
sudo docker exec -ti $VOMDITE_CONTAINER git clone https://github.com/kurotorakun/VOMDITE.git /home/project/

# .- Generate ssh keys on ./VOMDITE/terraform-files/ssh_keys/
sudo docker exec -ti $VOMDITE_CONTAINER mkdir /home/project/terraform-files/ssh_keys
sudo docker exec -ti $VOMDITE_CONTAINER ssh-keygen -f /home/project/terraform-files/ssh_keys/ansible_id_rsa

# [ TERRAFORM EXECUTION ]
# .- Init Terraform
sudo docker exec -ti $VOMDITE_CONTAINER terraform -chdir=/home/project/terraform-files init

# ~ DEBUG ~
# sudo docker exec -ti $VOMDITE_CONTAINER terraform -chdir=/home/project/terraform-files init

sudo docker exec -ti $VOMDITE_CONTAINER terraform -chdir=/home/project/terraform-files apply
