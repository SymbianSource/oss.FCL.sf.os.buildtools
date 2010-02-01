#!/usr/bin/perl

=head1 NAME

Getlatestrel.pl

=head1 SYNOPSIS

Getlatestrel.pl

=head1 DESCRIPTION

This script is designed to use latestver from the CBR tools to find at get the
latest version of a component.

If a baseline version is provided, then it will install the version of the component
released as part of that specified baseline.

=head1 COPYRIGHT

Copyright (c) 2008 Symbian Ltd. All rights reserved

=cut

use strict;

use Getopt::Long;

my ($iComp, $iSource, $iVersion, $iBaselineComponent, $iBaselineVersion) = ProcessCommandLine();

if ($iSource)
{
  $iSource = "-s";
} else {
  $iSource = "";
}
if (!defined $iVersion)
{
  if (defined $iBaselineVersion) {

    if (!defined $iBaselineComponent) {
      $iBaselineComponent = "gt_techview_baseline";
    }
    my $envout= `envsize -v $iBaselineComponent $iBaselineVersion 2>&1`;

    # match component    
    if ($envout =~ m/(Adding up size of )$iComp (.*)/) {
      print "INFO: Component $iComp version $2 found for baseline $iBaselineComponent $iBaselineVersion\n";
      $iVersion = $2;
    }elsif ($envout =~ m/(didn't exist)/) {
      print "WARNING: Baseline $iBaselineVersion didn't exist, unable to check $iBaselineComponent, geting latest version\n";
      $iVersion = `latestver $iComp`;  
    }
  } else {
    $iVersion = `latestver $iComp`;  
  }
}

chomp($iVersion);

my $getreloutput = `getrel -vv $iSource -o $iComp $iVersion`;

if (($getreloutput =~ /^Installing $iComp $iVersion/) || 
    ($getreloutput =~ /^Switching $iComp/)            ||
    ($getreloutput =~ /already installed and clean/)) {
  
  print $getreloutput;
} else {
  print "ERROR: could not getrel $iComp $iVersion - $getreloutput\n";
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
  my ($iHelp, $iComp, $iSource, $iVersion, $iBaselineComponent, $iBaselineVersion);

  GetOptions('h' => \$iHelp, 'c=s' => \$iComp, 's' => \$iSource, 'v=s' => \$iVersion, 'bc=s' => \$iBaselineComponent, 'bv=s' => \$iBaselineVersion);

  if (($iHelp) || (!defined $iComp))
  {
    &Usage();
  } else {
    return($iComp, $iSource, $iVersion, $iBaselineComponent, $iBaselineVersion);
  }
}

# Usage
#
# Output Usage Information.
#

sub Usage {
  print <<USAGE_EOF;

  Usage: getlatestrel.pl [Args/options]

  Args: (required)
  
  -c  [Component name]  Name of component to get 

  options:

  -h                    help
  -s                    install (and overwrite) source code
  -v  [version string]  Optional version to get instead of latest available.

  -bc [component str ]  Optional baseline component [default is gt_techview_baseline]
  -bv [version   str ]  Optional baseline version
  
  Example Commandline
  getlatestrel.pl -c tools_testexecute

USAGE_EOF
	exit 1;
} 
