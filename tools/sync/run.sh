#!/usr/bin/env bash


# sync files between projects

# how to define which files are being synced?
# how to define which projects each file is synced across?


file='.editorconfig'

# is there a newer version on the other projects?
# how to find newer version?
# clone other projects into sub dirs
# can be reused for all files under sync
# will the file have the timestamp from git?


# yes?
# take the newest version
# apply to this project


jq --version

# how to get the latest gradle version?
# Use the github release name
latestGradleVersion=$(curl -s https://api.github.com/repos/gradle/gradle/releases/latest | jq -r '.name')

./gradlew wrapper --gradle-version "$latestGradleVersion"
# need to run twice to get latest wrapper files
./gradlew wrapper --gradle-version "$latestGradleVersion"

# don't really need to check for updated files as git will handle that

#  cp "$f" "$f.before"
#  diff "$f" "$f.before" >/dev/null
#  updated=$?
#  totalUpdated=$((totalUpdated + updated))
#  if [ $updated -ne 0 ]; then
#    echo -n 'updated..'
##    TODO make delete imports not delete statics or make it more precise
##    $UTIL_PATH/delete-imports.sh "$f" 'org.mockito' 'Mock'
#    $UTIL_PATH/add-static-import.sh "$f" 'org.mockito.Mockito.mock'
#    $UTIL_PATH/remove-trailing-newline.sh "$f" "$f.before"
#  fi
#  rm "$f.before"



