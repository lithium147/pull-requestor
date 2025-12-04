#!/bin/bash

# Handle the different ways of running `sed` without generating a backup file based on OS
# - GNU sed (Linux) uses `-i`
# - BSD sed (macOS) uses `-i ''`
SED_OPTIONS=(-E -i)
case "$(uname)" in
  Darwin*) SED_OPTIONS=(-E -i "") ;;
esac

f="$1"

# sed -E: Interpret regular expressions as extended (modern) regular expressions rather than basic regular expressions (BRE's).
function replace() {
  sed "${SED_OPTIONS[@]}" '
/assertThat\(/{
  :b
  /.*;[[:space:]]*$/!{N;bb
  }
  '$1'
}' "$f"
}

function replaceSingleLine() {
  sed "${SED_OPTIONS[@]}" "$1" "$f"
}

# regular expressions patterns:
# `[^",]*` Match a single character not present in the list `^",`
# ".*[^\]" Match a single character within double quotes, and it can distinguish escaped double quotes
# .*\(.*\) Match a single character within round brackets
# echo ''
# echo "Converting hamcrest assertions to AssertJ assertions in files matching pattern : $FILES_PATTERN"
# echo ''

# echo '.1 - Replacing : assertThat(actual, hasItem(allOf())) .......... by : assertThat(actual).anySatisfy(allOf())'
replace 's/assertThat\((".*[^\]"),[[:space:]]*([^",]*|".*[^\]"|.*\(.*\)),[[:space:]]*hasItem\(([[:space:]]*allOf.*)\)\)/assertThat(\2).as(\1).anySatisfy(\3)/g'
replace 's/assertThat\([[:space:]]*([^",]*|".*[^\]"|.*\(.*\)),[[:space:]]*hasItem\(([[:space:]]*allOf.*)\)\)/assertThat(\1).anySatisfy(\2)/g'

# echo '.2 - Replacing : assertThat(actual, hasItem(isSomething())) .......... by : assertThat(actual).anySatisfy(isSomething())'
replace 's/assertThat\((".*[^\]"),[[:space:]]*([^",]*|".*[^\]"|.*\(.*\)),[[:space:]]*hasItem\(([[:space:]]*is.*)\)\)/assertThat(\2).as(\1).anySatisfy(\3)/g'
replace 's/assertThat\([[:space:]]*([^",]*|".*[^\]"|.*\(.*\)),[[:space:]]*hasItem\(([[:space:]]*is.*)\)\)/assertThat(\1).anySatisfy(\2)/g'

# echo '.3 - Replacing : assertThat(actual, hasItems(isSomething())) .......... by : assertThat(actual).anySatisfy(isSomething())'
replace 's/assertThat\((".*[^\]"),[[:space:]]*([^",]*|".*[^\]"|.*\(.*\)),[[:space:]]*hasItems\(([[:space:]]*is.*)\)\)/assertThat(\2).as(\1).anySatisfy(\3)/g'

replace 's/assertThat\([[:space:]]*([^",]*|".*[^\]"|.*\(.*\)),[[:space:]]*hasItems\([[:space:]]*(is.*),[[:space:]]*(is.*),[[:space:]]*(is.*)[[:space:]]*\)[[:space:]]*\)/assertThat(\1).anySatisfy(\2).anySatisfy(\3).anySatisfy(\4)/g'
replace 's/assertThat\([[:space:]]*([^",]*|".*[^\]"|.*\(.*\)),[[:space:]]*hasItems\([[:space:]]*(is.*),[[:space:]]*(is.*)[[:space:]]*\)[[:space:]]*\)/assertThat(\1).anySatisfy(\2).anySatisfy(\3)/g'
replace 's/assertThat\([[:space:]]*([^",]*|".*[^\]"|.*\(.*\)),[[:space:]]*hasItems\(([[:space:]]*is.*)\)\)/assertThat(\1).anySatisfy(\2)/g'

# echo '.4 - Replacing : assertThat(actual, contains(allOf())) ......... by : assertThat(actual).satisfiesExactly(allOf())'
replace 's/assertThat\((".*[^\]"),[[:space:]]*([^",]*|".*[^\]"|.*\(.*\)),[[:space:]]*contains\(([[:space:]]*allOf.*)\)[[:space:]]*\)/assertThat(\2).as(\1).satisfiesExactly(\3)/g'
replace 's/assertThat\([[:space:]]*([^",]*|".*[^\]"|.*\(.*\)),[[:space:]]*contains\(([[:space:]]*allOf.*)\)[[:space:]]*\)/assertThat(\1).satisfiesExactly(\2)/g'

# echo '.4 - Replacing : assertThat(actual, contains(isSomething())) ......... by : assertThat(actual).satisfiesExactly(isSomething())'
replace 's/assertThat\((".*[^\]"),[[:space:]]*([^",]*|".*[^\]"|.*\(.*\)),[[:space:]]*contains\(([[:space:]]*is.*)\)[[:space:]]*\)/assertThat(\2).as(\1).satisfiesExactly(\3)/g'
replace 's/assertThat\([[:space:]]*([^",]*|".*[^\]"|.*\(.*\)),[[:space:]]*contains\(([[:space:]]*is.*)\)[[:space:]]*\)/assertThat(\1).satisfiesExactly(\2)/g'

#            assertThat(weightDescriptions, contains(nullValue()));
# echo '.5 - Replacing : assertThat(actual, contains(nullValue())) ......... by : assertThat(actual).hasSize(1).containsNull()'
replace 's/assertThat\((".*[^\]"),[[:space:]]*([^",]*|".*[^\]"|.*\(.*\)),[[:space:]]*contains\(nullValue\(\)\)\)/assertThat(\2).as(\1).hasSize(1).containsNull()/g'
replace 's/assertThat\([[:space:]]*([^",]*|".*[^\]"|.*\(.*\)),[[:space:]]*contains\(nullValue\(\)\)\)/assertThat(\1).hasSize(1).containsNull()/g'

# echo ' 1 - Replacing : assertThat(actual, contains(expected)) ......... by : assertThat(actual).containsExactly(expected)'
replace 's/assertThat\((".*[^\]"),[[:space:]]*([^",]*|".*[^\]"|.*\(.*\)),[[:space:]]*contains\(([^",]*|".*[^\]"|.*\(.*\))\)\)/assertThat(\2).as(\1).containsExactly(\3)/g'
replace 's/assertThat\([[:space:]]*([^",]*|".*[^\]"|.*\(.*\)),[[:space:]]*contains\(([^",]*|".*[^\]"|.*\(.*\))\)\)/assertThat(\1).containsExactly(\2)/g'

# echo ' 2 - Replacing : assertThat(actual, containsInAnyOrder(expected)) by : assertThat(actual).containsExactlyInAnyOrder(expected)'
replace 's/assertThat\((".*[^\]"),[[:space:]]*([^",]*|".*[^\]"|.*\(.*\)),[[:space:]]*containsInAnyOrder\(([^",]*|".*[^\]"|.*\(.*\)|[^)]*)\)\)/assertThat(\2).as(\1).containsExactlyInAnyOrder(\3)/g'
replace 's/assertThat\([[:space:]]*([^",]*|".*[^\]"|.*\(.*\)),[[:space:]]*containsInAnyOrder\(([^",]*|".*[^\]"|.*\(.*\)|[^)]*)\)\)/assertThat(\1).containsExactlyInAnyOrder(\2)/g'

# echo ' 3 - Replacing : assertThat(actual, empty()) .................... by : assertThat(actual).isEmpty()'
replace 's/assertThat\((".*[^\]"),[[:space:]]*([^",]*|".*[^\]"|.*\(.*\)),[[:space:]]*empty\(\)\)/assertThat(\2).as(\1).isEmpty()/g'
replace 's/assertThat\([[:space:]]*([^",]*|".*[^\]"|.*\(.*\)),[[:space:]]*empty\(\)\)/assertThat(\1).isEmpty()/g'

# echo ' 4 - Replacing : assertThat(actual, hasSize(expected)) .......... by : assertThat(actual).hasSize(expected)'
replace 's/assertThat\((".*[^\]"),[[:space:]]*([^",]*|".*[^\]"|.*\(.*\)),[[:space:]]*hasSize\(([^",]*|".*[^\]"|.*\(.*\))\)\)/assertThat(\2).as(\1).hasSize(\3)/g'
replace 's/assertThat\([[:space:]]*([^",]*|".*[^\]"|.*\(.*\)),[[:space:]]*hasSize\(([^",]*|".*[^\]"|.*\(.*\))\)\)/assertThat(\1).hasSize(\2)/g'

# echo ' 5 - Replacing : assertThat(actual, is(nullValue()) ............. by : assertThat(actual).isNull()'
replace 's/assertThat\((".*[^\]"),[[:space:]]*([^",]*|".*[^\]"|.*\(.*\)),[[:space:]]*is\(nullValue\(\)\)\)/assertThat(\2).as(\1).isNull()/g'
replace 's/assertThat\([[:space:]]*([^",]*|".*[^\]"|.*\(.*\)),[[:space:]]*is\(nullValue\(\)\)\)/assertThat(\1).isNull()/g'

# echo ' 6 - Replacing : assertThat(actual, not(nullValue()) ............ by : assertThat(actual).isNotNull()'
replace 's/assertThat\((".*[^\]"),[[:space:]]*([^",]*|".*[^\]"|.*\(.*\)),[[:space:]]*not\(nullValue\(\)\)\)/assertThat(\2).as(\1).isNotNull()/g'
replace 's/assertThat\([[:space:]]*([^",]*|".*[^\]"|.*\(.*\)),[[:space:]]*not\(nullValue\(\)\)\)/assertThat(\1).isNotNull()/g'

# echo ' 5 - Replacing : assertThat(actual, nullValue()) ............. by : assertThat(actual).isNull()'
replace 's/assertThat\((".*[^\]"),[[:space:]]*([^",]*|".*[^\]"|.*\(.*\)),[[:space:]]*nullValue\(\)\)/assertThat(\2).as(\1).isNull()/g'
replace 's/assertThat\([[:space:]]*([^",]*|".*[^\]"|.*\(.*\)),[[:space:]]*nullValue\(\)\)/assertThat(\1).isNull()/g'

# echo ' 7 - Replacing : assertThat(actual, is(expected)) ............... by : assertThat(actual).isEqualTo(expected)'
replace 's/assertThat\((".*[^\]"),[[:space:]]*([^",]*|".*[^\]"|.*\(.*\)),[[:space:]]*is\(([^",]*|".*[^\]"|.*\(.*\)|.*)\)\)/assertThat(\2).as(\1).isEqualTo(\3)/g'
replace 's/assertThat\([[:space:]]*([^",]*|".*[^\]"|.*\(.*\)),[[:space:]]*is\(([^",]*|".*[^\]"|.*\(.*\)|.*)\)\)/assertThat(\1).isEqualTo(\2)/g'

# echo ' 8 - Replacing : assertThat(actual, equalTo(expected)) .......... by : assertThat(actual).isEqualTo(expected)'
replace 's/assertThat\((".*[^\]"),[[:space:]]*([^",]*|".*[^\]"|.*\(.*\)),[[:space:]]*equalTo\(([^",]*|".*[^\]"|.*\(.*\))\)\)/assertThat(\2).as(\1).isEqualTo(\3)/g'
replace 's/assertThat\([[:space:]]*([^",]*|".*[^\]"|.*\(.*\)),[[:space:]]*equalTo\(([^",]*|".*[^\]"|.*\(.*\))\)\)/assertThat(\1).isEqualTo(\2)/g'

# echo ' 9 - Replacing : assertThat(actual, containsString(expected)) ... by : assertThat(actual).contains(expected)'
replace 's/assertThat\((".*[^\]"),[[:space:]]*([^",]*|".*[^\]"|.*\(.*\)),[[:space:]]*containsString\(([^",]*|".*[^\]"|.*\(.*\))\)\)/assertThat(\2).as(\1).contains(\3)/g'
replace 's/assertThat\([[:space:]]*([^",]*|".*[^\]"|.*\(.*\)),[[:space:]]*containsString\(([^",]*|".*[^\]"|.*\(.*\))\)\)/assertThat(\1).contains(\2)/g'

# echo '10 - Replacing : assertThat(actual, hasEntry("Integer", "123")) . by : assertThat(actual).containsEntry(expected)'
replace 's/assertThat\((".*[^\]"),[[:space:]]*([^",]*|".*[^\]"|.*\(.*\)),[[:space:]]*hasEntry\(([^"]*|".*[^\]"|.*\(.*\),[[:space:]]*[^",]*|".*[^\]"|.*\(.*\))\)\)/assertThat(\2).as(\1).containsEntry(\3)/g'
replace 's/assertThat\([[:space:]]*([^"]*|".*[^\]"|.*\(.*\)),[[:space:]]*hasEntry\(([^"]*|".*[^\]"|.*\(.*\)|[^)]*,[[:space:]]*[^",]*|".*[^\]"|.*\(.*\))\)\)/assertThat(\1).containsEntry(\2)/g'

# echo '11 - Replacing : assertThat(actual, aMapWithSize(expected)) ..... by : assertThat(actual).hasSize(expected)'
replace 's/assertThat\((".*[^\]"),[[:space:]]*([^",]*|".*[^\]"|.*\(.*\)),[[:space:]]*aMapWithSize\(([^",]*|".*[^\]"|.*\(.*\))\)\)/assertThat(\2).as(\1).hasSize(\3)/g'
replace 's/assertThat\([[:space:]]*([^",]*|".*[^\]"|.*\(.*\)),[[:space:]]*aMapWithSize\(([^",]*|".*[^\]"|.*\(.*\))\)\)/assertThat(\1).hasSize(\2)/g'

# echo '12 - Replacing : assertThat(actual, anEmptyMap()) ............... by : assertThat(actual).isEmpty()'
replace 's/assertThat\((".*[^\]"),[[:space:]]*([^",]*|".*[^\]"|.*\(.*\)),[[:space:]]*anEmptyMap\(\)\)/assertThat(\2).as(\1).isEmpty()/g'
replace 's/assertThat\([[:space:]]*([^",]*|".*[^\]"|.*\(.*\)),[[:space:]]*anEmptyMap\(\)\)/assertThat(\1).isEmpty()/g'

# echo '13 - Replacing : assertThat(actual, hasItems(expected)) .......... by : assertThat(actual).contains(expected)'
replace 's/assertThat\((".*[^\]"),[[:space:]]*([^",]*|".*[^\]"|.*\(.*\)),[[:space:]]*hasItems\(([^",]*|".*[^\]"|.*\(.*\)|.*)\)\)/assertThat(\2).as(\1).contains(\3)/g'
replace 's/assertThat\([[:space:]]*([^",]*|".*[^\]"|.*\(.*\)),[[:space:]]*hasItems\(([^",]*|".*[^\]"|.*\(.*\)|.*)\)\)/assertThat(\1).contains(\2)/g'

# echo '14 - Replacing : assertThat(actual, hasKey(expected)) ........... by : assertThat(actual).containsKey(expected)'
replace 's/assertThat\((".*[^\]"),[[:space:]]*([^",]*|".*[^\]"|.*\(.*\)),[[:space:]]*hasKey\(([^"]*|".*[^\]"|.*\(.*\))\)\)/assertThat(\2).as(\1).containsKey(\3)/g'
replace 's/assertThat\([[:space:]]*([^",]*|".*[^\]"|.*\(.*\)),[[:space:]]*hasKey\(([^"]*|".*[^\]"|.*\(.*\))\)\)/assertThat(\1).containsKey(\2)/g'

# echo '15 - Replacing : assertThat(actual, not(hasKey(expected))) ........... by : assertThat(actual).doesNotContainKey(expected)'
replace 's/assertThat\((".*[^\]"),[[:space:]]*([^",]*|".*[^\]"|.*\(.*\)),[[:space:]]*not\(hasKey\(([^"]*|".*[^\]"|.*\(.*\))\)\)\)/assertThat(\2).as(\1).doesNotContainKey(\3)/g'
replace 's/assertThat\([[:space:]]*([^",]*|".*[^\]"|.*\(.*\)),[[:space:]]*not\(hasKey\(([^"]*|".*[^\]"|.*\(.*\))\)\)\)/assertThat(\1).doesNotContainKey(\2)/g'

# echo '16 - Replacing : assertThat(actual, hasValue(expected)) ........... by : assertThat(actual).containsValue(expected)'
replace 's/assertThat\((".*[^\]"),[[:space:]]*([^",]*|".*[^\]"|.*\(.*\)),[[:space:]]*hasValue\(([^"]*|".*[^\]"|.*\(.*\))\)\)/assertThat(\2).as(\1).containsValue(\3)/g'
replace 's/assertThat\([[:space:]]*([^",]*|".*[^\]"|.*\(.*\)),[[:space:]]*hasValue\(([^"]*|".*[^\]"|.*\(.*\))\)\)/assertThat(\1).containsValue(\2)/g'

# echo '17 - Replacing : assertThat(actual, not(hasValue(expected))) ........... by : assertThat(actual).doesNotContainValue(expected)'
replace 's/assertThat\((".*[^\]"),[[:space:]]*([^",]*|".*[^\]"|.*\(.*\)),[[:space:]]*not\(hasValue\(([^"]*|".*[^\]"|.*\(.*\))\)\)\)/assertThat(\2).as(\1).doesNotContainValue(\3)/g'
replace 's/assertThat\([[:space:]]*([^",]*|".*[^\]"|.*\(.*\)),[[:space:]]*not\(hasValue\(([^"]*|".*[^\]"|.*\(.*\))\)\)\)/assertThat(\1).doesNotContainValue(\2)/g'



# echo ''
# echo '5 - Replacing Hamcrest static imports by AssertJ ones, at this point you will probably need to :'
# echo '5 --- optimize imports with your IDE to remove unused imports'
# echo '5 --- add "import static org.assertj.core.api.Assertions.within;" if you were using JUnit number assertions with deltas'
replaceSingleLine 's/import static org\.hamcrest\.MatcherAssert\.assertThat;/import static org.assertj.core.api.Assertions.assertThat;/g'
replaceSingleLine 's/import static org\.hamcrest\.Matchers\.allOf;/import static com.hsbc.MatchingConsumer.allOf;/g'
#replaceSingleLine 's/import static org\.hamcrest\.Matchers\.\*;/import static com.hsbc.MatchingConsumer.allOf;/g'
#replaceSingleLine 's/import static org\.junit\.Assert\.\*;/import static org.assertj.core.api.Assertions.*;/g'
# echo ''


#                .andExpect(jsonPath("$.id", is(Matchers.equalTo(1))))
#                .andExpect(jsonPath("$.id").value(1))
replaceSingleLine 's/(jsonPath\("[^"]*"),[[:space:]]*is\((Matchers.)?equalTo\(([^)]*)\)\)\)/\1).value(\3)/g'

#                .andExpect(jsonPath("$.jobExecution.jobParameters", is(notNullValue())))
#                .andExpect(jsonPath("$.jobExecution.jobParameters").exists())
replaceSingleLine 's/(jsonPath\("[^"]*"),[[:space:]]*is\((Matchers.)?notNullValue\(\)\)\)/\1).exists()/g'

#                .andExpect(requestTo(equalTo("https://RAVENRISKSOURCE/api/v1/jobs/snapPrimary")))
#                .andExpect(requestTo("https://RAVENRISKSOURCE/api/v1/jobs/snapPrimary"))
# TODO expected url might not be a string constant
replaceSingleLine 's/requestTo\(equalTo\(("[^"]*")\)\)/requestTo(\1)/g'
