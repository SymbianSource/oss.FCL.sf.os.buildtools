# Copyright (c) 2005-2009 Nokia Corporation and/or its subsidiary(-ies).
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
# Script to export CBRs to the ODC
# 
#

use strict;
use Getopt::Long;
use File::Copy;
use File::Path;

use FindBin;
use lib $FindBin::Bin; # Pickup local modules

use record_delivery;

# location of text file on devbuilds
my $aODCBuilds = "\\\\builds01\\odcbuilds\\CBR_Export";

# location of templates and email cfg
my $aSupportLoc = "\\\\builds01\\devbuilds\\BuildTeam\\record_delivery";

# Process the commandline
my (%args) = ProcessCommandLine();
# run the export
&Main(%args);

# ProcessCommandLine
#
# Description
# This function processes the commandline

sub ProcessCommandLine
{
	my ($iHelp);
	
	my ($iSnapshot, $iDir, $iProduct, $iNotify, @iComponents, @iTemplates);
	
	GetOptions('h' => \$iHelp, 'c=s' => \@iComponents, 's=s' => \$iSnapshot, 'd=s' => \$iDir, 'p=s' => \$iProduct, 'n' => \$iNotify, 't=s' => \@iTemplates);
	
	if (($iHelp) || (scalar(@iComponents) < 1) || (!defined $iSnapshot) || (!defined $iDir) || (!defined $iProduct))
	{
		Usage();
	}
	
	my %args = ('Snapshot' => $iSnapshot, 'Dir' => $iDir, 'Product' => $iProduct, 'Notify' => $iNotify,
				'Components' => [@iComponents], 'Templates' => [@iTemplates]);
	
	return %args;
}

# Usage
#
# Output Usage Information.
#

sub Usage
{
	print <<USAGE_EOF;
	
	Usage: ExportCBR.pl [switches]
	
	[Switches]
	-c component (e.g gt_techview_baseline) [multiple allowed]
	-s snapshot number (e.g. 03445_Symbian_OS_v9.1)
	-d Directory of epoc32 (e.g. M: or CBRGT)
	-p Product (e.g.9.1)
	
	[Optional]
	-h help
	-n Notify ODC by logging that the export has been completed
	-t Templates for recording deliveries [multiple allowed]

USAGE_EOF
	exit 1;
}

# Main
#
# Runs the export of CBRs
#
sub Main
{
	my (%args) = @_;
	
	my $aExportCount;
	
	# Check to see if this is a TestBuild by looking at the Publish Location Environment variable
	# Do no export if a Test Build
	if ($ENV{'PublishLocation'} =~ /Test_Builds$/i)
	{
		print "Not exporting the Test Build\n";
		exit 0;
	}

	# Open Log file for writing
	my $logname = $ENV{'LogsDir'}."\\Export_CBR.log";
	open (LOGFILE, ">> $logname");
	
	foreach my $aComponent(@{$args{'Components'}})
  {
		my $line;
		
		print "\nAbout to export $aComponent ".$args{'Snapshot'}." from ".$args{'Dir'}."\n";

		my $iCmd = "exportenv -vv ".$aComponent." ".$args{'Snapshot'}." 2>&1";
		print LOGFILE "\nCommand: $iCmd\n";
		open (CMD, "$iCmd |");
		while ($line = <CMD>)
		{
			print LOGFILE $line;
			# Count the number of components exported
			if ( $line =~ /successfully exported/)
			{
				$aExportCount++;
			}
		}
		# Write time stamp to logfile
		print LOGFILE $aComponent." exportenv finsihed at ".localtime()."\n"; 
		print "\nExport Complete\n";
	}
	
	# Record export of components
	if (($aExportCount >0) && (scalar(@{$args{'Templates'}}) > 0))
	{
		my $delivery = record_delivery->new(config_file => $aSupportLoc."\\email.cfg");
		foreach my $iTemplate (@{$args{'Templates'}})
		{
                         eval {			
				$delivery->send(Template => $aSupportLoc."\\".$iTemplate, BuildNumber => $args{'Snapshot'}, BuildShortName => $args{'Product'});
                        };
                        if($@)
                        {
				print LOGFILE "ERROR: Failed to record delivery using template ".$aSupportLoc."\\".$iTemplate."\n";
                        } else
			{			
				print LOGFILE "Sending email to record delivery using template ".$aSupportLoc."\\".$iTemplate."\n";
			}
		}
	}
	
	close LOGFILE;

	if ((defined$args{'Notify'}) && ($aExportCount >0))
	{
		&copyFile($logname, $args{'Snapshot'}, $args{'Product'});
	}
	
	
	
	exit 0;
}

# copyFile
#
# Copies a file with the snapshot to devbuilds
sub copyFile
{
	my ($logname, $aSnapShot, $aProduct) = @_;

	# check there is an "Export_CBR.log" present to be copied across before deleting the previous one(s).
	unless ( -e $logname )
	{
		print "WARNING: $logname not found when trying to copy to $aODCBuilds\\$aSnapShot.txt $!\n";
		return;
	}

	# now delete the older text files
	print "\nCMD: del /F /Q $aODCBuilds\\*$aProduct.txt\n";
	system("del /F /Q $aODCBuilds\\*$aProduct.txt");
	print "REMARK: deleting old notify files failed with return of ".($?>>8)."($?)\n" if ($? > 0);
	
	# and copy the new file
	print "\ncopying $logname to $aODCBuilds\\$aSnapShot.txt\n";
	mkpath($aODCBuilds) if (! -d $aODCBuilds);
	copy($logname, "$aODCBuilds\\$aSnapShot.txt") || print "WARNING: Copy of $logname to $aODCBuilds\\$aSnapShot.txt failed $!\n";
}
