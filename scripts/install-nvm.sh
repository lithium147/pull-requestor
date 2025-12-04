#!/usr/bin/env bash

# ensure latest nvm/npm/node is being used locally
if [ -e ~/.nvm/nvm.sh ]; then
  echo "updating npm/node"
  source ~/.nvm/nvm.sh
  nvm install node
else
  echo "installing nvm"
  curl -s 'https://api.github.com/repos/nvm-sh/nvm/releases/latest' | jq -r '.name' > /tmp/nvm.version
  curl -sL "https://raw.githubusercontent.com/creationix/nvm/$(cat /tmp/nvm.version)/install.sh" | bash
  echo "installing npm/node"
  source ~/.nvm/nvm.sh
  nvm install node
fi
