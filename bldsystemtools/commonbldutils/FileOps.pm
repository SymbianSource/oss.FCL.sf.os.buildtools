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
#

package FileOps;
use strict;
use Carp;
use File::Copy;
use File::Path;
use Cwd;

sub ProcessDir
{
  my ($iSourceDir, $iTargetDir, $iAction, @iExcludes) = @_;
  my ($iFile);
   
  opendir(DIR, $iSourceDir) or croak "can't opendir $iSourceDir: $!";
  DIR: while (defined($iFile = readdir(DIR)))
  {
    next DIR if $iFile =~ /^\.\.?$/;     # skip . and ..
    foreach my $iExclude (@iExcludes)
    {
      if ($iExclude =~ /^$iFile$/)
      {
        print "Excluding $iExclude\n";
        next DIR;
      }
    }
    if ( lc($iAction) eq 'copy')
    {
      print "Copying $iSourceDir\\$iFile to $iTargetDir\\$iFile\n";
      if (-d "$iSourceDir\\$iFile")
      {
        system ("xcopy $iSourceDir\\$iFile", "$iTargetDir\\$iFile", "/E", "/Z", "/I");
      } else {
        system ("xcopy $iSourceDir\\$iFile", "$iTargetDir", "/Z");
      }
    } elsif ( lc($iAction) eq 'move') {
      print "Moving $iSourceDir\\$iFile to $iTargetDir\\$iFile\n";
      &move("$iSourceDir\\$iFile", "$iTargetDir\\$iFile");      
    } elsif ( lc($iAction) eq 'delete') {
      print "Deleting $iSourceDir\\$iFile\n";
      if (-d "$iSourceDir\\$iFile")
      {
        rmtree("$iSourceDir\\$iFile");
      } else {
        unlink("$iSourceDir\\$iFile");
      }
    } elsif ( lc($iAction) eq 'zip') {
      if (-d "$iSourceDir\\$iFile")
      {
        print "Ziping $iSourceDir\\$iFile\n";
        chdir("$iSourceDir");
        system("zip -r $iTargetDir\\$iFile.zip $iFile");
      }
    }
  }
  closedir(DIR);  
}

1;
