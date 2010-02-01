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
# Utility functions that are used by templates.
# 
#
package myutils;

my $iDir = $ENV{PublishLocation}."\\".$ENV{Type}."\\" .$ENV{BuildNumber}."\\logs\\";
my $iSnapshot = $ENV{SnapshotNumber};
my $iProduct = $ENV{Product};
my $iLinkPath = $ENV{PublishLocation}."\\".$ENV{Type}."\\logs\\".$ENV{BuildNumber}."\\";

sub getiDir
{
    return $iDir;
}

sub getiSnapshot
{
    return $iSnapshot;
}

sub getiProduct
{
    return $iProduct;
}

sub getiLinkPath
{
    return $iLinkPath;
}

sub getTime
{
    my ($sec,$min,$hours,$mday,$mon,$year)= localtime();
    $year += 1900;
    $mon +=1;
    my @date = ($year,$mon,$mday,$hours,$min,$sec);
    my $date = sprintf("%d-%02d-%02dT%02d:%02d:%02d", @date);
    return ($date);
}

sub getDelim
{
  $Delimiter = [ '[@--', '--@]' ];
  return (\$Delimiter);
}
1;
