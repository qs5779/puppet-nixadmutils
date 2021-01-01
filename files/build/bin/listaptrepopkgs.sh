#!/bin/bash
# vim:sta:et:sw=2:ts=2:syntax=sh
#
# Revision History:
# 20210101 - que - shellcheck corrections

ERRORS=0
RD=.
DF=${RD}/conf/distributions

if [ -r "$RD" ]
then
  while IFS= read -r cn
  do
    echo "dist: $cn"
    DD="${RD}/dists/${cn}"
    while IFS= read -r -d '' pf
    do
      PD=$(basename "$(dirname "$pf")")
      echo "-- $PD"
      zgrep Package "$pf"
    done <   <(find "$DD" -type f -name Packages.gz -print0)
  done < <(grep Codename "$DF" | awk '{print $2}')
else
  echo "File not found: $DF" >&2
  ((ERRORS+=1))
fi

if [ "$ERRORS" -gt 0 ]
then
  echo "exiting with: $ERRORS"
fi

exit "$ERRORS"
