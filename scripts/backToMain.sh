#!/usr/bin/env bash

set -e

# To be run once pr is merged
url=$(git remote get-url origin)
newUrl=$(echo $url | sed -E -n 's/(https:\/\/)(alm-github.systems.uk.hsbc)/\1'"${GIT_USR}:${GIT_PWD}"'@\2/p')
if [ "$newUrl" == "" ]; then
  echo "repo url already has a username/password"
else
  echo "adding username/password to repo url"
  git remote set-url origin "$newUrl"
fi

url=$(git remote get-url origin)
main=$(git ls-remote --symref "$url" HEAD | head -n 1 | sed -E -n 's|^.*refs/heads/([a-zA-Z0-9_-]*).*$|\1|p')

# save current branch so can be deleted later
oldBranch=$(git branch --show-current)

if [ "$oldBranch" == "$main" ]; then
  echo "already on $main branch"
  exit 1
else
  echo "switching from $oldBranch to $main branch"
fi

# update master
echo "updating $main branch"
git fetch origin $main:$main

# switch back to master
echo "switching back to $main branch"
git checkout $main

# delete previous branch
echo "deleting $oldBranch branch"
git branch -d "$oldBranch"
git push -d origin $oldBranch

