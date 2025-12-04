#!/bin/bash

# Handle the different ways of running `sed` without generating a backup file based on OS
# - GNU sed (Linux) uses `-i`
# - BSD sed (macOS) uses `-i ''`
SED_OPTIONS=(-E -i)
case "$(uname)" in
Darwin*) SED_OPTIONS=(-E -i "") ;;
esac

f="$1"

function fix() {
  sed "${SED_OPTIONS[@]}" "s/${1}/${2}/g" "$f"
}

fix "isEqualTo\(null\)" 'isNull()'
fix "isNotEqualTo\(null\)" 'isNotNull()'
fix "isEqualTo\(true\)" 'isTrue()'
fix "isEqualTo\(false\)" 'isFalse()'
fix "isEqualTo\(0\)" 'isZero()'
fix "hasSize\(0\)" 'isEmpty()'
fix "isEqualTo\(\"\"\)" "isEmpty()"
fix "\.size\(\)\)\.isZero\(\)" ").isEmpty()"
fix "\.length\)\.isZero\(\)" ").isEmpty()"
fix "\.size\(\)\)\.isEqualTo\(([^;]+)\)" ').hasSize(\1)'
fix "\)\.isEqualTo\(List.of\(([^;]+)\)\)" ').containsExactly(\1)'
fix "\)\.isEqualTo\(Collections.emptyList\(\)\)" ').isEmpty()'
# not assertj related
fix "\(\(([^)]*)\)\)" '(\1)'                    # ((abc)) -> (abc)
fix "\(\(([^()]*\([^()]*\)[^()]*)\)\)" '(\1)'   # ((abc(efg)hij)) -> (abc(efg)hij)

#assertThat((actual.getMessage())).isEqualTo(expected.getMessage());

#assertThat(!baselineProps.get(SP_COMMON_PROP).equals(resultProps.get(SP_COMMON_PROP))).as(String.format("Baseline property %s is not overriden with expected sub-profile value.", SP_COMMON_PROP)).isTrue();
fix "assertThat\(!([^;]+)\.equals\(([^;]+)\)\).as\(([^;]+)\).isTrue\(\)" 'assertThat(\1).isNotEqualTo(\2).as(\3)'
fix "assertThat\(!([^;]+)\.equals\(([^;]+)\)\).isTrue\(\)" 'assertThat(\1).isNotEqualTo(\2)'

fix "assertThat\(([^;]+)\.equals\(([^;]+)\)\).as\(([^;]+)\).isTrue\(\)" 'assertThat(\1).isEqualTo(\2).as(\3)'
fix "assertThat\(([^;]+)\.equals\(([^;]+)\)\).isTrue\(\)" 'assertThat(\1).isEqualTo(\2)'

# TODO update other replacements to support as()

#assertThat(EmailReceiptAvailability.getEmailReceiptAvailabilityLevel().equals(expectedEmailReceiptAvailabilityLevel)).isTrue();
#fix "\.equals\(([^;]+)\)\).isTrue\(\)" ').isEqualTo(\1)'

#            assertThat((!actualLines.contains("initial content\\n"))).isTrue();
#            assertThat((actualLines.contains("new content\\n"))).isTrue();
#        assertThat(result.get(0).getLines().get(1).getLineFormats().contains(LineFormatModifier.DOUBLE_HEIGHT)).isTrue();

fix "assertThat\(\!([^;]+)\.contains\(([^;]+)\)\).isTrue\(\)" 'assertThat(\1).doesNotContain(\2)'
fix "\.contains\(([^;]+)\)\).isTrue\(\)" ').contains(\1)'

#            assertThat(Files.exists(receiptFile)).isTrue();
#            assertThat(pathWithNewDirectory).exists();
fix "assertThat\(!Files.exists\(([^;]+)\)\).isTrue\(\)" 'assertThat(\1).doesNotExist()'
fix "assertThat\(Files.exists\(([^;]+)\)\).isTrue\(\)" 'assertThat(\1).exists()'
fix "assertThat\(!Files.exists\(([^;]+)\)\).isFalse\(\)" 'assertThat(\1).exists()'
fix "assertThat\(Files.exists\(([^;]+)\)\).isFalse\(\)" 'assertThat(\1).doesNotExist()'


#        assertThat(value.isLargerThanZero()).isTrue();
# isLargerThanZero is a custom method, so not suitable

#        assertThat(termsAndConditions.size() > 0).isTrue();
#        assertThat(termsAndConditions).isNotEmpty();
fix "\.size\(\)[[:space:]]*>[[:space:]]*0\).isTrue\(\)" ').isNotEmpty()'

#        assertThat(paymentInfo.getPaymentResult().isEmpty()).isTrue();
fix "\.isEmpty\(\)\).isTrue\(\)" ').isEmpty()'


#            assertThat(e instanceof PricingOrchServiceException).isTrue();

#        assertThatThrownBy(() -> underTest.mapToQuic(edForwardTsVol, processingGroup, "gs://bucket/file.csv"))
#                .isExactlyInstanceOf(XdsTransformException.class).hasMessage("Failed to receive currency from Redis database");
#        Exception exception = catchException(() -> underTest.mapToQuic(rates, processingGroup, "FX_WTF"));
#
#        assertThat(exception)
#                .isInstanceOf(XdsTransformException.class);
nb="[^()]*"         # no bracket
mb="($nb|\($nb\))*" # matched bracket - level 1
mb="($nb|\($mb\))*" # matched bracket - level 2
mb="($nb|\($mb\))*" # matched bracket - level 3
mb="($nb|\($mb\))*" # matched bracket - level 4

function replaceMultiline() {
  sed "${SED_OPTIONS[@]}" '
/^[[:space:]]*assertThatThrownBy/{
  :b
  /^[[:space:]]*assertThatThrownBy\('"$mb"'\)[^;]*;/!{N;bb
  }
  s/^([[:space:]]*)assertThatThrownBy(\('"$mb"'\))([^;]*);$/\1Exception exception = catchException\2;\n\n\1assertThat(exception)\1        \7;/
}' "$f"
}

# this won't work if the exception variable is already defined in the test method.
# perhaps it could reuse the existing variable.
# but test method should be split - one "when" per test method
replaceMultiline
