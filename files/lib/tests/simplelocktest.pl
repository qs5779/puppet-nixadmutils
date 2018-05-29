#!/usr/bin/perl
# -*- Mode: Perl; tab-width: 2; indent-tabs-mode: nil -*- vim:sta:et:sw=2:ts=2:syntax=perl
#
# Expounded upon logic from:
# Advanced Shell Scripting - http://members.toast.net/art.ross/rute/node24.html#SECTION002470000000000000000
#
# Revision History
#  20101207 - Initial Script
#  20180529 - que - initial version
#

use strict;

my $retVal = 1;
my $cmd = sprintf 'simplelock /tmp/simplelocktest %d', $$;
my $out;

while($retVal) {
  $out = qx($cmd);
  $retVal = $?;
  sleep 2 if($retVal);
}
print "out: $out\n";
print "Exiting. Got lock!!\n";
