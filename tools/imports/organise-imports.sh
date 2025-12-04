#!/usr/bin/env bash

SCRIPT_PATH=$(dirname "$0")
# util path might be one level up
if [ -e $(dirname "$0")/../../util ]; then
  UTIL_PATH=$(dirname "$0")/../../util
else
  UTIL_PATH=$(dirname "$0")/../util
fi

f="$1"

echo -n "organise.."
$JAVA_HOME/bin/java -jar $SCRIPT_PATH/google-java-format-all-deps.jar --fix-imports-only --skip-sorting-imports -i "$f"
