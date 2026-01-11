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
modifiers='(public|private|protected|static|abstract|final)'
# handle three modifiers before annotation
sed "${SED_OPTIONS[@]}" 's/^([[:space:]]*)'"$modifiers"'[[:space:]]+'"$modifiers"'[[:space:]]+'"$modifiers"'[[:space:]]+(@[0-9A-Za-z_\$£]*)[[:space:]]+(.*\{)/\1\5 \2 \3 \4 \6/' "$f"
# handle two modifiers before annotation
sed "${SED_OPTIONS[@]}" 's/^([[:space:]]*)'"$modifiers"'[[:space:]]+'"$modifiers"'[[:space:]]+(@[0-9A-Za-z_\$£]*)[[:space:]]+(.*\{)/\1\4 \2 \3 \5/' "$f"
# handle one modifier - must be last one so it doesn't interfere with others
sed "${SED_OPTIONS[@]}" 's/^([[:space:]]*)'"$modifiers"'[[:space:]]+(@[0-9A-Za-z_\$£]*)[[:space:]]+(.*\{)/\1\3 \2 \4/' "$f"

# move the annotation to it's own line
# TODO this matches method params that have been wrapped over to a new line
# which also means, annotations in the first line will not be fixed as they don't have the "{"
# how to exclude those?
# perhaps could use a multiline matcher until the "{" is matched
sed "${SED_OPTIONS[@]}" 's/^([[:space:]]*)(@[0-9A-Za-z_\$£]*)[[:space:]]+(.*\{)/\1\2\n\1\3/' "$f"
