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
# Script to set a P$ Client
# 
#

use strict;
use FindBin;		# for FindBin::Bin
use Getopt::Long;

use lib $FindBin::Bin;

use SetP4Client;

# Process the commandline
my ($iCodeline, $iDrive, $iType) = ProcessCommandLine();

# Sync the source
&SetP4Client::Start( $iCodeline, $iDrive, $iType);

# ProcessCommandLine
#
# Inputs
#
# Outputs
#
# Description
# This function processes the commandline

sub ProcessCommandLine {
  my ($iHelp, $iCodeline, $iDrive, $iType);
  GetOptions('h' => \$iHelp, 'l=s' => \$iCodeline, 'd=s' => \$iDrive, 't=s' => \$iType);

  if (($iHelp) || (!defined $iCodeline) || (!defined $iDrive) || (!defined $iType))
  {
    Usage();
  } 
  else 
  {
    return($iCodeline, $iDrive, $iType);
  }
}

# Usage
#
# Output Usage Information.
#

sub Usage {
  print <<USAGE_EOF;

	Usage: SetP4Client.pl [options]

	options:

	-h  help
	-l	Code line to create the client
	-d	Perforce Root
	-t	Type of Build

	Code line must be entered without white spaces or new line 
	characters where view is separated by +
	The word CLIENTNAME is automatically replaced with the correct clientname
    e.g. //EPOC/Release/Generic/7.0/...+//CLIENTNAME/...

USAGE_EOF
	exit 1;
}
