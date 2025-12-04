#!/usr/bin/env bash

PR_TOOL=$1
PR_ACTION=$2
SRC_BRANCH=$3
CHANGE_BRANCH=$4
DST_BRANCH=$5

# assume all scripts are in the source dir
SCRIPT_PATH=$(dirname "$0")

# and the current dir is where the files to be modified are

if [ "$PR_ACTION" = 'none' ]; then
  echo 'not pushing changes - PR_ACTION==none'
  exit
fi
if [ "$PR_ACTION" = 'push' ]; then
  echo 'not creating pr - PR_ACTION==push'
  exit
fi
$SCRIPT_PATH/hub-create-pr.sh "$DST_BRANCH" "$SRC_BRANCH" $SCRIPT_PATH/description.txt

# TODO pr message from commits to branch
