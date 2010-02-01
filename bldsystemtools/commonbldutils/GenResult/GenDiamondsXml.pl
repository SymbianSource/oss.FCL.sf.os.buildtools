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
# Script to Generate the XML file that is suitable for Diamonds
# 
#
use strict;
use FindBin;
use lib "$FindBin::Bin";
use lib "$FindBin::Bin/lib";
use Getopt::Long;
use GenDiamondsXml;

my ($iStage, $iState, $iServer) = ProcessCommandLine();

&GenDiamondsXml::main($iStage, $iState, $iServer);

# ProcessCommandLine
# Description
# This function processes the commandline

sub ProcessCommandLine {
  my ($iHelp);
  
  GetOptions('h' => \$iHelp, 't=s' => \$iStage, 'i=s' => \$iState, 's=s' => \$iServer);

  if (($iHelp) || (!defined $iStage) || (!defined $iState) || (!defined $iServer)) {
    Usage();
  }
  return ($iStage, $iState, $iServer);
}

# Usage
#
# Output Usage Information.

sub Usage {
  print <<USAGE_EOF;

  Usage: GenDiamondsXml.pl [switches]

  [Switches]
  -t Stage (e.g. STARTBUILD|GT|TV|ROM|CBR|CDB|BUILD|ENDBUILD|ALL)
  -i (START|END)
  -s server (e.g. diamonds.nmp.nokia.com:9003)
    
  [Optional]
  -h help
      
USAGE_EOF
	exit 1;
}


