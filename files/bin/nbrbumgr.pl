#!/usr/bin/perl
# -*- Mode: Perl; tab-width: 2; indent-tabs-mode: nil -*- vim:sta:et:sw=2:ts=2:syntax=perl
#
# Revision History:
# 20150527 richarjt - initial version
#
use strict;
use File::Basename qw/ basename dirname /;
use Getopt::Long;
use Pod::Usage;
use Data::Dumper;
use constant TRUE => 1;
use constant FALSE => 0;

my $basenm = basename( "$0" );
my $SCRDIR = dirname("$0");
my $debug = 0;
my $verbose = 0;
my $man = 0;
my $help = 0;
my $version = 0;
my $keep = 5;
my @files = ();

Getopt::Long::Configure("bundling");

GetOptions(
  'd|debug+'       => \$debug,
  'f|file=s'       => \@files,
  'k|keep=i'       => \$keep,
  'v|verbose+'     => \$verbose,
  'V|Version'      => \$version,
  'man'            => \$man,
  'h|help|?'       => \$help
) or pod2usage( 2 );
pod2usage( 1 ) if $help;
pod2usage(-exitstatus => 0, -verbose => 2) if $man;

my $VERSION = '$Revision: 963 $';

if ( $version ) {
  $VERSION =~ s/\$//g;
  print "$basenm $VERSION\n";
  exit(0);
}

if ($keep <= 0) {
  exit(0);
}

if (@ARGV) {
  push(@files, @ARGV);
}

foreach my $f (@files) {
  if (! -f $f) {
    printf "File not found: %s\n", $f;
    next;
  }

  my $bn = basename($f);
  my $dn = dirname($f);

  if ($debug) {
    printf "bn: %s\n", $bn;
    printf "dn: %s\n", $dn;
  }

  if (! -d $dn) {
    printf "Directory not found: %s\n", $dn;
    next;
  }

  if ($bn =~ /\.~\d+~$/) {
    printf "Skipping numbered backup file: %s\n", $f;
    next;
  }

  if ( opendir(D,$dn) ) {
    my @backups = sort highlow grep /${bn}\.~\d+~$/,readdir D;
    print Data::Dumper->Dump([\@backups], [qw(backups)]) if($debug);
    closedir D;

    my $bcnt = @backups;

    if ($bcnt < $keep) {
      $keep = $bcnt;
    }

    my %renames = ();

    my $nb;

    foreach $nb (@backups) {
      if ($keep > 0) {
        $renames{$nb} = sprintf '%s.~%d~', $bn, $keep;
      }

      else {
        $renames{$nb} = 0; # delete it
      }
      $keep--;
    }

    print Data::Dumper->Dump([\%renames], [qw(renames)]) if($debug);

    my $tn;

    # first we'll delete all that need to be deleted
    foreach $nb (sort highlow keys %renames) {
      if (!$renames{$nb}) {
        $tn = sprintf '%s/%s', $dn, $nb;
        printf "unlinking %s\n", $tn if($verbose || $debug);
        unlink($tn) if(!$debug);
      }
    }

    my $sn;

    # next we'll rename all that need to be renamed
    foreach $nb (sort lowhigh keys %renames) {
      if ($renames{$nb}) {
        $sn = sprintf '%s/%s', $dn, $nb;
        $tn = sprintf '%s/%s', $dn, $renames{$nb};
        printf "renaming %s to %s\n", $sn, $tn if($verbose || $debug);
        rename($sn, $tn) if(!$debug);
      }
    }
  }
  else {
    printf STDERR "Failed to open directory: %s\n", $dn;
  }
}

sub highlow {

  if ($a =~ /\.~(\d+)~$/) {
    my $an = $1;
    if ($b =~ /\.~(\d+)~$/) {
      return $1 <=> $an;
    }
  }

  print "oops\n" if ($debug);
  return $b cmp $a;
}

sub lowhigh {

  if ($a =~ /\.~(\d+)~$/) {
    my $an = $1;
    if ($b =~ /\.~(\d+)~$/) {
      return $an <=> $1;
    }
  }

  print "oops\n" if ($debug);
  return $a cmp $b;
}


__END__

=head1 NAME

nbrbumgr.pl - perl script to manage maximum number of numbered backup files create by the "cp --backup=numbered" option

=head1 SYNOPSIS

nbrbumgr.pl [-d] [-f file] [-k keepbnr] [-h] [-v] [-V] [file1 ...]

  perl script to manage maximum number of numbered backup files create by the "cp --backup=numbered" option
  list of files can be passed as bare arguments or -f file, multi files supported

=head1 OPTIONS

=over 8

=item B<-d|--debug>

  Sets debug flag to show more output.

=item B<-f|--file>

  Specify a file to manage numbered backups for.

=item B<-k|--keep>

  Specify a maximum number of backups to keep (default 5).

=item B<-h|--help>

  Print a brief help message and exits.

=item B<-v|--verbose>

  Sets verbose flag to show more output.

=item B<-V|--version>

  Prints version and exits


=back
