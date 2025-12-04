#!/usr/bin/env bash

# Handle the different ways of running `sed` without generating a backup file based on OS
# - GNU sed (Linux) uses `-i`
# - BSD sed (macOS) uses `-i ''`
SED_OPTIONS=(-E -i)
case "$(uname)" in
  Darwin*) SED_OPTIONS=(-E -i '')
esac

f="$1"  # file

function fix() {
  sed "${SED_OPTIONS[@]}" "s/${1}/${2}/g" "$f"
}

function fixPerl() {
  perl -i -pe "s/${1}/${2}/g" "$f"
}

# not assertj related
fix '\(\(([^()]*)\)\)' '(\1)'                    # ((abc)) -> (abc)
fix '\(\(([^()]*\([^()]*\)[^()]*)\)\)' '(\1)'   # ((abc(efg)hij)) -> (abc(efg)hij)

#assignmentOperators='>>>=|<<=|>>=|\+=|-=|\*=|\/=|\%=|\&=|\^=|\|=|='
assignmentOperators='(>>>|<<|>>|\+|-|\*|\/|\%|\&|\^|\|)'

#        var exception = (catchThrowableOfType(() -> pureSerialDriverResolver.attemptPrinterDriverResolution(pureSerialPrinterDeviceObserver), UnknownPureSerialDeviceException.class));
#fix "([^(){}\" ]+)[[:space:]]*(${assignmentOperators}=)[[:space:]]*\(([^)]+)\)[[:space:]]*;" '\1 \2 \4;'                    # abc = (efg);

#fix "([^(){}\" ]+[[:space:]]*[0-9A-Za-z_ ])=[[:space:]]*\(([^)]+)\)[[:space:]]*;" '\1= \2;'                    # abc = (efg);
#
#fix "([^(){}\" ]+[[:space:]]*[0-9A-Za-z_ ])=[[:space:]]*\(([^()]*\([^()]*\)[^()]*)\)[[:space:]]*;" '\1= \2;'                    # abc = (efg(hij)klm);
#
#fix "([^(){}\" ]+[[:space:]]*[0-9A-Za-z_ ])=[[:space:]]*\((([^()]*\(){3}[^()]*\){3}[^()]*)\)[[:space:]]*;" '\1= \2;'                    # abc = (efg(hij)klm);

# use recursive regex to match balanced brackets
fixPerl '([^(){}\" ]+[[:space:]]*[0-9A-Za-z_ ])= (\((([^)(]+|(?2))*+)\))[[:space:]]*;' '\1= \3;'                    # abc = (efg(hij)klm);
fixPerl "([^(){}\" ]+)[[:space:]]*(${assignmentOperators}=)[[:space:]]*(\((([^)(]+|(?4))*+)\))[[:space:]]*;" '\1 \2 \5;'                    # abc = (efg);


# TODO Collections.singletonList() -> Lists.of()

# perl creates a bak file
if [ -e "$f.bak" ]; then
  rm "$f.bak"
fi
