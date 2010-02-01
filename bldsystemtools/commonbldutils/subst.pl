# Copyright (c) 2004-2009 Nokia Corporation and/or its subsidiary(-ies).
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
# Script to subst and un-subst drives
# 
#

use strict;
use Getopt::Long;

my ($drive, $path, $delete, $force) = &ProcessCommandLine;

die "ERROR: Bad virtual drive \"$drive\"" if $drive !~ /^\w:$/;

if ($delete)
{
  system "subst /d $drive";
  die("ERROR: Could not un-subst \"$drive\"") if $?;
}
else
{
  die "ERROR: \"$path\" does not exist" if !-d $path;
  `subst /d $drive` if $force;
  system "subst $drive $path";
  die("ERROR: Could not subst \"$path\" to \"$drive\"") if $?;
}

# Subst has been successful
print "Resultant subst mappings:\n";
my $output = `subst`;
$output ? print $output : print "None";

# End of script

sub ProcessCommandLine {
  my ($iHelp, $iDrive, $iPath, $iDelete, $iForce);
  GetOptions('h'   => \$iHelp,
             'v=s' => \$iDrive,
             'p=s' => \$iPath,
             'd'   => \$iDelete,
             'f'   => \$iForce);

  if (($iHelp) || (!defined $iDrive) || ((!defined $iPath)&&(!defined $iDelete)))
  {
    Usage();
  } 
  else 
  {
    return($iDrive, $iPath, $iDelete, $iForce);
  }
}

# Usage
#
# Output Usage Information.
#

sub Usage {
  print <<USAGE_EOF;

Usage: subst.pl [options]

options:

  -d  delete the SUBSTed virtual drive
  -h  help
  -f  force an un-subst first in case drive is already SUBSTed
  -p  <physical path>
  -v  <virtual drive>

For example "subst.pl -v z: -p d:\\master\\03237" will subst the directory
"d:\\master\\03237" to the virtual drive "z:"
USAGE_EOF
  exit 1;
}