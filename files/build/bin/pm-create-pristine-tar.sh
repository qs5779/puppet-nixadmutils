#!/bin/bash
# vim:sta:et:sw=2:ts=2:syntax=sh
#
# Revision History:
# 20210101 - que - shellcheck corrections

SCRIPT=$(basename "$0")
ERRORS=0
VERBOSE=0
PKGDIR=''
MAYBE=''
TGTPAR=''

avend() {
  echo "$1" >&2
  ((ERRORS==1))
  exit $ERRORS
}

function usage {
  cat << EOM
usage: $SCRIPT [-h] [-v]
  where:
    -D dir - specify perl module source directory
    -h     - show this message and exit
    -T dir - specify output/tgt directory (default parent of source dir)
    -v     - add verbosity

EOM
  exit 1
}

while getopts ":hD:tT:v" opt
do
  case "$opt" in
    D )
      PKGDIR="$OPTARG"
    ;;
    h ) usage ;;
    T )
      TGTPAR="$OPTARG"
    ;;
    t )
      MAYBE="echo [noex] "
      ((VERBOSE+=1))
    ;;
    v ) ((VERBOSE+=1)) ;;
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

if [ ! -f "${PKGDIR}/Build.PL" ]
then
  echo "File not found: ${PKGDIR}/Build.PL" >&2
  echo "Invalid perl build directory: $PKGDIR" >&2
  usage
fi

PKGPAR=$(dirname "$PKGDIR")
PKGVERS=$(pm-get-release.sh -D "$PKGDIR" version)
PKGNAME=$(pm-get-release.sh -D "$PKGDIR" name)
TGTBAS="${PKGNAME}-${PKGVERS}"

if [ -z "$TGTPAR" ]
then
  TGTPAR="$PKGPAR"
else
  TGTPAR=$(readlink -f "$TGTPAR")
  if [ ! -d "$TGTPAR" ]
  then
    mkdir -p "$TGTPAR"
  fi
fi

TGTDIR="${TGTPAR}/${TGTBAS}"
TARBAS="${TGTBAS}.tar.gz"
TAR="${TGTPAR}/${TARBAS}"

if [ "$VERBOSE" -ne 0 ]
then
  echo "PKGDIR:  $PKGDIR"
  echo "PKGPAR:  $PKGPAR"
  echo "name:    $PKGNAME"
  echo "version: $PKGVERS"
  echo "tgtpar:  $TGTPAR"
  echo "tgtdir:  $TGTDIR"
  echo "tarbal:  $TAR"
fi

if [ -e "$TAR" ]
then
  if [ -d "$TAR" ]
  then
    echo "Can't create a tarbal due to directory at: $TAR" >&2
    exit 1
  fi
  while true; do
    read -rp "Overwrite existing file $TARBAS ? (y/n) " yn
    case $yn in
      [Yy]* ) rm -f "$TAR"; break;;
      [Nn]* ) exit;;
      * ) echo "Please answer yes or no.";;
    esac
  done
fi

# TODO make sure rsync src / tgt are not the same

EX=$(mktemp)

cat << EOF > "$EX"
blib/
cpanfile*
_build/
envs.sh
local/
MANIFEST.SKIP
misc/
Build
Makefile*
MY*
*.komodoproject
EOF


echo "creating pristine package dir in: $TGTPAR"
$MAYBE rsync -Cav --delete --delete-excluded \
  --exclude-from="$EX" "${PKGDIR}/" "${TGTDIR}/"
RC=$?
if [ $RC -ne 0 ]
then
  echo "rsync exited with exit code: $?" >&2
  ((ERRORS+=RC))
else
  cd "$TGTPAR" || abend "cd $TGTPAR failed!!!"
  echo "creating tar in: $(pwd)"
  $MAYBE tar -czf "$TAR" "$TGTBAS"
  RC=$?
  ((ERRORS+=RC))
fi

rm -f "$EX"

exit "$ERRORS"
