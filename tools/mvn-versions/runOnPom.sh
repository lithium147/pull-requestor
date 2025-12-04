#!/usr/bin/env bash
shopt -s globstar

# this tries to update all deps including transitive which is useless
#mvn versions:use-next-versions

# How to update versions when there are many to update?
#   find the properties
#   for each property
#     update it
#     if it has changed exit
# This means there will be one update per run (every night)
# How to handle updates that are declined?
# If the branch is left in place, then it could be detected.
# Would be easier if the branch included the property name.
# This would require the branch name to be overridden.
# Could have a custom apply script.
# Dependabot works by creating many pr's per run, so could follow similar approach.
# Could convert dependencies to use properties, then convert back after the update.

#mvn org.codehaus.mojo:properties-maven-plugin:1.1.0:write-project-properties -DoutputFile=pom.properties

#mvn versions:update-properties
#mvn versions:update-properties -DincludeProperties=junit-jupiter.version

#mvn versions:commit


# Update spring boot
# requires updating spring boot parent and cloud bom together
#### Update plugins
# should it update all, or one by one like this tool?
# maybe can use properties for plugins?
# mvn versions:display-plugin-updates
# it works:
#                <plugin>
#                    <groupId>org.jacoco</groupId>
#                    <artifactId>jacoco-maven-plugin</artifactId>
#                    <version>${jacoco.version}</version>
#                </plugin>
# could use the same scripts
# as long as there are no overlaps

$MVN -v

CUSTOM_PARAMS=("$@")

# assume all scripts are in the source dir
SCRIPT_PATH=$(dirname "$0")
# util path might be one level up
if [ -e $(dirname "$0")/../../util ]; then
  UTIL_PATH=$(dirname "$0")/../../util
else
  UTIL_PATH=$(dirname "$0")/../util
fi

#tput setaf 1
#tput -T xterm setaf 1

#b=$(tput -T xterm bold)
#n=$(tput -T xterm sgr0)

# and the current dir is where the files to be modified are

$SCRIPT_PATH/close-invalid-prs.sh

cp pom.xml pom.xml.before-convert
$SCRIPT_PATH/convert-to-properties.sh pom.xml

cp pom.xml pom.xml.original

rules="file://$SCRIPT_PATH/rules-snapshot.xml"

