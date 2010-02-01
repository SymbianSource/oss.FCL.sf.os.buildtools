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
# Script that return a list of Perforce Change lists that are associated to a build snapshot.
# 
#
package Changelists;
use DBI;
my $dbh; #connection handle
sub connectDB()
{
  my $dBase = "autobuild2";
  my $serverPort = "intweb:3306";
  my $user = "autobuild2";
  my $password = "autobuild2";
  $dbh->disconnect if ($dbh); #disconnect if already connected
  $dbh = DBI->connect("DBI:mysql:$dBase:$serverPort", $user, $password, {PrintError => 0, RaiseError => 0}); # should use a username which has read-only credentials only.
  if (!$dbh)
  {
    print "Cannot connect to the AutoBuild2 server:$DBI::errstr\n";
    exit;
  }
  else
  {
    print "Connected to AutoBuild\n";
  }
}


sub queryHandler #handle querying the database.
{
  my $query = shift;
  my $handle;
  $handle = $dbh->prepare($query);
  $handle->execute;
  if($handle->err())
  {
    Logit(2,"could not execute Query:".$handle->errstr());
    if ($handle->errstr() =~ m/(Lost connection|MySQL server has gone away)/i) #sometimes the connection to server is lost, 
    {
      Logit(0,"Lost connection, ".$handle->errstr());
      exit;
    }
  }
  return $handle;
}

my $snapshot = $ENV{SnapshotNumber};
my $buildShortName = $ENV{BuildShortName};
sub main {
	
	print "$snapshot \t $buildShortName\n";
	my $query = "select distinct(sub3.changelist), snap.name as Name, sub3.description as Description
	from codeline, Submission as sub, Submission as sub3
		left join Snapshot    as snap  on (snap.Submission_id  = sub.id )
		left join Build       as bld   on (bld.Snapshot_id     = snap.id)
		left join Spec        as spec  on (bld.Spec_id         = spec.id)
		left join Product     as prod  on (spec.Product_id     = prod.id)
		left join Build       as bld2  on (bld2.id             = bld.BCPrevious_id)
		left join Snapshot    as snap2 on (bld2.Snapshot_id    = snap2.id)
		left join Submission  as sub2  on (snap2.Submission_id = sub2.id)
	where snap.name = \"$snapshot\" and prod.build_short_name=\"$buildShortName\" and sub3.Codeline_id = (SELECT codeline_id FROM `spec` , codeline cl where Product_id=(select id from product where build_short_name = \"$buildShortName\") and pool_id = \"1\" and cl.name = \"MCLsfRO\" and spec.codeline_id= cl.id and end_date > CURDATE() ORDER by spec.id LIMIT 1) and sub3.changelist between sub2.changelist and sub.changelist order by sub3.changelist;";

	&connectDB();
	my $ClInfo = &queryHandler($query);
	my @AllCls = ();
	my %CLhash = ();
	while (my $Data = $ClInfo->fetchrow_hashref)
	{
		my @Cl = ();
		my $changelist = ${$Data}{'changelist'};
		my ($submitter) = ${$Data}{'Description'} =~ /<detail submitter=\s*\"(.*?)\"/;
		my ($team) = ${$Data}{'Description'} =~ /<detail team=\s*\"(.*?)\"/;
		my ($sub_time) = ${$Data}{'Description'} =~ /<detail submissionTime=\s*\"(.*?)\"/;
		${$Data}{'Description'} =~ s/\n/##/g;
		my ($desc) = ${$Data}{'Description'} =~ /<EXTERNAL>####(.*?)####<\/EXTERNAL>/i;
		$desc =~ s/##/\n/g;
		$CLhash{$changelist}{'submitter'} = $submitter;
		$CLhash{$changelist}{'team'} = $team;
		$CLhash{$changelist}{'sub_time'} = $sub_time;
		$CLhash{$changelist}{'desc'} = $desc;
		#~ print "#################${$Data}{'changelist'}#####################\n";
		#~ print "$submitter\t$team\t$sub_time\n$desc\n";
	}
	return (\%CLhash);
}
1;
