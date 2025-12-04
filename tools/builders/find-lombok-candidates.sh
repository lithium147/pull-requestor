#!/usr/bin/env bash

shopt -s nullglob
shopt -s globstar
# setopt extended_glob
files="$1"

for f in $files; do
  # TODO use filename instead of grep
  # or could use @Configuration to exclude
  if grep -Eq 'class .*(Config|Entity|Resource|Controller|Repository|Service)' "$f"; then
    continue
  fi
  if grep -Eq '^(public )?enum' "$f"; then
    continue
  fi
  if grep -Eq '@Xml' "$f"; then
    echo "$f"
    continue
  fi
  if grep -Eq 'import lombok.Builder;' "$f" && grep -Eq '@Builder' "$f"; then
    echo "$f"
    continue
  fi
  if grep -Eq 'import lombok.experimental.SuperBuilder;' "$f" && grep -Eq '@SuperBuilder' "$f"; then
    echo "$f"
    continue
  fi
#  if grep -Eq 'import lombok.RequiredArgsConstructor;' "$f" && grep -Eq '@RequiredArgsConstructor' "$f"; then
#    echo "$f"
#    continue
#  fi
  if grep -Eq 'import lombok.AllArgsConstructor;' "$f" && grep -Eq '@AllArgsConstructor' "$f"; then
    echo "$f"
    continue
  fi
  if grep -Eq 'import lombok.NoArgsConstructor;' "$f" && grep -Eq '@NoArgsConstructor' "$f"; then
    echo "$f"
    continue
  fi
  if grep -Eq 'import lombok.Getter;' "$f" && grep -Eq '@Getter' "$f"; then
    echo "$f"
    continue
  fi
  if grep -Eq 'import lombok.Setter;' "$f" && grep -Eq '@Setter' "$f"; then
    echo "$f"
    continue
  fi
  if grep -Eq 'import lombok.Data;' "$f" && grep -Eq '@Data' "$f"; then
    echo "$f"
    continue
  fi
  if grep -Eq 'import lombok.Value;' "$f" && grep -Eq '@Value' "$f"; then
    echo "$f"
    continue
  fi
done
