#!/usr/bin/env bash
# requires env var: GITHUB_TOKEN

dstBranch="$1"
title="$2"
messageFile="$3"

# bullet formatting for pr description
message=$(sed 's/^/* /' $messageFile)

#export HUB_VERBOSE=1

# each -m means a new line will be added
hub pull-request -b $dstBranch -m $title -m '' -m "$message" -l java

# --no-edit - doesn't work as it cant detect commits
# also tried with unpushed changes, still doesn't work
#hub pull-request --no-edit -l java -p
