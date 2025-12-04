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
#    TODO make delete imports not delete statics or make it more precise
#    $UTIL_PATH/delete-imports.sh "$f" 'org.mockito' 'Mock'
$UTIL_PATH/add-static-import.sh "$f" 'org.mockito.Mockito.mock'
echo -n '.'
$UTIL_PATH/add-static-import.sh "$f" 'org.mockito.Mockito.RETURNS_DEEP_STUBS'
echo -n '.'
