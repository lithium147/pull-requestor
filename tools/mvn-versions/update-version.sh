#!/usr/bin/env bash

# assume all scripts are in the source dir
SCRIPT_PATH=$(dirname "$0")

# Handle the different ways of running `sed` without generating a backup file based on OS
# - GNU sed (Linux) uses `-i`
# - BSD sed (macOS) uses `-i ''`
SED_OPTIONS=(-E -i.bak)
case "$(uname)" in
  Darwin*) SED_OPTIONS=(-E -i '.bak')
esac

f="$1"  # file
name="$2"
newVersion="$3"

function replaceMultiline() {
  tag="$1"
  sed "${SED_OPTIONS[@]}" '
/<'"$tag"'>[[:space:]]*(<!--.*-->)?[[:space:]]*$/{
  :b
  /.*<'"$tag"'>.*<\/'"$tag"'>[[:space:]]*(<!--.*-->)?[[:space:]]*$/!{N;bb
  }
  '"$2"'
}' "$3"

  # zero means true in bash if statements
  local changed=0
  if diff "$3" "$3.bak" &> /dev/null; then
    changed=1 # not changed
  fi
  rm "$3.bak"

  return $changed
}

artifactVersionReplacer="s/<artifactId>$name<\/artifactId>(.*)<version>.*<\/version>/<artifactId>$name<\/artifactId>\1<version>$newVersion<\/version>/"
# use [^<] as should not be another tag in between
# but this means a comment after the artifactId tag could break the matching
# How to allow for comments? Could replace comment start/end with something like [!--
# and then replace back afterwards
pluginArtifactVersionReplacer="s/<artifactId>$name<\/artifactId>([^<]*)<version>[^<]*<\/version>/<artifactId>$name<\/artifactId>\1<version>$newVersion<\/version>/"
if replaceMultiline 'dependency' "$artifactVersionReplacer" "$f"; then
  echo 'dependency'
  exit
fi
if replaceMultiline 'plugin' "$pluginArtifactVersionReplacer" "$f"; then
  echo 'plugin'
  exit
fi
if replaceMultiline 'extension' "$artifactVersionReplacer" "$f"; then
  echo 'extension'
  exit
fi
if replaceMultiline 'path' "$artifactVersionReplacer" "$f"; then
  echo 'path'
  exit
fi
