#!/usr/bin/perl

=head1 NAME

Record delivery

=head1 SYNOPSIS

record_delivery.pl

=head1 DESCRIPTION

This script is designed to send an email for the purpose of recording deliveries.

=head1 COPYRIGHT

Copyright (c) 2005-2006 Symbian Ltd. All rights reserved

=cut

use strict;

use Getopt::Long;

use FindBin;  # for FindBin::Bin
use lib $FindBin::Bin; # For Local modules

use record_delivery;

my %gEntries;

my ($iConfig, $iTemplates, $iEntries) = ProcessCommandLine();

#Convert the entries to a hash
foreach my $iEntry (@$iEntries)
{
  my ($key, $value) = $iEntry =~ /(.*?)=(.*)/;
  $gEntries{$key} = $value;
}
my $delivery = record_delivery->new(config_file => $iConfig);
foreach my $iTemplate (@$iTemplates)
{
  eval {
  $delivery->send(Template => $iTemplate, %gEntries);
  };
  if ($@)
  {
    print "ERROR: Failed to record delivery using Template $iTemplate - $@\n";
  } else {
    print "Delivery Email Sent using Template $iTemplate\n";
  }
}



# ProcessCommandLine
#
# Inputs
#
# Outputs
# $ilog - logfile location
#
# Description
# This function processes the commandline

sub ProcessCommandLine {
  my ($iHelp, @iTemplates, $iConfig, @iEntries);

  GetOptions('h' => \$iHelp, 't=s' => \@iTemplates, 'c=s' => \$iConfig, 'e=s' => \@iEntries);

  if (($iHelp) || (scalar(@iTemplates) == 0) || (!defined $iConfig) || (scalar(@iEntries) == 0))
  {
    &Usage();
  } else {
    return($iConfig, \@iTemplates, \@iEntries);
  }
}

# Usage
#
# Output Usage Information.
#

sub Usage {
  print <<USAGE_EOF;

  Usage: record_delivery.pl [options]

  options:

  -h              help
  -t  [filename]  HTML::Template file to use [Multiple Allowed]
  -c  [filename]  configuration file to use
  -e  [Key=Value] Template Key and associated Value [Multiple Allowed]

  The parameters to the -e option must be provided in the form Key=Value
  e.g BuildNumber=20
  This will replace the "<TMPL_VAR NAME=BuildNumber>" text in the
  HTML::template file with the text "20".
  Keys listed on the commandline that do not exist in the template
  will generate an ERROR.
  Keys listed in the template but not provided on the command line will not
  generate an error.
  
  Example Commandline
  record_delivery.pl -t SymbianKK.tmpl -c testemail.cfg -e BuildNumber=03803_Symbian_OS_v9.2 -e PublishLocation=\\\\builds01\\devbuilds

USAGE_EOF
	exit 1;
}
