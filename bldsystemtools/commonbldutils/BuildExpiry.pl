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
# Script to navigate through the builds and check for the expiry time
# 
#

use strict;
use FindBin;		# for FindBin::Bin
use Getopt::Long;
use File::Path;

# For Date calculations
use lib "$FindBin::Bin/../tools/build/lib"; # For running in source
use Date::Manip;

# Set TimeZone because Date:Manip needs it set and then tell it to IGNORE the TimeZone
&Date_Init("TZ=GMT","ConvTZ=IGNORE");

# Process the commandline
my ( $iPath, $iPreview, $iLogPath ) = ProcessCommandLine();

# Open the output logfile if needed
if ( $iLogPath && !$iPreview )
{
  # Redirect both STDOUT and STDERR to the logfile
  open (STDOUT, ">>$iLogPath") or die ("ERROR: Unable to open file \"$iLogPath\" for writing: $!");
  open (STDERR, ">&STDOUT") or die ("ERROR: Unable to redirect STDERR to STDOUT: $!");
  
  # Turn off buffering for each file handle to preserve ordering
  select((select(STDOUT), $|=1)[0]);
  select((select(STDERR), $|=1)[0]);
}

# Get today's date
my $timestamp = &UnixDate("today","%Y-%m-%d");

# Open the published path and get an array of build directories there
opendir (DIRS, $iPath);
my @dirs = readdir(DIRS);
closedir(DIRS);
chomp @dirs;

my @build_dirs;
foreach my $dir (@dirs)
{
   if (( -d "$iPath\\$dir" ) && ( $dir =~ /^\d{5}/ ))
   {
      # We have found a build directory
      push @build_dirs, "$iPath\\$dir";
   }
}

# Go through each build directory looking for expiry files
foreach my $dir (@build_dirs)
{
  &ProcessDir($dir);
}

sub ProcessDir
{
  my ($dir) = @_;

  opendir(DIR, $dir);
  my @expirys = readdir(DIR);
  closedir(DIR);
  chomp @expirys;

  foreach my $entry (@expirys)
  {
    next if (($entry eq ".") or ($entry eq ".."));
    &ProcessDir("$dir\\$entry") if (-d "$dir\\$entry");
    next if ((!-f "$dir\\$entry") or ($entry !~ /^(\d+)_(\d+)_(\d+).expiry$/i));
    
    # We have found an expiry file so extract the expiry date
    my ($year, $month, $day) = ($1, $2, $3);

    my $delta = &DateCalc("$year-$month-$day","today");
    if ( &Delta_Format($delta,'0',"%dt") > 0)
    {
      # This build directory has expired
      print "$timestamp: Removing directory \"$dir\" (Expired $year-$month-$day)\n";
      &RemoveDirectory($dir) if (!$iPreview);
      
      # Removal of this build directory is complete, so move onto the next one
      last;
    }
  }
}

sub RemoveDirectory()
{
  my $dir = shift;

  my $temp = rmtree($dir);
  print "$temp file(s) removed.\n";

  return if ( !-d $dir );

  # Directory removal has failed
  warn "WARNING: Directory \"$dir\" could not be removed.\n";
}


# End of script

sub ProcessCommandLine {
  my ($iHelp, $iPath, $iPreview,$iLogPath);
  GetOptions('h' => \$iHelp, 'p=s' => \$iPath, 'n' => \$iPreview,, 'l=s' => \$iLogPath);

  if ( ($iHelp) || (!defined $iPath) )
  {
    Usage();
  } 
  else 
  {
    return( $iPath, $iPreview, $iLogPath );
  };
}

# Usage
#
# Output Usage Information.
#

sub Usage {
  print <<USAGE_EOF;

  Usage: BuildExpiry.pl [options]

  options:

  -h  Help
  -p  %s Path to publish directory
  -n  Preview only
  -l  %s Path to log file

USAGE_EOF
  exit 1;
}

