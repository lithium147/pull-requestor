#!/usr/bin/env bash
set -o errexit -o nounset -o pipefail

# Handle the different ways of running `sed` without generating a backup file based on OS
# - GNU sed (Linux) uses `-i`
# - BSD sed (macOS) uses `-i ''`
SED_OPTIONS=(-E -i)
case "$(uname)" in
Darwin*) SED_OPTIONS=(-E -i "") ;;
esac

SCRIPT_PATH=$(dirname "$0")
# util path might be one level up
if [ -e $(dirname "$0")/../../util ]; then
  UTIL_PATH=$(dirname "$0")/../../util
else
  UTIL_PATH=$(dirname "$0")/../util
fi

groupId="$1"
artifactId="$2"
token="$3"
branch="$4"
readmeFile="$5"
pod="$6"

# TODO use a tmp path
badgesTmpFile='badges.md'

function sonarBadge() {
  local metric="$1"
  local metricName="$2"
  local projectKey="${groupId}%3A${artifactId}"
  local path="dashboard?id=${projectKey}"
  if [ "$metric" != "alert_status" ]; then
    path="component_measures?id=${projectKey}&metric=${metric}&view=list"
  fi
  local md="[![${metricName}](https://devsupport-sonar.it.global.hsbc:9009/sonar/api/project_badges/measure?project=${projectKey}&metric=${metric}&token=${token})](https://devsupport-sonar.it.global.hsbc:9009/sonar/${path})"
  echo -n " $md" >> $badgesTmpFile
}

function jenkinsBadge() {
  local pod="$1"
  # should it get the jenkinsUrl from the pom?
  # TODO not working for tc-shared
  # https://risk-jenkins.systems.uk.hsbc/jenkins/buildStatus/icon?job=RISK_IT%2FTRADED_RISK%2FRAVENCR%2FNULL%2Fprojects%2Fshared%2Fmaster
  # https://risk-jenkins.systems.uk.hsbc/jenkins/job/RISK_IT/job/TRADED_RISK/job/RAVENCR/job/NULL/job/projects/job/shared/job/master/lastBuild/consoleFull
  # why is the pod null?
  # <artifactId>shared</artifactId> doesn't match project name in github
  # should the artifact be renamed to tc-shared?
  # can use $PROJECT for jenkins and $artifactId for sonar
  local jenkinsUrl="https://risk-jenkins.systems.uk.hsbc/jenkins/job/RISK_IT/job/TRADED_RISK/job/RAVENCR/job/${pod}/job/projects/job/${PROJECT}/job/${branch}/lastBuild/consoleFull"
  local jobPath="RISK_IT%2FTRADED_RISK%2FRAVENCR%2F${pod}%2Fprojects%2F${PROJECT}%2F${branch}"
  local md="[![Build Status](https://risk-jenkins.systems.uk.hsbc/jenkins/buildStatus/icon?job=${jobPath})](${jenkinsUrl})"
  echo -n " $md" >> $badgesTmpFile
}

jenkinsBadge $pod
sonarBadge 'alert_status' 'Quality Gate Status'
sonarBadge 'coverage' 'Coverage'
echo >> $badgesTmpFile

# remove existing badges
sed "${SED_OPTIONS[@]}" 's/\[\!\[Quality Gate Status\][^]]*\]\([^)]*\)//' "$readmeFile"
sed "${SED_OPTIONS[@]}" 's/\[\!\[Coverage\][^]]*\]\([^)]*\)//' "$readmeFile"
sed "${SED_OPTIONS[@]}" 's/\[\!\[Build Status\][^]]*\]\([^)]*\)//' "$readmeFile"
# insert new badges after line 1
sed "${SED_OPTIONS[@]}" '1r'$badgesTmpFile "$readmeFile"
# join new badges onto line
sed "${SED_OPTIONS[@]}" '1{N;s/[[:space:]]*\n[[:space:]]*/ /}' "$readmeFile"

rm -f "$badgesTmpFile"

# TODO would be good to combine all the badges into a single page
# could be README.md in pullrequestor project
# but have lost the project check out by this point
# - perhaps dont clean workspace

# otherwise, could update the README.md for this project.
# although, other jobs could be doing that at same time
# how to combine changes without conflicts?
# could add to end of file, then sort, then double space
# since orig project is wiped out, could do another git checkout and push to that
# but would be better to do to a PR
# no useful badges in github enterprise
# is there another way to get the number of open pull requestors in the readme?
