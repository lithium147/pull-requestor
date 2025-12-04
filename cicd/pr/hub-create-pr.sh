#!/usr/bin/env bash
# requires env var: GITHUB_TOKEN

set -e

dstBranch="$1"
shift
title="$1"
shift
messageFile="$1"
shift
labels=("$@")

# bullet formatting for pr description
message=$(sed 's/^- /* /' $messageFile)

#export HUB_VERBOSE=1

labelParams=()
for label in ${labels[@]}; do
  labelParams+=('-l' "$label")
done
echo "using label params: ${labelParams[@]}"

# each -m means a new line will be added
hub pull-request -b "$dstBranch" -m "$title" -m '' -m "$message" ${labelParams[@]}

# --no-edit - doesn't work as it cant detect commits
# also tried with unpushed changes, still doesn't work
#hub pull-request --no-edit -l java -p
