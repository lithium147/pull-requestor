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

echo 'converting to final fields'
echo 'searching for files with @Builder or @SuperBuilder but not @Configuration'
# Using the find approach is unnecessary, can use standard loop approach
# although the find approach separates the find from the update which is a good idea
while read -r f; do
#for f in src/main/java/com/hsbc/gbm/grt/orch/jobs/masking/MaskParameter.java; do
#for f in src/main/java/com/hsbc/gbm/grt/orch/management/executions/JobInfo.java; do
#for f in src/main/java/com/hsbc/gbm/grt/orch/management/executions/JobExecution.java; do
#for f in src/main/java/com/hsbc/gbm/grt/orch/jobs/snap/ExecuteSnapCptyOrchJobRequest.java; do
  echo -n "processing $f"

  cp "$f" "$f.before"

  echo -n '.'
  $SCRIPT_PATH/convert-to-final-fields.sh "$f"
  # TODO better to replace @NoArgsConstructor with @Jacksonized
  echo -n '.'
  $SCRIPT_PATH/convert-no-args-to-force.sh "$f"
  echo -n '.'
#  $UTIL_PATH/remove-trailing-newline.sh "$f" "$f.before"

  diff "$f" "$f.before" >/dev/null
  if [ $? -ne 0 ]; then
    let totalUpdated=totalUpdated+1
    echo -n 'updated..'
#    $UTIL_PATH/remove-trailing-newline.sh "$f" "$f.before"
  fi

  rm "$f.before"
  echo 'done'

  if [[ $maxFilesAffected -gt 0 ]] && [[ $totalUpdated -ge $maxFilesAffected ]]; then
    echo "reached limit of $maxFilesAffected affected files"
    exit
  fi

done < <($SCRIPT_PATH/find-lombok-builders.sh)
