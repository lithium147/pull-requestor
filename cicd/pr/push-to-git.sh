#!/usr/bin/env bash

set -e

branch_name=$1
commit_title="$2"
commit_message_file="$3"

git update-index --refresh
if git diff-index --quiet HEAD --; then
  echo no changes
  exit
fi

commit_message=$(cat $commit_message_file)

echo "creating branch and pushing to origin"
git checkout -b $branch_name
git add .
#git reset .git-credentials || true # don't want this file committed
git commit -m "$commit_title" -m "$commit_message"
git push -u origin "$branch_name"

# seems like pre-receive hooks only apply commits on existing branches
# remote: [**** ERROR: A valid JIRA Issue number is missing from commit message... example format=JIRA-123 Commit message ...' ****]
# ! [remote rejected] pr/junit5 -> pr/junit5 (pre-receive hook declined)

# must be on master
#  currentBranch=$(git rev-parse --abbrev-ref HEAD)
#  if [[ $currentBranch != "master" ]]; then
#    echo "can only create pr from master"
#    return
#  fi

# to delete the remote branch if not happy
# git push -d origin uppercase-hex-digits
