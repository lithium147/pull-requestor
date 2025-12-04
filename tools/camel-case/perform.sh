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
$SCRIPT_PATH/replace-within-files.sh "$f"
echo -n '.'

# TODO rename files with underscores to camel case:
# - json/xml resources
# - java classes
# requires references to the file to be updated also
# doesn't suit standard tool since its not just java files
