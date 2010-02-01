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
#

#!/usr/bin/perl -w
use strict;
use Getopt::Long;
use HTTP::Date;

my $JOBS_PATH = "autobfc\\";
my $JOB_QUEUE = 'jobqueue.lst';
my $CURR_JOB = 'currentjob.bat';
my $QUIT_BFC = 'quit.txt';

my $ENV_BFCPOOL = "AutoBFCServerPool";


SendBFC( ProcessCommandLine() );

# SendBFC
# Send a BFC test request to an active Auto BFC server
# 
# Return 0 if request was successfully added to the BFC queue.
#
# N.B: Since this script is invoked during the system build, WARNING/ERROR
# messages must NOT be printed out in order to avoid affecting the BRAG status.
#

sub SendBFC
{
	my ($iProduct, $iBuild, $iCodeline, $iServerPool, $iARMVer, $iMWVer, $iWait, $iExtraArg, $iQuit, $iSubType) = @_;

	# Get server list from ENV or from command line
	$iServerPool = $ENV{$ENV_BFCPOOL} if (!defined($iServerPool));

	my $server = FindAvailableServer(split /\#/, $iServerPool);

	if (!$server)
	{
		print "Could not find BFC server \n";
		return 1;
	}

	my $jobQueue = "\\\\$server\\".$JOBS_PATH.$JOB_QUEUE;

	# Set basic release info
	my $request = "Product=$iProduct,SnapshotNumber=$iBuild,CurrentCodeline=$iCodeline";

	# Set timeout
	if (defined($iWait) && !($iExtraArg =~ /-o/))
	{
		my $nowStr = HTTP::Date::time2isoz(time() + $iWait*60*60);
		$request .= ",BFCTimeout=$nowStr";
	}

	$request .= ",ARMRVCTBLD=$iARMVer" if ($iARMVer);
	$request .= ",MWVER=$iMWVer" if ($iMWVer);

	$request .= ",QMAction=$iQuit" if ($iQuit);

	# Get BuildSubType from ENV or from command line, if specified.
	$iSubType = $ENV{'BuildSubType'} unless ($iSubType);
	$request .= ",BuildSubType=$iSubType" if ($iSubType);

	# Add extra arguments at the end
	$request .= ",BFCCommand=$iExtraArg" if ($iExtraArg);

	# Add the request to the server queue
	open FILE, ">> $jobQueue" or die "Can't open $jobQueue\n$!\n";
	print FILE "$request \n";
	close FILE;

	print "Added request: $request\nto $server\n";
	return 0;
}

# FindAvailableServer
# Scan the server list and find an available AutoBFC server.
# 
# Return the first bfc server with no jobs or the bfc server with
# the least jobs on the queue.
#
sub FindAvailableServer
{
	my @servers = @_;

	my %bestServer;
	foreach my $server (@servers)
	{
		# Check autobfc shared dir.
		my $jobsPath = "\\\\$server\\".$JOBS_PATH;
		next if !(-d $jobsPath);

		# This is a valid server.
		# Check the job list.
		my $jobQueue = $jobsPath.$JOB_QUEUE;
		my $currentJob = $jobsPath.$CURR_JOB;
		push my @jobs, "current"  if (-e $currentJob);
		if (open (FH1, $jobQueue))
		{
			push @jobs, <FH1>;
			close FH1;
		}
		%bestServer = ('Server' => $server, 'Jobs' => scalar @jobs) if (!exists($bestServer{'Server'}) || (scalar @jobs < $bestServer{'Jobs'}));
		last if ($bestServer{'Jobs'} == 0);
	}
	
	return $bestServer{'Server'}; 
}


# ProcessCommandLine
#

sub ProcessCommandLine
{
  my ($iHelp);
  my ($iProduct, $iBuild, $iCodeline, $iServerPool, $iARMVer, $iMWVer, $iWait, $iExtraArg, $iQuit, $iSubType);

  my $ret = GetOptions('h' => \$iHelp,
                       "product=s" => \$iProduct,
                       "build=s" => \$iBuild,
		       "codeline=s" => \$iCodeline,
                       "server=s" => \$iServerPool,
                       "arm=s" => \$iARMVer,
                       "mw=s" => \$iMWVer,
                       "wait=i" => \$iWait,
                       "reboot" => \$iQuit,
		       "type=s" => \$iSubType);

  $iExtraArg = join(' ',  @ARGV);

  if ((!$ret) || ($iHelp) || (!defined $iProduct) || (!defined $iBuild) || (!defined $iCodeline))
  {
    Usage();
  }

  if (defined($iQuit))
  {
  	$iQuit = "reboot";
  }

  return ($iProduct, $iBuild, $iCodeline, $iServerPool, $iARMVer, $iMWVer, $iWait, $iExtraArg, $iQuit, $iSubType);
}

# Usage
#
# Output Usage Information.
#

sub Usage 
{
  print <<USAGE_EOF;

  Request a BFC
  Usage: bfcClient.pl -p <Ver> -b <BuildNo> -c <Codeline> -s <ServerPool> [options] -- [bfc extra arg]

  --product   Specify OS product (e.g. 9.1).
  --build     Specify Build Number (e.g. M04191).
  --codeline  Specify Codeline (e.g. Master, Symbian_OS_v9.4)
  --server    Hash separated BFC server list (e.g lon-engbuild20\#lon-engbuild21).
              Alternatively, set $ENV_BFCPOOL.
  
  [Options]
  -h           This help
  --arm        Specify ARM version to be used (435 or 559 or 616).
  --mw         Specify Metrowerk version to be used (3.0 or 3.1.1 or 3.1.2).
  --wait 0..n  Force the bfc process to wait no more than n hours from now.
  --reboot     Force the bfc process to reboot before this task.
  --type       Specify BuildSubType (e.g. Daily, Test).

  [bfc extra arg]
   Any other switches will be passed to the bfc process tools

USAGE_EOF
	exit 0;
}


