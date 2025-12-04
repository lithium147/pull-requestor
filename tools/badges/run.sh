#!/usr/bin/env bash

shopt -s nullglob
shopt -s globstar
setopt extended_glob

# Handle the different ways of running `sed` without generating a backup file based on OS
# - GNU sed (Linux) uses `-i`
# - BSD sed (macOS) uses `-i ''`
SED_OPTIONS=(-E -i.bak)
case "$(uname)" in
  Darwin*) SED_OPTIONS=(-E -i '.bak')
esac

SCRIPT_PATH=$(dirname "$0")

branch=$SRC_BRANCH

if [ -e pom.xml ]; then
  echo "pom detected"

  # Need the project.artifactId to create the run config
  # assume the first artifactId tag in the pom is the main one
  # TODO exclude parent block in case it appears first
  artifactId=$(sed -E -n 's/^.*<artifactId>(.*)<\/artifactId>.*$/\1/p' pom.xml | head -n 1)
  groupId=$(sed -E -n 's/^.*<groupId>(.*)<\/groupId>.*$/\1/p' pom.xml | head -n 1)
  token=$($SCRIPT_PATH/sonarToken.sh "$groupId" "$artifactId")

  if [ "$token" == "" ] || [ "$token" == "null" ]; then
    # run command again to see output
    $SCRIPT_PATH/sonarToken.sh "$groupId" "$artifactId"
    echo "could not get token for $groupId:$artifactId"
    exit 255
  fi

  # XXX how to determine the pod?
  # perhaps can get the tag from github
  # this is where it would be better to run in the project-configurer
  pod=$($SCRIPT_PATH/githubTopic.sh "$GITHUB_ORGANISATION" "$PROJECT")
  pod=${pod^^}  # uppercase in jenkins url
  echo "$groupId $artifactId $token $branch $pod"
  $SCRIPT_PATH/readme.sh "$groupId" "$artifactId" "$token" "$branch" "README.md" "$pod"
fi

git add README.md
