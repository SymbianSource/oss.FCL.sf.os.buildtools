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
# Script that actually calls the send_xml_to_diamonds.pl for sending data to Diamonds server
# It also maintains the Diamonds BuildID
#
package publishDiamonds;
use strict;
use FindBin;
use lib "$FindBin::Bin";

my $buildIdFile = "DiamondsBuildID";
#~ my $server = 'diamonds.nmp.nokia.com:9003';
#~ my $localServer = '2ind04992.noe.nokia.com:8888';
sub publishToDiamonds
{
  my $file = shift;
  my $server = shift;
  chomp ($file);
  
  ##--remove blank lines
  open (FILE,"<$file") or warn "$file::$!\n";
  open (OUT, ">tmpfile.$$") or warn "tmpfile.$$::$!\n";
  while(<FILE>)
  {
    next if /^\s*$/;
    print OUT $_;
  }
  close FILE; close OUT;
  unlink("$file") or warn "Error in deleting: $!\n";
  rename("tmpfile.$$", "$file") or warn "Error in rename: $!";
  
  my $command = "perl $FindBin::Bin\\send_xml_to_diamonds.pl -s $server -f $file";
  
  my $id = 0;
  eval
  {
    open(FH,"<DiamondsBuildID") or warn "DiamondsBuildID file not created: $!\n";
  };
  if (!$@)
  {
    $id = <FH>;
    close (FH);
  }
  if($id ne "" && $id > 1)
  {
    $command .= " -u /diamonds/builds/$id/";
    executeCommand($command);
  }
  else
  {
    $command .= " -u /diamonds/builds/";
    $id = executeCommand($command);
    open (FH,">DiamondsBuildID") or die "DiamondsBuildID file not created: $!\n";
    print FH $id;
  }
close(FH);
}


sub executeCommand
{
  my $command = shift;
  #~ print "$command\n";
  my @cmdOP = `$command`;
  my @serverResponse = grep {/^Server response:/i} @cmdOP;
  my @responseStatus = grep {/^Response status:/i} @cmdOP;
  my @responseReason = grep {/^Response reason:/i} @cmdOP;
  
  chomp(@serverResponse,@responseReason,@responseStatus);
  if ($responseStatus[0] !~ /:200/)
  {
    print "Error sending XML: $responseReason[0]\n";
  }
  elsif($serverResponse[0] !~ /:\/diamonds\/builds\/\d+\//)
  {
    print "Diamond Server Response: $serverResponse[0]\n";
  }
  else
  {
    $serverResponse[0] =~ /:\/diamonds\/builds\/(\d+)\//;
    my $id = $1;
    print "$id\n";
    return $id;
  }
}

1;
