#!/usr/bin/perl -w
# -*- Mode: Perl; tab-width: 2; indent-tabs-mode: nil -*- vim:sta:et:sw=2:ts=2:syntax=perl
#
# Revision History:
# 20160915 - quiensabe - finished version from ~/bin for vmail user
#

use strict;
use File::Basename qw/ basename dirname /;
use Getopt::Long;
use Pod::Usage;
use MIME::Lite;

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
my $attachfn = 0;
my $from_address = 0;
my $to_address   = 0;
my $subject      = 0;
my $message_body = "";

Getopt::Long::Configure("bundling");

GetOptions(
  'a|attach=s'       => \$attachfn,
  'd|debug+'         => \$debug,
  'f|from=s'         => \$from_address,
  't|to=s'           => \$to_address,
  'm|message=s'      => \$message_body,
  's|subj|subject=s' => \$subject,
  'v|verbose+'       => \$verbose,
  'V|Version'        => \$version,
  'man'              => \$man,
  'h|help|?'         => \$help
) or pod2usage( 2 );

pod2usage( 1 ) if $help;
pod2usage(-exitstatus => 0, -verbose => 2) if $man;

my $VERSION = '$Revision: 2202 $';

if ( $version ) {
  $VERSION =~ s/\$//g;
  print "$SCRIPT $VERSION\n";
  exit(0);
}

if (!$from_address) {
  print STDERR "from address is a required parameter!!!\n";
  pod2usage( 1 );
}

if (!$subject) {
  print STDERR "subject is a required parameter!!!\n";
  pod2usage( 1 );
}

if (!$to_address) {
  print STDERR "to address is a required parameter!!!\n";
  pod2usage( 1 );
}

if(! -t STDIN) {
  my $line;

  while ($line = <STDIN>) {
    $message_body .= $line;
  }
}

if (!$message_body) {
  print STDERR "a message body is a required!!!\n";
  pod2usage( 1 );
}



# Set this variable to your smtp server name
my $ServerName = "localhost";

my $mime_type    = 'text';

# Create the initial text of the message
my $mime_msg = MIME::Lite->new(
   From => $from_address,
   To   => $to_address,
   Subject => $subject,
   Type => $mime_type,
   Data => $message_body
   )
  or die "Error creating MIME body: $!\n";


# Attach the text file
#my $filename = 'C:\tmp\test.txt';

if ($attachfn && -r $attachfn) {

  my $recommended_filename = basename($attachfn);
  $mime_msg->attach(
     Type => 'application/text',
     Path => $attachfn,
     Filename => $recommended_filename
     )
    or die "Error attaching text file: $!\n";
}


# encode body of message as a string so that we can pass it to Net::SMTP.
$message_body = $mime_msg->body_as_string();

# Let MIME::Lite handle the Net::SMTP details
MIME::Lite->send('smtp', $ServerName);
$mime_msg->send() or die "Error sending message: $!\n";

exit($error_count);

__END__

=head1 NAME

send-mail.pl - perl script to send an email

=head1 SYNOPSIS

send-mail.pl [-a file] [-d] [-h] [-v] [-V] -f from -t to -m message -s subj

  perl script to send an email

=head1 OPTIONS

=over 8

=item B<-a|--attach filename>

  Specify the file named for optional attachment.

=item B<-d|--debug>

  Sets debug flag to show more output.

=item B<-f|--from from>

  Specify the from address.

=item B<-h|--help>

  Print a brief help message and exits.

=item B<-m|--message message>

  Specify the messsage body.

=item B<-s|--subj|--subject subject>

  Specify the subject.

=item B<-t|--to to>

  Specify the to address.

=item B<-v|--verbose>

  Sets verbose flag to show more output.

=item B<-V|--version>

  Prints version and exits


=back
