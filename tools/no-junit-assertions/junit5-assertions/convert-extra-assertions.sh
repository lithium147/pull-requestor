#!/bin/bash

f="$1"

# Handle the different ways of running `sed` without generating a backup file based on OS
# - GNU sed (Linux) uses `-i`
# - BSD sed (macOS) uses `-i ''`
SED_OPTIONS=(-i -e)
case "$(uname)" in
  Darwin*) SED_OPTIONS=(-i "" -e)
esac

# sed -E: Interpret regular expressions as extended (modern) regular expressions rather than basic regular expressions (BRE's).
function replace() {
  sed -E "${SED_OPTIONS[@]}" '
/'$1'\(/{
  :b
  /.*;[[:space:]]*$/!{N;bb
  }
  '$2'
}' "$f"
}

function replaceSingleLine() {
  sed -E "${SED_OPTIONS[@]}" "$1" "$f"
}

# regular expressions patterns:
# `[^",]*` Match a single character not present in the list `^",`
# ".*[^\]" Match a single character within double quotes, and it can distinguish escaped double quotes
# .*\(.*\) Match a single character within round brackets

#       assertEquals(EnumSet.of(FontFormat.DOUBLE_WIDTH, FontFormat.DOUBLE_HEIGHT), ((PrintLine) printCommand).getFontFormats());
#       assertThat(FontFormat.DOUBLE_HEIGHT), ((PrintLine) printCommand).getFontFormats()).isEqualTo(EnumSet.of(FontFormat.DOUBLE_WIDTH);


#echo ' 2 - Replacing : assertEquals(expected, actual, String.format(desc)) ................. by : assertThat(actual).as(String.format(desc)).isEqualTo(expected)'
replace 'assertEquals' 's/assertEquals\(([^",]*|".*[^\]"|.*\(.*\)),[[:space:]]*([^",]*|".*[^\]"|.*\(.*\)),[[:space:]]*(String.format\(.*\))\)/assertThat(\2).as(\3).isEqualTo(\1)/g'
#echo ' 3 - Replacing : assertTrue(logicalCondition, String.format(desc)) ................... by : assertThat(logicalCondition).as(String.format(desc)).isTrue()'
replace 'assertTrue' 's/assertTrue\(([^",]*|".*[^\]"|.*\(.*\)),[[:space:]]*(String.format\(.*\))\)/assertThat(\1).as(\2).isTrue()/g'

#var exception = assertThrows(HttpClientResponseException.class, () -> httpClient.toBlocking().exchange(request));
#        var exception = catchThrowableOfType(() -> httpClient.toBlocking().exchange(request), HttpClientResponseException.class);
# TODO multiline not working for this one
replaceSingleLine 's/=[[:space:]]*assertThrows\(([^",]*|".*[^\]"|.*\(.*\)),[[:space:]]*(.*)\)/= catchThrowableOfType(\2, \1)/g'

#        assertThrows(MissingDomainInfoException.class, () -> TotalsViewModel.from(order, invoice, payments, includeVat));
replace 'assertThrows' 's/assertThrows\(([^",]*|".*[^\]"|.*\(.*\)),[[:space:]]*(.*)\)/assertThat(catchThrowable(\2)).isInstanceOf(\1)/g'
# TODO split out catchThrowable

#        assertThat(catchThrowable(() -> VatViewModel.isSalesTaxCodeForNonZeroRate("GB", "C123456")).isInstanceOf(IllegalArgumentException.class);
#        assertThat(throwable)
#                .isInstanceOf(IllegalArgumentException.class);

#        assertDoesNotThrow(() -> PaperReceiptViewModelBuilder.from(tillTransaction, tillContext, PaperJourneyType.REPRINT));
#        assertThat(catchThrowable(() -> PaperReceiptViewModelBuilder.from(tillTransaction, tillContext, PaperJourneyType.REPRINT)).isNull();
replace 'assertDoesNotThrow' 's/assertDoesNotThrow\(([^",]*|".*[^\]"|.*\(.*\))\)/assertThat(catchThrowable(\1)).isNull()/g'

#        assertInstanceOf(RuntimeException.class, new RuntimeException());
# ->
#        assertThat(new RuntimeException()).isInstanceOf(RuntimeException.class);
replace 'assertInstanceOf' 's/assertInstanceOf\(([^",]*|".*[^\]"|.*\(.*\)),[[:space:]]*([^",]*|".*[^\]"|.*\(.*\)),[[:space:]]*(".*[^\]")\)/assertThat(\2).as(\3).isInstanceOf(\1)/g'
replace 'assertInstanceOf' 's/assertInstanceOf\(([^",]*|".*[^\]"|.*\(.*\)),[[:space:]]*(.*)\)/assertThat(\2).isInstanceOf(\1)/g'
