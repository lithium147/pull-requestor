#!/usr/bin/env bash

set -e

# create pr for current branch
# enable auto merge

#git push
#git push --set-upstream origin test-pr

gh pr create --fill
gh pr merge --merge --auto
