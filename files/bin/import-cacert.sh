#!/bin/bash
# vim:sta:et:sw=2:ts=2:syntax=sh
#
# Revision History:
# 20210101 - que - shellcheck corrections
#

SCRIPT=$(basename "$0")
VERSION=1.0.0
VERBOSE=0
DEBUG=0
ERRORS=0
CN=''

function usage {
  cat << EOM
usage: $SCRIPT [-d] [-h] [-n commonName] [-v] [-V] certfile
  where:
    -d        - specify debug mode
    -h        - show this message and exit
    -n caname - default extracted commonName from cert
    -v        - add verbosity
    -V        - show version and exit
EOM
  exit 1
}

while getopts ":dhnvV" opt
do
  case "$opt" in
    d )
      ((DEBUG+=1))
      ((VERBOSE+=1))
    ;;
    h )
      usage
    ;;
    n )
      CN="$OPTARG"
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

if [ -z "$1" ]
then
  usage
fi

INFILE="$1"
shift

if [ -r "$INFILE" ]
then
  if [ -z "$CN" ]
  then
    CN=$(ssl-cn "$INFILE")
  fi

  if [ -n "$CN" ]
  then
    certutil -d "sql:${HOME}/.pki/nssdb" -A -t TC -n "$CN" -i "$INFILE"
  else
    echo "Failed to determine commonName for: $INFILE" >&2
    ((ERRORS+=1))
  fi
else
  echo "File not (found|readable): $INFILE" >&2
  ((ERRORS+=1))
fi

# ERRORS=$((ERRORS+=1)) # darn ubuntu default dash shell
exit "$ERRORS"
