#!/bin/bash
# vim:sta:et:sw=2:ts=2:syntax=sh
#
# Revision History:
# 20160811 - quiensabe - initial version
#

SCRIPT=$(basename "$0")
VERSION='$Revision: 2123 $'
VERBOSE=0
DEBUG=0
ERRORS=0

function usage {
  cat << EOM
usage: $SCRIPT [-d] [-h] [-v] [-V]
  where:
    -d specify debug mode
    -h show this message and exit
    -v add verbosity
    -V show version and exit

    find fifo files in current directory

EOM
  exit 1
}

while getopts ":dhvV" opt
do
  case "$opt" in
    d )
      ((DEBUG+=1))
      ((VERBOSE+=1))
    ;;
    h )
      usage
    ;;
    v ) ((VERBOSE+=1)) ;;
    V )
      echo "$SCRIPT VERSION: $VERSION"
      exit 0
    ;;
    * )
      echo "Unexpected option \"$opt\""
      usage
    ;;
  esac
done
shift $((OPTIND - 1))

find . -type p

exit "$ERRORS"
