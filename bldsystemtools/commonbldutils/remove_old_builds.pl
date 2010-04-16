#
# Copyright (c) 2009 Nokia Corporation and/or its subsidiary(-ies).
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
#!perl -w
#
# remove_old_builds.pl
#
# usage:
# perl remove_old_builds.pl current_build_number build-directory required-free-space
#
use strict;

sub usage
    {
  print <<USAGE_EOF;

Usage: perl remove_old_builds.pl current_build build-directory required-bytes

where: current_build   = the number of the current build (e.g 00924_Symbian_OS_v9.1)
       build-directory = the top level directory containing the various builds
       required-bytes  = the free disk space required.

USAGE_EOF
    exit 1;
    }

sub freespace
    {
    my $dir = shift;
    open FDIR, "dir /-c $dir |" or die "Cannot open FDIR $dir";    # /-c = suppress thousand separators (commas)
    my $s= -1;      # Signifying "ERROR"
    while (<FDIR>)
        {
        if (/\s+(\d+) bytes free/) { $s=$1;}
        }
    return $s;
    }

my $current_build=$ARGV[0];
my $bld_dir=$ARGV[1];
my $space=$ARGV[2];

unless ($space) { usage() };    # Must have all three args. So check for last one only.

open DIRS, "dir /b /ad /od $bld_dir |" or die "Cannot open DIRS $bld_dir";     # /b = "bare output"  /ad = directories only   /od = sort by date
while (my $name = <DIRS>)
    {
       if (freespace($bld_dir) >= $space)
       { last; }
       chomp $name;
       chomp $current_build;
           
       if(($name =~ /^((D|T|M|MSF|TB|E|(\d{2,3}_))?(\d+))(([a-z]\.\d+)|([a-z])|(\.\d+))?/) && ($name ne $current_build))
       {
                print "Removing $bld_dir\\$name\n";
                if (system("rmdir /s /q $bld_dir\\$name"))
                {
                    print "ERROR: Failed to remove: $bld_dir\\$name\n";
                }
       }
    }
close DIRS;

if (freespace($bld_dir) < $space)
    {
    print "ERROR: Cannot create $space free bytes in $bld_dir\n";
    exit 1;
    }

exit 0;




