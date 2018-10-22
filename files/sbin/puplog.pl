#!/usr/bin/perl -w
# -*- Mode: Perl; tab-width: 2; indent-tabs-mode: nil -*- vim:sta:et:sw=2:ts=2:syntax=perl
#
# Revision History:
# 20180818 - whoami - initial version
#

use strict;
use File::Basename qw/ basename dirname /;
use Getopt::Long;
use Pod::Usage;
use File::Temp qw/ :POSIX /;

use constant TRUE => 1;
use constant FALSE => 0;

my $SCRIPT = basename( "$0" );
my $SCRDIR = dirname("$0");

my $debug = 0;
my $verbose = 0;
my $man = 0;
my $help = 0;
my $version = 0;
my $error_count = 0;

Getopt::Long::Configure("bundling");

GetOptions(
  'd|debug+'       => \$debug,
  'v|verbose+'     => \$verbose,
  'V|Version'     => \$version,
  'man' => \$man,
  'h|help|?'  => \$help
) or pod2usage( 2 );

pod2usage( 1 ) if $help;
pod2usage(-exitstatus => 0, -verbose => 2) if $man;

my $VERSION = '$Revision: 990 $';

if ( $version ) {
  $VERSION =~ s/\$//g;
  print "$SCRIPT $VERSION\n";
  exit(0);
}

my $lfn;

my $scratch = qx(grep ID_LIKE /etc/os-release);

if ($scratch =~ m/debian/i) {
  $lfn = '/var/log/syslog';
}
else {
  $lfn = '/var/log/messages';
}


my $tac;
if(! -r $lfn) {
  $tac = 'sudo tac';
}
else {
  $tac = 'tac';
}

 my ($fh, $file) = tmpnam();

open(LOG, "$tac '$lfn'|") or die(sprintf("Failed to open pipe for command 'tac %s'\n", $lfn));

my $line;
my $hits = 0;
my ($lead, $pid);
my $print = 0;

while ($line = <LOG>) {
  if ($line =~ /^([^:]).*puppet-agent\[(\d+)\]: Applied catalog/) {
    $lead = $1;
    $pid = $2;
    if($hits > 0) {
      close($fh);
      system(sprintf("tac %s", $file));
      cleanexit();
    }
    else {
      $hits++;
      $print = 1;
    }
  }
  elsif($hits > 0 && $line =~ /^${lead}.*puppet-agent\[${pid}\]:/) {
    print $fh $line;
  }
  print $fh $line if($print);
}

exit($error_count);

sub cleanexit {
  close(LOG);
  exit($error_count);
}

__END__

=head1 NAME

perl-script-template.pl - example perl script template

=head1 SYNOPSIS

perl-script-template.pl [-d] [-h] [-v] [-V]

  example perl script template

=head1 OPTIONS

=over 8

=item B<-d|--debug>

  Sets debug flag to show more output.

=item B<-h|--help>

  Print a brief help message and exits.

=item B<-v|--verbose>

  Sets verbose flag to show more output.

=item B<-V|--version>

  Prints version and exits


=back
