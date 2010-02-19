#!perl
# Copyright (c) 2002-2009 Nokia Corporation and/or its subsidiary(-ies).
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
# Perl script to output the current build rom_metric to a csv file.
# The file is of the format <build_no>,<rom_size>
# use warnings;
# 
#

use strict;
use Getopt::Long;
use File::Copy;

#
# Main
#

# Check arguments
my $build = '';
my $do_all = 0;
my $device = '';
my $rom_loc = '';
my $publish_loc = '';
my $preview = 0;
my $help = 0;
my $dir_name;
my $roms_loc;

GetOptions ( 'n' => \$preview, 'b=s' => \$build, 'a' => \$do_all, 'd=s' => \$device, 'p=s' => \$publish_loc, 'h|?' => \$help );
&Usage() if $help;
&Usage() if ( !$do_all && $build eq '' );
&Usage() if ( ( $publish_loc eq '' )  || ( $device eq '' ) );

# 
# Check if all builds are to be processed

my $pathspec = $publish_loc.'\\logs\\<build>\\rom_logs';
my $rom_logfilespec = "$pathspec\\${device}.log";
my $csv_logfilespec = $publish_loc."\\Rom_metrics"."\\${device}.csv";
my $csv_logfilespec_old = $publish_loc."\\Rom_metrics"."\\${device}.old";
$roms_loc = $publish_loc.'\\logs';
my $do_read = 1;

if ( $do_all )
{
	# Get all the log directories and process a new csv file.


	# Check if old log file exist then remove it then move the current file to old name.
	if ( -e $csv_logfilespec )
	{
		print ( "Moving old file\n" );
		if ( -e $csv_logfilespec_old )
		{
			if ( $preview )
			{
				print( "\ndel $csv_logfilespec_old\n" );
			}
			else
			{
				unlink( "$csv_logfilespec_old" );
			}
		}
		if ( $preview )
		{
			print( "\nmove $csv_logfilespec $csv_logfilespec_old\n" );
		}
		else
		{
			move( "$csv_logfilespec", "$csv_logfilespec_old" );
		}
	}

	# Get list of directories
	opendir ( DIRS, $roms_loc );
	while ( defined ( $dir_name = readdir( DIRS ) ) )
	{
		# $dir_name = $_;
		chomp ( $dir_name );

		# Look for name starting with 5 numbers, should be a build directory
		print "Checking dir $dir_name \n";
		if ( -d $roms_loc."\\".$dir_name )
		{
			if  ( $dir_name =~ /^(\d{5})/ )
			{
				$rom_logfilespec = "$roms_loc\\$dir_name\\rom_logs\\${device}.log";
				print "Looking in $roms_loc\\$dir_name for $rom_logfilespec\n";
				$do_read = 1;

				# Open the file for reading
				if ( -e $rom_logfilespec )
				{
					open( INPUT, $rom_logfilespec ) or next "Can't open $rom_logfilespec\n";
				}
				else
				{
					print "Can't find log file $rom_logfilespec\n";
					open(CSVFILE, ">> $csv_logfilespec" ) or die "Can't open log file for appending.\n";
					if ( $preview )
					{
						print ( "$dir_name,-1,\n" );
					}
					else
					{
						print CSVFILE ( "$dir_name,-1,\n" );
					}
					close(CSVFILE);
					$do_read = 0;
				
				}

				# Extract details from the log file
				print "Checking do_read $do_read \n";
				if ( $do_read )
				{
					my $line;
					while($line = <INPUT>)
					{
						# Find size information
						if($line =~ /^Total used	(\d+)$/)
						{
							# Open the csv file for appending
							open(CSVFILE, ">> $csv_logfilespec" ) or die "Can't open log file for appending.\n";
							if ( $preview )
							{
								print ( "$dir_name,$1,\n" );
							}
							else
							{
								print CSVFILE ( "$dir_name,$1,\n" );
							}
							close(CSVFILE);
						}
					}

					close(INPUT);
				}
			}
		}
	}
}	
else
{
	# Do not process all directories. Just get the log file from the given one and append to the csv file.
	
	# Check if old log file exist then remove it then move the current file to old name.
	if ( -e $csv_logfilespec )
	{
		print ( "Copy to old file\n" );
		if ( -e $csv_logfilespec_old )
		{
			if ( $preview )
			{
				print( "del $csv_logfilespec_old\n" );
			}
			else
			{
				unlink( "$csv_logfilespec_old" );
			}
		}
		if ( $preview )
		{
			print( "copy $csv_logfilespec $csv_logfilespec_old\n" );
		}
		else
		{
			copy( "$csv_logfilespec", "$csv_logfilespec_old" );
		}
	}

	$rom_logfilespec = "$roms_loc\\${build}\\rom_logs\\${device}.log";
	print "Looking in $roms_loc\\$build for $rom_logfilespec\n";

	# Open the file for reading
	if ( -e $rom_logfilespec )
	{
		open( INPUT, $rom_logfilespec ) or die "Can't open $rom_logfilespec\n";
	}
	else
	{
		open(CSVFILE, ">> $csv_logfilespec" ) or die "Can't open log file for appending.\n";
		if ( $preview )
		{
			print ( "$build,-1,\n" );
		}
		else
		{
			print CSVFILE ( "$build,-1,\n" );
		}
		close(CSVFILE);
		die "Can't find log file $rom_logfilespec\n";
	}

	# Extract details from the log file
	my $line;
	while($line = <INPUT>)
		{
		# Find size information
		if($line =~ /^Total used	(\d+)$/)
			{
				# Open the csv file for appending
				open(CSVFILE, ">> $csv_logfilespec" ) or die "Can't open log file for appending.\n";
				if ( $preview )
				{				
					print ( "$build,$1,\n" );
				}
				else
				{
					print CSVFILE ( "$build,$1,\n" );
				}
			}
		}

	close(INPUT);

}

sub Usage
{
	print "\nperl rom_metrics_list.pl [-a | -b %1] -d %2 -p %3 [-n]\n\n";
	print "-a Process all builds.\n";
	print "-b Build number.\n";
	print "-d Device type.e.g. ab_001.techview\n";
	print "-p Publish location.\n";
	print "-n Preview only.\n";
	print "-h Help.\n\n";
	exit (0);	
}
