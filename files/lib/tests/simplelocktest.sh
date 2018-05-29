#!/bin/sh
# -*- Mode: Bash; tab-width: 2; indent-tabs-mode: nil -*- vim:sta:et:sw=2:ts=2:syntax=sh
#
# Revision History
#  20180529 - que - initial version
#

OWNSLOCK=0
CLEANUP=0
LOCKDIR=/tmp/locktest
LOCKNAME=${LOCKDIR}/simplelocktest
LOCKFILE=${LOCKNAME}.lock

while getopts ":c" OPT
do
  case $OPT in
    q ) ((CLEANUP+=1)) ;;
    * ) echo "Unrecognized option $OPT" ;;
  esac
done
shift $(($OPTIND - 1))

function trapped {
  echo "$(date) $SCRIPT trap received, exiting"
  if [ $OWNSLOCK -ne 0 -a $CLEANUP -ne 0 ]
  then
    rm -f $LOCKFILE
  fi
  exit 1
}

function trapint {
  echo "$(date) $SCRIPT INT received"
  trapped
}

function trapterm {
  echo "$(date) $SCRIPT TERM received"
  trapped
}

function trapquit {
  echo "$(date) $SCRIPT QUIT received"
  trapped
}

trap "trapint" INT
trap "trapterm" TERM
trap "trapquit" QUIT

#my $retVal = 1;
#my $cmd = sprintf 'simplelock /tmp/simplelocktest %d', $$;

if [ ! -d $LOCKDIR ]
then
  mkdir -p $LOCKDIR
fi

RC=1

while [ $RC -ne 0 ]
do
  simplelock $LOCKNAME $$
  RC=$?
  if [ $RC -ne 0 ]
  then
    sleep 2
  fi
done

OWNSLOCK=1

echo "Got lock!!\n";

ls -l $LOCKFILE

while [ $RC -eq 0 ]
do
  sleep 2
done
