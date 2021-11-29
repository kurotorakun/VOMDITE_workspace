#!/bin/bash 

# Workspace name: Virtualization and Orchestration as a Mean to Deploy an Infrastructure Test Environment
# Acronym: VOMDITE

# [ STEPS ]

# 1.- Create workspace-home directory with permissions as 777
mkdir --mode=777 workspace-home

# 2.- Create docker container
docker create --name spaceVOMDITE \
  -p 8020-8035:8020-8035 \
  -p 9000:9000 \
  -v $(pwd)/workspace-home/:/home/project \
  -v $(pwd)/static-server/:/home/static-server/ \
  --restart unless-stopped \
  alnoda/ansible-terraform-workspace

docker start spaceVOMDITE

# .- Wait for container being up&running
echo "Waiting container to be loaded..."
sleep 30

# .- Generate ssh keys on ./VOMDITE/terraform-files/ssh_keys/

