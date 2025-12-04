#!/usr/bin/env bash

#set -x

# Handle the different ways of running `sed` without generating a backup file based on OS
# - GNU sed (Linux) uses `-i`
# - BSD sed (macOS) uses `-i ''`
SED_OPTIONS=(-E -i.bak)
case "$(uname)" in
  Darwin*) SED_OPTIONS=(-E -i '.bak')
esac

f=$1  # file

nb="[^()]*"         # no bracket
mb="($nb|\($nb\))*" # matched bracket - level 1
mb="($nb|\($mb\))*" # matched bracket - level 2
mb="($nb|\($mb\))*" # matched bracket - level 3
mb="($nb|\($mb\))*" # matched bracket - level 4
# use mcb to ensure code in lambda blocks gets combined into one line
ncb="[^{}]*"         # no bracket
mcb="($ncb|\{$ncb\})*" # matched bracket - level 1
mcb="($ncb|\{$mcb\})*" # matched bracket - level 2
mcb="($ncb|\{$mcb\})*" # matched bracket - level 3
mcb="($ncb|\{$mcb\})*" # matched bracket - level 4
ws='        ' # extra white space for indentation

function replaceBlock() {
  sed "${SED_OPTIONS[@]}" '
/'"$1"'/{
  :b
  /'"$1$mcb"';$/!{N;bb
  }
  '"$2"'
}' "$f"

  # zero means true in bash if statements
  local changed=0
  if diff "$f" "$f.bak" &> /dev/null; then
    changed=1 # not changed
  fi
  rm "$f.bak"

  return $changed
}

function replaceChain() {
  begin="$1"
  method="\.${2}[A-Za-z0-9_£$]*" # method might be a prefix, eg: find -> findAny
  isEnd="$3"

  # preserve comments on new lines
  replace='s/^((\/\/)?[[:space:]]*)(.*[)])('"$method"')/\1\3\
\1'"$ws"'\4/'

  # don't split onto new line if there is only one method in the chain
  # how to do that? ignore: ${begin}\($mb\)${method}\($mb\);
  # would it always end in a ;
  # also ignore: ${begin}\($mb\)${method}\($mb\)${end}
  # but don't have end in here
  # there could be many different ends, so hard to ignore
  # instead, don't split if there is only two methods in the chain
  # second method could be the end method or not
  # second method can be any method, not just the known ones
  # in fact, all methods could just be words, only need to know the beginning method
  # just use word match for second method for now to make it more precise
  # TODO always wrap streams but allow builders with 1 op
  if [ "$isEnd" -ne 0 ]; then
    # ignore chains with no or 1 operation
    replace="/${begin}\($mb\)(\.[A-Za-z0-9_£$]+\($mb\))?${method}/!$replace"
  else
    replace="/${begin}\($mb\)${method}\($mb\)(\.[A-Za-z0-9_£$]+\($mb\))?[[:space:]]*[;),}]/!$replace"
  fi

  while replaceBlock "$begin" "$replace"; do
    echo -n '.'
  done
  echo -n '.'
}

function replaceChainOps() {
  begin="$1"
  shift

  for method in "$@"; do
    replaceChain "$begin" "$method" 0
  done
}

function replaceChainEnds() {
  begin="$1"
  shift

  for method in "$@"; do
    replaceChain "$begin" "$method" 1
  done
}
replaceChainOps '\.stream' 'map' 'flatMap' 'sorted' 'distinct' 'peek' 'filter' 'limit' 'skip'\
 'takeWhile' 'dropWhile' 'parallel' 'sequential' 'unordered' 'onClose' 'find' 'min' 'max'

replaceChainEnds '\.stream' 'forEach' 'collect' 'reduce' 'toArray' 'toList'\
 'count' 'anyMatch' 'allMatch' 'noneMatch' 'orElse'
exit


replaceChainOps '\.builder' 'with' 'clear'
replaceChainEnds '\.builder' 'build'
replaceChainOps '\.toBuilder' 'with' 'clear'
replaceChainEnds '\.toBuilder' 'build'

# for protobuf objects
replaceChainOps '\.newBuilder' 'set'
replaceChainEnds '\.newBuilder' 'build'
replaceChainOps '\.toBuilder' 'set'

replaceChainOps 'assertThat' 'extracting' 'flatExtracting'
replaceChainEnds 'assertThat' 'contains' 'hasSize' 'isInstanceOf' 'isExactlyInstanceOf' 'hasMessage'

# map will cover mapToInt, mapMulti etc
# flatMap will cover flatMapToInt etc
# find - findOne, findAny - this is not a terminal op as it leads to an optional which can then have a map()
# same for min and max
# orElse is actually from optional, but can be chained from a stream
replaceChainOps '\.stream' 'map' 'flatMap' 'sorted' 'distinct' 'peek' 'filter' 'limit' 'skip'\
 'takeWhile' 'dropWhile' 'parallel' 'sequential' 'unordered' 'onClose' 'find' 'min' 'max'

replaceChainEnds '\.stream' 'forEach' 'collect' 'reduce' 'toArray' 'toList'\
 'count' 'anyMatch' 'allMatch' 'noneMatch' 'orElse'

replaceChainOps 'new JsonMapper' 'registerModule'
replaceChainOps 'new ObjectMapper' 'registerModule'

replaceChainEnds 'new StringBuilder' 'toString'

# Wrap mockito statements when they are longer than 120 chars, eg:
#        when(runner.streamTrades(any(), any(), any(), anyInt(), anyInt()))
#                .thenReturn(Flux.just(dataResponse, dataResponse2));
# can use something like this:
#   /.{120}/
