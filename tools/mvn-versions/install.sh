#!/usr/bin/env bash
set -o errexit -o nounset -o pipefail

SCRIPT_PATH=$(dirname "$0")
# util path might be one level up
if [ -e $(dirname "$0")/../../util ]; then
  UTIL_PATH=$(dirname "$0")/../../util
else
  UTIL_PATH=$(dirname "$0")/../util
fi

function injectRules() {
  injection="$1"
  target="$2"

  # strip all but the rules from the ignore rules
  sed -E '0,/<rules>/d;/<\/rules>/,$d' "$injection" > "$SCRIPT_PATH/rules.tmp"
  # insert rules to ignore at beginning of <rules> block
  sed -E -i '/<rules>/r'$SCRIPT_PATH/rules.tmp "$target"
  rm "$SCRIPT_PATH/rules.tmp"
}

# setup rules for releases and snapshots

cp $UTIL_PATH/rules.xml $SCRIPT_PATH/rules.xml

cp $SCRIPT_PATH/rules.xml $SCRIPT_PATH/rules-snapshot.xml
cp $SCRIPT_PATH/rules.xml $SCRIPT_PATH/rules-release.xml


# detect version of spring boot
# check for parent in pom
# add the spring-boot2 rules here since that applies for all deps in the project
# could also detect based on java version - spring boot 3 can only be used with java17+
if $UTIL_PATH/spring-boot-version.sh pom.xml "2.*"; then
  echo "spring boot 2 detected, adding ignores from ignore-spring-boot3.xml"
  injectRules "$UTIL_PATH/ignore-spring-boot3.xml" "$SCRIPT_PATH/rules-snapshot.xml"
  injectRules "$UTIL_PATH/ignore-spring-boot3-and-raven-snapshot.xml" "$SCRIPT_PATH/rules-release.xml"
elif ! $UTIL_PATH/java-version.sh pom.xml "17"; then
  echo "non java 17 detected, adding ignores from ignore-spring-boot3.xml"
  injectRules "$UTIL_PATH/ignore-spring-boot3.xml" "$SCRIPT_PATH/rules-snapshot.xml"
  injectRules "$UTIL_PATH/ignore-spring-boot3-and-raven-snapshot.xml" "$SCRIPT_PATH/rules-release.xml"
else
  injectRules "$UTIL_PATH/ignore-raven-snapshots.xml" "$SCRIPT_PATH/rules-release.xml"
fi
