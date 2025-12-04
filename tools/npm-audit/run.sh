#!/usr/bin/env bash
shopt -s globstar

SCRIPT_PATH=$(dirname "$0")

packageFileName='package.json'

echo
echo "running over any $packageFileName"
# TODO this causes it to run twice on the root file
for f in $packageFileName **/$packageFileName; do
  if [ ! -e "$f" ]; then
    continue
  fi
  PACKAGE_ROOT=$(dirname "$f")
  echo "running audit on $PACKAGE_ROOT"
  $SCRIPT_PATH/npm-audit.sh $PACKAGE_ROOT || true
done
