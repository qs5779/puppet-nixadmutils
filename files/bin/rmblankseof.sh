#!/bin/bash

ERRORS=0
tmpfile=$(/bin/mktemp /tmp/scratch.XXXXXXXXX)

if [ ! -w "$tmpfile" ]
then
  echo "/bin/mktemp failed to create file!!" >&2
  exit 1
fi

while [ -n "$1" ]
do
  TGT="$1"
  shift

  if [ -w "$TGT" ]
  then
    awk '/^$/ {nlstack=nlstack "\n";next;} {printf "%s",nlstack; nlstack=""; print;}' "$TGT" > "$tmpfile"
    diff -q "$TGT" "$tmpfile" >/dev/null
    RC=$?
    if [ $RC -ne 0 ]
    then
      if [ $RC -eq 1 ]
      then
        cat "$tmpfile" > "$TGT"
      else
        ((ERRORS+=1))
        echo "diff -q \"$TGT\" \"$tmpfile\" exited with exitcode: $RC" >&2
      fi
    fi
  else
    ((ERRORS+=1))
    echo "File not found|writable: $TGT" >&2
  fi
done

rm -f "$tmpfile"

exit "$ERRORS"
