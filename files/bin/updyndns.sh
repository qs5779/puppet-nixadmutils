#!/bin/bash
# vim:sta:et:sw=2:ts=2:syntax=sh
#
# Revision History:
# 20170519 - que - initial verison
# 20210101 - que - shellcheck corrections
#

SCRIPT=$(basename "$0")
VERSION=1.0.0
VERBOSE=0
DEBUG=0
ERRORS=0
CREDS="${HOME}/.updyndnsrc"

function usage {
  cat << EOM
usage: $SCRIPT [-c configrc ] [-d] [-h] [-v] [-V] name ipads
  where:
    -d          - specify debug mode
    -c configrc - specify alternate config (default ~/.updyndnsrc)
    -h          - show this message and exit
    -v          - add verbosity
    -V          - show version and exit
EOM
  exit 1
}

while getopts ":c:C:dhvV:" opt
do
  case "$opt" in
    c|C )
      CREDS="$OPTARG"
    ;;
    d )
      ((DEBUG+=1))
      ((VERBOSE+=1))
    ;;
    h )
      usage
    ;;
    v )
      ((VERBOSE+=1))
    ;;
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

# shellcheck source=/dev/null
. "$CREDS" || echo "File not found|readable: $CREDS"

curl "https://${DDNSUSER}:${DDNSKEY}@members.dyndns.org/v3/update?hostname=${1}&myip=${2}"

# ERRORS=$((ERRORS+=1)) # darn ubuntu default dash shell
exit "$ERRORS"
