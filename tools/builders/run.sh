#!/usr/bin/env bash

SCRIPT_PATH=$(dirname "$0")

files=$(cat "$SCRIPT_PATH/files.txt")

# migrate to with prefix first, so migrate-to-use-builders can be applied to all builders uniformly
$SCRIPT_PATH/migrate-to-with-builders.sh "$files" "$files" $*
$SCRIPT_PATH/convert-to-builders.sh "$files" $*
$SCRIPT_PATH/migrate-to-use-builders.sh "$files" "$files" $*

# TODO instead of 3 loops, better to have one loop but do more in the loop
# the migrates ones use the same loop mechanism: find-lombok-builders.sh
# also, the sequence of replacement is important, so hard to combine the loops

# replace .builder() .ucrId()
# with    .builder() .withUcrId()

#        FetchTradesResponse response = FetchTradesResponse.builder()
#                .ucrId(request.getUcrId())
#                .valueDate(request.getValueDate())
#                .responseStatus(ResponseStatus.SUCCESS)
#                .outcome(outcome)
#                .responseTime(getResponseTime(start))
#                .build();

