# Copyright (c) 2005-2009 Nokia Corporation and/or its subsidiary(-ies).
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
# Script to get version of various tools
# 
#

use strict;
use FindBin;
use lib "$FindBin::Bin";
use GenResult;
use Getopt::Long;

# Process the commandline
my ($iDir, $iSnapshot, $iProduct, $iLinkPath, $iStage, $iBrag, $imail) = ProcessCommandLine();

&GenResult::main($iDir, $iSnapshot, $iProduct, $iLinkPath, $iStage, $iBrag, $imail);

# ProcessCommandLine
# Description
# This function processes the commandline

sub ProcessCommandLine {
  my ($iHelp);
  
  GetOptions('h' => \$iHelp, 'd=s' => \$iDir, 's=s' => \$iSnapshot, 'p=s' => \$iProduct, 'l=s' => \$iLinkPath, 't=s' => \$iStage, 'b=s' => \$iBrag, 'm' => \$imail);

  if (($iHelp) || (!defined $iDir) || (!defined $iSnapshot) || (!defined $iProduct) || (!defined $iStage)) {
    Usage();
  }
  return ($iDir, $iSnapshot, $iProduct, $iLinkPath, $iStage, $iBrag, $imail);
}

# Usage
#
# Output Usage Information.

sub Usage {
  print <<USAGE_EOF;

  Usage: GenResult.pl [switches]

  [Switches]
  -d directory (e.g. \\builds01\\devbuilds\\master\\03445_Symbian_OS_v9.1\\logs)
  -s snapshot number (e.g. 03445)
  -p product (e.g. 9.1)
  -t Stage (e.g. GT|TV|ROM|CBR|CDB|BUILD|ALL)
    
  [Optional]
  -h help
  -l link path (\\builds01\\devbuilds\\master\\logs\\03445_Symbian_OS_v9.1)
  -b Brag status (FINAL|TBA[default])
  -m Sends CDB break notification mail to cdb support
    
 It is possible to generate the logs based upon a local copy, but also link them to
 a different (remote) location. This will be useful when copying the report into another
 application such as Lotus Notes.

USAGE_EOF
	exit 1;
}
