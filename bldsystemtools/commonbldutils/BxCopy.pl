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
# Script to get Source from Perforce
# 
#

use strict;
use Getopt::Long;

use FindBin;
use lib "$FindBin::Bin";
use BxCopy;


# Process the commandline
my ($iSource, $iTarget, $iExclude, $iInclude, $iVerbose, $iNoAction) = ProcessCommandLine();

# Get list of files
my $iCopyFiles = &BxCopy::FilterDir($iSource,$iExclude,$iInclude);

# Copy Function
&BxCopy::CopyFiles($iSource, $iTarget, $iCopyFiles, $iVerbose, $iNoAction);


# ProcessCommandLine
#
# Inputs
#
# Outputs
#
# Description
# This function processes the commandline

sub ProcessCommandLine {
  my ($iHelp, $iSource, $iTarget, @iExclude, @iInclude, $iVerbose, $iNoAction);
  GetOptions('h' => \$iHelp, 's=s' => \$iSource, 't=s' => \$iTarget, 'x=s' => \@iExclude, 'i=s' => \@iInclude, 'v' => \$iVerbose, 'n' => \$iNoAction);

  if (($iHelp) || (!defined $iSource) || (!defined $iTarget))
  {
    Usage();
  } elsif (! -d $iSource) {
    print "$iSource is not a directory\n";
    Usage();
  } elsif ( -d $iTarget) {
    print "$iTarget already exist\n";
    Usage();
  } else {
    # Remove any trailing \ or from dirs
    $iSource =~ s#[\\\/]$##;
    $iTarget =~ s#[\\\/]$##;
    # Make sure all the \ are /
    $iSource =~ s/\\/\//g;
    $iTarget =~ s/\\/\//g;
    return($iSource, $iTarget, \@iExclude, \@iInclude, $iVerbose, $iNoAction);
  }
}

# Usage
#
# Output Usage Information.
#

sub Usage {
  print <<USAGE_EOF;

  Usage: BxCopy.pl [options]

  options:

  -h         -- help
  -s  source -- source directory
  -t  target -- target directory
  -x  regexp -- exclude a reqular expression from the list of files
  -i  regexp -- include a regular expression in to the list of files
  -v         -- Verbose mode
  -n         -- No Copy

  Note:  The inclusion takes precedence over the exclusion.
  Note:  This will not overwrite files as target cannot exist.
USAGE_EOF
  exit 1;
}
