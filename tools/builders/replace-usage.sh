#!/usr/bin/env bash

# Handle the different ways of running `sed` without generating a backup file based on OS
# - GNU sed (Linux) uses `-i`
# - BSD sed (macOS) uses `-i ''`
SED_OPTIONS=(-E -i)
case "$(uname)" in
  Darwin*) SED_OPTIONS=(-E -i '')
esac

c="$1"  # class
shift
f="$1"  # file
shift
fields=($*)
cbc="${c}Builder" # The static builder class is imported later
# TODO could use 'var' but how to know if it is a local variable?
# for SuperBuilder, its like this:
# ExecuteSnapCptyOrchJobRequest.ExecuteSnapCptyOrchJobRequestBuilder<?, ?>
# cbc="${c}.${c}Builder<?, ?>"
# using this might affect the replacements below
# would need to be escaped
cbm="${c}.builder()"
# handle nested braces in the block - only supports three levels
mb='[^{}]*([^{}]*\{[^{}]*([^{}]*\{[^{}]*([^{}]*\{[^{}]*\}[^{}]*)*[^{}]*\}[^{}]*)*[^{}]*\}[^{}]*)*[^{}]*'

ws='        '

function redefine() {
  v="$1"
  sed "${SED_OPTIONS[@]}" 's/^([[:space:]]+)'"$v"'[[:space:]]*=[[:space:]]*new[[:space:]]+'"$c"'\(\);/\1'"$c"' '"$v"' = new '"$c"'();/' "$f"
}

function undoRedefine() {
  v="$1"
  sed "${SED_OPTIONS[@]}" 's/^([[:space:]]+)'"$c"'[[:space:]]+'"$v"'[[:space:]]*=/\1'"$v"' =/' "$f"
}

function replaceBlock() {
  v="$1"
  beginning='[[:space:]]+'"$c"'[[:space:]]+'"$v"'[[:space:]]*=[[:space:]]*new[[:space:]]+'"$c"'()'

  sed "${SED_OPTIONS[@]}" '
/'"$beginning"'/{
  :b
  /.*'"$beginning"''"$mb"'}/!{N;bb
  }
  s/([[:space:]]+)'"$c"'[[:space:]]+'"$v"'[[:space:]]*=[[:space:]]*new[[:space:]]+'"$c"'\(\);/\1'"$cbc"' '"$v"' = '"$cbm"';/
  s/([[:space:]]+)'"$v"'.set/\1'"$v"'.with/g
  s/([^0-9A-Za-z_."])'"$v"'([[:space:]]+[^0-9A-Za-z_.="]|[[:space:]]*[^0-9A-Za-z_.=" ]|.get)/\1'"$v"'.build()\2/g
}' "$f"
}

function chainBuilderCalls() {
  v="$1"
  beginning='[[:space:]]+'"$cbc"'[[:space:]]+'"$v"'[[:space:]]*=[[:space:]]*'"$cbm"
  withCombiner='s/\n([[:space:]]+)(('"$v"')?.with[^;]*);([[:space:]]+)'"$v"'.with/\n\1\2\n\1.with/g'

  sed "${SED_OPTIONS[@]}" '
/'"$beginning"'/{
  :b
  /.*'"$beginning"''"$mb"'}/!{N;bb
  }
  s/^([[:space:]]+)('"$cbc"'[[:space:]]+'"$v"'[[:space:]]*=[[:space:]]*'"$cbm"'[^;]*);([[:space:]]+)'"$v"'.with/\1\2\n\1.with/
  '"$withCombiner"'
  '"$withCombiner"'
  '"$withCombiner"'
  '"$withCombiner"'
  '"$withCombiner"'
  '"$withCombiner"'
  '"$withCombiner"'
  '"$withCombiner"'
  '"$withCombiner"'
  '"$withCombiner"'
  '"$withCombiner"'
  '"$withCombiner"'
  '"$withCombiner"'
}' "$f"
}

