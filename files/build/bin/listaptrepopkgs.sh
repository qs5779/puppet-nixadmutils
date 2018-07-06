#!/bin/bash

ERRORS=0
RD=.
DF=${RD}/conf/distributions

if [ -r "$RD" ]
then
  for cn in $(grep Codename "$DF" | awk '{print $2}')
  do
    echo "dist: $cn"
    DD="${RD}/dists/${cn}"
    for pf in $(find $DD -type f -name Packages.gz)
    do
      PD=$(basename "$(dirname "$pf")")
      echo "-- $PD"
      zgrep Package "$pf"
    done
  done
else
  echo "File not found: $DF" >&2
  ((ERRORS+=1))
fi

if [ $ERRORS -gt 0 ]
then
  echo "exiting with: $ERRORS"
fi

exit $ERRORS
