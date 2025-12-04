#!/usr/bin/env bash

SCRIPT_PATH=$(dirname "$0")
# util path might be one level up
if [ -e $(dirname "$0")/../../util ]; then
  UTIL_PATH=$(dirname "$0")/../../util
else
  UTIL_PATH=$(dirname "$0")/../util
fi

# Handle the different ways of running `sed` without generating a backup file based on OS
# - GNU sed (Linux) uses `-i`
# - BSD sed (macOS) uses `-i ''`
SED_OPTIONS=(-E -i)
case "$(uname)" in
  Darwin*) SED_OPTIONS=(-E -i '')
esac

# TODO overwrite existing branch if a newer version exists

# force update from external repo
rulesPath=$UTIL_PATH/rules.xml
if which cygpath &>/dev/null; then
  # mvn run from gitbash requires a windows path.  this might not be the case if using mvnw..
  rulesPath=$(cygpath --windows "$rulesPath")
fi
rules="file://$rulesPath"

cd $SCRIPT_PATH || exit
MVN_OPTIONS=(-U)
if [ -e "${MVN_SETTINGS}" ]; then
  echo 'with settings'
  MVN_OPTIONS=(-U -s "${MVN_SETTINGS}")
fi
$MVN "${MVN_OPTIONS[@]}" versions:update-properties -DincludeProperties=apache-maven.version -Dmaven.version.rules=${rules}
$MVN "${MVN_OPTIONS[@]}" compile
$MVN "${MVN_OPTIONS[@]}" help:evaluate -Dexpression=apache-maven.version -q -DforceStdout
latestVersion=$($MVN "${MVN_OPTIONS[@]}" help:evaluate -Dexpression=apache-maven.version -q -DforceStdout)
cd - || exit

# the following nexus url doesn't seem to update anymore, so just use version that was updated in pom
#nexusUrl='https://nexus304.systems.uk.hsbc:8081/nexus/service/rest/repository/browse/mavencentral_iq'
# there is no option to use latest version, so need to find latest
# how to get the latest maven version?
# This approach will only find versions that have already been used by another project somewhere
# Perhaps could create a pom.xml with maven binary as a dependency and then do mvn versions:update-properties
#echo "looking for versions in nexus - ${nexusUrl}/org/apache/maven/apache-maven/"
#curl -k -L -u "$NEXUS3_USER:$NEXUS3_PASSWORD" "${nexusUrl}/org/apache/maven/apache-maven/"

# https://nexus304.systems.uk.hsbc:8081/nexus/service/rest/repository/browse/mavencentral_iq/org/apache/maven/apache-maven/

#curl -k -L -u "$NEXUS3_USER:$NEXUS3_PASSWORD" "${nexusUrl}/org/apache/maven/apache-maven/" | grep href | sed 's/<[^>]*>//g' | sed 's/\s*//g' | sed 's/[/]//g' | sed '/^[^0-9]/d'
#latestVersion=$(curl -k -L -u "$NEXUS3_USER:$NEXUS3_PASSWORD" "${nexusUrl}/org/apache/maven/apache-maven/" | grep href | sed 's/<[^>]*>//g' | sed 's/\s*//g' | sed 's/[/]//g' | sed '/^[^0-9]/d' | tail -n 1)

if [ "$latestVersion" == "" ]; then
  echo "ERROR::no version detected, something went wrong"
  exit 255
fi

echo "updating maven version to $latestVersion"

function mkSemver() {
  # call any command on semver to validate the version format and add ".0" if required
  $UTIL_PATH/semver.sh get major "$1" &>/dev/null
  if [ $? -ne 0 ]; then
    echo "$1.0"
  else
    echo "$1"
  fi
}

# latest release might be of the previous major version, eg: 6.9.1
# could compare the version with the current version to make sure it is actually newer
#currentGradleVersion=$(./gradlew --version | sed -nE '/^Gradle/s/Gradle //p')
#echo "current gradle version $currentGradleVersion"
#
#latestGradleSemver=$(mkSemver "$latestGradleVersion")
#currentGradleSemver=$(mkSemver "$currentGradleVersion")
#
#comparison=$($UTIL_PATH/semver.sh compare $latestGradleSemver $currentGradleSemver)
#if [ $? -ne 0 ]; then
#  echo "comparison failed, aborting"
#  exit
#fi
#
#if [ "$comparison" -lt 0 ]; then
#  echo "$latestGradleVersion is an older version than the current version of $currentGradleVersion"
#else
  # since 3.1.1 is not working, use script mode so the version can be changed easily
$MVN "${MVN_OPTIONS[@]}" wrapper:wrapper -Dmaven="$latestVersion" -Dtype=script

#-DincludeDebug=true
#-Dtype=script

  # replace the url's for nexus
central='https:\/\/repo.maven.apache.org\/maven2\/'
internal='https:\/\/nexus305.systems.uk.hsbc:8081\/nexus\/repository\/prd\/'
sed "${SED_OPTIONS[@]}" "s/${central}/${internal}/" .mvn/wrapper/maven-wrapper.properties

#distributionUrl=https://repo.maven.apache.org/maven2/org/apache/maven/apache-maven/3.8.2/apache-maven-3.8.2-bin.zip
#wrapperUrl=https://repo.maven.apache.org/maven2/org/apache/maven/wrapper/maven-wrapper/3.1.1/maven-wrapper-3.1.1.jar
#
#distributionUrl=https://dsnexus.uk.hibm.hsbc:8081/nexus/content/groups/prd/org/apache/maven/apache-maven/3.8.1/apache-maven-3.8.1-bin.zip
#wrapperUrl=https://dsnexus.uk.hibm.hsbc:8081/nexus/content/groups/prd/org/apache/maven/wrapper/maven-wrapper/3.1.0/maven-wrapper-3.1.0.jar
#

#fi

title="mvnw $latestVersion"
echo $title > $SCRIPT_PATH/title.txt

# TODO description is used for both commit and pr, however commit doesn't support markdown
# so allow pr description to be override
asfUrl="https://maven.apache.org/docs/${latestVersion}/release-notes.html"
echo >> $SCRIPT_PATH/description.txt
echo "[Release notes](${asfUrl})" >> $SCRIPT_PATH/description.txt
