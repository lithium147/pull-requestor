#!/usr/bin/env bash

type="${1:-main}"

# symbol:   class Map(String)
# static import:
# [ERROR]   symbol:   method when(com.hsbc.host.raven.foxvatrade.enumeration.ResponseStatus)
symbolRegex='/symbol:/s/^.*symbol:[[:space:]]+[A-Za-z0-9_]+[[:space:]]+([A-Za-z0-9_]+).*$/\1/p'
# error: package DependencyNames does not exist
errorRegex='/error: package.*does not exist/s/^.*error: package ([A-Za-z0-9_]+) does not exist$/\1/p'

# disable colour output so it can be parsed
export MAVEN_OPTS=""

mkdir -p target
compileOut=target/compile.out

# only compile main/test based on where the class is located
if [ "$type" == "test" ]; then
  phase="test-compile"
else
  phase="compile"
fi
echo "phase=$phase" >> $compileOut

# don't need to set the version during compile
# jacoco interfering with compile sometimes
$MVN -U -s ${MVN_SETTINGS} $phase -P '!git_revision_in_finalName' -Djacoco.skip=true 2>&1 | tee -a $compileOut | sed -E -n -e "$symbolRegex" -e "$errorRegex" | sort -u
