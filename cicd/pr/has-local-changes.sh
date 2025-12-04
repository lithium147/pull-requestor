#!/usr/bin/env bash

git update-index --refresh >/dev/null
git diff-index --quiet HEAD --
changed=$?
if [ $changed -eq 0 ]; then
  exit 1
else
  exit 0
fi
