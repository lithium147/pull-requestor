#!/usr/bin/env bash

f="$1"  # file

cat "$f" | tr -d '\r' > "$f.tr"
mv "$f.tr" "$f"
