#!/usr/bin/env bash

set -e

# TODO How about creating multiple PR's from one tool
# - Seems to be a rare case and a custom apply script could achieve this.

PR_TOOL="$1"
shift
PR_ACTION="$1"
shift
SRC_BRANCH="$1"
shift
CHANGE_BRANCH="$1"
shift
DST_BRANCH="$1"
shift
#CUSTOM_PARAMS=("$@")

# assume all scripts are in the source dir
# and the current dir is where the files to be modified are
SCRIPT_PATH=$(dirname "$0")
# util path might be one level up
if [ -e $(dirname "$0")/../../util ]; then
  UTIL_PATH=$(dirname "$0")/../../util
else
  UTIL_PATH=$(dirname "$0")/../util
fi

recreate=0
if [ "$1" = "--recreate" ]; then
  shift
  recreate=1
fi

# This doesn't affect mvn-versions since it uses a different branch name
# But for mvnw it prevents new versions superseding old ones
# How to solve this?  Perhaps create a script for this, so it can be overridden
# But this doesn't apply to other tools, so not very useful
# support --recreate option (or --force)
# delete the existing branch before proceeding
echo "Checking for existing branch: $CHANGE_BRANCH"
if [ "$SRC_BRANCH" != "$CHANGE_BRANCH" ]; then  # if srcBranch is the changeBranch, then it must exist
  matchingBranches=$(git ls-remote --heads origin $CHANGE_BRANCH | wc -l)
  if [ $matchingBranches -gt 0 ]; then
    # TODO if the existing branch has conflicts, then recreate it
    if [ $recreate -ne 0 ]; then
      # should it only delete the existing one if there are new changes?
      # if it is not deleted, then harder to know if there were new changes or not.
      echo 'branch already exists and have --recreate option, so deleting existing branch'
      $UTIL_PATH/close-pr.sh "$CHANGE_BRANCH" 'closed due --recreate option'
    else
      echo 'branch already exists and --recreate not specified, so will do nothing'
      exit
    fi
  fi
fi

if [ -e "$SCRIPT_PATH/install.sh" ]; then
  $SCRIPT_PATH/install.sh
fi
# TODO how to return the pr title
# - write it to a file and read it back
# - output it with a token, and read it from the output with tee
# - require a custom apply script
# could be more than just the title, what about the pr label
if ! $SCRIPT_PATH/run.sh "$1" "$2" "$3" "$4"; then
  echo 'ERROR::run script failed'
  # TODO how to return exit code from run script?
  exit 255
fi

rm -f .attach_pid*  # sometime this file is left behind
rm -f */.attach_pid*  # sometime this file is left behind
rm -f .mvn/wrapper/maven-wrapper.jar
git add .
if ! $SCRIPT_PATH/has-local-changes.sh; then
  echo 'no changes made, will not do anything'
  exit
fi

if [ "$PR_ACTION" = 'none' ]; then
  echo 'not pushing changes - PR_ACTION==none'
  exit
fi

title="$PR_TOOL"
if [ -e "$SCRIPT_PATH/title.txt" ]; then
  title=$(cat "$SCRIPT_PATH/title.txt")
fi
labels=()
if [ -e "$SCRIPT_PATH/labels.txt" ]; then
  labels=($(cat "$SCRIPT_PATH/labels.txt"))
fi
branch="$CHANGE_BRANCH"
if [ -e "$SCRIPT_PATH/branch.txt" ]; then
  branch="$(cat "$SCRIPT_PATH/branch.txt")"
fi

$SCRIPT_PATH/push-to-git.sh "$branch" "$title" $SCRIPT_PATH/description.txt
if [ "$PR_ACTION" = 'push' ]; then
  echo 'not creating pr - PR_ACTION==push'
  exit 1
fi

# TODO if pushing to the same branch, the pr might already exist, so should not fail
$SCRIPT_PATH/hub-create-pr.sh "$DST_BRANCH" "$title" $SCRIPT_PATH/description.txt ${labels[@]}
exit 1
