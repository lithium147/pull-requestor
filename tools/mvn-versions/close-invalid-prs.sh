#!/usr/bin/env bash

# TODO close PR's for versions that have been updated in master, perhaps through another change
# could be another tool, since its a bit different
# for versions that are on the latest version
# check if there is an existing pr
# close it
# Also, what about PR's that have a conflict, might be helpful to close those and reopen
# but why would they have a conflict unless master was updated to latest?
# perhaps the dependency has been removed as its not required anymore
# actually, if the dependency has been removed, it wont be iterated through in mvn-versions
# would need an extra loop which checks all open pull-requestor PR's
#   for each open PR's
#     check for conflict
#     check if dependency still exists
#     close PR if so
#   this will mean when processing versions in next step, the conflicting PR will be created because they don't exist
# by closing the conflicting PR's, it solves the problem of artifacts that were updated to latest
# how to know if PR has a conflict?
#   seems like have to try to merge to local, then reset --hard
#   otherwise have to scrape the github pull request ui
# how to check if dependency still exists?
#   extract artifactId from PR title
#   search pom for artifactId
#   or use the property extraction script and then check that

# assume all scripts are in the source dir
SCRIPT_PATH=$(dirname "$0")
# util path might be one level up
if [ -e $(dirname "$0")/../../util ]; then
  UTIL_PATH=$(dirname "$0")/../../util
else
  UTIL_PATH=$(dirname "$0")/../util
fi

echo "---- open pr's ----"
hub pr list -b "$SRC_BRANCH" -f '%I %t%n'
echo "-------------------"
gh pr list

while read -r prNum prBranch prTitle; do
  # title="mvn-versions $artifactId:$newVersion"
  echo "*** checking pr: $prNum, title: $prTitle"
  if [[ ! "$prTitle" =~ "mvn-versions" ]]; then
    echo "not a mvn-versions pr, ignoring"
    continue
  fi

  artifactId=${prTitle##* }   # strip chars before the space
  artifactId=${artifactId%:*} # strip the version

  # doesn't handle pr's for submodules nicely
  # checking pr: 217, title: mvn-versions common:3.0.6
  # 217	mvn-versions common:3.0.6	pr/mvn-versions/security/common	OPEN	2024-03-16 22:50:36 +0000 UTC
  # artifactId is in title, but submodule name is in branch name
  # if submodule name doesn't match, then should ignore pr
  # as it will be handled when running on the submodule
  echo "prBranch: $prBranch"
  echo "CHANGE_BRANCH: $CHANGE_BRANCH"
  # prBranch: pr/mvn-versions/configuration-client/common
  # remove prefix 'pr/mvn-versions/'
#  prBranch=${prBranch#*/}   # strip pr/
#  prBranch=${prBranch#*/}   # strip mvn-versions/
  if [ "$prBranch" != "$CHANGE_BRANCH/$artifactId" ]; then
    echo "prBranch is not matching expected change branch, this means pr could be for a submodule, ignoring"
    continue
#    submodule=${prBranch%/*}   # strip /common
#    echo "detected submodule $submodule"
    # how to check its running on same submodule?
    # current dir, CHANGE_BRANCH, artifactId from pom
#    currentSubmodule=${CHANGE_BRANCH%/*}
#    echo "current submodule $currentSubmodule"
  fi

  # check for missing artifact first as its a lighter check
  echo "looking for $artifactId in pom"
  if ! grep "<artifactId>$artifactId</artifactId>" pom.xml && ! grep "<${artifactId}.version>" pom.xml; then
    echo "$artifactId is missing from pom, closing pr"
    $UTIL_PATH/close-pr.sh "$CHANGE_BRANCH/$artifactId" 'closed due to missing artifactId'
    continue
  fi

  # check for conflict - only way is to try to merge to the main branch
  git checkout "$CHANGE_BRANCH/$artifactId"
  # git merge --ff-only >>> seems to be rather sensitive - any commits to the main branch will show as merge failed
  # git merge --no-commit >>> seems to detect where there really is a conflict
  # TODO for branches that can be merged, could update from master so they are always up to date
  if ! git merge --no-commit "origin/$SRC_BRANCH"; then
    echo "merge failed"
    # abort was required on local, is it required in jenkins also?
    git merge --abort
    git checkout "$SRC_BRANCH"
    $UTIL_PATH/close-pr.sh "$CHANGE_BRANCH/$artifactId" 'closed due merge conflict'
  else
    echo "merge ok"
    # error: Your local changes to the following files would be overwritten by checkout:
    git merge --abort
    git checkout "$SRC_BRANCH"
  fi
done < <(hub pr list -b "$SRC_BRANCH" -f '%I %H %t%n')
