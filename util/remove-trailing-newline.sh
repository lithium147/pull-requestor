#!/usr/bin/env bash

f="$1"
fb="$2"

#SCRIPT_PATH=$(dirname "$0")
#
#lastChar=$(tail -c 1 $f)
#newLineChar=$(echo "")
#
#  if [ $updated -ne 0 ]; then
#  diff $f $f.before
#  fi

diff $f $fb | grep -q 'No newline at end of file'
if [ $? -eq 0 ]; then
  echo -n 'removing newLineAdded..'
  size=$(stat -f '%z' $f)
  size=$((size - 1))
  head -c $size $f >$f.nl
  mv $f.nl $f
fi
