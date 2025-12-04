#!/usr/bin/env bash
set -o errexit -o nounset -o pipefail

SCRIPT_PATH=$(dirname "$0")
# util path might be one level up
if [ -e $(dirname "$0")/../../util ]; then
  UTIL_PATH=$(dirname "$0")/../../util
else
  UTIL_PATH=$(dirname "$0")/../util
fi

org="$1"
artifactId="$2"

BASE_API_URL='https://alm-github.systems.uk.hsbc/api/v3'
url="${BASE_API_URL}/repos/${org}/${artifactId}/topics"
#echo "$url"
# now there are multiple topics - it's choosing the wrong one
# can exclude *jenkins from the tags
curl -s -L -H "Accept: application/vnd.github.v3+json" \
  -H "Authorization: Bearer $GIT_AUTH_PSW" \
  "$url" | jq -r '.names[]' | grep --invert-match 'jenkins'
