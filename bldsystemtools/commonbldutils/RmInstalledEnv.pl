#!/usr/bin/perl

=head1 NAME

RmInstalledEnv.pl

=head1 SYNOPSIS

RmInstalledEnv.pl

=head1 DESCRIPTION

This script is designed to use RemoveRel command from the CBR tools to remove the installed environment.

=head1 COPYRIGHT

Copyright (c) 2009 Nokia Corporation and/or its subsidiary(-ies).
All rights reserved.

=cut

use strict;
use Getopt::Long;


my ($iIncludeFile) = ProcessCommandLine();

open(INPUT, "<$iIncludeFile");
my (@includecomponentlist) = <INPUT>;
close(INPUT);
foreach my $includecomponent ( @includecomponentlist ){
  chomp($includecomponent);
  my ($component, $version ) = split(/=>/, $includecomponent);
  $component =~  s/^\s+//;
  $component =~  s/\s+$//;
  print "removerel $component \n";
  my $getrelresult = `removerel $component `;
  print $getrelresult ;
}

# ProcessCommandLine
#
# Description
# This function processes the commandline
sub ProcessCommandLine {
  my ($iHelp, $iIncludeFile);

  GetOptions('h' => \$iHelp,  'x=s' => \$iIncludeFile);

  if ($iHelp)
  {
    &Usage();
  } else {
    return($iIncludeFile);
  }
}

# Usage
#
# Output Usage Information.
#

sub Usage {
  print <<USAGE_EOF;

  Usage: RmInstalledEnv.pl [Args/options]

  Args: (required)
  -x  <file> with list of components to remove  
  
  options:
  
  -h                    help
  
  
  Example Commandline
  RmInstalledEnv.pl -x includes_phase3.txt 

USAGE_EOF
	exit 1;
}