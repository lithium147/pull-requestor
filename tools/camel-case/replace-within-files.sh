#!/usr/bin/env bash

#set -x

# Handle the different ways of running `sed` without generating a backup file based on OS
# - GNU sed (Linux) uses `-i`
# - BSD sed (macOS) uses `-i ''`
SED_OPTIONS=(-i)
case "$(uname)" in
  Darwin*) SED_OPTIONS=(-i '')
esac

f=$1  # file

# \u doesn't work on mac
#sed -E "${SED_OPTIONS[@]}" 's/_([a-z])/\u\1/g' "$f"

# exclude by replacing them to something else
# - quoted strings
# - all caps
function joinBy {
  local IFS="$1"
  shift
  echo "$*"
}

function repeatedReplace() {
  cnt=$1
  begin="$2"
  middle="$3"
  end="$4"

  parts=("$begin")
  # have to use dollar notation for back reference since there are more than 9 groups
  replacements=('$1')
  for ((i=0; i<$cnt; i++)); do
    parts+=("$middle")
    replacements+=("\$$((i+2))")
  done
  parts+=("$end")
  replacements+=("\$$((cnt+2))")

  search=$(joinBy '_' "${parts[@]}")
  replacement=$(joinBy '±' "${replacements[@]}")
  perl -i -p -e 's/'"$search"'/'"$replacement"'/g' "$f"
#  sed -E -i 's/'"$search"'/'"$replacement"'/g' "$f"
}

for ((i=15; i>=0; i--)); do
  # perl -i -p -e 's/("[^"]*)_([^"]*)_([^"]*)_([^"]*")/\1±\2±\3±\4/g' "$f"
  # perl -i -p -e 's/("[^_"]*")?("[^"]*)_([^"]*")/\1\2±\3/g' "$f"
  repeatedReplace $i '("[^"]*)' '([^"]*)' '([^"]*")'
done

perl -i -p -e 's/([A-Z0-9]+)_([A-Z0-9]+)_([A-Z0-9]+)_([A-Z0-9]+)/\1±\2±\3±\4/g' "$f"
perl -i -p -e 's/([A-Z0-9]+)_([A-Z0-9]+)_([A-Z0-9]+)/\1±\2±\3/g' "$f"
perl -i -p -e 's/([A-Z0-9]+)_([A-Z0-9]+)/\1±\2/g' "$f"
perl -i -p -e 's/^package(.*)_(.*)_(.*)_(.*)/package\1±\2±\3±\4/g' "$f"
perl -i -p -e 's/^package(.*)_(.*)_(.*)/package\1±\2±\3/g' "$f"
perl -i -p -e 's/^package(.*)_(.*)/package\1±\2/g' "$f"
perl -i -p -e 's/^import(.*)_(.*)_(.*)_(.*)/import\1±\2±\3±\4/g' "$f"
perl -i -p -e 's/^import(.*)_(.*)_(.*)/import\1±\2±\3/g' "$f"
perl -i -p -e 's/^import(.*)_(.*)/import\1±\2/g' "$f"
perl -i -p -e 's/([^0-9A-Za-z_]|^)UTF_8([^0-9A-Za-z_]|$)/\1UTF±8\2/g' "$f"

perl -i -p -e 's/([[:space:]])([A-Z][a-z0-9]*_)/$1\l$2/g' "$f"  # first letter uppercase is made lower, but keep the underscore to be resolved next
perl -i -p -e 's/_+([a-z0-9])/\u$1/g' "$f"  # uppercase after underscore
perl -i -p -e 's/_+([A-Z][a-z])/$1/g' "$f"  # fix upper snake case

# safe to assume that there are no other occurrences of '±'
perl -i -p -e 's/±/_/g' "$f"
