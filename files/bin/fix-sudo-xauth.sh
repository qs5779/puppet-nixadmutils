#!/bin/bash

DISPLAY_NUMBER=$(echo $DISPLAY | awk -F: '{print $2}' | awk -F. '{print $1}')
EC=0

if [ -n "$DISPLAY_NUMBER" ]
then
  #echo "DISPLAY #: $DISPLAY_NUMBER"
  COOKIE=$(xauth list | grep "unix:${DISPLAY_NUMBER}")
  #echo "COOKIE: $COOKIE"
  if [ -n "$COOKIE" ]
  then
    echo "executing: sudo xauth add $COOKIE"
    sudo xauth add $COOKIE
  else
    echo "No cookie found!"
    EC=1
  fi
else
  echo "No display number found!"
  EC=1
fi

exit $EC

