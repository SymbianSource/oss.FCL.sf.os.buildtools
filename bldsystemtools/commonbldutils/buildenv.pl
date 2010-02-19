# Copyright (c) 2004-2009 Nokia Corporation and/or its subsidiary(-ies).
# All rights reserved.
# This component and the accompanying materials are made available
# under the terms of the License "Eclipse Public License v1.0"
# which accompanies this distribution, and is available
# at the URL "http://www.eclipse.org/legal/epl-v10.html".
#
# Initial Contributors:
# Nokia Corporation - initial contribution.
#
# Contributors:
#
# Description:
# Script to get version of various tools and Windows hotfixes and write to XML file
# 
#

use strict;
use Getopt::Long;
use File::Copy;
use Sys::Hostname;
use FindBin;
use lib $FindBin::Bin;
use Carp;
use buildenv;

# Process the commandline
my ($gHostName, $gXMLfilePathname) = ProcessCommandLine();

&buildenv::Main($gHostName, $gXMLfilePathname);

# ProcessCommandLine
#
# Inputs
# Command line options via GetOptions()
#
# Returns
# Hostname, XML output file name
#
# Description
# This function processes the commandline and also establishes hostname and hence XML file name

sub ProcessCommandLine {
  my ($iHelp, $iXMLfileLocation);
  GetOptions('h' => \$iHelp, 'o=s' => \$iXMLfileLocation);

  if ($iHelp) { Usage(); }
  
  if (!defined $iXMLfileLocation)
  {
    $iXMLfileLocation = '.\\';
  }

  # add trailing backslash if missing, and add filename as hostname.xml
  $iXMLfileLocation =~ s/[^\\]$/$&\\/;

# Validate output directory. NB: If option not given, undef defaults to current directory!
  confess("ERROR: $iXMLfileLocation not a directory: $!") if !-d $iXMLfileLocation;
  my $iHostName = hostname;     # Depends on "use Sys::Hostname;"
  $iHostName =~ s/\.intra$//i;  # Remove trailing ".intra" if any.
  $iXMLfileLocation = $iXMLfileLocation . $iHostName ."\.xml";

  &backupFile($iXMLfileLocation) if (-e $iXMLfileLocation);
  return($iHostName, $iXMLfileLocation);    # NB: $iXMLfileLocation is now the full pathname of the output file
}

# backupFile
#
# Inputs
# $iFile - filename to backup
#
# Outputs
#
# Description
# This function renames an existing file with the .bak extension
sub backupFile
{
	my ($iFile) = @_;
	my ($iBak) = $iFile.".bak";
	
	if (-e $iFile)
	{
	    print "WARNING: $iFile already exists, creating backup of orignal with new name of $iBak\n";
	    move($iFile,$iBak) or die "Could not backup $iFile to $iBak because of: $!\n";	  
	}
}

# Usage
#
# Output Usage Information and exit
#

sub Usage {
  print <<USAGE_EOF;

  Usage: BuildEnv.pl [options]

  options:

  -h  Display this Help and exit
  -o  Directory in which to write output XML file (defaults to current)
      e.g \\\\Builds01\\Devbuilds\\BuildPCs\\BldEnvData\\2006-04-24
      Name will be added automatically as the host computername,
      extension as '.XML'
USAGE_EOF
	exit 1;
}
