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
# This module is intended to be run at an early stage when starting a Master Codeline build (or analogous "steady state) build.
# As such it is called from StartBuild.pl. It can also be called by PreBuildChecks.pl
# It will check for disk space and other aspects of the build environment.
# It issues errors and/or warnings by pushing texts onto global arrays and returning references to these arrays.
# 
#

package PreBldChecks;
use strict;
use FindBin;
use lib "$FindBin::Bin";
use lib "$FindBin::Bin\\..\\tools\\build\\lib";
use lib "$FindBin::Bin\\..\\buildsystemtools\\lib";
use XML::Parser;
use IO::Socket;
use Socket;
use Date::Manip;

# Set TimeZone because Date:Manip needs it set and then tell it to IGNORE the TimeZone
Date::Manip::Date_Init("TZ=GMT","ConvTZ=IGNORE");

my @Errors = ();
my @Warnings = ();

# XMLEnvironment
# This is a public interface to this module
# Reads supplied XML file and resolves back references (i.e the %<varName>% syntax!).
#
# Inputs
# Name of input XML file
#
# Returns
# Reference to hash containing environment data read from XML file, or undef on error.
#
sub XMLEnvironment
{
    my $iXMLfile = shift;
    my %iXML_ENV;       # Hash whose reference will be returned
    @SubHandlers::gXMLdata = ();     # Clear global array. This allows this subroutine to be called twice.
    my $iParser = new XML::Parser(Style=>'Subs', Pkg=>'SubHandlers', ErrorContext => 2);

    unless (-e $iXMLfile)
    {
        push @Errors, "XML File not found at: \"$iXMLfile\"!";
        return undef;
    }
    
    # Pass XML data source filename to the XML Parser
    $iParser->parsefile($iXMLfile);
    for (my $iIndx = 0; $iIndx < scalar @SubHandlers::gXMLdata; $iIndx++)
    {
        my $iHashRef = $SubHandlers::gXMLdata[$iIndx];
        unless (defined $iHashRef) { next; }
        # Resolve references to preceding variables in the current XML file or in the Windows environment
        while ($iHashRef->{Value} =~ m/%(\w+)%/)
        {
            my $iVarName = $1;
            if (defined $iXML_ENV{$iVarName})
            {   # First substitute from our own XML file data
                $iHashRef->{Value} =~ s/%\w+%/$iXML_ENV{$iVarName}/;
            }
            elsif (defined $ENV{$iVarName})
            {   # Secondly substitute from the Windows environment
                $iHashRef->{Value} =~ s/%\w+%/$ENV{$iVarName}/;
            }
            else
            {
                $iHashRef->{Value} =~ s/%\w+%//;  # Undefined variables become 'nothing'.
            }
        }   # End while()
        $iHashRef->{Value} =~ s/%%//g;      # Any remaining double % become single %
        $iXML_ENV{$iHashRef->{Name}} = $iHashRef->{Value};
    }   # End for()
    return \%iXML_ENV;
}

# MergeEnvironment
# This is a public interface to this module
# Merge supplied environment variables into %ENV. It seems that %ENV is a form of tied hash which supports
# Windows (case-preserving) variable names. Names are always returns (by key function) in upper case.
#
# Input: New variables to be added to %ENV (hash ref.)
#
# Output: Modifications to global %ENV
#
# Return: None
#
sub MergeEnvironment
{
    my $iEnvRef = shift;            # Environment variables to be added to %ENV

    for my $iName (keys %$iEnvRef)
    {
        $ENV{$iName} = $iEnvRef->{$iName};
    }
}

# AllChecks
# This is a public interface to this module
# It checks various items in the build environment and reports any anomalies.
#
# Inputs
# Reference to environment hash. This may be the hash populated by a previous call to sub XMLEnvironment()
# or may be the predefined hash %ENV
#
# Returns
# Two array refs: \@Errors,\@Warnings
#
sub AllChecks
{
    my $iEnvRef = shift;
    my $iXMLerror = 0;
    
    checkdiskspace($iEnvRef);  # Check Disk Space
    checkCWlicensing();        # Check CodeWarrior licensing
    checkARMlicensing();       # Check ARM licensing
    return \@Errors,\@Warnings;
}

