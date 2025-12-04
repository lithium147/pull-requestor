#!/usr/bin/env bash

# Handle the different ways of running `sed` without generating a backup file based on OS
# - GNU sed (Linux) uses `-i`
# - BSD sed (macOS) uses `-i ''`
SED_OPTIONS=(-E -i)
case "$(uname)" in
  Darwin*) SED_OPTIONS=(-E -i '')
esac

c="$1"  # class
f="$2"  # file
cbm="${c}\.builder\(\)"

# migrate existing @Builder to use with prefix
#        return CounterpartyEodQuery.builder() .ucrId(ucrId) .site(site) .valueDate(valueDate) .query(cptyQuery) .build();
# .set -> .with is easier to find
# $cbm join until .build();
# $cbm[[:space:]](.[a-z]) -> $cbm[[:space:]](.with[A-Z])

# performs too many with replacements, then fixes the over run by removing the "With"
# also fix overrun by restoring withBuild back to build
function addWithPrefix() {
  cbm="$1"
  # recursively build up matched brackets
  nb="[^()]*"         # no bracket
  mb="($nb|\($nb\))*" # matched bracket - level 1
  mb="($nb|\($mb\))*" # matched bracket - level 2
  mb="($nb|\($mb\))*" # matched bracket - level 3
  mb="($nb|\($mb\))*" # matched bracket - level 4
  # outside bracket - level 5
  replacement="s/(${cbm}[^.]*(\.with[A-Z][a-zA-Z0-9_]*\(${mb}\)[^.()]*)*\.)([a-z][^.()]*)/\1with\u\7/g"
  sed "${SED_OPTIONS[@]}" '
/'"$cbm"'/{
  :b
  /.*'"$cbm"'.*\.build\(\).*;/!{N;bb
  }
  '"$replacement"'
  '"$replacement"'
  '"$replacement"'
  '"$replacement"'
  '"$replacement"'
  '"$replacement"'
  '"$replacement"'
  '"$replacement"'
  '"$replacement"'
  '"$replacement"'
  '"$replacement"'
  '"$replacement"'
  '"$replacement"'
  '"$replacement"'
  '"$replacement"'
  '"$replacement"'
  '"$replacement"'
  '"$replacement"'
  '"$replacement"'
  '"$replacement"'
  '"$replacement"'
  '"$replacement"'
  '"$replacement"'
  '"$replacement"'
  '"$replacement"'
  '"$replacement"'
  '"$replacement"'
  '"$replacement"'
  '"$replacement"'
  '"$replacement"'
  '"$replacement"'
  '"$replacement"'
  '"$replacement"'
  '"$replacement"'
  '"$replacement"'
  '"$replacement"'
  '"$replacement"'
  '"$replacement"'
  '"$replacement"'
  '"$replacement"'
  s/with(With)*Build/build/g
}' "$f"
}

echo -n "."
addWithPrefix "$cbm"
echo -n "."

# also support toBuilder()
#        Stream<Trade> trades = Stream.of(trade.toBuilder().marketDataCurves(null).build());

varNames=($(sed -E -n 's/^.*([[:space:]]+)'"$c"'[[:space:]]+([0-9A-Za-z_]+)[[:space:]]*;.*$/\2/p' "$f" | sort -u))
for v in ${varNames[@]}; do
  echo -n "$v"
  echo -n "."
  addWithPrefix "$v\.toBuilder\(\)"
  echo -n "."
done
