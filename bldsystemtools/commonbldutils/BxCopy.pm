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
# This module implements the MD5 version of the Evalid's comapre
# 
#

package BxCopy;

use strict;
use File::Copy;
use File::Find;
use File::Path;

# FilterDir
#
# Inputs
# $iDir - Directory to process
# $iExclude - Reference to array of regular expression patterns to exclude
# $iInclude - Reference to array of regular expression patterns to include
#
# Outputs
# @iFinalFileList - Filtered list relative filenames
#
# Description
# This function produces a filtered list of filenames in the specified directory

sub FilterDir
{
  my ($iDir,$iExclude,$iInclude) = @_;

  my (@iFileList, @iFinalFileList);
  my ($iExcludeCount, $iIncludeCount);

  # Produce full filelist listing without directory names
  # Remove the specified directory path from the front of the filename
  find sub {
    if (!-d)
    {
      my $filepath = $File::Find::name;
      $filepath=~ s#^$iDir/##i;
      push @iFileList, $filepath;
    }
    }, $iDir;
  
  #Calculate the number of regex includes and excludes to optimise the filtering
  if (defined $iExclude){
    $iExcludeCount = scalar(@$iExclude);
  } else {
    $iExcludeCount = 0;
  }

  if (defined $iInclude){
    $iIncludeCount = scalar(@$iInclude);
  } else {
    $iIncludeCount = 0;
  }

  # return unmodified list of files if there are no regexs to fitler it by
  return \@iFileList if (($iExcludeCount == 0) && ($iIncludeCount == 0));

  foreach my $iFile ( @iFileList)
  {
    my $iExcludeFile = 0;

    # Process all Exclude RegEx to see if this file matches
    foreach my $iExcludeRegEx (@$iExclude)
    {
      if ($iFile =~ /$iExcludeRegEx/i)
      {
        # Mark this file to be excluded from the final list
        $iExcludeFile = 1;
      }
    }

    # Process all Include RegEx to see if this file matches
    foreach my $iIncludeRegEx (@$iInclude)
    {
      if ($iFile =~ /$iIncludeRegEx/i)
      {
        # Mark this file to be Included in the final list
        $iExcludeFile = 0;
      }
    }

    # Added the file to the final list based on the flag
    push @iFinalFileList, $iFile unless $iExcludeFile;
  }

  return \@iFinalFileList;

}

# CopyFiles
#
# Inputs
# $iSource - Directory to copy from
# $iTarget - Directory to copy to
# $iCopyFiles - Reference to an array of relative filenames to copy
#
# Outputs
#
# Description
# This function copies files from one dir to another

sub CopyFiles
{
  my ($iSource, $iTarget, $iCopyFiles, $iVerbose, $iNoAction) = @_;

  print "No Copy specified, would have performed:-\n" if (defined $iNoAction);

  #Loop through the list of files
  my ($j);
  for($j = 0; $j < scalar(@$iCopyFiles); $j++)
  {
    my ($iFile) = $$iCopyFiles[$j];
    #Check if the to final directory exists, if not create it
    my ($iDir) = $iFile =~ m#(.*)/.*#;

    if (defined $iVerbose)
    {
      print $iSource."/".$iFile." => ".$iTarget."/".$iFile."\n";
    }

    if (!defined $iNoAction)
    {
      if (!-d $iTarget."/".$iDir)
      {
        mkpath ($iTarget."/".$iDir) || die "ERROR: Cannot create ".$iTarget."/".$iDir;
      }
      copy($iSource."/".$iFile,$iTarget."/".$iFile) || die "ERROR: Failed to copy ".$iSource."/".$iFile." to ".$iTarget."/".$iFile." $!";
    }
  }

  print "$j files processed\n";
}

1;