# checkdiskspace
#
# Inputs
# Reference to hash containing environment variables
#
# Outputs
# Pushes error/warning texts onto global arrays
#
sub checkdiskspace
{
    my $iEnvRef = shift; 
    my $iPublishLoc = $iEnvRef->{'PublishLocation'};    # Directory (network share) to which build is to be published e.g \\Builds01\DevBuilds
    $iPublishLoc =~ s/([^\\])$/$1\\/;                   # Ensure trailing backslash   
    my $iCBRLocation = $iEnvRef->{'CBRLocation'};       # Directory (network share) containg CBR archive(s)
    unless (defined $iCBRLocation) { $iCBRLocation = '\\\\Builds01\\devbuilds\\ComponentisedReleases'; };
    $iPublishLoc .= $iEnvRef->{'Type'};                 # Append Type to gaive a real directory name for DIR to check
    my $iPublishMin = $iEnvRef->{'PublishDiskSpaceMin'};# Space in gigabytes required on that drive
    my $iLocalMin = $iEnvRef->{'LocalDiskSpaceMin'};    # Space in gigabytes required on local (current) drive

# Check disk space on local drive (assumed to be the Windows current drive)
    unless (defined $iLocalMin)
    {
        push @Errors, "Unable to check disk space on local drive!\n\tCheck environment variable \"LocalDiskSpaceMin\"";
    }
    else
    {
        my $free = freespace('');
        unless (defined $free)
        {
            push @Errors, 'Unable to check disk space on local drive!';
        }
        elsif ($free < ($iLocalMin * 1000000000))
        {
            push @Errors, "Insufficient space on local drive! $iLocalMin gigabytes required.";
        }
    }
    
# Check disk space on "Publishing Location"
    unless ((defined $iEnvRef->{'PublishLocation'}) and (defined $iEnvRef->{'Type'}) and (defined $iPublishMin))
    {
        push @Errors, "Unable to check disk space on \"Publishing\" drive\"!\n\tCheck env. var\'s \"PublishLocation\", \"Type\" and \"PublishDiskSpaceMin\"";
    }
    else
    {
        my $free = freespace($iPublishLoc);
        unless (defined $free)
        {
            push @Errors, "Unable to check disk space on \"$iPublishLoc\"!";
        }
        elsif ($free < ($iPublishMin * 1000000000))
        {
            push @Warnings, "Insufficient space on \"$iPublishLoc\"! $iPublishMin gigabytes required.";
        }
    }

    # Check disk space on CBR location
    unless ((defined $iCBRLocation) and (defined $iPublishMin))
    {
        push @Errors, "Unable to check disk space on \"CBR\" drive\"!\n\tCheck env. var\'s \"CBRLocation\" and \"PublishDiskSpaceMin\"";
    }
    else
    {
        my $free = freespace($iCBRLocation);
        unless (defined $free)
        {
            push @Errors, "Unable to check disk space on \"$iCBRLocation\"";
        }
        elsif ($free < ($iPublishMin * 1000000000))
        {
            push @Warnings, "Insufficient space on \"$iCBRLocation\"! $iPublishMin gigabytes required.";
        }
    }
}

# freespace
#
# Inputs
# Drive letter or share name (or empty string for current drive)
#
# Returns
# Free space in bytes or undef on error.
#
sub freespace
{
    my $drive = shift;  # Typically 'D:' (including the colon!) or '\\Builds01\DevBuilds'
    my $free = undef;   # Free bytes on drive
    if (defined $drive)
    {
        open FDIR, 'DIR /-c ' . $drive. '\* |';
        while (<FDIR>)
        {
        	if ($_ =~ /\s+(\d+) bytes free/) { $free=$1;}
        }
    }
    return $free;
}

