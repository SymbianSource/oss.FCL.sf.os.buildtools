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
# This script was originally just a test harness for PreBldChecks.pm
# Subsequently it has been included in the MCL build
# 
#

use strict;
use Getopt::Long;
use File::Copy;
use Net::SMTP;
use Sys::Hostname;
use FindBin;
use lib "$FindBin::Bin";
use PreBldChecks;

my $gSMTPServer = 'smtp.nokia.com';
my $gNotificationSender = Sys::Hostname::hostname();
if (defined $ENV{'USERNAME'}) { $gNotificationSender .= ".$ENV{'USERNAME'}"; }
my $gXML2EnvVar = 'PreBldChecksXML2';

# Notes on License Files used by CodeWarrior (CW) and/or ARM
# The official IS-supported "RVCT2.0.1 to RVCT2.1" upgrade mechanism installs C:\APPS\ARM\LICENSE.DAT.
# but leaves ARMLMD_LICENSE_FILE pointing to License Server(s)
# The immediate fix was to delete the ARMLMD_LICENSE_FILE environment variable and edit
# LM_LICENSE_FILE to read C:\apps\Metrowerks\OEM2.8\license.dat;C:\apps\arm\license.dat.

# Note on CodeWarrior (CW) Version 3.0 (January 2005)
# NOKIA now own CodeWarrior. Thus we have a further Environment Variable, named NOKIA_LICENSE_FILE

# Note on CodeWarrior (CW) Version 3.1 (November 2006)
# A licence is no longer required for the command line utilities, only for the IDE

# Capture the name of this script for Help display etc.
$0 =~ m/([^\\]+?)$/;
my $gThisFile = $1;

# Process the commandline
my ($gXMLfile1,$gLogFile,$gNotificationAddress) = ProcessCommandLine();
# If XML file specified, get environment variables from that file into %$gXMLEnvRef1.
# Otherwise assume that all the required variables are already in the predefined hash %ENV
if (defined $gXMLfile1)
{
    my $gXMLEnvRef1;    # Reference to hash containing environment data read from the XML file
    $gXMLEnvRef1 = PreBldChecks::XMLEnvironment($gXMLfile1);
    PreBldChecks::MergeEnvironment($gXMLEnvRef1);
}

# Now refer to the build-specific XML file for further environment variables
# In an MCL build, this file has probably not been sync'ed yet. So get it from Perforce into a temporary directory
my $gP4Location = $ENV{CurrentCodeline};
$gP4Location =~ s#/$##;      # Remove trailing slash, if any
if ((uc $ENV{'Platform'}) eq 'SF')
{
  $gP4Location = "$gP4Location/os/deviceplatformrelease/symbianosbld/cedarutils/$ENV{BuildBaseName}.xml"; #For Symbian MCL SF and TB91SF
}
else 
{
  $gP4Location = "$gP4Location/$ENV{Platform}/generic/utils/$ENV{BuildBaseName}.xml";  #For Symbian OS v9.5 and earlier
}

# The following use of an environment variable to override $gP4Location is provided to make it 
# possible to test a product-specific XML file from a development branch. This functionality
# can be used in a manual test build or in stand-alone tests.
# NB: Remember that you are specifying a location in Perforce, not a Windows directory!
if (defined $ENV{$gXML2EnvVar})
{
    $gP4Location = $ENV{$gXML2EnvVar};
}

my $gXMLfile2 = "$ENV{'TEMP'}\\$ENV{BuildBaseName}.xml";

my $gCmd = "P4 print -q -o $gXMLfile2 $gP4Location 2>&1";
my $gResponse = `$gCmd`;    # It seems that response is empty when P4 succeeds. On error, it will contain details.

if (-e $gXMLfile2)
{
    my $gXMLEnvRef2;
    $gXMLEnvRef2 = PreBldChecks::XMLEnvironment($gXMLfile2);
    chmod (0666, $gXMLfile2);   # Make file R/W
    unlink ($gXMLfile2);
    PreBldChecks::MergeEnvironment($gXMLEnvRef2);
}
else
{
    $gP4Location = undef;   # See reporting text below
}

# Having acquired all available environment variables, set up text for eventual message.
my $gBuildNumTxt = (defined $ENV{'BuildNumber'})? " - Build: $ENV{'BuildNumber'}": '';

# Run checks.
my($ErrorsRef,$WarningsRef) = PreBldChecks::AllChecks(\%ENV);
# Log checks and/or print to screen
my $errorCount = scalar @$ErrorsRef;
my $warningCount = scalar @$WarningsRef;

open BUILDENVOUTPUT, ">$gLogFile";

print "\n\n";
PrintLine('Results from pre-build checks:');
PrintLine('Computer: ' . Sys::Hostname::hostname() . $gBuildNumTxt);
PrintLine('XML Files used:');
if (defined $gXMLfile1) { PrintLine("  $gXMLfile1"); }
if (defined $gP4Location) { PrintLine("  $gP4Location"); }  # Report Perforce location ($gXMLfile2 points to temporary file only

my @gEMailMsg = ();
my $gErrMsg = '';

if ($errorCount)
{
    $gErrMsg = 'Errors must be fixed before restarting build!';
    PrintLine("$errorCount Error(s):");
    push @gEMailMsg, "$errorCount Error(s):\n";
    for my $text (@$ErrorsRef)
        {
        PrintLine("  $text");
        push @gEMailMsg, "\t$text\n";
        }
}
else
{
    PrintLine('No error.');
}

if ($warningCount)
{
    PrintLine("$warningCount Warning(s):");
    push @gEMailMsg, "$warningCount Warning(s):\n";
    for my $text (@$WarningsRef)
    {
        PrintLine("  $text");
        push @gEMailMsg, "\t$text\n";
    }
}
else
{
    PrintLine('No warning.');
}

