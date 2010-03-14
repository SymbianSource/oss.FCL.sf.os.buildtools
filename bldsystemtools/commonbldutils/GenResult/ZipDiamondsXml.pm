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
# Script that will zip the XMLs generated
#
package ZipDiamondsXml;
use Archive::Zip qw( :ERROR_CODES :CONSTANTS );
use strict;

my $ZipFile = "DiamondsXmls.zip";
my $tempZipFile = "DiamondsXmls.zip.new";
&main("");
sub main
{
  my $FileToAdd = shift;
  $FileToAdd =~ /([^\\\/]*?)$/;
  my $FileName = $1;
  my $zip = Archive::Zip->new();
  if (-e $ZipFile)
  {
    die 'Zip read error' if $zip->read($ZipFile) != AZ_OK;
  }
  my $member = $zip->addFile($FileToAdd,$FileName);
  die 'Zip write error' if $zip->writeToFileNamed($tempZipFile) != AZ_OK;
  unlink($ZipFile);
  rename($tempZipFile,$ZipFile);
}
