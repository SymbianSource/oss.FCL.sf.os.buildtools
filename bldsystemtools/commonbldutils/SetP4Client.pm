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
#

package SetP4Client;

use strict;
use Carp;
use Sys::Hostname;

# Start
#
# Inputs
# $iClientName (Name of the client to create)
# $iCodeline (Codeline root)
# $iUser
# $iDrive
# $iHost
# $iType
#
# Outputs
#
# Description
#

sub Start
{
	my ( $iCodeline, $iDrive, $iType) = @_;
	my ($iUser, $iHost, $iClientname);

	$iUser = &get_user();
	($iHost) = &hostname() =~ /(\S+?)\./;
  if ($iHost eq "")
  {
    # Not a fully qualified Hostname, use use raw name
    $iHost =  &hostname();
  }
  print "Hostname is $iHost\n";
  $iClientname = $iHost."_source_".$iType;

	#processing codeline
	$iCodeline =~ s?//CLIENTNAME/?//$iClientname/?g;
	my (@iSplit_codeline) = split /\+/, $iCodeline;
	for (my ($n)=1; $n <= $#iSplit_codeline; $n=$n+2)
	{
		$iSplit_codeline[$n] .= "\n";
	} 

	#Flushes and deletes old client, then creates new client and sets it as a default
	&set_view($iClientname);
	#Sets up client specification
	&set_client($iHost, $iClientname, $iUser, $iDrive, @iSplit_codeline);


}

# Start
#
# Inputs
#
# Outputs
# $iUser
#
# Description
# This Gets the user name
sub get_user
{
  my ($iLine, $iUser);  
  
	open USER, "p4 user -o |" or die "Can't read user";
	while ($iLine=<USER>)
	{
		if ($iLine =~ /^User:\s+(\S+)/)
		{
		  $iUser = $1; 
		}
	}
	close USER;
	return ($iUser);
}

sub set_client
{
  my ($iHost, $iClientname, $iUser, $iDrive, @iSplit_codeline) = @_;  
  
	open CLIENT, "| p4 client -i" or die "Can't create Perforce client";
	
	print CLIENT<<CLIENTSPEC_EOF;
# A Perforce Client Specification.
#
#  Client:      The client name.
#  Update:      The date this specification was last modified.
#  Access:      The date this client was last used in any way.
#  Owner:       The user who created this client.
#  Host:        If set, restricts access to the named host.
#  Description: A short description of the client (optional).
#  Root:        The base directory of the client workspace.
#  Options:     Client options:
#                      [no]allwrite [no]clobber [no]compress
#                      [un]locked [no]modtime [no]rmdir
#  LineEnd:     Text file line endings on client: local/unix/mac/win/share.
#  View:        Lines to map depot files into the client workspace.
#
# Use 'p4 help client' to see more about client views and options.

Client:  $iClientname

Owner:	$iUser 

Host:	$iHost

Description:
  DO NOT USE THIS CLIENT UNLESS YOU ARE PART OF THE "BUILD" TEAM. 
  This client is generated automatically when GetSource.pl is 
  called as a part of the build process. If client spec
  is changed manually it will not take any effect as the
  client will be deleted and then regenerated during
  build. 
  
Root:	$iDrive

Options:	noallwrite noclobber nocompress crlf unlocked nomodtime normdir

View:
  @iSplit_codeline

CLIENTSPEC_EOF

	close CLIENT;  # Terminate input, and wait for command to finish..
}


sub set_view()
{
	my ($iClientname) = @_;	
	print `p4 client -d $iClientname 2>&1`;	
	print `p4 set p4client=$iClientname 2>&1`;
}
1;
