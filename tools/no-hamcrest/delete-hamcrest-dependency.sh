#!/usr/bin/env bash
shopt -s globstar

# util path might be one level up
if [ -e $(dirname "$0")/../../util ]; then
  UTIL_PATH=$(dirname "$0")/../../util
else
  UTIL_PATH=$(dirname "$0")/../util
fi

# for mac
#setopt extended_glob

#testCompile "org.hamcrest:hamcrest-all:1.3"

# Handle the different ways of running `sed` without generating a backup file based on OS
# - GNU sed (Linux) uses `-i`
# - BSD sed (macOS) uses `-i ''`
SED_OPTIONS=(-i)
case "$(uname)" in
  Darwin*) SED_OPTIONS=(-i '')
esac

for f in build.gradle **/build.gradle; do
  if [ ! -e "$f" ]; then
    continue
  fi

  echo -n "Processing $f "

  cp "$f" "$f.before"

  sed "${SED_OPTIONS[@]}" '/org.hamcrest/d' "$f"
  $UTIL_PATH/remove-trailing-newline.sh "$f" "$f.before"

  rm "$f.before"
  echo 'done'
done


#    testImplementation('org.awaitility:awaitility:4.1.0') {
#        exclude group: 'org.hamcrest', module: 'hamcrest'
#    }
