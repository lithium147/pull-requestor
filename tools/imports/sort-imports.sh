#!/usr/bin/env bash

# Handle the different ways of running `sed` without generating a backup file based on OS
# - GNU sed (Linux) uses `-i`
# - BSD sed (macOS) uses `-i ''`
SED_OPTIONS=(-E -i)
case "$(uname)" in
  Darwin*) SED_OPTIONS=(-E -i '')
esac

export LC_ALL=C

f="$1"  # file

function findImports() {
sed -E -n '
/^([/][*]| [*]).*$/d
/^[[:space:]]*package.*$/d
/^([[:space:]]*|.*import.*)$/!q
/'"$1"'/p
' "$f" | sed 's/;/!!!!!/' | sort -u | sed 's/!!!!!/;/' > "$2"
# use '!' to make sure it comes before any other chars
# -d to ignore the ";" when sorting
# -d doesn't work well with "_"
}

findImports 'import static' "$f.is"
findImports 'import javax' "$f.ijx"
findImports 'import java\.' "$f.ij"
findImports 'import' "$f.ia"

# subtract static/javax/java from all imports to leave the other imports - $f.io
diff --new-line-format='' --unchanged-line-format='' "$f.ia" "$f.is" > "$f.ia1"
diff --new-line-format='' --unchanged-line-format='' "$f.ia1" "$f.ijx" > "$f.ia2"
diff --new-line-format='' --unchanged-line-format='' "$f.ia2" "$f.ij" > "$f.io"
#cat "$f.io"

# combine all the sections (with newlines) into $f.i
echo >> "$f.i"
cat "$f.io" >> "$f.i"
if [ -s "$f.io" ]; then
  echo >> "$f.i"
fi
cat "$f.ijx" >> "$f.i"
cat "$f.ij" >> "$f.i"
if [ -s "$f.ij" ] || [ -s "$f.ijx" ]; then
  echo >> "$f.i"
fi
cat "$f.is" >> "$f.i"
if [ -s "$f.is" ]; then
  echo >> "$f.i"
fi


function deleteImportsSection() {
# TODO what if there is no package?
packageLine=$(sed -E -n '/^[[:space:]]*package.*$/{
=;q
}' "$f")
# quits when first line is found that is not a comment/package/import/newline
# but this will remove class comments
# want to find first /**|//|@|[A-Za-z0-9]
#lastImportLine=$(sed -E -n '
#/^([/][*]| [*]).*$/d
#/^[[:space:]]*package.*$/d
#/^([[:space:]]*|.*import.*)$/!{
#=;q
#}
#' "$f")
# find first line starting with: /**|//|[A-Za-z0-9@_]
# excluding package, import and newlines
# sometime copyright with start with /**** ...
# so just exclude the first line - if its not a comment, then it would be a package which is ok to exclude
lastImportLine=$(sed -E -n '
1d
/^[[:space:]]*package.*$/d
/^[[:space:]]*import.*$/d
/^[[:space:]]*$/d
/^[[:space:]]*(\/\*\*|\/\/|[A-Za-z0-9@_])/{
=;q
}
' "$f")

packageLine=$((packageLine + 1))
lastImportLine=$((lastImportLine - 1))
echo -n "replacing lines $packageLine...$lastImportLine"

if [ $lastImportLine -lt $packageLine ]; then
  echo "lastImportLine can't be less than packageLine"
  rm $f.i*
  exit 255
fi

sed "${SED_OPTIONS[@]}" "${packageLine},${lastImportLine}d" "$f"

}

deleteImportsSection

sed "${SED_OPTIONS[@]}" "/^[[:space:]]*package.*$/r$f.i" "$f"

rm $f.i*
