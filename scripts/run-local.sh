#!/usr/bin/env bash

# to run the tool locally without cloning the project into your workspace
# WIP - glob matching doesn't seem to be working properly
# eg: ./run-local.sh no-junit-assertions ContactService.Java.Logging

shopt -s nullglob
shopt -s globstar
setopt extended_glob

SCRIPT_PATH=$(dirname "$0")

PR_TOOL="$1"
PROJECT="$2"
GITHUB_ORGANISATION='raven-cr'

PR_TOOL_ROOT='/tmp/pr_tools'
PR_TOOL_PATH="$PR_TOOL_ROOT/$PR_TOOL"

rm -rf $PR_TOOL_ROOT
mkdir -p $PR_TOOL_PATH
cp -R $SCRIPT_PATH/../cicd/pr/* "$PR_TOOL_PATH"
cp -R $SCRIPT_PATH/../util "$PR_TOOL_ROOT/"
cp -R $SCRIPT_PATH/../$PR_TOOL/* "$PR_TOOL_PATH"
chmod +x $PR_TOOL_PATH/*.sh

pushd "$PR_TOOL_ROOT"
for f in **/*.sh **/**/*.sh; do
  echo -n "Processing $f "
  sed -E -i '' 's/bash/zsh/' "$f"
done
popd

PROJECT_ROOT='/tmp/pr_tools'
export PROJECT_ROOT="$(mktemp -d /tmp/pr-proj.XXXXXX)"
cd "$PROJECT_ROOT"

git clone "https://$GITHUB_HOST/$GITHUB_ORGANISATION/$PROJECT.git"
#git config --add hub.host $GITHUB_HOST
cd "$PROJECT"

$PR_TOOL_PATH/apply.sh $PR_TOOL dry-run

cd -

