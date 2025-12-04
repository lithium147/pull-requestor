#!/usr/bin/env bash

# Handle the different ways of running `sed` without generating a backup file based on OS
# - GNU sed (Linux) uses `-i`
# - BSD sed (macOS) uses `-i ''`
SED_OPTIONS=(-E -i)
case "$(uname)" in
  Darwin*) SED_OPTIONS=(-E -i '')
esac

f=$1  # file

# All variations of final method params - single line
# allows for optional annotations
sed "${SED_OPTIONS[@]}" 's/\(((@[0-9A-Za-z_]+(\([^)]*\))? )*)final ([^)]*)\)/(\1\4)/g' $f   # (final String s)
sed "${SED_OPTIONS[@]}" 's/\(((@[0-9A-Za-z_]+(\([^)]*\))? )*)final ([^,]*),/(\1\4,/g' $f   # (final String s,
# repeat this one to allow for many method params
sed "${SED_OPTIONS[@]}" 's/, ((@[0-9A-Za-z_]+(\([^)]*\))? )*)final ([^,]*),/, \1\4,/g' $f # , final String s,
sed "${SED_OPTIONS[@]}" 's/, ((@[0-9A-Za-z_]+(\([^)]*\))? )*)final ([^,]*),/, \1\4,/g' $f # , final String s,
sed "${SED_OPTIONS[@]}" 's/, ((@[0-9A-Za-z_]+(\([^)]*\))? )*)final ([^,]*),/, \1\4,/g' $f # , final String s,
sed "${SED_OPTIONS[@]}" 's/, ((@[0-9A-Za-z_]+(\([^)]*\))? )*)final ([^)]*)\)/, \1\4)/g' $f # , final String s)

#sed "${SED_OPTIONS[@]}" 's/[[:space:]]*final ([^,]*),/\1,/g' $f # final String s,
#sed "${SED_OPTIONS[@]}" 's/[[:space:]]*final ([^;]*)$/\1/g' $f  # final String s)

sed "${SED_OPTIONS[@]}" 's/([[:space:]]*)final var/\1var/g' $f # final var

# to catch final local fields, assume they don't have a modifier
# also catch multiline final params
sed "${SED_OPTIONS[@]}" '/(private|protected|static|transient|volatile)/!s/^([[:space:]]*)((@[0-9A-Za-z_]+(\([^)]*\))? )*)final (.*)$/\1\2\5/g' $f

# TODO don't touch final inside quotes, eg:
# throw new IllegalStateException("Pipeline didn't complete successfully, final state: " + state);

# public static final String byteToMbStr(int bytes) {
# ignore lines with an assignment
# won't work if:
# - annotations with brackets in method params
# - opening brace of method is on another line
sed "${SED_OPTIONS[@]}" '/=/!s/static final(.*\([^)]*\)[[:space:]]*[{])/static\1/' $f

#    public static final String generateQueryStringForCounterparty(String site, LocalDate valueDate, String cptyCode,
#                                                                  CounterpartyQuery cptyQuery) {
function replaceMultiline() {
  start="$1"
  replace="$2"
  sed "${SED_OPTIONS[@]}" '
/'"$start"'/{
  :b
  /[;{]+$/!{N;bb
  }
  '"$replace"'
}' "$f"
}

replaceMultiline 'static final' '/=/!s/static final(.*\([^)]*\)[[:space:]]*[{])/static\1/'

#    private final static Predicate<List<String>> isPopulated() {
replaceMultiline 'final static' '/=/!s/final static(.*\([^)]*\)[[:space:]]*[{])/static\1/'

#    public static final class ReverseEodTrade {
sed "${SED_OPTIONS[@]}" 's/final class/class/g' $f

