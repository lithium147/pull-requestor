#!/usr/bin/env bash

SCRIPT_PATH=$(dirname "$0")
# util path might be one level up
if [ -e $(dirname "$0")/../../util ]; then
  UTIL_PATH=$(dirname "$0")/../../util
else
  UTIL_PATH=$(dirname "$0")/../util
fi

f="$1"

echo -n '.'
# -wB to ignore whitespace/blank-lines
diff -wB "$f" "$f.before" >/dev/null
reallyUpdated=$?
if [ $reallyUpdated -eq 0 ]; then
  echo -n 'whitespace only..'
  cp "$f.before" "$f" # restore original since its only change in whitespace
else
  echo -n 'updated..'
fi
echo -n '.'
