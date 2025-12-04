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

echo 'migrating to use builders provided by @Builder and @SuperBuilder'
while read -r -a arr; do
#for bf in src/main/java/com/hsbc/gbm/grt/orch/jobs/ExecuteJobRequest.java src/main/java/com/hsbc/gbm/grt/orch/jobs/snap/ExecuteSnapCptyOrchJobRequest.java; do
#for bf in src/main/java/com/hsbc/gbm/grt/orch/jobs/masking/MaskParameter.java; do
#for bf in src/main/java/com/hsbc/gbm/grt/orch/management/executions/JobInfo.java; do
#for bf in src/main/java/com/hsbc/gbm/grt/orch/management/executions/JobExecution.java; do
#for bf in src/main/java/com/hsbc/gbm/grt/orch/jobs/snap/ExecuteSnapCptyOrchJobRequest.java; do
#  echo "processing $bf"
  p="${arr[0]}"
  c="${arr[1]}"
  fields=(${arr[@]:2})
  echo "converting usages of: $p.$c"
  echo "fields: ${fields[*]}"

  for f in $replaceFiles; do
#  for f in src/main/java/com/hsbc/host/raven/foxvamarketdata/model/xds/mapper/EdForwardMoneynessImpliedVolMapper.java; do
#  for f in src/main/java/com/hsbc/host/raven/foxvamarketdata/model/xds/mapper/CdsSpreadsMapper.java; do
#  for f in src/main/java/com/hsbc/host/raven/foxvamarketdata/funding/FundingSwapRatesMapper.java; do
  #for f in src/test/java/com/hsbc/gbm/grt/orch/management/executions/ExecutionControllerV1Test.java; do
  #for f in src/main/java/com/hsbc/gbm/grt/orch/management/executions/JobExecution.java src/test/java/com/hsbc/gbm/grt/orch/management/executions/ExecutionControllerV1Test.java; do
  #for f in src/main/java/com/hsbc/gbm/grt/orch/jobs/JobExecutionControllerV1.java; do
  #for f in src/test/java/com/hsbc/gbm/grt/orch/jobs/JobExecutionControllerV1Test.java src/test/java/com/hsbc/gbm/grt/orch/jobs/snap/RiskSourceJobExecutionControllerV1Test.java; do
    # the package could be found in an import or package statement

    if ! ( grep -Eq "$p" "$f" && grep -Eq "$c" "$f" ); then
      echo -n "."
      continue
    fi
    echo ""
    echo -n "  Processing $f "

    cp "$f" "$f.before"

    $SCRIPT_PATH/replace-usage.sh "$c" "$f" "${fields[@]}"
    $UTIL_PATH/remove-trailing-newline.sh "$f" "$f.before"

    diff "$f" "$f.before" >/dev/null
    if [ $? -ne 0 ]; then
      $UTIL_PATH/add-import.sh "$f" "$p.$c.${c}Builder"
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
  done
  echo 'done'
done < <($SCRIPT_PATH/find-lombok-builders.sh "$searchFiles")

echo ""
echo "totalUpdated=$totalUpdated"
