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
v="$2"  # version to match

function extractMultiline() {
  tag="$1"
  sed -E -n '
/<'"$tag"'>[[:space:]]*(<!--.*-->)?[[:space:]]*$/{
  :b
  /.*<'"$tag"'>.*<\/'"$tag"'>[[:space:]]*(<!--.*-->)?[[:space:]]*$/!{N;bb
  }
  '"$2"'
}' "$3"
}

propertyExtractor='/\$\{.*\}/!{s/.*<artifactId>(.*)<\/artifactId>.*<version>(.*)<\/version>.*/\1:\2/p}'
# remove blocks first as they might have ${props} in them
parent=$(extractMultiline 'parent' "$propertyExtractor" "$f")

if [[ "$parent" =~ spring-boot-starter-parent.* ]]; then
  echo "spring boot parent"
else
  exit 1
fi

if [[ "$parent" =~ .*:$v ]]; then
  echo "version matches $v"
else
  exit 1
fi

