#!/usr/bin/env bash

# check for docker compose V2 - must be installed separately on linux
docker compose &>/dev/null
if [ $? -ne 0 ]; then
  arch=$(uname)
  if [ "$arch" == "Linux" ]; then
    echo "installing docker compose V2"
    mkdir -p ~/.docker/cli-plugins/
    curl -SL https://github.com/docker/compose-cli/releases/download/v2.0.0-rc.1/docker-compose-linux-amd64 -o ~/.docker/cli-plugins/docker-compose
    chmod +x ~/.docker/cli-plugins/docker-compose
  else
    echo "docker compose V2 not available"
    echo "see here for more info: https://docs.docker.com/compose/cli-command/"
    exit 1
  fi
fi