function combineWithBuildMethod() {
  v="$1"
  beginning='[[:space:]]+'"$cbc"'[[:space:]]+'"$v"'[[:space:]]*=[[:space:]]*'"$cbm"

  sed "${SED_OPTIONS[@]}" '
/'"$beginning"'/{
  :b
  /.*'"$beginning"''"$mb"'}/!{N;bb
  }
  /\n[[:space:]]+('"$v"')?.with/!{
    s/^([[:space:]]+)'"$cbc"'[[:space:]]+'"$v"'[[:space:]]*=[[:space:]]*'"$cbm"'[^;]*;/\1'"$c"' '"$v"' = '"$cbm"'.build();/
  }
  /\n[[:space:]]+'"$v"'.with/!{
    s/'"$cbc"'/'"$c"'/
    s/\n([[:space:]]+)(.with[^;]*);/\n\1\2\n\1.build();/g
    s/([^0-9A-Za-z_."])'"$v"'.build\(\)/\1'"$v"'/g
  }
}' "$f"
}

function combineWithReturn() {
  v="$1"
  beginning='[[:space:]]+'"$c"'[[:space:]]+'"$v"'[[:space:]]*=[[:space:]]*'"$cbm"

  sed "${SED_OPTIONS[@]}" '
/'"$beginning"'/{
  :b
  /.*'"$beginning"''"$mb"'}/!{N;bb
  }
  /[[:space:]]+'"$v"'.with/!{
  s/([[:space:]]+)'"$c"'[[:space:]]+'"$v"'[[:space:]]*=[[:space:]]*('"$cbm"'[^;]*.build\(\);)[[:space:]]+return[[:space:]]+'"$v"';/\1return \2/
  }
}' "$f"
}

function processVariable() {
  v="$1"
  replaceBlock "$v"
  echo -n "."
  chainBuilderCalls "$v"
  echo -n "."
  combineWithBuildMethod "$v"
  echo -n "."
  combineWithReturn "$v"
}

# Variable might be initialised later on
#    private CounterpartyQuery counterpartyQuery;
#    private CounterpartyQuery counterpartyQuery = new CounterpartyQuery();
# All the replacements require the class to be defined and initialized together.
# This is partly because it can change the variable type to the builder class.
# Could redefine the variable on initialization.
# But this wont work if the variable used more than once in a method.
# also won't work where variable is initialized in the constructor/setup method.
# perhaps could revert the redefining at the end, or is it easy to make all the replacements agnostic of definition?
# reverting redefine like this won't work if the same variable name is in both initialised and uninitialised cases.
# How to solve that?
varNames=($(sed -E -n 's/([[:space:]]+)'"$c"'[[:space:]]+([0-9A-Za-z_]+)[[:space:]]*=[[:space:]]*new[[:space:]]+'"$c"'\(\);/\2/p' "$f" | sort -u))
for v in ${varNames[@]}; do
  echo -n "$v"
  echo -n "."
  processVariable "$v"
  echo -n "."
done

varNames=($(sed -E -n 's/^.*([[:space:]]+)'"$c"'[[:space:]]+([0-9A-Za-z_]+)[[:space:]]*;.*$/\2/p' "$f" | sort -u))
for v in ${varNames[@]}; do
  echo -n "$v (redefined)"
  echo -n "."
  redefine "$v"
  echo -n "."
  processVariable "$v"
  echo -n "."
  undoRedefine "$v"
  echo -n "."
done

# Empty constructor
#       PageInfo<JobExecution> result = jobExecutionService.getJobExecutions(new ListJob());
#>>>
#       PageInfo<JobExecution> result = jobExecutionService.getJobExecutions(ListJob.builder().build());
#
sed "${SED_OPTIONS[@]}" 's/([^0-9A-Za-z_])new '"$c"'\(\)/\1'"$cbm"'.build()/g' "$f"

# Constructor with params
#        return new ExecuteJobResponse(jobQueueService.enqueue(executeJob, priority));
#>>>
#        return ExecuteJobResponse.builder().withId(jobQueueService.enqueue(executeJob, priority)).build();
# This requires knowing the field names in the class (and super classes)

# ExecuteJob executeJob = new ExecuteJob(); >>>> ExecuteJob.Builder executeJob = ExecuteJob.builder();

