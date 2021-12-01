#!/bin/bash 

# Workspace name: Virtualization and Orchestration as a Mean to Deploy an Infrastructure Test Environment
# Acronym: VOMDITE

# [ Variables ]
VOMDITE_CONTAINER='spaceVOMDITE'
YELLOW='\033[1;33m'
NC='\033[0m'

printf "${YELLOW}[ $(date -Iseconds) ] [VOMDITE] Starting process... ${NC}\n"

# [ Requirements ]
printf "${YELLOW}[ $(date -Iseconds) ] [VOMDITE] -- REQUIREMENTS PHASE -- ${NC}\n"

printf "${YELLOW}[ $(date -Iseconds) ] [VOMDITE] Getting last Ubuntu Cloud Image (focal version)... ${NC}\n"
# .- Get last ubuntu server OVA
wget -O ./static-server/OVF/focal-server-cloudimg-amd64.ova https://cloud-images.ubuntu.com/focal/current/focal-server-cloudimg-amd64.ova

# .- Install docker
#   NOTE: most of these steps are based on recommendations from:
#         https://docs.docker.com/engine/install/ubuntu/
printf "${YELLOW}[ $(date -Iseconds) ] [VOMDITE] Uninstalling old docker versions... ${NC}\n"
sudo apt-get remove docker docker-engine docker.io containerd runc

# Update apt and install dependencies
printf "${YELLOW}[ $(date -Iseconds) ] [VOMDITE] Updating APT and installing requirements... ${NC}\n"
sudo apt-get update
sudo apt-get install \
  ca-certificates \
  curl \
  gnupg \
  lsb-release

printf "${YELLOW}[ $(date -Iseconds) ] [VOMDITE] Add official Docker GPG... ${NC}\n"
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

printf "${YELLOW}[ $(date -Iseconds) ] [VOMDITE] Install docker stable repository... ${NC}\n"
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

printf "${YELLOW}[ $(date -Iseconds) ] [VOMDITE] Install docker engine... ${NC}\n"
sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io

printf "${YELLOW}[ $(date -Iseconds) ] [VOMDITE] All requirements installed. ${NC}\n"

# [ INITIAL STEPS ]
printf "${YELLOW}[ $(date -Iseconds) ] [VOMDITE] -- INITIALAZING VOMDITE SERVICE -- ${NC}\n"

# 1.- Create workspace-home directory with permissions as 777
printf "${YELLOW}[ $(date -Iseconds) ] [VOMDITE] Setting up VOMDITE workspace... ${NC}\n"
mkdir --mode=777 workspace-home

# 2.- Create docker container
printf "${YELLOW}[ $(date -Iseconds) ] [VOMDITE] Creating and starting workspace container... ${NC}\n"
sudo docker create --name $VOMDITE_CONTAINER \
  -p 8020-8035:8020-8035 \
  -p 9000:9000 \
  -v $(pwd)/workspace-home/:/home/project \
  -v $(pwd)/static-server/:/home/static-server/ \
  --restart unless-stopped \
  alnoda/ansible-terraform-workspace

sudo docker start $VOMDITE_CONTAINER

# .- Wait for container being up&running
printf "${YELLOW}[ $(date -Iseconds) ] [VOMDITE] Waiting container to be loaded... ${NC}\n"
sleep 30

# .- Generate ssh keys on VOMDITE container ~/.ssh/
printf "${YELLOW}[ $(date -Iseconds) ] [VOMDITE] Generating workspace SSH key pair... ${NC}\n"
sudo docker exec -ti $VOMDITE_CONTAINER ssh-keygen

# .- Clone VOMDITE repository
printf "${YELLOW}[ $(date -Iseconds) ] [VOMDITE] Downloading VOMDITE... ${NC}\n"
sudo docker exec -ti $VOMDITE_CONTAINER git clone https://github.com/kurotorakun/VOMDITE.git /home/project/

# .- Generate ssh keys on ./VOMDITE/terraform-files/ssh_keys/
printf "${YELLOW}[ $(date -Iseconds) ] [VOMDITE] Generating internal Ansible Service SSH key pair... ${NC}\n"
sudo docker exec -ti $VOMDITE_CONTAINER mkdir /home/project/terraform-files/ssh_keys
sudo docker exec -ti $VOMDITE_CONTAINER ssh-keygen -f /home/project/terraform-files/ssh_keys/ansible_id_rsa

# .- Install OVFTool
printf "${YELLOW}[ $(date -Iseconds) ] [VOMDITE] Installing OVFTool on workspace... ${NC}\n"
sudo docker exec -ti -u root $VOMDITE_CONTAINER /home/project/addittional_software/VMware-ovftool-4.4.1-16812187-lin.x86_64.bundle --eulas-agreed

# [ TERRAFORM EXECUTION ]
printf "${YELLOW}[ $(date -Iseconds) ] [VOMDITE] Initialazing Terraform service... ${NC}\n"
sudo docker exec -ti $VOMDITE_CONTAINER terraform -chdir=/home/project/terraform-files init

# ~ DEBUG ~
# printf "${YELLOW}[ $(date -Iseconds) ] [VOMDITE] Planning Terraform process... ${NC}\n"
# sudo docker exec -ti $VOMDITE_CONTAINER terraform -chdir=/home/project/terraform-files plan

printf "${YELLOW}[ $(date -Iseconds) ] [VOMDITE] Starting terraforming... ${NC}\n"
sudo docker exec -ti $VOMDITE_CONTAINER terraform -chdir=/home/project/terraform-files apply

printf "${YELLOW}[ $(date -Iseconds) ] [VOMDITE] Terraforming process completed. Review any error output. ${NC}\n"
printf "                              Access workspace through http://localhost:8022/ to review any error.\n"