# checkCWlicensing
#
# Inputs
# None. Environment variables must come from the Windows environment (via global hash %ENV)
#
# Outputs
# Pushes warning texts onto global arrays
# (Licensing problems are always treated as warnings because new compiler versions
# tend to create apparent errors and it takes a finite time to update this script.)
#
sub checkCWlicensing
{   # Environment variables: LM_LICENSE_FILE and/or NOKIA_LICENSE_FILE
    my @licensefiles;
    if (defined $ENV{'MWVER'})
    {
         if($ENV{'MWVER'} gt '3.0')
         {
            ####???? print "No CodeWarrior licence required!";   For debugging
            return;
         }
    }
    if (defined $ENV{'LM_LICENSE_FILE'})
    {
        push @licensefiles, split /;/, $ENV{'LM_LICENSE_FILE'};
    }
    if (defined $ENV{'NOKIA_LICENSE_FILE'})
    {
        push @licensefiles, split /;/, $ENV{'NOKIA_LICENSE_FILE'};
    }
    unless (@licensefiles)
    {   # Environment variable(s) not set up
        push @Warnings, 'Neither LM_LICENSE_FILE nor NOKIA_LICENSE_FILE defined!';
        return;
    }
    foreach my $licensefile (@licensefiles)
    {
        if (-e $licensefile)
        {   # File exists. So open and parse
            if (parseCWlicensefile($licensefile))
                { return; }     # If parsing subroutine returns TRUE, do not look for any more files
        }
        else
        {
            push @Warnings, "Environment specifies file $licensefile but not found!";
        }
    }   # End foreach()
    push @Warnings, "No valid CodeWarrior license found!";
}

