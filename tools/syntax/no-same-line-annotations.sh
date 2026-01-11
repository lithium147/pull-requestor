#!/usr/bin/env bash

# Handle the different ways of running `sed` without generating a backup file based on OS
# - GNU sed (Linux) uses `-i`
# - BSD sed (macOS) uses `-i ''`
SED_OPTIONS=(-E -i)
case "$(uname)" in
  Darwin*) SED_OPTIONS=(-E -i '')
esac

f=$1  # file

# Two steps:
# - move annotation to beginning of line
# - move leading annotations to their own line
# TODO These steps could be repeated in a loop in case there are multiple annotations
# could keep looping until the file didn't change

# need "{" to make sure it matches methods and not variables
# only matching simple annotations, eg: @Nullable
# won't work if annotation has params, eg: @Nullable(false)
# handle static then a keyword
sed "${SED_OPTIONS[@]}" 's/([[:space:]]*)(static)[[:space:]](public|private|protected)[[:space:]](@[0-9A-Za-z_\$£]*)[[:space:]](.*\{)/\1\4 \2 \3 \5/' "$f"
# handle a keyword static
sed "${SED_OPTIONS[@]}" 's/([[:space:]]*)(public|private|protected)[[:space:]](static)[[:space:]](@[0-9A-Za-z_\$£]*)[[:space:]](.*\{)/\1\4 \2 \3 \5/' "$f"
# handle a single keyword - must be last one so it doesn't interfere with others
sed "${SED_OPTIONS[@]}" 's/([[:space:]]*)(public|private|protected|static)[[:space:]](@[0-9A-Za-z_\$£]*)[[:space:]](.*\{)/\1\3 \2 \4/' "$f"

# move the annotation to it's own line
sed "${SED_OPTIONS[@]}" 's/([[:space:]]*)(@[0-9A-Za-z_\$£]*)[[:space:]](.*\{)/\1\2\n\1\3/' "$f"

# TODO might be a way to handle multiple modifiers in one command
# TODO are there other modifiers?
