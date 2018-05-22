#!/bin/bash
# -*- Mode: Bash; tab-width: 2; indent-tabs-mode: nil -*- vim:sta:et:sw=2:ts=2:syntax=sh
# Revision History:
# 20170519 - que - initial verison
#

SCRIPT=$(basename "$0")
VERSION='$Revision: 1 $'
VERBOSE=0
DEBUG=0
ERRORS=0
ZONES=''
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
      echo "$SCRIPT VERSION: $(echo $VERSION | awk '{ print $2 }')"
      exit 0
    ;;
    * )
      echo "Unexpected option \"$opt\""
      usage
    ;;
  esac
done
shift $((OPTIND - 1))

. "$CREDS" || echo "File not found|readable: $CREDS"

curl "https://${DDNSUSER}:${DDNSKEY}@members.dyndns.org/v3/update?hostname=${1}&myip=${2}"

# ERRORS=$((ERRORS+=1)) # darn ubuntu default dash shell
exit $ERRORS