if($gNotificationAddress and scalar @gEMailMsg)
{
    my $iHostName = Sys::Hostname::hostname;     # Depends on "use Sys::Hostname;"
    my $iEmailSubject = "ERROR: PreBldCheck Errors/Warnings!$gBuildNumTxt";
    my $iMsgIntro = "PreBldCheck Reports:$gBuildNumTxt";     # Message introduction (becomes first line of email body)
    $iMsgIntro .= "\nComputer $iHostName - Log file: $gLogFile";
    unshift @gEMailMsg, "$iMsgIntro:\n\n";
    push @gEMailMsg, "\n$gErrMsg\n---------------------------------------------\n";
    unless (SendEmail($iEmailSubject,@gEMailMsg)) { ++$errorCount; }
}

if ($errorCount)
{
    print "\n";
    # IMPORTANT: In the following text, "ERROR:" is a keyword for ScanLog to identify
    PrintLine("ERROR: $gErrMsg\n");
}

close BUILDENVOUTPUT;
print "\n";

exit($errorCount);      # End of main script

# PrintLine
#
# Inputs
# Text to be written. (No CRLF required)
#
# Outputs
# Text to screen and to log file.
#
# Description
# This subroutine takes a line of text, adds CRLF and writes it to both screen and to the logfile.

sub PrintLine
{
    my $iLine = shift;
    print "$iLine\n";
    print BUILDENVOUTPUT "$iLine\n";
}

# SendEmail
#
# Input: Subject, Message (array of lines)
#
# Returns: TRUE on success
#
sub SendEmail
{
    my ($iSubject, @iBody) = @_;

    my (@iMessage);
    my $iRetVal = 0;

    push @iMessage,"From: $gNotificationSender\n";
    push @iMessage,"To: $gNotificationAddress\n";
    push @iMessage,"Subject: $iSubject\n";
    push @iMessage,"\n";
    push @iMessage,@iBody;

    # Create an SMTP Client object that connects to the Symbian SMTP server
    # Client tells the server what the mail domain is.
    # Debug - just enables debugging information.
    my $iSMTP = Net::SMTP->new($gSMTPServer, Hello => $ENV{'COMPUTERNAME'}, Debug   => 0);

    if($iSMTP)
    {
        $iSMTP->mail();
        $iSMTP->to($gNotificationAddress);
        $iRetVal = $iSMTP->data(@iMessage);
        $iSMTP->quit;
    }
    unless ($iRetVal)
    {   # Report email failure to log and to screen (NB: "WARNING:" is a keyword for ScanLog to identify)
        PrintLine ("WARNING: Failed to send email notification!\nSubject: $iSubject\nMessage:\n");
        print join ('',@iBody), "\n";   # Send email body to screen only. (Will be logged by BuildServer/Client)
    }
    return $iRetVal;
}

# ProcessCommandLine
#
# Inputs
#
# Returns
# $iXMLfile filename of XML file from, which environment data are to be read.
# $iLogFile filename to write log to.
#
# Description
# This function processes the commandline

sub ProcessCommandLine {
    my ($iHelp, $iXMLfile,$iLogfile,$iEMailAddress);
    GetOptions('h' => \$iHelp, 'x=s' => \$iXMLfile, 'l=s' => \$iLogfile, 'e=s' => \$iEMailAddress);

    if ($iHelp) { Usage(); }

    if (!defined $iLogfile) { Usage("Logfile not specified!"); }

    &backupFile($iLogfile) if (-e $iLogfile);
  
    return($iXMLfile, $iLogfile, $iEMailAddress);
}

# backupFile
#
# Inputs
# $iFile - filename to backup
#
# Outputs
#
# Description
# This function renames an existing file with the .bak extension
sub backupFile
{
	my ($iFile) = shift;
	my ($iBak) = $iFile;
        $iBak =~ s/(\.\w*?$)/\.bak$1/;  # Convert, e.g., "PreBldChecks.log" to "PreBldChecks.bak.log"
	if ((-e $iFile) and ($iFile ne 'NUL'))
	{   # (NB: "WARNING:" is a keyword for ScanLog to identify)
	    print "WARNING: $iFile already exists!\n\t Creating backup of original with new name of $iBak\n";
	    move($iFile,$iBak) or die "WARNING: Could not backup $iFile to $iBak because of: $!\n";	  
	}
}

# Usage
#
# Output Usage Information and exit whole script.
#

sub Usage {
    my $iMsg = shift;
    
    if (defined $iMsg) { print "\nERROR: $iMsg\n"; }
    
    print <<USAGE_EOF;
    
    $gThisFile:
        Carries out various checks on the build environment
        including disk free space, the state of licensing
        for CodeWarrion and for ARM RVCT.
        Writes errors and warnings to the specified log file.
        Emails notification of errors (but not warnings) to
        the specified email address.
        On exit, ERRORLEVEL is set to the Error Count.

    Usage: $gThisFile parameters [options]

    Parameters:
    -l  logfile (output)

    Options:
    -x  XML file (input)
    -e  EMail address for warnings (internet format)
    -h  Help

    If no XML file is specified, script will assume that all
    necessary variables are already in the environment (\%ENV).
    In any case, script will attempt to locate the relevant
    build-specific XML file in Perforce and will read any
    environment variables found in it.
    
    Strictly for test purposes, the calculated location of the
    secondary (product-specific) XML file may over-ridden by
    setting the Environment Variable $gXML2EnvVar
    
USAGE_EOF

	exit 1;
}

