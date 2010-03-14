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
# Script to launch MakeCBR.pl and test return code and zip up the CBR Environment on failure
# 
#

use strict;
use Getopt::Long;

my($build_id, $config_file, $log_file, $parallel, $release_ver, $debug_file, $help_flag, $prev_ver, $repair, $int_ver);

GetOptions (
   'b=s'    => \$build_id,
   'c=s'    => \$config_file,
   'l=s'    => \$log_file,
   'v=s'    => \$release_ver,
   'p=s'    => \$prev_ver,
   'd=s'    => \$debug_file,
   '+h'     => \$help_flag,
   'repair' => \$repair,
   'i=s'    => \$int_ver,
   'j=i'    => \$parallel
);

if(defined $ENV{PERL510_HOME})
{
	$ENV{PATH} = "$ENV{PERL510_HOME}\\bin;".$ENV{PATH};
	system("path");
	my $cmd_perl_version = `perl -v`;
	$cmd_perl_version =~ /(v\d+.\d+.\d+)/i;
	my $perl_version = $1;
	print "Add perl $perl_version executable path into env path\n";
}
else
{
	$parallel = 0;
}


# Build Command line
# Must on correct drive
my $commandline = "perl \\sf\\os\\buildtools\\toolsandutils\\productionbldtools\\makecbr\\makecbr.pl -b $build_id -v $release_ver -c $config_file";

if (defined $log_file)
{
  $commandline .= " -l $log_file";
}

if (defined $debug_file)
{
  $commandline .= " -d $debug_file";
}

if (defined $prev_ver)
{
  $commandline .= " -p $prev_ver";
}

if (defined $parallel)
{
  $commandline .= " -j $parallel";
}
print "makcbr command: $commandline\n";
system("$commandline");

