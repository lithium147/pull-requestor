#!/usr/bin/env bash

# Handle the different ways of running `sed` without generating a backup file based on OS
# - GNU sed (Linux) uses `-i`
# - BSD sed (macOS) uses `-i ''`
SED_OPTIONS=(-E -i)
case "$(uname)" in
  Darwin*) SED_OPTIONS=(-E -i '')
esac

f="$1"  # file

function isSuper() {
  if [ ${1:-0} -eq 0 ]; then
    grep -Eq "^@SuperBuilder" "$f"
    if [ $? -eq 0 ]; then
      return 1
    fi
    grep -Eq '^(public)?[[:space:]]+class[[:space:]]+.*[[:space:]]+extends[[:space:]]+' "$f"
    if [ $? -eq 0 ]; then
      return 1
    fi
  fi
  return $1
}

isSuper $2
super=$?

function replaceSingleLine() {
  sed "${SED_OPTIONS[@]}" "$1" "$f"
}

# if it extends a class, add super builder:
# @SuperBuilder(toBuilder = true, setterPrefix = "with")
# also have to update super class to have SuperBuilder
# if it already has SuperBuilder, don't down grade to builder

# preserve the @Jacksonized annotation
jackson=0
if grep -Eq '@Jacksonized' "$f"; then
  jackson=1
fi

replaceSingleLine '/@Value/d'
replaceSingleLine '/@Setter/d'
replaceSingleLine '/@Data/d'
replaceSingleLine '/@Builder/d'
replaceSingleLine '/@SuperBuilder/d'
# don't remove RequiredArgsConstructor if it has a param
# @RequiredArgsConstructor(onConstructor_ = @ConstructorBinding)
replaceSingleLine '/@RequiredArgsConstructor$/d'
replaceSingleLine '/@AllArgsConstructor/d'
replaceSingleLine '/@NoArgsConstructor/d'
replaceSingleLine '/@ToString/d'
replaceSingleLine '/@Getter/d'
replaceSingleLine '/@Jacksonized/d'
replaceSingleLine '/@XmlType/d'
# Jacksonized requires:
# com.fasterxml.jackson.databind.annotation
# also, should only be added to objects involved in rest
# how to know which objects? perhaps could check if they are used in any controllers
# how to check if used in any controllers?
#   check for any classes with @Controller and the class being processed
#   more precise check is to see if the class is used in any controller method params
# what about if its a field of a class used in a controller?
#   could check fields also, but getting rather complicated
#   is it worth it?
# also required if its used in an object mapper directly:
#   executeJob = objectMapper.readValue(entity.getRequestJson(), ExecuteJob.class);

if [ "$super" -ne 0 ]; then
#  echo "converting to super builder: $f"
  builder='@SuperBuilder(toBuilder = true, setterPrefix = "with")'
else
#  echo "converting to builder: $f"
  builder='@Builder(toBuilder = true, setterPrefix = "with")'
fi

if [ "$jackson" -gt 0 ] || grep -Eq '@Json' "$f"; then
  builder="$builder\n\
\1@Jacksonized"
fi

if grep -Eq '@Xml' "$f"; then
  builder="\
@XmlType(factoryMethod = \"newInstance\")\n\
\1$builder\
"
  if ! grep -Eq 'newInstance\(\)' "$f"; then
  # XXX don't need to do this if its already in the class
  factoryMethod='\
\1    @SuppressWarnings("unused")\
\1    private static \3 newInstance() {\
\1        return \3.builder().build();\
\1    }'
  fi
fi

# preserve indent in-case its a nested class
# don't touch @RestController, but do touch nested classes
# don't touch builder classes, eg: FetchTradesOutcomeBuilder
replaceSingleLine '/class [a-zA-Z0-9_]*(Builder|Resource|Controller)/!s/^([[:space:]]*)(public|private|static|abstract|[[:space:]]*)*class[[:space:]]*([a-zA-Z0-9_£$]+).*\{/\1'"$builder"'\
\1@Getter\
\1@ToString\
\0'"$factoryMethod"'/'

# Constructor provided by Builder is package-private, so can add @RequiredArgsConstructor to make it public.
# However, after migrating code to use the builder, this is not be required.

# TODO some classes might already have a toString() method
# how to adjust replacement not to include the @ToString?
# not easy to do above since it could be matching on nested classes
# could fix up the @ToString after the replacement
# would need to be a multiline match to ensure nested classes are handled


