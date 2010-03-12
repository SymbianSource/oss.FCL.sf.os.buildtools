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
# Script to do file operations within a directory with the option to exclude sub directories or files
# 
#

use strict;
use FindBin;		# for FindBin::Bin
use Getopt::Long;

use lib $FindBin::Bin;

use FileOps;

# Process the commandline
my ($iSourceDir, $iTargetDir, $iAction, @iExcludes) = &ProcessCommandLine();

&FileOps::ProcessDir($iSourceDir, $iTargetDir, $iAction, @iExcludes);

# ProcessCommandLine
#
# Inputs
#
# Outputs
#
# Description
# This function processes the commandline

sub ProcessCommandLine {
  my ($iHelp, $iSourceDir, $iTargetDir, $iAction, @iExclude, @iExcludes);
  GetOptions('h' => \$iHelp, 's=s' =>\$iSourceDir,  't:s' =>\$iTargetDir, 'a=s' => \$iAction, 'x:s@' => \@iExclude);

  if (($iHelp) || (!defined $iSourceDir) || (!defined $iAction))
  {
    Usage();
  } elsif (! -d $iSourceDir) {
    die "$iSourceDir is not a Directory";
  } elsif ((lc($iAction) ne 'copy') && (lc($iAction) ne 'move') && (lc($iAction) ne 'delete') && (lc($iAction) ne 'zip')) {
    die "$iAction is not a supported Action";
  } elsif ((lc($iAction) eq 'copy') || (lc($iAction) eq 'move') && (lc($iAction) ne 'delete')) {
    if (!defined $iTargetDir)
    {
      die "$iAction Requires a Target Directory";
    }
    if (! -d $iTargetDir)
    {
      die "$iTargetDir is not a Directory";
    }
  } 
  
  # Check all the exclude sub directories or files
  foreach my $iSubItem (@iExclude)
  {
    if ((! -d "$iSourceDir\\$iSubItem") && (! -f "$iSourceDir\\$iSubItem"))
    {
      print "$iSubItem is not a Directory or File in $iSourceDir - not Excluding\n";
    } else {
      push  @iExcludes,$iSubItem;
    }
  }
  
  return($iSourceDir, $iTargetDir, $iAction, @iExcludes);
}

# Usage
#
# Output Usage Information.
#

sub Usage {
  print <<USAGE_EOF;

	Usage: FileOps.pl [options]

	options:

	-h  help
	-a  Action (Move or Copy or Delete or Zip the directories)
	-s  Source Directory
	-t  Target Directory (Not required for Delete Action)
	-x  Exclude a File or Directory from the Action
USAGE_EOF
	exit 1;
}
