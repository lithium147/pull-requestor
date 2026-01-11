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
#sed "${SED_OPTIONS[@]}" 's/^([[:space:]]*)'"$modifiers"'[[:space:]]+'"$modifiers"'[[:space:]]+'"$modifiers"'[[:space:]]+(@[0-9A-Za-z_\$£]*)[[:space:]]+(.*\{)/\1\5 \2 \3 \4 \6/' "$f"
#sed "${SED_OPTIONS[@]}" 's/^([[:space:]]*)'"$modifiers"'[[:space:]]+'"$modifiers"'[[:space:]]+(@[0-9A-Za-z_\$£]*)[[:space:]]+(.*\{)/\1\4 \2 \3 \5/' "$f"
#sed "${SED_OPTIONS[@]}" 's/^([[:space:]]*)'"$modifiers"'[[:space:]]+(@[0-9A-Za-z_\$£]*)[[:space:]]+(.*\{)/\1\3 \2 \4/' "$f"

modifiers='(public|private|protected|static|abstract|final)'

# Use a multiline matcher until the "{" is matched
# Otherwise it would match method params that have been wrapped over to a new line
# TODO this won't work on abstract methods as they don't have a "{"
function replaceMultiline() {
  local prefix="$1"
  local replacement="$2"

  sed "${SED_OPTIONS[@]}" '
/^[[:space:]]*'"$prefix"'(@[0-9A-Za-z_\$£]*)[[:space:]]+/{
  :b
  /^[[:space:]]*'"$prefix"'(@[0-9A-Za-z_\$£]*)[[:space:]]+(.*\{)/!{N;bb
  }
  s/^([[:space:]]*)'"$prefix"'(@[0-9A-Za-z_\$£]*)[[:space:]]+(.*\{)/'"$replacement"'/
}' "$f"
}
# handle three modifiers before annotation
replaceMultiline "$modifiers"'[[:space:]]+'"$modifiers"'[[:space:]]+'"$modifiers"'[[:space:]]+' '\1\5 \2 \3 \4 \6'
# handle two modifiers before annotation
replaceMultiline "$modifiers"'[[:space:]]+'"$modifiers"'[[:space:]]+' '\1\4 \2 \3 \5'
# handle one modifier - must be last one so it doesn't interfere with others
replaceMultiline "$modifiers"'[[:space:]]+' '\1\3 \2 \4'

# move the annotation to it's own line
replaceMultiline '' '\1\2\n\1\3'
