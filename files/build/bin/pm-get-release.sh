#!/bin/bash
# vim:sta:et:sw=2:ts=2:syntax=sh
#
# Revision History:
# 20210101 - que - shellcheck corrections

SCRIPT=$(basename "$0")
ERRORS=0
PKGDIR=''

function usage {
  cat << EOM
usage: $SCRIPT [-h] [-v] [-V]
  where:
    -D dir - specify perl module source directory
    -h     - show this message and exit

EOM
  exit 1
}

while getopts ":hD:" opt
do
  case "$opt" in
    D )
      PKGDIR="$OPTARG"
    ;;
    h )
      usage
    ;;
    * )
      echo "Unexpected option \"$opt\""
      usage
    ;;
  esac
done
shift $((OPTIND - 1))

if [ -z "$PKGDIR" ]
then
  PKGDIR=$(pwd)
fi

PKGDIR=$(readlink -f "$PKGDIR")

if [ -n "$1" ]
then
  QUERY="$1"
else
  QUERY=version
fi

SRC=${PKGDIR}/Build.PL
if [ -r "$SRC" ]
then
  case "$QUERY" in
    vers* )
      VERSION_FROM=$(grep dist_version_from "$SRC" | awk '{print $NF}' | tr -d "\'\",")
      SRC=${PKGDIR}/${VERSION_FROM}
      if [ -r "$SRC" ]
      then
        #VERSION=$(grep -P "^our \$VERSION" "$SRC" | tr -d "[',\"]" | awk '{print $NF}')
        RESULT=$(grep VERSION "$SRC" | grep ^our | tr -d "\';\"" | awk '{print $NF}')
        # assumes major/minor each less <= 9
        MAJOR=$(echo "$RESULT" | awk -F '.' '{print $1}')
        RIGHT=$(echo "$RESULT" | awk -F '.' '{print $NF}')
        RESULT="${MAJOR}.${RIGHT:0:1}.${RIGHT:1}"
      else
        echo "File not (found|readable): $SRC" >&2
        ((ERRORS+=1))
      fi
    ;;
    name )
      RESULT=$(grep module_name "$SRC" | awk '{print $NF}' | tr -d "\',\"")
    ;;
    * )
      echo "unrecognized query: $QUERY" >&2
      ((ERRORS+=1))
    ;;
  esac
else
  echo "File not (found|readable): $SRC" >&2
  ((ERRORS+=1))
fi

if [ "$ERRORS" -eq 0 ]
then
  if [ -n "$RESULT" ]
  then
    echo "$RESULT"
  else
    echo "nothing found for query: $QUERY" >&2
    ((ERRORS+=1))
  fi
fi

exit "$ERRORS"
