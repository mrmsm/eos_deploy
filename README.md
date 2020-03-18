# eos_deploy
EOS Deployment Tool

# About
Created to easily distribute nodeos.

# Requirements
- wget
- [JQ](https://stedolan.github.io/jq/download/)  1.4 or higher
- [Docker](https://docs.docker.com)  17.05 or higher

# How to use
1. git clone https://github.com/mrmsm/eos_deploy 
2. cd eos_deploy
3. chmod +x run_docker.sh
4. ./run_docker.sh
5. If the node is fully synchronized, stop and remove the docker container and restart run_docker.sh.
   If the docker container is not deleted and restarted, it will attempt to recover to Snapshot during the restart process.
  ./run_docker.sh remove; ./run_docker.sh start

