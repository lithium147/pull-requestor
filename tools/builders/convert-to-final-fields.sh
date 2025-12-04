#!/usr/bin/env bash

# Handle the different ways of running `sed` without generating a backup file based on OS
# - GNU sed (Linux) uses `-i`
# - BSD sed (macOS) uses `-i ''`
SED_OPTIONS=(-E -i)
case "$(uname)" in
  Darwin*) SED_OPTIONS=(-E -i '')
esac

f="$1"  # file

# Ignore:
# - fields already final
# - static fields
# - fields assigned a value
# - methods
# ensure the statement ends in a semicolon so its not a method
sed "${SED_OPTIONS[@]}" '/(final|static|[={])/!{s/^([[:space:]]*)(public|protected|private)(.*);$/\1\2 final\3;/}' "$f"

# Change visibility from public to private
# TODO what about protected/package protected?
sed "${SED_OPTIONS[@]}" '/(static|[={])/!s/^([[:space:]]*)public[[:space:]](.*);$/\1private \2;/' "$f"

# TODO what about field with values?
# a private final field with a default means builder can't set it.
# if default value is an empty list, can remove it.
sed "${SED_OPTIONS[@]}" '/(final|static|[{])/!{s/^([[:space:]]*)private(.*)[[:space:]]=[[:space:]]*new[[:space:]]+ArrayList<>\(\);$/\1private final\2;/}' "$f"
sed "${SED_OPTIONS[@]}" '/(final|static|[{])/!{s/^([[:space:]]*)private(.*)[[:space:]]=[[:space:]]*List.of\(\);$/\1private final\2;/}' "$f"

function addAnnotation() {
  annotation="$1"

  sed "${SED_OPTIONS[@]}" '
/^[[:space:]]*@/{
  :b
  /^[[:space:]]*@[^;{]*/!{N;bb
  }
  /(static|[={]|@'"$annotation"')/!{s/^([[:space:]]*)(public|protected|private|final|[[:space:]]*)*List<.*;$/\1@'"$annotation"'\n\0/}
}' "$f"
}

# add @Singular only if its not already there
# add singular to List fields
# might be better to do this along side converting the code use the singular
# singular is something that could be added at anytime, so could be run nightly
# to convert usage:
# need to know the singular fields
addAnnotation Singular
