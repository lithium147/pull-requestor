#!/usr/bin/env bash

p=$1

cd "$p"

# can this be done in the install script?
source ~/.nvm/nvm.sh && nvm use node_latest

npm config set @contactservice:registry "https://hsbc.com/nexus/content/repositories/Hsbc_npm/" \
    && npm config set "//hsbc.com/nexus/content/repositories/Hsbc_npm/:_authToken" ${NPM_HSBC_TOKEN}

npm audit fix --force

cd -
