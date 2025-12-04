#!/usr/bin/env bash

# Handle the different ways of running `sed` without generating a backup file based on OS
# - GNU sed (Linux) uses `-i`
# - BSD sed (macOS) uses `-i ''`
SED_OPTIONS=(-E -i)
case "$(uname)" in
  Darwin*) SED_OPTIONS=(-E -i '')
esac

f="$1"  # file

function removeBlankLineAfterOpeningBraces() {
  sed "${SED_OPTIONS[@]}" '
/[{]$/{
  :b
  /[{]$/{N;bb
  }
  s/^(.*[{])\n$/\1/
}' "$f"
}

if [[ $f == *.yaml ]] || [[ $f == *.yml ]]; then
  # where there is a non-blank line followed by a line without leading white space
  # insert a new line between
  # couldn't get this approach working
  # instead add a new line before every root block line
  # and if there are multiple blank lines, that will be fixed subsequently
  # skip comments lines - but this means new line needs to be added before comment line
  sed "${SED_OPTIONS[@]}" '/^#/,/^[a-zA-Z0-9]/!s/^([a-zA-Z0-9]+.*)$/\n\1/g' "$f"
  echo -n '.'
fi

# skip on python files since they use double new lines between methods
if [[ $f != *.py ]]; then
  # https://stackoverflow.com/questions/4521162/can-i-use-the-sed-command-to-replace-multiple-empty-line-with-one-empty-line
  sed "${SED_OPTIONS[@]}" '/^$/N;/^\n$/D' "$f"
  echo -n '.'

  # remove blank line after opening brace
  # this misses cases where there are two opening brace lines in a row
#  sed "${SED_OPTIONS[@]}" '/[{]$/N;s/^(.*[{])\n$/\1/' "$f"
  removeBlankLineAfterOpeningBraces
  echo -n '.'
  # remove blank line before closing brace
  # closing brace could be part of a lambda, eg "  });"
  sed "${SED_OPTIONS[@]}" '/^$/N;s/^\n([[:space:]]*})/\1/' "$f"
  echo -n '.'
fi

# remove leading blank lines
sed "${SED_OPTIONS[@]}" '/./,$!d' "$f"
echo -n '.'

# remove trailing spaces
sed "${SED_OPTIONS[@]}" 's/[[:space:]]*$//' "$f"
