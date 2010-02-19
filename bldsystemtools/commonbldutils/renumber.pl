# Copyright (c) 2003-2009 Nokia Corporation and/or its subsidiary(-ies).
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
# Script to renumber the XML command file
# 
#

use strict;
use Getopt::Long;
use File::Copy;

# Process the commandline
my ($iDataSource) = ProcessCommandLine();

&Renumber($iDataSource);


# ProcessCommandLine
#
# Inputs
#
# Outputs
# $iDataSource (XML file to process)
#
# Description
# This function processes the commandline

sub ProcessCommandLine {
  my ($iHelp, $iPort, $iDataSource, $iLogFile);
  GetOptions('h' => \$iHelp, 'd=s' =>\$iDataSource );

  if (($iHelp) || (!defined $iDataSource))
  {
    Usage();
  } elsif (! -e $iDataSource) {
    die "Cannot open $iDataSource";
  } else {
    return($iDataSource);
  }
}

# Usage
#
# Description
# Output Usage Information.
#

sub Usage {
  print <<USAGE_EOF;

	Usage: Renumber.pl [options]

	options:

	-h  help
	-d  Data Source (xml file)
USAGE_EOF
	exit 1;
}

# Renumber
#
# Inputs
# $iDataSource (XML file to process)
#
# Outputs
# A renumber XML File
#
# Description
# Renumber the XML file.
sub Renumber
{
  my ($iDataSource) = @_;
  
  my ($iLine, $iNum, $iOrder);
  $iNum = 1;
  $iOrder = 1;
  move($iDataSource,$iDataSource.".bak");  
  
  open XML, "<$iDataSource.bak" or die "Can't read $iDataSource.bak";
  open XMLOUT, ">$iDataSource" or die "Can't read $iDataSource";

	while ($iLine=<XML>)
	{
	  if ($iLine =~ /ID=\"\d+\"/)
	  {
	    $iLine =~ s/ID="\d+"\s+Stage="\d+"/ID="$iNum" Stage="$iNum"/;
	    $iNum++;
	  }
	  elsif ($iLine =~ /Order="\d+"/)
	  {
		 $iLine =~  s/Order="\d+"/Order="$iOrder"/;
		 $iOrder++;
	  }
	  print XMLOUT $iLine; 

	}

  close XML;
}
