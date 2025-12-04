#!/usr/bin/env bash
set -o errexit -o nounset -o pipefail

SCRIPT_PATH=$(dirname "$0")
# util path might be one level up
if [ -e $(dirname "$0")/../../util ]; then
  UTIL_PATH=$(dirname "$0")/../../util
else
  UTIL_PATH=$(dirname "$0")/../util
fi

groupId="$1"
artifactId="$2"

projectKey="${groupId}%3A${artifactId}"
SONARQUBE_BASE_API_URL='https://devsupport-sonar.it.global.hsbc:9009/sonar/api'
curl -s -u "$NEXUS3_USER:$NEXUS3_PASSWORD" "${SONARQUBE_BASE_API_URL}/project_badges/token?project=${projectKey}" | jq -r '.token'
