#!/usr/bin/perl

# print all occurences of well formed IPv6 addresses in stdin to stdout. The IPv6 addresses should not overlap or be adjacent to eachother.
our $opt_v = 0;
our $opt_d = 0;

use Getopt::Std;

getopts("v");

my $aeron = qr/^(((?=(?>.*?::)(?!.*::)))(::)?([0-9A-F]{1,4}::?){0,5}|([0-9A-F]{1,4}:){6})(\2([0-9A-F]{1,4}(::?|$)){0,2}|((25[0-5]|(2[0-4]|1[0-9]|[1-9])?[0-9])(\.|$)){4}|[0-9A-F]{1,4}:[0-9A-F]{1,4})(?<![^:]:)(?<!\.)\z/i;
my $hits = 0;
my $line;
while ($line = <STDIN>) {
  if($line =~ $aeron) {
    print $1 . "\n";
    $hits++;
  }
}

if($opt_v || $opt_d) {
  printf "%d hits\n", $hits;
}
exit(0);
