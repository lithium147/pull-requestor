#!/usr/bin/env bash

# assume all scripts are in the source dir
SCRIPT_PATH=$(dirname "$0")

# Handle the different ways of running `sed` without generating a backup file based on OS
# - GNU sed (Linux) uses `-i`
# - BSD sed (macOS) uses `-i ''`
SED_OPTIONS=(-E -i)
case "$(uname)" in
  Darwin*) SED_OPTIONS=(-E -i '')
esac

f="$1"  # file

function extractMultiline() {
  tag="$1"
  sed -E -n '
/<'"$tag"'>$/{
  :b
  /.*<'"$tag"'>.*<\/'"$tag"'>$/!{N;bb
  }
  '"$2"'
}' "$3"
}

# what if the parent version is defined by a property?
# parent version is not allowed to be a property
propertyExtractor='/\$\{.*\}/!{s/.*<artifactId>(.*)<\/artifactId>.*<version>(.*)<\/version>.*/\1:\2/p}'
extractMultiline 'parent' "$propertyExtractor" "$f"
