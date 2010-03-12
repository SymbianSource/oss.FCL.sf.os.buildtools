#!perl -w
# Copyright (c) 2005-2009 Nokia Corporation and/or its subsidiary(-ies).
# All rights reserved.
# This component and the accompanying materials are made available
# under the terms of "Eclipse Public License v1.0"
# which accompanies this distribution, and is available
# at the URL "http://www.eclipse.org/legal/epl-v10.html".
#
# Initial Contributors:
# Nokia Corporation - initial contribution.
#
# Contributors:
#
# Description:
# Script to perform Build Launch Checks
# 
#

use strict;
use Getopt::Long;
use FindBin;
use lib "$FindBin::Bin";
use BuildLaunchChecks;

my %BCData;

# Process the commandline
my ($iBuildLaunch) = ProcessCommandLine();

($BCData{'BCToolsBaseBuildNo'}) = BuildLaunchChecks::GetBCValue(\%ENV);

BuildLaunchChecks::UpdateXML($iBuildLaunch, \%BCData);


# ProcessCommandLine
#
# Inputs
#
# Outputs
# $iBuildLaunch (BuildLaunch xml file)
#
# Description
# This function processes the commandline
#

sub ProcessCommandLine {
  my ($iBuildLaunch, $iHelp);
 
  GetOptions('x=s'   => \$iBuildLaunch, 'h' => \$iHelp )|| die Usage();

  if ((!defined $iBuildLaunch) || ($iHelp))
  {
    Usage();
  } else {
    return $iBuildLaunch;
  }

}

# Usage
#
# Description
# Output Usage Information and exit whole script.
#

sub Usage {
  print <<USAGE_EOF;

  Usage: BCupdateXML.pl [options]

  options:

  -x  XML file to add BCToolsBaseBuildNo to
  -h  Usage
USAGE_EOF
  exit 1;
}