# combine commands on builder into one statement
#        ListJob.Builder listJob = ListJob.builder();
#        listJob.withPage(1);
#        listJob.withSize(1);
#        PageInfo<JobExecutionEntity> page = repository.getJobExecutions(listJob.build());

#        ListJob.Builder listJob = ListJob.builder()
#           .withPage(1)
#           .withSize(1);
#        PageInfo<JobExecutionEntity> page = repository.getJobExecutions(listJob.build());

#        ListJob.Builder listJob = ListJob.builder()
#                .withPage(page)
#                .withSize(size)
#                .withStatus(StringEscapeUtils.escapeHtml(status))
#                .withCalcRunId(StringEscapeUtils.escapeHtml(calcRunId))
#                .withEndTime(endTime)
#                .withStartTime(startTime)
#                .withJobName(StringEscapeUtils.escapeHtml(jobName));
#        PageInfo<JobExecution> jobExecutions = jobExecutionService.getJobExecutions(listJob.build());

# if builder is used in one block
#   how to know this?
#   if there are no $v.with usages, then the combining has worked fully
#   no $v.with
# then can combine with .build();
# and variable type is no longer the builder
# and usages of var don't need .build()

# src/main/java/com/hsbc/gbm/grt/orch/management/jobs/StaleJobHousekeeper.java
# src/test/java/com/hsbc/gbm/grt/orch/jobs/masking/MaskServiceTest.java

#                new SourceCurve("first_" + curveId, CVA_CURVE, location1),
# How to replace constructor with builder?
# Can use intellij to replace with builder.

# @Value has 9 classes in marketdata-service
# Also, new line before every ".with..()
# add @Singular to all List<> fields
# how to add new line
# - add while adding with?
# - add while converting from setter?
# could create a new tool - new-lines
# - it also take care of assertThat(), stream()

# constructor conversion, can be done here cos know it has a builder.
# but need to go back to original class to get fields
# or perhaps they could be passed in..?
# for each field, add to capture to match and get value
# also add builder op - .withFieldName(fieldValue)

# if no fields, then it would have been changed to the builder with no ops
# perhaps could also level constructor usage if field count is low
# but this would require changing the visibility of the constructor
if [ ${#fields[@]} -eq 0 ]; then
  exit
fi

nb="[^()]*"         # no bracket
mb="($nb|\($nb\))*" # matched bracket - level 1
mb="($nb|\($mb\))*" # matched bracket - level 2
mb="($nb|\($mb\))*" # matched bracket - level 3
mb="($nb|\($mb\))*" # matched bracket - level 4
fm="($mb)"
fieldMatches="$fm"
fn=${fields[0]^}
fi=2
fieldBuilderOps=".with${fn}(\\${fi})"
fieldBuilderOpsPerl=".with${fn}(\$${fi})"
echo -n "."

for field in "${fields[@]:1}"; do
  fn="${field^}"
  fi=$((fi + 5))
  fieldMatches="$fieldMatches,[[:space:]]*$fm"
  fieldBuilderOps="$fieldBuilderOps.with${fn}(\\${fi})"
  fieldBuilderOpsPerl="$fieldBuilderOpsPerl.with${fn}(\$${fi})"
  echo -n "."
done

#echo $fieldMatches
#echo $fieldBuilderOps

constructor="([^0-9A-Za-z_])new ${c}"
params="\(${fieldMatches}\)"
buildSed="\1${cbm}${fieldBuilderOps}.build()"
buildPerl="\1${cbm}${fieldBuilderOpsPerl}.build()"

# use perl since it supports > 9 back references
perl -i -p -e 's/'"${constructor}""$params"'/'"${buildPerl}"'/g' "$f"

# for multiline have to use sed
function replaceMultilineConstructor() {
  local beginning="$1"
  local fieldMatches="$2"
  local replacement="$3"

  sed "${SED_OPTIONS[@]}" '
/'"$beginning"'/{
  :b
  /'"$beginning""$fieldMatches"'/!{N;bb
  }
  s/'"$beginning""$fieldMatches"'/'"$replacement"'/g
}' "$f"
}

replaceMultilineConstructor "${constructor}" "${params}" "${buildSed}"
