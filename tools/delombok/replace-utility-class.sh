#!/usr/bin/env bash

# Handle the different ways of running `sed` without generating a backup file based on OS
# - GNU sed (Linux) uses `-i`
# - BSD sed (macOS) uses `-i ''`
SED_OPTIONS=(-E -i)
case "$(uname)" in
  Darwin*) SED_OPTIONS=(-E -i '')
esac

f=$1  # file

function replaceAnnotatedClass() {
  sed "${SED_OPTIONS[@]}" '
/@'"$1"'/{
  :b
  /.*@'"$1"'.*class.*\{$/!{N;bb
  }
  '"$2"'
}' "$f"
}

# @UtilityClass[[:space:]]* -- match annotation and the new line for removal
# (.*) -- match other annotations that could come after as want to keep these
replaceAnnotatedClass 'UtilityClass' 's/@UtilityClass[[:space:]]*(.*)((public )?(final )?class )([a-zA-Z0-9_\$£]+) \{/\1\2\5 \{\
    private \5() \{\
    \}/'

# TODO ensure all methods are static
