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

propertyExtractor='/\$\{.*\}/!{s/.*<maven.compiler.release>(.*)<\/maven.compiler.release>.*/\1/p}'
# remove blocks first as they might have ${props} in them
#version=$(extractMultiline 'properties' "$propertyExtractor" "$f")
version=$(sed -E -n "$propertyExtractor" "$f")

if [[ "$version" -eq "$v" ]]; then
  echo "version matches $v"
else
  exit 1
fi
