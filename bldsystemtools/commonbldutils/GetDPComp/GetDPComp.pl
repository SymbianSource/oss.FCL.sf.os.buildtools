#!/usr/bin/perl

=head1 NAME

GetDPComp.pl

=head1 SYNOPSIS

GetDPComp.pl

=head1 DESCRIPTION

This script is designed to use latestver, envsize and getrel commands from the CBR tools to find and get the latest green version of one DP SF component(s).

=head1 COPYRIGHT

Copyright (c) 2009 Nokia Corporation and/or its subsidiary(-ies).
All rights reserved.

=cut

use strict;
use LWP::UserAgent;
use Getopt::Long;
use FindBin;
use lib "$FindBin::Bin";
use GetDPComp;

my ($iComponentNames, $iInputFile, $iBaselineComponentName, $iBaselineComponentVersion, $iSource, $iOutputFile) = ProcessCommandLine();
$iBaselineComponentName = GetDPComp::LRtrim($iBaselineComponentName);
$iBaselineComponentVersion = GetDPComp::LRtrim($iBaselineComponentVersion);

if (!defined $iBaselineComponentName) {
  $iBaselineComponentName = "sf_tools_baseline";
}

my $retval = 1 ;
($iBaselineComponentVersion, $retval) = GetDPComp::ValidateVersion( $iBaselineComponentVersion, $iBaselineComponentName);
if ($retval == 0 ) {
  print "\nERROR: Input version is wrong. \n";
  exit ;
}

my %ComponentVersion = GetDPComp::GenerateComponentVersion( $iBaselineComponentVersion, $iBaselineComponentName ) ;

if ( scalar(@$iComponentNames) == 0 ) {
  open(INPUT, "<$iInputFile") or die $! ;
  (@$iComponentNames) = <INPUT>;
  close(INPUT);
}

if ($iSource)
{
  $iSource = "-s";
} else {
  $iSource = "";
}

foreach my $includecomponent ( @$iComponentNames ){
  $includecomponent = GetDPComp::LRtrim( $includecomponent );
  print "getrel -v $iSource -o $includecomponent $ComponentVersion{$includecomponent} \n";
  `getrel -v $iSource -o $includecomponent $ComponentVersion{$includecomponent} `;
}

open(UPDATE, ">$iOutputFile") or die $! ;
foreach my $includecomponent ( @$iComponentNames ){
  $includecomponent = GetDPComp::LRtrim( $includecomponent );
  print UPDATE "$includecomponent => $ComponentVersion{$includecomponent} \n";
}
close(UPDATE);

# ProcessCommandLine
#
# Description
# This function processes the commandline
sub ProcessCommandLine {
  my (@iComponentNames, $iInputFile, $iBaselineComponentName, $iBaselineComponentVersion, $iSource, $iOutputFile, $iHelp);

  GetOptions('c=s@' => \@iComponentNames, 'cf=s' => \$iInputFile, 'bc=s' => \$iBaselineComponentName, 'bv=s' => \$iBaselineComponentVersion, 's' => \$iSource, 'o=s' => \$iOutputFile, 'h' => \$iHelp);
  Usage() if ($iHelp);

  Usage("-c and -cf can not use together") if ( (scalar(@iComponentNames) > 0 ) and (defined $iInputFile));
  Usage("Must specify component via -c or component list via -cf") if (( scalar(@iComponentNames) == 0 ) and ( ! defined $iInputFile) );
  Usage("Must specify baseline component version via -bv and output file name via -o") if ((! defined $iBaselineComponentVersion) or (! defined $iOutputFile) );

  return(\@iComponentNames, $iInputFile, $iBaselineComponentName, $iBaselineComponentVersion, $iSource, $iOutputFile);
}

# Usage
#
# Output Usage Information.
#

sub Usage {
  my ($reason) = @_;
  
  print "ERROR: $reason\n" if ($reason);
  
  print <<USAGE_EOF;

  Usage: GetDPComp.pl [Args]

  Args: 
  -c <Specified component name>, [Multiple -c options allowed], this option should not use together with -cf option.
  -cf <Specified file name which contains list of component name>, this option should not use together with -c option.
  -bc <Specified basline component name>, e.g. developer_product_baseline, this argument is optional.
  -bv <Version string for baseline component specified by -bc or sf_tools_baseline>, valid input: latest, green, #specifiednumber. 
  -s                    install (and overwrite) source code, this is optional argument.
  -o  <Specified file name which records version information for component specified by -c or components specified by -cf>
  -h                    help
  
  
  Example Commandline
  GetDPComp.pl -s -c tools_sbs -bc developer_product_baseline -bv green -o component_version.txt
  GetDPComp.pl -s -c tools_sbs -bc developer_product_baseline -bv latest -o component_version.txt
  GetDPComp.pl -s -c tools_sbs -bc developer_product_baseline -bv DP00454_DeveloperProduct -o component_version.txt
  GetDPComp.pl -cf component_list.txt -bv green -o component_version.txt
  GetDPComp.pl -cf component_list.txt -bv latest -o component_version.txt
  GetDPComp.pl -cf component_list.txt -bv DP00454_DeveloperProduct -o component_version.txt
  GetDPComp.pl -c dev_build_sbsv2_raptor -c dev_build_sbsv2_cpp-raptor -c dev_hostenv_dist_cygwin-1.5.25 -c dev_hostenv_dist_mingw-5.1.4 -c dev_hostenv_pythontoolsplat_python-2.5.2 -bv green -o component_version.txt
  GetDPComp.pl -h

USAGE_EOF
	exit 1;
}