# parseCWlicensefile
#
# Inputs
# Filename
#
# Outputs
# Pushes error/warning texts onto global arrays
# Returns TRUE if relevant license information found. FALSE means "Try another file."
#
sub parseCWlicensefile
{
    my $fname = shift;
    my $return = 0; # Default to FALSE - "Try another file."
    unless (open (LFILE, "$fname"))
        {
        push @Warnings, "License file ($fname) cannot be opened!";
        return $return;     # "Try another file."
        }
    my $wholeline;  # Used to assemble continuation lines into one entry
    while(my $line = <LFILE>)
        {
        chomp $line;
        $line =~ s/^\s*//;     # Remove leading spaces
        $wholeline .= $line;
        if ($wholeline =~ s/\\$//) { next; }    # Trailing backslash means entry continues on next line
        if ($wholeline =~ m/^FEATURE.+symbian/i) # FEATURE is CW usage (not ARM !?)
            {
            if ($wholeline =~ m/permanent/i)
                {        
                $return = 1;    # Licence OK. "Do not try another file."
                last;
                }
            if ($wholeline =~ m/(\d{1,2}-\w{3}-\d{2,4})/i)
                {
                my ($date2) = Date::Manip::ParseDate($1);
                unless (defined $date2)
                    {
                    push @Warnings, "Failed to parse CodeWarrior license expiry date! (License file $fname)";
                    last;   # "Try another file."
                    }
                my $expirytext = Date::Manip::UnixDate($date2,"%Y/%m/%d");
                my $delta = Date::Manip::DateCalc("today",$date2);
                my $Dd = Date::Manip::Delta_Format($delta,'0',"%dt");
                if ($Dd < 1)
                    {
                    push @Warnings, "CodeWarrior license expired on $expirytext! (License file $fname)";
                    }
                elsif ($Dd < 7)
                    {
                    push @Warnings, "CodeWarrior license expires on $expirytext! (License file $fname)";
                    }
                $return = 1;    # Licence expiry date parsed. "Do not try another file."
                last;
                }
            }
        $wholeline = '';
        }   # End while()
    close LFILE;
    return $return;
}

# checkARMlicensing
#
# Inputs
# None. Environment variables must come from the Windows environment (via global hash %ENV)
#
# Outputs
# Pushes warning texts onto global arrays
# (Licensing problems are always treated as warnings because new compiler versions
# tend to create apparent errors and it takes a finite time to update this script.)
#
sub checkARMlicensing
{   # Environment variables: LM_LICENSE_FILE and/or ARMLMD_LICENSE_FILE
    my @licensefiles;
    if (defined $ENV{'LM_LICENSE_FILE'})
    {
        push @licensefiles, split /;/, $ENV{'LM_LICENSE_FILE'};
    }
    if (defined $ENV{'ARMLMD_LICENSE_FILE'})
    {
        push @licensefiles, split /;/, $ENV{'ARMLMD_LICENSE_FILE'};
    }
    unless (@licensefiles)
    {   # Environment variable(s) not set up
        push @Warnings, 'Neither LM_LICENSE_FILE nor ARMLMD_LICENSE_FILE defined!';
        return;
    }
    my $iLicenceFound = 0;
    foreach my $licensefile (@licensefiles)
    {
        if($licensefile =~ m/^(\d+)\@([-\w\.]+)$/)
        {
            if(VerifySocket($2,$1))
                { $iLicenceFound = 1; next; }
            push @Warnings, "Apparent licence server cannot be accessed. (Host=$2 Port=$1)!";
        }
        elsif (-e $licensefile)
        {   # File exists. So open and parse
            if (parseARMlicensefile($licensefile))
                { $iLicenceFound = 1; next; }
        }
        else
        {
            push @Warnings, "Environment specifies file $licensefile but not found!";
        }
    }   # End foreach()
    unless ($iLicenceFound)
        { push @Warnings, "No valid ARM license found!"; }
}

# parseARMlicensefile
#
# Inputs
# Filename
#
# Outputs
# Pushes error/warning texts onto global arrays
# Returns TRUE if relevant license information found. FALSE means "Try another file."
#
sub parseARMlicensefile
{
    my $fname = shift;
    my $return = 0; # Default to FALSE - "Try another file."
    unless (open (LFILE, "$fname"))
        {
        push @Warnings, "License file ($fname) cannot be opened!";
        return $return;     # "Try another file."
        }
    my $wholeline;  # Used to assemble continuation lines into one entry
    while(my $line = <LFILE>)
        {
        chomp $line;
        $line =~ s/^\s*//;     # Remove leading spaces
        $wholeline .= $line;
        if ($wholeline =~ s/\\$//) { next; }    # Trailing backslash means entry continues on next line
        if ($wholeline =~ m/^INCREMENT.+symbian/i) # INCREMENT is ARM usage (not CW !?)
            {
            if ($wholeline =~ m/permanent/i)
                {        
                $return = 1;    # Licence OK. "Do not try another file."
                last;
                }
            if ($wholeline =~ m/(\d{1,2}-\w{3}-\d{2,4})/i)
                {
                my ($date2) = Date::Manip::ParseDate($1);
                unless (defined $date2)
                    {
                    push @Warnings, "Failed to parse ARM license expiry date! (License file $fname)";
                    last;   # "Try another file."
                    }
                my $expirytext = Date::Manip::UnixDate($date2,"%Y/%m/%d");
                my $delta = Date::Manip::DateCalc("today",$date2);
                my $Dd = Date::Manip::Delta_Format($delta,'0',"%dt");
                if ($Dd < 1)
                    {
                    push @Warnings, "ARM license expired on $expirytext! (License file $fname)";
                    }
                elsif ($Dd < 7)
                    {
                    push @Warnings, "ARM license expires on $expirytext! (License file $fname)";
                    }
                $return = 1;    # Licence expiry date parsed. "Do not try another file."
                last;
                }
            }
        $wholeline = '';
        }   # End while()
    close LFILE;
    return $return;
}

# VerifySocket
#
# Verify that the specified host+port exists and that a socket can be opened
#
# Input: Hostname, Port number
#
# Return: TRUE if socket can be opened
#
sub VerifySocket
{
    my $iHost = shift;
    my $iPort = shift;
    my $iSocket;

    # Attempt to create a socket connection
    $iSocket = IO::Socket::INET->new(PeerAddr => $iHost,
                                PeerPort => $iPort,
                                Proto    => "tcp",
                                Type     => SOCK_STREAM);
                               
    unless ($iSocket) { return 0; } # FALSE = Failure
    close($iSocket);
    return 1;   # TRUE = Success
}


package SubHandlers;
our @gXMLdata;       # Stores data as read from XML file. Is accessed by PreBldChecks::XMLEnvironment() only

# SetEnv
#
# Description
# This subroutine handles the callback from the XML parser for the SetEnv tag in the XML file.
# Multiple instances allowed
# In the Build System context, each call to this subroutine corresponds to one environment variable.
#
# Inputs
# Reference to an instance of XML::Parser::Expat
# The name of the element ('SetEnv')
# A list of alternating attribute names and their values.
#
# Outputs
# Adds data directly to global array @gXMLdata
#
sub SetEnv
{
    shift;   # Hashref (instance of XML::Parser::Expat)
    shift;   # Always 'SetEnv'

    # Read the attributes of the tag into a hash
    my %iAttribs = @_;

    # Add this hash (representing a single tag) to the array of SetEnv tags from this file
    push @gXMLdata, \%iAttribs;
}

1;

__END__

