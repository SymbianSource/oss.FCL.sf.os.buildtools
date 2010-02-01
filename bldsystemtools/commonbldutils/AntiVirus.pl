#!/usr/bin/perl -w
use strict;
use FindBin;		    # for FindBin::Bin
use lib $FindBin::Bin;  # for BldMachineDir (if in same dir. as this .PL file)
use Getopt::Long; # Get long options
use AntiVirus qw{Start Stop Scan WaitTillAntiVirusStarts};

####my $gTimeNow = time();
 
# Get the command line args
my ($gCommand,$gOutFilesDir ,$gDirsToScan,$gWaitingTime, $gRetries) = &ProcessCommandLine();
	
# If the command is to stop the services/processes, then do so.

if($gCommand eq 'STOP')
{    	
	Stop($gWaitingTime, $gRetries);	
}
elsif($gCommand eq 'START')
{
    Start();
}
else    # ($gCommand eq 'SCAN') NB Any unknown command has been caught by ProcessCommandLine()
{
    Scan($gOutFilesDir, $gDirsToScan);
}

####printf ("DEBUG MSG: Elapsed time = %d seconds", time() - $gTimeNow);   ####???? For debugging!

################################################################################
# ProcessCommandLine                                                           #
# Inputs: None (Gets data from @ARGV)                                          #
# Outputs: ($iCommand, $iOutFilesDir, \@iDirsToScan)                             #
# Remarks: None                                                                #
################################################################################
sub ProcessCommandLine
{
    my ($iHelp, $iCommand,$iOutFilesDir,@iDirsToScan,$iWaitingTime, $iRetries );
    unless (GetOptions('h' => \$iHelp, 'o=s' => \$iOutFilesDir, 'c=s' => \$iCommand,'w=s' => \$iWaitingTime,'r=s' => \$iRetries, 'd=s' => \@iDirsToScan))
    {
        Usage('Command Line error(s), as above.');
    }
    if (scalar @ARGV)
    {
        Usage("Redundant data on Command Line: @ARGV");
    }
    if ($iHelp)
    {
        Usage();
    }
    unless(defined($iCommand))
    {
        Usage('No command given');
    }
    # Uppercase $iCommand once and for all. Then we can check using 'eq'.
    # NB: uppercasing undef results in a defined, but empty, string!
    $iCommand = uc $iCommand;

	

    if($iCommand eq 'SCAN')
    {
        unless((scalar @iDirsToScan) and ($iOutFilesDir))
        {   # Make sure there are some directories to scan!
            # It is an error to ask for a scan and to not
            # supply directories, so print usage information
            Usage('With SCAN command, must specify directory(ies) and output file');
        }
        return ($iCommand, $iOutFilesDir, \@iDirsToScan);
    }

    if(($iCommand eq 'START')or ($iCommand eq 'STOP'))
        {
            if((scalar @iDirsToScan) or ($iOutFilesDir))
            {       # Can't specify directories when starting and stopping
            # the AV processes and services.
            Usage('With START/STOP command, cannot specify directories &/or output file');
        }
        # Only valid to start/stop if no directories have been given 
	   return ($iCommand, $iOutFilesDir, \@iDirsToScan,$iWaitingTime, $iRetries);
        }
    # Something else has gone wrong. So print usage.
    Usage("Unknown command $iCommand");
}

################################################################################
# Usage                                                                        #
# Inputs: Optional error message                                               #
# Outputs: Usage information for the user.                                     #
# Remarks: None                                                                #
################################################################################
sub Usage
{
    my $iErrorMsg = shift;

    if ($iErrorMsg)
    {
        print STDERR "\nERROR: $iErrorMsg.\n";
    }

    print <<USAGE_EOF;

Usage: AntiVirus.pl -c STOP [-w waitTime -r retries]
	   AntiVirus.pl -c START
       AntiVirus.pl -c SCAN -d scandir1 [-d scandir2 [-d scandir3]] -o outdir

Parameters:
 -c  command to perform, limited to "START", "STOP", "SCAN"
 -d  used ONLY in combination with "-c SCAN" to specify the directories to 
     scan. Multiple allowed.
 -o  used ONLY in combination with "-c SCAN" to specify the full name 
     of the directory in which the output file is to be written.
 -w  used ONLY in combination with "-c STOP" .If Antivirus is inactive at
     the time of STOP attempt,this argument specifies the waiting time in
     seconds before next attempt is made to check AV service status
 -r  used ONLY in combination with "-c STOP" .If Antivirus is inactive at
     the time of STOP attempt,this argument specifies the maximum number 
     of attempts to check  AntiVirus service status.
	 
	 
     
Optional Parameters:
 -h  help - print this information and exit

Examples:
 1) AntiVirus.pl -c STOP
 2) AntiVirus.pl -c START
 3) AntiVirus.pl -c SCAN -d M:\\epoc32\\ -o M:\\logs\\cedar\\
 4) AntiVirus.pl -c STOP -w 30 -r 5
 
Description and Remarks:
 This script controls operation of the installed anti-virus software. The 
 script stops and starts anti-virus services &/or programs. Reports of 
 missing anti-virus programs or failures to start/stop a service are 
 reported with keyword "WARNING:" or "REMARK:" prepended.

 Scanning is carried out on all the directories listed on the command line,
 each one being specified with the -d option.

 Currently only McAfee anti-virus software is supported.

USAGE_EOF
    exit 1;
}