if [ ${#CUSTOM_PARAMS[@]} -gt 0 ] && [ "${CUSTOM_PARAMS[0]}" != "" ] && [ "${CUSTOM_PARAMS[1]}" != "" ]; then
  echo "have custom params ${#CUSTOM_PARAMS[@]}"
  # TODO allow for multiple artifacts to be specified
  explicitArtifactId=${CUSTOM_PARAMS[0]}
  explicitArtifactId="${explicitArtifactId}.version"
  versionType=${CUSTOM_PARAMS[1]}
  if [ "${versionType}" = "release" ]; then
    echo "using release version"
    # force current version to be 0 and ignore snapshots
#    rules="file://$SCRIPT_PATH/rules-release.xml"
    $MVN -U -s ${MVN_SETTINGS} versions:set-property -Dproperty=$explicitArtifactId -DnewVersion=0
  fi
  echo "Only updating explicit artifact: $explicitArtifactId"
  sed -E -n "/<properties>/,/<\/properties>/{s/<\!--.*-->//;s/<\/[^>]*>//;s/.*<//;s/>/:/p}" pom.xml | grep version | grep "$explicitArtifactId"
  nameAndVersionArr=($(sed -E -n "/<properties>/,/<\/properties>/{s/<\!--.*-->//;s/<\/[^>]*>//;s/.*<//;s/>/:/p}" pom.xml | grep version | grep "$explicitArtifactId"))
else
  sed -E -n "/<properties>/,/<\/properties>/{s/<\!--.*-->//;s/<\/[^>]*>//;s/.*<//;s/>/:/p}" pom.xml | grep version
  nameAndVersionArr=($(sed -E -n "/<properties>/,/<\/properties>/{s/<\!--.*-->//;s/<\/[^>]*>//;s/.*<//;s/>/:/p}" pom.xml | grep version))
fi

countOccurrences() {
  local word=$1
  local cnt=0
  shift
  for e in "$@"; do
    if [[ "$e" =~ ^${word} ]]; then
      cnt=$((cnt+1))
    fi
  done
  return $cnt
}

cnt=0
for nameAndVersion in ${nameAndVersionArr[@]}; do
  cnt=$((cnt+1))
  echo -e "\033[1mchecking for updates of $nameAndVersion ($cnt of ${#nameAndVersionArr[@]})\033[0m"
  parts=(${nameAndVersion//:/ })
  propName=${parts[0]}
  version=${parts[1]}
  artifactId=${propName%.version}  # remove '.version' from prop name
  newVersion=$version

  if [ "$version" == "1.0.0-SNAPSHOT" ]; then
    echo "ignoring artifact version managed by build"
    continue
  fi

  echo "updating $artifactId from version $version"

  # if property is repeated with different versions, then might retrieve the old version which has not changed
  # ignore these for now, but is there a better way?  perhaps could extract a property
  countOccurrences "${propName}:" "${nameAndVersionArr[@]}"
  occurs=$?
  if [ $occurs -gt 1 ]; then
    echo -e "\033[31mERROR\033[0m::$propName appears more than once, ignoring (occurred $occurs times)"
    continue
  fi

  # call any command on semver to validate to see if it is a release version
  $UTIL_PATH/semver.sh get major "$version" >/dev/null
  if [ $? -eq 0 ] || [ "${versionType}" = "release" ]; then
    echo "a semver, using releases"
    rulesPath="$SCRIPT_PATH/rules-release.xml"
#    rules="file://c:\Users\43999227\IdeaProjects\pull-requestor\tools\mvn-versions\rules-release.xml"
  else
    echo "not a semver, using snapshots"
    rulesPath="$SCRIPT_PATH/rules-snapshot.xml"
#    rules="file://c:\Users\43999227\IdeaProjects\pull-requestor\tools\mvn-versions\rules-snapshot.xml"
  fi
  if which cygpath &>/dev/null; then
    # mvn run from gitbash requires a windows path.  this might not be the case if using mvnw..
    rulesPath=$(cygpath --windows "$rulesPath")
  fi
  rules="file://$rulesPath"

#  rules="file://c:\Users\43999227\IdeaProjects\pull-requestor\tools\mvn-versions\rules-release.xml"
#  $MVN -s ${MVN_SETTINGS} versions:update-properties -DincludeProperties=$propName -Dmaven.version.rules="file://c:\Users\43999227\IdeaProjects\pull-requestor\tools\mvn-versions\rules-release.xml"
  # -U forces update from nexus
  # -X debug
  if [ -e "${MVN_SETTINGS}" ]; then
    echo 'with settings'
    $MVN -U -s ${MVN_SETTINGS} versions:update-property -Dproperty=$propName -Dmaven.version.rules=${rules}
  else
    echo 'without settings'
    $MVN -U versions:update-property -Dproperty=$propName -Dmaven.version.rules=${rules}
  fi

  # seems to be overlap in these:
  # - beam.version:2.41.0
  # - nemo-compiler-frontend-beam.version:0.1
  # grep is not precise enough, so include prefix/suffix on match
  # <beam.version>2.41.0</beam.version> -> beam.version:2.41.0
  # remove comments, remove closing tag, remove beginning of line inc <, replace remaining > with :
  newNameAndVersion=$(sed -E -n "/<properties>/,/<\/properties>/{s/<\!--.*-->//;s/<\/[^>]*>//;s/.*<//;s/>/:/p}" pom.xml | grep "^${propName}:")
  parts=(${newNameAndVersion//:/ })
  newVersion=${parts[1]}

  diff pom.xml pom.xml.original
  if [ $? -ne 0 ]; then
    # sometimes the version detected by versions:update-properties is missing
    # seems to apply to raven libs.
    # is there a way to check the dependency before proceeding?
#    if ! $MVN -s ${MVN_SETTINGS} dependency:analyze; then
#      echo 'failed analyze, ignoring'
#      continue
#    fi
    # still reports it as ok.  perhaps its coming from the local repo.

    echo "checking for existing branch: $CHANGE_BRANCH/$artifactId"
    # TODO check for a closed PR - but what if PR was closed so it couldn't be rerun?
    matchingBranches=$(git ls-remote --heads origin "$CHANGE_BRANCH/$artifactId" | wc -l)
    if [ $matchingBranches -gt 0 ]; then
      echo 'branch already exists'
      cp pom.xml.original pom.xml

      echo "existing PRs for branch: $CHANGE_BRANCH/$artifactId"
      hub pr list -h "$CHANGE_BRANCH/$artifactId" -f '%t'
      prTitle=$(hub pr list -h $CHANGE_BRANCH/$artifactId -f '%t' -L 1)
      echo "existing PR: $prTitle"
      prVersion=${prTitle##*:}
      echo "existing PR version: $prVersion"
      # XXX if there is a branch but no PR, then prVersion will be empty
      # This means branches without a PR will always be recreated, even if the version is the same

      if [ "$prVersion" != "$newVersion" ]; then
        echo 'newVersion is different to prVersion, so can use newVersion'
        $UTIL_PATH/close-pr.sh "$CHANGE_BRANCH/$artifactId" "superseded by $newVersion"
        break
      else
        # Ensure version not updated in case its falling out of the loop
        newVersion=$version
      fi

      continue
      # TODO if branch was for an older version, then it can be replaced with the new version
      # should it delete the existing branch and create a new one, or should it update it?
      # could check out the existing branch, then perform update
      #   if its same version then no changes will be made
      #   otherwise, push to the branch and PR will be updated automatically
      #   this way don't need to know the version in the branch
      #   but what if the branch is out of date and the pom has changed?
      #   could update from remote.
      #   this will also keep the history in one PR.
      #   How to checkout the branch?
      #     Doing check out might spoil current state
      #     Also, if the branch was not updated after the checkout,
      #     Then would need to revert so tool can continue with next property
      # otherwise, need to check branch to workout which version its for
      #   this is safer in a way because doesn't matter if existing branch is stale
      #   Can look at the pr title: "$PR_TOOL $artifactId:$newVersion"
      #   How to get the title for a PR from the branch?
      # What does Dependabot do?
      #   It closes the PR and creates new one
      # Also Dependabot includes version in branch name, eg:
      #   dependabot/maven/org.assertj-assertj-core-3.23.1

    fi
    echo "version updated - $artifactId"

    # if the new version is not a semantic number, don't use it
    # only accept 12.34 or 12.34.56 or 12.34.56.789 for now
    # How to make maven ignore those other versions?
    # rules-release.xml does this
    # what about raven versions like: 202208020138-3f3af82
    # number comparisons don't work, so must be either 1.0.0 or 202208020138-3f3af82
    # ignore date based versions for now.
    # even with ignore, date based version won't be moved because number will be smaller that date based value.
    # could force the current version to 0 so update happens
    # but then version could go backwards
    # could have a custom methodology for raven deps:
    #   set current version to 0
    #   run mvn properties update
    #   extract new version
    #   determine git commit id's for both versions
    #   compare based on commitId, which one is newer?
    # alternatively:
    #   find the commitId from the tag of the semantic version
    #   build the date based version from this
    #   replace the semantic version with the date version in the pom
    #   run mvn update
    #   it will update to a newer date based version
    #   determine git commitId for this one
    #   check if there is a tag
    #   if so, use that tag as the version
    # allowing for conversion from date to semantic, but not the other way:
    #   set current version to 0
    #   run mvn properties update (where date versions are ignored)
    #   extract new version
    #   determine git commit id's for new version and build date based version
    #   compare based on date style version?
    #   if new version is newer, then use the semantic representation
    #   otherwise, original date based version will be left in place
    # only have artifactId for raven project, don't know the github repo.
    #   is it possible to find the date for the artifact from nexus?
    # could force conversion to semantic
    #   set current version to 0
    #   run mvn properties update (where date versions are ignored)
    #   extract new version and use it (even if it could be older)
    #   otherwise, there is no semantic version
    # could align approach with current version style
    #   if current is semantic, use rules that exclude date style
    #   if current is date based, use rules that include date style
    # When a new release is made can push update to all projects
    #   as know it is the latest version and safe to update
    #   need to be able to run the update tool for:
    #     all projects, artifactId
    # Could have another job just for this scenario,
    # or could add params to the main job
    #   multiselect for the projects
    #   multiselect for the tools
    #   multiselect is tricky.  could use single param to choose the tool
    #   otherwise it will run all tools
    #   how to specify the artifactId?
    #     its a special param for a tool.  how to specify params per tool?
    #     could have syntax like mvn-versions:raven-security-util
    #     or could just pass same params to all tools for now
    #   should the new version be passed in or should it follow update process?
    #   if using update process, then need a flag to know if it can be a release version or snapshot version
    #   or could set current version in pom to 0
    #   0 wont work because it will still update to snapshot version
    #   if release version
    #     need to do both: set current version to 0 and ignore snapshots
    #   if snapshot version
    #     allow snapshots
    #   if release version
    #     need to do both: set current version to 0 and ignore snapshots
    #   if snapshot version
    #     do nothing

    break

  fi
  echo "version not updated - $artifactId"
done
# TODO how to raise multiple PR from the same tool?
# After a PR is raised, keep looping through the properties.
# would need to bring in the PR creation into the run script.
# or perhaps the pr creation could be delegated:
# - $MVN set-version artifactId version
# this tool might have other uses - eg, when a new version of a lib is released
# or switching from to semver lib
# after each property, dont need to revert anything since it will be done in another job
# how to launch the new job? can it be done from bash, or does it need to be done in groovy?
#
# Could rerun from Jenkinsfile, it will start again from the first property
# but since the branch would exist for the previous property, it would eventually get to the next one
# would need to clear out local changes and get back to primary branch
# could a reset for that

if [ "$version" = "$newVersion" ]; then
  echo 'version unchanged, will not do anything'
  cp pom.xml.before-convert pom.xml
  rm -f pom.xml.before-convert
  rm -f pom.xml.original
  exit
fi

echo "version of $artifactId updating from $version to $newVersion"
cp pom.xml.before-convert pom.xml

# how to know if it was already property?
# can just look for property in original file
grep -q "$propName" pom.xml
if [ $? -eq 0 ]; then
  echo 'updating existing property'
  # what if the artifactId was already a property?
  # this will break the property usage, so need to avoid that.
  # the standard mvn prop update works in this case, so revert to that.
  # requires the unconverted file. perhaps run the process twice.
  # could rerun the mvn update on the original file.
  $MVN -U -s ${MVN_SETTINGS} versions:set-property -Dproperty=$propName -DnewVersion=$newVersion
  label='property'
else
  echo 'updating version in pom'
  label=$($SCRIPT_PATH/update-version.sh pom.xml "$artifactId" "$newVersion")
fi

rm -f pom.xml.before-convert
rm -f pom.xml.original
rm -f pom.xml.versionsBackup
rm -f .attach*
rm -f ./**/.attach*

# TODO just checking for version is not a reliable validation
if ! grep -q ">$newVersion<" pom.xml; then
  echo "ERROR::expecting a version to be updated to $newVersion in pom"
  exit 255
fi

# add label for type: dependency, plugin, extension
# not easy to keep track of the type through the process
# also, for existing properties, don't know the type, would have to work that out
# or could use type=property
# and can get the type from update-version.sh

# extract the version of the updated property
# restore pre-converted file
# replace dep $name with $version
# could use mvn versions plugin
# $MVN versions:use-dep-version -Dincludes=org.projectlombok:lombok -DdepVersion=1.1.1
# requires groupId also
# the property just has the artifactId, so not easy to get groupId

# title is used for both commit message and pr title
# TODO include module subDir in PR title
title="mvn-versions $artifactId:$newVersion"
branch="$CHANGE_BRANCH/$artifactId"

# TODO add link to library release - requires knowing the group
# how to work out the group since the properties only contain the artefactId?
#if [ "$group" = "com.hsbc.host.raven" ]; then
#  link="https://alm-github.systems.uk.hsbc/raven-cr/${artifactId}/releases/tag/${newVersion}"
#  echo $link >> $SCRIPT_PATH/description.txt
#fi
#        } else if (!id.contains('hsbc')) {
#            link = "https://mvnrepository.com/artifact/" + id.replace(":", "/")

# since already have description.txt, can follow a similar approach
echo "maven $label" > $SCRIPT_PATH/labels.txt
echo $title > $SCRIPT_PATH/title.txt
echo $branch > $SCRIPT_PATH/branch.txt

exit 1  # successfully made a change
