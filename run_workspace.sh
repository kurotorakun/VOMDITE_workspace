#!/bin/bash 

# Workspace name: Virtualization and Orchestration as a Mean to Deploy an Infrastructure Test Environment
# Acronym: VOMDITE

docker create --name spaceVOMDITE \
  -p 8020-8035:8020-8035 \
  -p 9000:9000 \
  -v $(pwd)/workspace-home/:/home/project \
  -v $(pwd)/static-server/:/home/static-server/ \
  --restart unless-stopped \
  alnoda/ansible-terraform-workspace

