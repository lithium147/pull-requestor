#!/usr/bin/env bash

shopt -s nullglob
shopt -s globstar
# setopt extended_glob

SCRIPT_PATH=$(dirname "$0")
# util path might be one level up
if [ -e $(dirname "$0")/../../util ]; then
  UTIL_PATH=$(dirname "$0")/../../util
else
  UTIL_PATH=$(dirname "$0")/../util
fi

maxFilesAffected=0
if [ "$1" = "--maxFilesAffected" ]; then
  if [ "$#" -lt 2 ] || [ "$2" = "" ]; then
    echo "'--maxFilesAffected' requires a value, eg: --maxFilesAffected 100"
  fi
  maxFilesAffected=$2

  shift
  shift
fi
totalUpdated=0
searchFiles="$1"
replaceFiles="$2"

echo 'migrating existing builders to use with prefix'
while read -r p c; do
  echo "converting usages of: $p.$c"

  for f in $replaceFiles; do
    # the package could be found in an import or package statement
    if ! ( grep -Eq "$p" "$f" && grep -Eq "$c" "$f" ); then
      echo -n "."
      continue
    fi
    echo ""
    echo -n "  Processing $f "

    cp "$f" "$f.before"

    $SCRIPT_PATH/use-with-prefix.sh "$c" "$f"
    $UTIL_PATH/remove-trailing-newline.sh "$f" "$f.before"

    diff "$f" "$f.before" >/dev/null
    if [ $? -ne 0 ]; then
#      $UTIL_PATH/add-import.sh "$f" "$p.$c.${c}Builder"
      let totalUpdated=totalUpdated+1
      echo -n 'updated..'
  #    $UTIL_PATH/remove-trailing-newline.sh "$f" "$f.before"
    fi

    rm "$f.before"
    echo 'done'

    if [[ $maxFilesAffected -gt 0 ]] && [[ $totalUpdated -ge $maxFilesAffected ]]; then
      echo "reached limit of $maxFilesAffected affected searchFiles"
      exit
    fi
  done
  echo 'done'
done < <($SCRIPT_PATH/find-lombok-builders.sh "$searchFiles" 'setterPrefix')

echo ""
echo "totalUpdated=$totalUpdated"
