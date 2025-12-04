#!/usr/bin/env bash

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
files="$1"

function convert() {
  local f=$1
  local super=$2
  $SCRIPT_PATH/add-lombok-builder.sh "$f" $super
  $SCRIPT_PATH/convert-to-final-fields.sh "$f"
  $UTIL_PATH/add-import.sh "$f" 'javax.xml.bind.annotation.XmlType'
  $UTIL_PATH/add-import.sh "$f" 'lombok.Builder'
  $UTIL_PATH/add-import.sh "$f" 'lombok.ToString'
  $UTIL_PATH/add-import.sh "$f" 'lombok.Getter'
  $UTIL_PATH/add-import.sh "$f" 'lombok.AllArgsConstructor'
  $UTIL_PATH/add-import.sh "$f" 'lombok.Singular'
  $UTIL_PATH/add-import.sh "$f" 'lombok.experimental.SuperBuilder'
  $UTIL_PATH/add-import.sh "$f" 'lombok.extern.jackson.Jacksonized'

  # TODO only increment if the file changed
  let totalUpdated=totalUpdated+1
}

superBuilders=()
echo 'converting to @Builder or @SuperBuilder'
while read -r f; do
#for f in src/main/java/com/hsbc/gbm/grt/orch/jobs/masking/MaskParameter.java; do
#for f in src/main/java/com/hsbc/gbm/grt/orch/management/executions/JobInfo.java; do
#for f in src/main/java/com/hsbc/gbm/grt/orch/management/executions/JobExecution.java; do
#for f in src/main/java/com/hsbc/gbm/grt/orch/jobs/snap/ExecuteSnapCptyOrchJobRequest.java; do
  echo -n "processing $f"
  ff="${f%.*}"      # remove .java
  c="${ff##*/}"     # remove path to leave class name
  p="${ff%/*}"      # remove file name to leave path
  p="${p##*java/}"  # remove src/main/java
  p="${p//\//.}"    # convert path to package

  if [[ " ${superBuilders[*]} " =~ " ${p}.${c} " ]]; then
    echo -n '.'
    echo "already converted"
    continue
  fi

  nb="[^<>]*"         # no bracket
  mb="($nb|\<$nb\>)*" # matched bracket - level 1
  mb="($nb|\<$mb\>)*" # matched bracket - level 2
  mb="([[:space:]]+|\<$mb\>)" # matched bracket - level 3

  # convert the parent classes if any
  # ensure generics are excluded
  extends='^(public)?[[:space:]]+class[[:space:]]+[A-Za-z0-9_£$]*'"$mb"'[[:space:]]*extends[[:space:]]+'
  parentClasses=0
  sf=$f
  while grep -Eq "$extends" "$sf"; do
    echo -n '.'
    let parentClasses=parentClasses+1
    #   find package and class for extends
    sc=$(sed -E -n 's/^'"$extends"'([0-9A-Za-z_]*).*$/\5/p' "$sf")
    # if subsclass is in same package, there won't be an import
    sp=$(sed -E -n 's/^import[[:space:]]+(.*)\.'"$sc"';$/\1/p' "$sf")
    if [ "$sp" == "" ]; then
      sp="$p"
    fi
    sfq="${sp}.${sc}"
    echo ""
    echo -n "  processing subclass: $sfq"
    if [[ " ${superBuilders[*]} " =~ " ${sfq} " ]]; then
      echo -n '.'
      echo "already converted"
      break
    fi
    superBuilders+=("${sfq}")
    sf="${sfq//.//}"    # convert package to path
    # TODO also check src/test/java
    sf="src/main/java/$sf.java"
    echo -n '.'
    convert "$sf" 1
  done

  # convert this class
  echo -n '.'
  convert $f $parentClasses
  echo -n '.'
  echo 'done'
done < <($SCRIPT_PATH/find-lombok-candidates.sh "$files")

echo ""
echo "totalUpdated=$totalUpdated"
