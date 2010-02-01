# Copyright (c) 2003-2009 Nokia Corporation and/or its subsidiary(-ies).
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
# Script to create a timestamp for builds
# 
#

use strict;
use Getopt::Long;

# For Date calculations
use FindBin;		# for FindBin::Bin
use lib "$FindBin::Bin/../tools/build/lib"; # For running in source
use lib "$FindBin::Bin/../buildsystemtools/lib"; # For running in source (Foundation Structure)
use Date::Manip;

# Set TimeZone because Date:Manip needs it set and then tell it to IGNORE the TimeZone
&Date_Init("TZ=GMT","ConvTZ=IGNORE");

# Process the commandline
my ($iBuildNum, $iDaysNum, $iPath) = ProcessCommandLine();

# Gets today date then build the date stamp file by adding on the number of days given by the -d flag
# The file name is of the format year_month_day.expiry
my $date = &DateCalc("today","+ $iDaysNum days");
my $Logfilename = &UnixDate($date,$iPath."\\".$iBuildNum."\\"."%Y_%m_%d"."\."."expiry");


# Create the date stamp file
open(FILE,">> $Logfilename");
print FILE "Build to be deleted on this date\n";
close FILE;

if ($ENV{'BuildSubType'} eq "Test")
{
  # Gets today date then build the date stamp file for devkit deletion and setting it to 3 days
  # The file name is of the format year_month_day.devkitExpiry
  my $date = &DateCalc("today","+ 3 days");
  my $Logfilename = &UnixDate($date,$iPath."\\".$iBuildNum."\\Product\\"."%Y_%m_%d"."\."."expiry");

  mkdir ($iPath."\\".$iBuildNum."\\Product");

  # Create the date stamp file
  open(FILE,">> $Logfilename");
  print FILE "Build to be deleted on this date\n";
  close FILE;
}
# End of script

sub ProcessCommandLine {
  my ($iHelp, $iBuildNum, $iDaysNum, $iPath);
  GetOptions('h' => \$iHelp, 'b:s' =>\$iBuildNum, 'd:i' => \$iDaysNum, 'p:s' => \$iPath);

  if (($iHelp) || (!defined $iBuildNum) || (!defined $iPath) )
  {
    Usage();
  } 
  else 
  {
    if (!defined $iDaysNum)
    {
      $iDaysNum = 14;
    }
    return($iBuildNum, $iDaysNum, $iPath);
  };
}

# Usage
#
# Output Usage Information.
#

sub Usage {
  print <<USAGE_EOF;

	Usage: BuildStamp.pl [options]

	options:

	-h Help
	-b	%s Build number
	-d	%n Number of days from today
	-p	%s Path to publish directory

USAGE_EOF
	exit 1;
}
