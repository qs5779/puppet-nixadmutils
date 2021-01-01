#!/bin/bash
# vim:sta:et:sw=2:ts=2:syntax=sh
#
# Revision History:
# 20180819 - que - initial version
# 20210101 - que - shellcheck corrections
#

SCRIPT=$(basename "$0")
VERSION=1.0.1
VERBOSE=0
MAYBE=''
ERRORS=0

function usage {
  cat << EOM
usage: $SCRIPT [-h] [-v] [-V]
  where:
    -h show this message and exit
    -v add verbosity
    -V show version and exit
EOM
  exit 1
}

while getopts ":htvV" opt
do
  case "$opt" in
    h )
      usage
      ;;
    t ) MAYBE='echo [noex] ' ;;
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

while [ -n "$1" ]
do
  SRC=$1
  shift

  if [ -w "$SRC" ]
  then
    SRCDIR=$(dirname "$SRC") # TODO: make sure src dir is writable
    SRCBAS=$(basename "$SRC")

    TGTBAS=$(echo "$SRCBAS" | tr -d \" | sed -e 's/ /-/g' -e 's/--/-/g' -e 's/\.\./\./g' -e 's/\//-/g')
    NEWNM="${SRCDIR}/${TGTBAS}"
    #echo "NEWNM: $NEWNM"

    if [ "$SRC" != "$TGTBAS" ]
    then
      $MAYBE mv "$SRC" "$NEWNM"
    fi

  else
    echo "File not (found|writable): $SRC"
    ((ERRORS+=1))
  fi
done

exit "$ERRORS"
