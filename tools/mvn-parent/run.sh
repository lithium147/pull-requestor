#!/usr/bin/env bash

UTIL_PATH=$(dirname "$0")/../util
SCRIPT_PATH=$(dirname "$0")

# Handle the different ways of running `sed` without generating a backup file based on OS
# - GNU sed (Linux) uses `-i`
# - BSD sed (macOS) uses `-i ''`
SED_OPTIONS=(-E -i)
case "$(uname)" in
  Darwin*) SED_OPTIONS=(-E -i '')
esac

echo 'Attempt update of parent from:'
$SCRIPT_PATH/extract-parent.sh pom.xml

function injectRules() {
  injection="$1"
  target="$2"

  # strip all but the rules from the ignore rules
  sed -E '0,/<rules>/d;/<\/rules>/,$d' "$injection" > "$SCRIPT_PATH/rules.tmp"
  # insert rules to ignore at beginning of <rules> block
  sed -E -i '/<rules>/r'$SCRIPT_PATH/rules.tmp "$target"
  rm "$SCRIPT_PATH/rules.tmp"
}

cp $UTIL_PATH/rules.xml $SCRIPT_PATH/rules.xml

if $UTIL_PATH/spring-boot-version.sh pom.xml "2.*"; then
  echo "spring boot 2 detected, adding ignores from ignore-spring-boot3.xml"
  injectRules "$UTIL_PATH/ignore-spring-boot3.xml" "$SCRIPT_PATH/rules.xml"
fi

$MVN -U -s ${MVN_SETTINGS} versions:update-parent -Dmaven.version.rules="file://$SCRIPT_PATH/rules.xml"

rm -f pom.xml.versionsBackup

# Include artifactId in branch name and/or commit message
# since there can only be one parent for a project, don't need to include in branch name
# but commit message and pr title would still be useful
# Although, this would mean there is another thing to update if updating an existing PR/branch

# How to determine artifactId and new version?
artifactAndVersion=$($SCRIPT_PATH/extract-parent.sh pom.xml)
parts=(${artifactAndVersion//:/ })
artifactId=${parts[0]}

# How to get the artifactAndVersion into the PR/branch?
# could use custom apply.sh
# title used for both commit message and pr title
title="mvn-parent $artifactAndVersion"
branch="$CHANGE_BRANCH/$artifactId"

# since already have description.txt, can follow a similar approach
echo $title > $SCRIPT_PATH/title.txt
echo $branch > $SCRIPT_PATH/branch.txt
