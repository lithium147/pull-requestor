#!/usr/bin/env bash

SCRIPT_PATH=$(dirname "$0")
# util path might be one level up
if [ -e $(dirname "$0")/../../util ]; then
  UTIL_PATH=$(dirname "$0")/../../util
else
  UTIL_PATH=$(dirname "$0")/../util
fi

f="$1"

# TODO support other style of comments:
# HTML/XML: <!--  -->
# sql: /*, --
# properties: #
# Jenkinsfile: /*

echo -n '.'
$SCRIPT_PATH/remove.sh "$f"
echo -n '.'
