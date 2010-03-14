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
# Script summarise and hotlink logfiles by reading
# HTMLscanlog generated files
# This initial version is phase 1 of 3.
# 1. HTML scanlog input --> HTML report output
# 2. HTML scanlog input --> XML report output + XSLT to HTML
# 3. XML scanlog input  --> XML report output + XSLT to HTML
# 
#

#!/usr/bin/perl -w
package GenResult;
use BragStatus;
use GenAutoSmokeTestResult;
use GenPostBuildResult;
use strict;

# global log file locations
# - to be set by main() function
# on module entry
our $iGTLogFileLocation;
our $iTVLogFileLocation;
our $iTVEBSLogFileLocation;
our $iBUILDLogFileLocation;
our $iCBRLogFileLocation;
our $iROMLogFileLocation;
our $iCDBLogFileLocation;
our $iLinkPathLocation;
our $iLogsPublishLocation;
our $iGTFileName;
our $iTVFileName;
our $iTVEBSFileName;
our $iBUILDFileName;
our $iCBRFileName;
our $iROMFileName;
our $iCDBFileName;
our $iBraggflag = 0;

our %iProducts;
our %iTests;
no strict qw($iGTLogFileLocation,
	     $iTVLogFileLocation,
             $iTVEBSLogFileLocation;
	     $iBUILDLogFileLocation,
	     $iCBRLogFileLocation,
	     $iROMLogFileLocation,
           $iCDBLogFileLocation,
	     $iLinkPathLocation,
	     $iLogsPublishLocation,
	     $iGTFileName,
	     $iTVFileName,
             $iTVEBSFileName;
	     $iBUILDFileName,
	     $iCBRFileName,
	     $iROMFileName,
             $iCDBFileName);

my $iGTFileFound    = "1";
my $iTVFileFound    = "1";
my $iTVEBSFileFound = "1";
my $iBUILDFileFound = "1";
my $iCBRFileFound   = "1";
my $iROMFileFound   = "1";
my $iCDBFileFound   = "1";
	


# stores the list of stages
my $iBuildStages = 'GT|TV|ROM|CBR|CDB|BUILD';

# outline style sheet internally  
my $gStyleSheet = " \n

                <style type=\"text/css\">                    
                    h1,h2,h3
                    {
                        font-family: \"arial\", lucida calligraphy, 'sans serif'; 
                    }

                    p,table,li,
                    {
                        font-family: \"arial\", lucida calligraphy, 'sans serif'; 
                        margin-left: 8pt;
                    }

                    body
                    {
                        background-color:#fffaf0;
                    }

                    p,li,th,td
                    {
                        font-size: 10pt;
                        vertical-align:top;
                    }

                    h1,h2,h3,hr {color:#483d8b;}

                    table {border-style:outset}
                    li {list-style: square;}

                    a.hoverlink:link {color: #0000ff; text-decoration: none}
                    a.hoverlink:visited {color: #0000ff; text-decoration: none}
                    a.hoverlink:hover {text-decoration: underline}
                </style>";


##########################################################################
#
# Name    :  getGTResults()
# Synopsis:  To parse a logfile, and output results
#            into a common data format for processing
#
# Inputs  :  None
# Outputs : Array of refs to arrays containing 5 scalars. The structure
#           is then used by the  printResultRow() to display
#
#  1    <array 'container'>
#         |
#  0-n    <array ref>
#            |
#            -- <scalar[0]>  component name
#            -- <scalar[1]>  number of errors
#            -- <scalar[2]>  link to errors
#            -- <scalar[3]>  number of warnings
#            -- <scalar[4]>  link to warnings
#            -- <scalar[5]>  number of advisorynotes
#            -- <scalar[6]>  link to advisorynotes
#
# Note: Links are currently not used, but instead constructed from the
#       component name and logfile location. Can be used in future for
#       logs located elsewhere etc.
##########################################################################
sub getGTResults {
   

    my $iComponent;
    my $iErrors;
    my $iErrorLink;
    my $iWarnings;
    my $iWarningLink;
	my $iAdvisoryNotes;
	my $iAdvisoryNotesLink;
    my $iRemarks;
    my @components;
 
    open (GTLOGFILE, $iGTLogFileLocation) || setHandleErrors($_[0]);
    
    my @iGTLog = <GTLOGFILE>;
    
    foreach (@iGTLog) {
        
        if (m/(Component_)(.*)(\s[0-9]{0,2}:[0-9]{0,2}:[0-9]{0,2}\.?[0-9]{0,3})\s([0-9]*)\s([0-9]*)\s([0-9]*)\s([0-9]*)\s([0-9]*)/) 	    {
            if (($4 != 0) || ($5 !=0) || ($6 != 0)) {
                
                $iComponent = $2;
                $iErrors    = $4;
                $iWarnings  = $5;
                $iAdvisoryNotes = $6;
                $iRemarks   = $7;   # currently we ignore remarks from components.
                
                # now extract the URL for each warning. At the moment, this is a relative link
                # MUST make it absolute, to avoid problems
                
                my @componentdetails = ($iComponent, $iErrors, $iErrorLink, $iWarnings, $iWarningLink, $iAdvisoryNotes, $iAdvisoryNotesLink);
                push @components, \@componentdetails;
            }
			
			
        }
				
        }
    # return array of refs to arrays
    return @components;
}

##########################################################################
#
# Name    :  getTVResults()
# Synopsis:  To parse a logfile, and output results
#            into a common data format for processing
#
# Inputs  :  None
# Outputs : Array of refs to arrays containing 5 scalars. The structure
#           is then used by the  printResultRow() to display
#
#  1    <array 'container'>
#         |
#  0-n    <array ref>
#            |
#            -- <scalar[0]>  component name
#            -- <scalar[1]>  number of errors
#            -- <scalar[2]>  link to errors
#            -- <scalar[3]>  number of warnings
#            -- <scalar[4]>  link to warnings
#            -- <scalar[5]>  number of advisorynotes
#            -- <scalar[6]>  link to advisorynotes
#
# Note: Links are currently not used, but instead constructed from the
#       component name and logfile location. Can be used in future for
#       logs located elsewhere etc.
##########################################################################
sub getTVResults {
    
    my $iComponent;
    my $iErrors;
    my $iErrorLink;
    my $iWarnings;
    my $iWarningLink;
	my $iAdvisoryNotes;
	my $iAdvisoryNotesLink;
    my $iRemarks;
    
    my @components;
    open (TVLOGFILE, $iTVLogFileLocation) || setHandleErrors($_[0]);

    my @iTVLog = <TVLOGFILE>;
    
    foreach (@iTVLog) {
        
        if (m/(Component_)(.*)(\s[0-9]{0,2}:[0-9]{0,2}:[0-9]{0,2}\.?[0-9]{0,3})\s([0-9]*)\s([0-9]*)\s([0-9]*)\s([0-9]*)\s([0-9]*)/) {
             
            if (($4 != 0) || ($5 !=0) || ($6 != 0)) {
                
                $iComponent = $2;
                $iErrors    = $4;
                $iWarnings  = $5;
                $iAdvisoryNotes = $6;
                $iRemarks   = $7;   # currently we ignore remarks from components.
                
                # now extract the URL for each warning. At the moment, this is a relative link
                # MUST make it absolute, to avoid problems
                
                my @componentdetails = ($iComponent, $iErrors, $iErrorLink, $iWarnings, $iWarningLink, $iAdvisoryNotes, $iAdvisoryNotesLink);
                push @components, \@componentdetails;
            }
        }
    }
    
    open (TVEBSLOGFILE, $iTVEBSLogFileLocation) || setHandleErrors($_[0]);
    my @iTVEBSLog = <TVEBSLOGFILE>;
     foreach (@iTVEBSLog) {
        
        if (m/(Component_)(.*)(\s[0-9]{0,2}:[0-9]{0,2}:[0-9]{0,2}\.?[0-9]{0,3})\s([0-9]*)\s([0-9]*)\s([0-9]*)\s([0-9]*)\s([0-9]*)/) {
             
            if (($4 != 0) || ($5 !=0) || ($6 != 0)) {
                
                $iComponent = $2;
                $iErrors    = $4;
                $iWarnings  = $5;
                $iAdvisoryNotes = $6;
                $iRemarks   = $7;   # currently we ignore remarks from components.
                
                # now extract the URL for each warning. At the moment, this is a relative link
                # MUST make it absolute, to avoid problems
                
                my @componentdetails = ($iComponent, $iErrors, $iErrorLink, $iWarnings, $iWarningLink, $iAdvisoryNotes, $iAdvisoryNotesLink);
                push @components, \@componentdetails;
            }
        }
    }
    
    # return array of refs to arrays
    return @components;
}


##########################################################################
#
# Name    :  getBUILDResults()
# Synopsis:  To parse a logfile, and output results
#            into a common data format for processing
#
# Inputs  :  None
# Outputs : Array of refs to arrays containing 5 scalars. The structure
#           is then used by the  printResultRow() to display
#
#  1    <array 'container'>
#         |
#  0-n    <array ref>
#            |
#            -- <scalar[0]>  component name
#            -- <scalar[1]>  number of errors
#            -- <scalar[2]>  link to errors
#            -- <scalar[3]>  number of warnings
#            -- <scalar[4]>  link to warnings
#            -- <scalar[5]>  number of advisorynotes
#            -- <scalar[6]>  link to advisorynotes
#
# Note: Links are currently not used, but instead constructed from the
#       component name and logfile location. Can be used in future for
#       logs located elsewhere etc.
##########################################################################
sub getBUILDResults {
    
    my $iComponent;
    my $iErrors;
    my $iErrorLink;
    my $iWarnings;
    my $iWarningLink;
	my $iAdvisoryNotes;
	my $iAdvisoryNotesLink;
    my $iRemarks;
    
    my @components;
    open (BUILDLOGFILE, $iBUILDLogFileLocation) ||setHandleErrors($_[0]);
    my @iBUILDLog = <BUILDLOGFILE>;
    
    foreach (@iBUILDLog) {
        
        if (m/(Component_)(.*)(\s[0-9]{0,2}:[0-9]{0,2}:[0-9]{0,2}\.?[0-9]{0,3}?)\s([0-9]*)\s([0-9]*)\s([0-9]*)\s([0-9]*)\s([0-9]*)/) {
             
            if (($4 != 0) || ($5 !=0) || ($6 != 0)) {
                
                $iComponent = $2;
                $iErrors    = $4;
                $iWarnings  = $5;
                $iAdvisoryNotes = $6;
                $iRemarks   = $7;   # currently we ignore remarks from components.
                               # now extract the URL for each warning. At the moment, this is a relative link
                # MUST make it absolute, to avoid problems
                
                my @componentdetails = ($iComponent, $iErrors, $iErrorLink, $iWarnings, $iWarningLink, $iAdvisoryNotes, $iAdvisoryNotesLink);
                push @components, \@componentdetails;
            }
        }
    }
    
    # return array of refs to arrays
    return @components;
}

##########################################################################
#
# Name    :  getCBRResults()
# Synopsis:  To parse a logfile, and output results
#            into a common data format for processing
#
# Inputs  :  None
# Outputs : Array of refs to arrays containing 5 scalars. The structure
#           is then used by the  printResultRow() to display
#
#  1    <array 'container'>
#         |
#  0-n    <array ref>
#            |
#            -- <scalar[0]>  component name
#            -- <scalar[1]>  number of errors
#            -- <scalar[2]>  link to errors
#            -- <scalar[3]>  number of warnings
#            -- <scalar[4]>  link to warnings
#            -- <scalar[5]>  number of advisorynotes
#            -- <scalar[6]>  link to advisorynotes
#
# Note: Links are currently not used, but instead constructed from the
#       component name and logfile location. Can be used in future for
#       logs located elsewhere etc.
##########################################################################
sub getCBRResults {
    
    my $iComponent;
    my $iErrors;
    my $iErrorLink;
    my $iWarnings;
    my $iWarningLink;
	my $iAdvisoryNotes;
	my $iAdvisoryNotesLink;
    my $iRemarks;
    
    my @components;
    open (CBRLOGFILE, $iCBRLogFileLocation) || setHandleErrors($_[0]);

    my @iCBRLog = <CBRLOGFILE>;
    
    foreach (@iCBRLog) {
        
        if (m/(Overall_Total\s)([0-9]{0,2}:[0-9]{0,2}:[0-9]{0,2})\s([0-9]*)\s([0-9]*)\s([0-9]*)\s([0-9]*)\s([0-9]*)/) {
            if (($3 != 0) || ($4 !=0) || ($5 != 0)) {
                                
                $iComponent = "Total";
                $iErrors    = $3;
                $iWarnings  = $4;
                $iAdvisoryNotes = $5;
                $iRemarks   = $6;   # currently we ignore remarks from components.
                
                # now extract the URL for each warning. At the moment, this is a relative link
                # MUST make it absolute, to avoid problems
                
                my @componentdetails = ($iComponent, $iErrors, $iErrorLink, $iWarnings, $iWarningLink, $iAdvisoryNotes, $iAdvisoryNotesLink);
                push @components, \@componentdetails;
            }
        }
    }
    
    # return array of refs to arrays
    return @components;
}

##########################################################################
#
# Name    :  getROMResults()
# Synopsis:  To parse a text logfile, and output results
#            into a common data format for processing
#
# Inputs  :  None
# Outputs : Array of refs to arrays containing 5 scalars. The structure
#           is then used by the  printResultRow() to display
#
#  1    <array 'container'>
#         |
#  0-n    <array ref>
#            |
#            -- <scalar[0]>  component name
#            -- <scalar[1]>  number of errors
#            -- <scalar[2]>  link to errors
#            -- <scalar[3]>  number of warnings
#            -- <scalar[4]>  link to warnings
#            -- <scalar[5]>  number of advisorynotes
#            -- <scalar[6]>  link to advisorynotes
#
##########################################################################
sub getROMResults {
    
    my $iComponent;
    my $iErrors;
    my $iErrorLink;
    my $iWarnings;
    my $iWarningLink;
	my $iAdvisoryNotes;
	my $iAdvisoryNotesLink;
    my $iRemarks;
    my @components;
    open (ROMLOGFILE, $iROMLogFileLocation) || setHandleErrors($_[0]);

    my @iROMLog = <ROMLOGFILE>;
    
    # special kludge to deal with multi-line errors from ROMBUILD!
    #
    my $i = 0;
    my @iSingleLineErrors;
    
    foreach (@iROMLog) {
        ++$i;
        if ((m/ERROR: Can't build dependence graph for/) ||
            (m/ERROR: Can't resolve dll ref table for/)) {
        
            # read 4 lines for the single error
            my $iErr = $_ . $iROMLog[$i].$iROMLog[$i+1].$iROMLog[$i+2].$iROMLog[$i+3];
            $iErr =~ s/\t|\n/ /g; # replace tabs and newlines with a space

            # remove multi-line error, so that we dont process it twice
            $iROMLog[$i-1] = "";
            $iROMLog[$i]   = "";
            $iROMLog[$i+1] = "";
            $iROMLog[$i+2] = "";
            $iROMLog[$i+3] = "";
            
            push @iSingleLineErrors, $iErr;
        }
    }
    
    # now merge two arrays before processing
    push (@iROMLog, @iSingleLineErrors);
    
    
    # identify unique lines in log, as errors
    # are repeated for each ROM built
    my %iSeenLines = ();
    foreach my $iUniqueItem (@iROMLog) {
        $iSeenLines{$iUniqueItem}++;
    }
    my @iUniqueLogList = keys %iSeenLines;
    
    foreach (@iUniqueLogList) {
	if((m/WARNING: Sorting Rom Exception Table/) ||
           (m/WARNING: DEMAND PAGING ROMS ARE A PROTOTYPE FEATURE ONLY/)) {
           my @componentdetails = ($_, "", $iErrorLink, "", $iWarningLink);
           push @components, \@componentdetails;
        } elsif ((m/Missing/) || (m/Invalid Resource name/) || (m/warning:/) || (m/WARNING:/)) {
           my @componentdetails = ($_, "", $iErrorLink, "1", $iWarningLink);
                        
            push @components, \@componentdetails;   
        }
        
        if ((m/ERROR: Can't build dependence graph for/) ||
            (m/ERROR: Can't resolve dll ref table for/) ||
            (m/cpp failed/i) ||
            (m/cannot find oby file/i) ||
            (m/no such file or directory/i)) {
            
            my @componentdetails = ($_, "1", $iErrorLink, "", $iWarningLink);
            push @components, \@componentdetails;   
        } elsif (m/ERROR/) {
            my @componentdetails = ($_, "1", $iErrorLink, "", $iWarningLink);
            push @components, \@componentdetails;   
        }
    }   
    
    return @components;
}

##########################################################################
#
# Name    :  getCDBResults()
# Synopsis:  To parse a logfile, and output results
#            into a common data format for processing
#
# Inputs  :  None
# Outputs : Array of refs to arrays containing 5 scalars. The structure
#           is then used by the  printResultRow() to display
#
#  1    <array 'container'>
#         |
#  0-n    <array ref>
#            |
#            -- <scalar[0]>  component name
#            -- <scalar[1]>  number of errors
#            -- <scalar[2]>  link to errors
#            -- <scalar[3]>  number of warnings
#            -- <scalar[4]>  link to warnings
#            -- <scalar[5]>  number of advisorynotes
#            -- <scalar[6]>  link to advisorynotes
#
# Note: Links are currently not used, but instead constructed from the
#       component name and logfile location. Can be used in future for
#       logs located elsewhere etc.
##########################################################################
sub getCDBResults {
   

    my $iComponent;
    my $iErrors;
    my $iErrorLink;
    my $iWarnings;
    my $iWarningLink;
	my $iAdvisoryNotes;
	my $iAdvisoryNotesLink;
    my $iRemarks;
    my @components;
 
    open (CDBLOGFILE, $iCDBLogFileLocation) || setHandleErrors($_[0]);
    
    my @iCDBLog = <CDBLOGFILE>;
    
    foreach (@iCDBLog) {
        
        if (m/(Component_)(.*)(\s[0-9]{0,2}:[0-9]{0,2}:[0-9]{0,2}\.?[0-9]{0,3})\s([0-9]*)\s([0-9]*)\s([0-9]*)\s([0-9]*)\s([0-9]*)/) 	    {
            if (($4 != 0) || ($5 !=0) || ($6 != 0)) {
                
                $iComponent = $2;
                $iErrors    = $4;
                $iWarnings  = $5;
				$iAdvisoryNotes = $6;
                $iRemarks   = $7;   # currently we ignore remarks from components.
                
                # now extract the URL for each warning. At the moment, this is a relative link
                # MUST make it absolute, to avoid problems
                my @componentdetails = ($iComponent, $iErrors, $iErrorLink, $iWarnings, $iWarningLink, $iAdvisoryNotes, $iAdvisoryNotesLink);
                push @components, \@componentdetails;
				
            }
			}			
		}
	
	# return array of refs to arrays
    return @components;
}

##########################################################################
#
# Name    :  getResults()
# Synopsis:  Factory like function to return an associated data structure
#            depending on the type requested. i.e. GT, TV etc.
#  
# Inputs  :  Scalar containing the log/type required
# Outputs :  The output of getXXXResults() functions.
#
#  1    <array 'container'>
#         |
#  0-n    <array ref>
#            |
#            -- <scalar[0]>  component name
#            -- <scalar[1]>  number of errors
#            -- <scalar[2]>  link to errors
#            -- <scalar[3]>  number of warnings
#            -- <scalar[4]>  link to warnings
#            -- <scalar[5]>  number of advisorynotes
#            -- <scalar[6]>  link to advisorynotes
#
##########################################################################
sub getResults {
    
    if ($_[0] eq "GT") {
        return getGTResults($_[0]); }
    
    if ($_[0] eq "TV") {
        return getTVResults($_[0]); }
    
    if ($_[0] eq "BUILD") {
        return getBUILDResults($_[0]); }
    
    if ($_[0] eq "CBR") {
        return getCBRResults($_[0]); }
   
    if ($_[0] eq "ROM") {
        return getROMResults($_[0]); }
    
    if ($_[0] eq "CDB") {
        return getCDBResults($_[0]); }

}

##########################################################################
#
# Name    :  getLogFileLocation()
# Synopsis:  Accessor like function, to return the expected log file
#            location that is initialised in GenResult::main()
#
# Inputs  :  Scalar containing the log/type required
# Outputs : Scalar containing the log location
#
##########################################################################
sub getLogFileLocation {
    
    if ($_[0] eq "GT") {
        return setBrowserFriendlyLinks($iLinkPathLocation.$iGTFileName); }
    
    if ($_[0] eq "TV") {
        if($_->[0]=~ /systemtest/i) {
              return setBrowserFriendlyLinks($iLinkPathLocation.$iTVEBSFileName);}
        else {   
        return setBrowserFriendlyLinks($iLinkPathLocation.$iTVFileName); }
        }
    
    if ($_[0] eq "BUILD") {
        return setBrowserFriendlyLinks($iLinkPathLocation.$iBUILDFileName); }
    
    if ($_[0] eq "CBR") {
        return setBrowserFriendlyLinks($iLinkPathLocation.$iCBRFileName); }
        
    if ($_[0] eq "ROM") {
        return $iLinkPathLocation.$iROMFileName; }

    if ($_[0] eq "CDB") {
        return setBrowserFriendlyLinks($iLinkPathLocation.$iCDBFileName); }
		
}

##########################################################################
#
# Name    :  getAnchorType()
# Synopsis:  Helper function, to return the HTML scanlog anchor for
#            a desired log type.
#
# Inputs  :  Scalar containing the log/type required
# Outputs :  Scalar containing the HTML anchor 
#
##########################################################################
sub getAnchorType {
    
    if ($_[0] eq "GT") {
        return "Component"; }
    
    if ($_[0] eq "TV") {
        return "Component"; }
    
    if ($_[0] eq "BUILD") {
        return "Component"; }
    
    if ($_[0] eq "CBR") {
        return "Overall"; }
        
    if ($_[0] eq "CDB") {
        return "Overall"; }

}

##########################################################################
#
# Name    :  isHTMLFile()
# Synopsis:  Identifies which log files should be processed as HTML
#
# Inputs  :  Scalar containing the log/type required
# Outputs :  "1" if the requested log is HTML
#
##########################################################################
sub isHTMLFile {
    
    if ($_[0] eq "GT" || $_[0] eq "TV" || $_[0] eq "BUILD" || $_[0] eq "CBR"  || $_[0] eq "CDB") {
        return "1"; }
}

##########################################################################
#
# Name    :  isTestBuild()
# Synopsis:  Identifies if this report is being generated for a test build
#
# Inputs  :  Global scalar for linkto location
# Outputs :  "1" if the build is being published as a testbuild. This will
#            obviously fail if testbuilds are not correctly published to
#            \\builds01\devbuilds\test_builds
#
##########################################################################
sub isTestBuild {
    
    # somehow, determine if this is a TBuild
    if (uc($iLinkPathLocation) =~ m/TEST_BUILD/) {
        return "1";
    }
    
    return "0";
}


##########################################################################
#
# Name    :  setBrowserFriendlyLinks()
# Synopsis:  Re-formats UNC path to file, with a Opera/Fire-Fox friendly
#            version. Lotus Notes may cause problems though.
# Inputs  :  UNC Path scalar
# Outputs :  Scalar
#
##########################################################################
sub setBrowserFriendlyLinks {
    my ($iOldLink) = @_;
    
    $iOldLink =~ s/\\/\//g;  # swap backslashes to fwd slashes
    return "file:///".$iOldLink;
}

##########################################################################
#
# Name    :  setBrowserFriendlyLinksForIN()
# Purpose:  Generate Links for Bangalore Site
# Inputs  :  UNC Path scalar
# Outputs :  Scalar
#
##########################################################################

sub setBrowserFriendlyLinksForIN($ ) {
    my ($iOldLinkIN) = shift;
    
    $iOldLinkIN =~ s/\\/\//g;  # swap backslashes to fwd slashes
    $iOldLinkIN = "file:///".$iOldLinkIN ;
    $iOldLinkIN =~ s/builds01/builds04/ ;  # Generate Bangalore Log Location
    return $iOldLinkIN;
}

##########################################################################
#
# Name    :  setBrowserFriendlyLinksForCN()
# Purpose:  Generate Links for Beijing Site
# Inputs  :  UNC Path scalar
# Outputs :  Scalar
#
##########################################################################

sub setBrowserFriendlyLinksForCN($ ) {
    my ($iOldLinkCN) = shift;
    
    $iOldLinkCN =~ s/\\/\//g;  # swap backslashes to fwd slashes
    $iOldLinkCN = "file:///".$iOldLinkCN ;
    $iOldLinkCN =~ s/builds01/builds05/ ;  # Generate Beijing Log Location
    return $iOldLinkCN;
}

# helper function for formatting
sub printSubmissionsLink {
    
    my ($iSnapshot) = @_;
    
    if (isTestBuild() eq "0") {
        return "[ <a class =\"hoverlink\" href = \"http://lon-engbuild08/bis-cgi/BIS_buildchanges.pl?first=$iSnapshot\"> Submissions</a>  ]";
    }
}

# helper function for formatting
sub printDefectsColumn {
        
    if (isTestBuild() eq "0") {    
        return "<th width=\"15%\"><font color=\"#ffffff\">Defects</font></th>";
    }
}

# helper function to notify of any missing logs
sub setHandleErrors {
    
    # set global filenotfound to "0"
    
    if ($_[0] eq "GT") {
        $iGTFileFound    = "0"; }
    
    if ($_[0] eq "TV") {
        $iTVFileFound    = "0"; }
    
    if ($_[0] eq "TV") {
        $iTVEBSFileFound = "0"; }
    
    if ($_[0] eq "BUILD") {
        $iBUILDFileFound = "0"; }
    
    if ($_[0] eq "CBR") {
        $iCBRFileFound   = "0"; }
        
    if ($_[0] eq "ROM") {
        $iROMFileFound   = "0"; }
    
    if ($_[0] eq "CDB") {
        $iCDBFileFound   = "0"; }

}

# accessor function to return the flag for this type
sub getHandleErrors {
    
    if ($_[0] eq "GT") {
        return $iGTFileFound; }
    
    if ($_[0] eq "TV") {
        return $iTVFileFound; }
    
    if ($_[0] eq "TV") {
        return $iTVEBSFileFound; }
        
    if ($_[0] eq "BUILD") {
        return $iBUILDFileFound; }
    
    if ($_[0] eq "CBR") {
        return $iCBRFileFound; }
    
    if ($_[0] eq "ROM") {
        return $iROMFileFound; }

    if ($_[0] eq "CDB") {
        return $iCDBFileFound; }
}


##########################################################################
#
# Name    :  printResultRow()
# Synopsis:  Creates each HTML row for the build report. If the log file
#            being processed is HTML, then HTML links are generated also.
#            Plain text log files will just include output as specified
#            in the regexp for associated getXXXResults() functions.
#
# Inputs  :  Scalar containing the log/type required
# Outputs :  Scalar containing HTML row string to be inserted into
#            the build report
##########################################################################
sub printResultRow {
    
    my ($iLogFile, $iStage, $iStagesFromFile) = @_;
    my $iResultRowHolder;
    my $iResultRow;
    
    # The hash holds values of the stages as array which are completed in the report.html file 
    # so that older values in report.html file can be preserved.
    my %iStagesFromFileInHash = %{$iStagesFromFile} if defined ($iStagesFromFile);
    
    # get result        
    my $iCount = "0";
        $iResultRowHolder =
         "\n
          <tr>
            <th bgcolor=\"#006699\" width =\"5%\" align =\"left\"> <font color=\"#ffffff\">$iLogFile</font></th>
            <td width=\"15%\" align = \"left\">";
    
    # prints the build results extracted from old report.html file.
    # Below code looks into the hash for stages whose results(Errors) are already calculated, and proceeds 
    # computing results for next $iStage in xml file. 
    if (defined ($iStagesFromFile) and defined ($iStagesFromFileInHash{$iLogFile})) {
	$iResultRowHolder = $iResultRowHolder . ${$iStagesFromFileInHash{$iLogFile}}[0];
    }elsif (!getHandleErrors($iLogFile) or "$iLogFile" ne "$iStage") {
        $iResultRowHolder = $iResultRowHolder . "Stage not completed";
    }else {    
    	foreach (getResults($iLogFile)) {
        undef $iResultRow;
        if ($_->[1] != "0") {
            if (isHTMLFile($iLogFile)) {
                $iResultRow = "<a class =\"hoverlink\" href =\"" .
                               getLogFileLocation($iLogFile,$_->[0])     .
                               "#errorsBy"                       .
                               getAnchorType($iLogFile)          .
                               "_$_->[0]\">$_->[0]\ ($_->[1]\) <br></a>";
            }
            else {
                $iResultRow = "<li>". $_->[0];
		chomp $iResultRow;
            }
            ++$iCount;
        }
         
         $iResultRowHolder = $iResultRowHolder . $iResultRow;
        }
         # zero errors, means 'None' is displayed
         if ($iCount == "0"){
            $iResultRowHolder = $iResultRowHolder . "None";
	}
    } 
         
    $iResultRowHolder = $iResultRowHolder . "</td>\n<td width=\"15%\" align = \"left\">";
         
    $iCount = "0";
    # print build results extracted from old report.html file.
    # Below code looks into the hash for stages whose results(Warnings) are already calculated, and proceeds 
    # computing results for next $iStage in xml file.
    if (defined ($iStagesFromFile) and defined ($iStagesFromFileInHash{$iLogFile})) {
	    $iResultRowHolder = $iResultRowHolder . ${$iStagesFromFileInHash{$iLogFile}}[1];
    }elsif (!getHandleErrors($iLogFile) || "$iLogFile" ne "$iStage") { 
            $iResultRowHolder = $iResultRowHolder . "Stage not completed";
    }else {
        foreach (getResults($iLogFile)) {
        undef $iResultRow;         
        if ($_->[3] != "0") {
            if (isHTMLFile($iLogFile)) {
                $iResultRow = "<a class =\"hoverlink\" href =\"" .
                               getLogFileLocation($iLogFile)     .
                               "#warningsBy"                     .
                               getAnchorType($iLogFile)          .
                               "_$_->[0]\">$_->[0]\ ($_->[3]\) <br></a>";
            }
            else {
                $iResultRow = "<li>".$_->[0];
		chomp $iResultRow;
            }
            ++$iCount;
        }


        $iResultRowHolder = $iResultRowHolder . $iResultRow;
        }
        
        # zero warnings, means 'None' is displayed
        if ($iCount == "0"){
            $iResultRowHolder = $iResultRowHolder . "None";
        }
    }

	$iResultRowHolder = $iResultRowHolder . "</td>\n<td width=\"15%\" align = \"left\">";
         
    $iCount = "0";
    # print build results extracted from old report.html file.
    # Below code looks into the hash for stages whose results(AdvisoryNotes) are already calculated, and proceeds 
    # computing results for next $iStage in xml file.
    if (defined ($iStagesFromFile) and defined ($iStagesFromFileInHash{$iLogFile})) {
	    $iResultRowHolder = $iResultRowHolder . ${$iStagesFromFileInHash{$iLogFile}}[2];
    }elsif (!getHandleErrors($iLogFile) || "$iLogFile" ne "$iStage") { 
            $iResultRowHolder = $iResultRowHolder . "Stage not completed";
    }else {
        foreach (getResults($iLogFile)) {
        undef $iResultRow;         
        if ($_->[5] != "0") {
            if (isHTMLFile($iLogFile)) {
                $iResultRow = "<a class =\"hoverlink\" href =\"" .
                               getLogFileLocation($iLogFile)     .
                               "#AdvisoryNotesBy"                     .
                               getAnchorType($iLogFile)          .
                               "_$_->[0]\">$_->[0]\ ($_->[5]\) <br></a>";
            }
            else {
                $iResultRow = "<li>".$_->[0];
		chomp $iResultRow;
            }
            ++$iCount;
			$iBraggflag = 1;
        }
        
        $iResultRowHolder = $iResultRowHolder . $iResultRow;
        }
        
        # zero warnings, means 'None' is displayed
        if ($iCount == "0"){
            $iResultRowHolder = $iResultRowHolder . "None";
        }
    }
    $iResultRowHolder = $iResultRowHolder . "</td>\n<td>&nbsp;</td> \n</tr>\n";

    return $iResultRowHolder;    
}
##########################################################################
#
# Name    :  extractOldResults()
# Synopsis:  Extracts the old results of different stages which are already generated
# Inputs  :  Filename of report.html along with complete path 
# Outputs :  Returns a reference to hash whose keys are stages and values are values from html file.
##########################################################################
sub extractOldResults	{
	my $iFileName = shift @_;
	my $iFlag = 0;
	my @lines;
	my %iStages;
	
	open FILE, "$iFileName" or die "Can't open $iFileName: $!\n";
	@lines = <FILE>;
	close FILE;
	
	my $iStagesToFetch = $iBuildStages;
	my $iCurrentStage = '';
	my @iStageValues = ();

	foreach (@lines )	{
		if ($iFlag == 1 and /<\/tr>/i)	{
			my $iCurrentStageValues = "@iStageValues";
			$iStages{$iCurrentStage} = [@iStageValues] if ($iCurrentStageValues !~ /(Stage not completed *){2}/);
			$iFlag = 0;
		}
		
		if ($iFlag == 1)	{
			push (@iStageValues, $1) if (/left">(.+?)<\/td>/);
		}
		
		if (/>($iStagesToFetch)</)	{
			@iStageValues = ();
			$iFlag = 1;
			$iCurrentStage = $1;
		}
	}
	return \%iStages;
}

##########################################################################
#
# Name    :  generateHTMLSummary()
# Synopsis:  Creates an HTML report for the specified build.
# Inputs  :  Scalar containing the build snapshot and product type
# Outputs :  HTML report, published in current working dir
##########################################################################
sub generateHTMLSummary {
    
    my ($iDir, $iSnapshot, $iProduct, $iLinkPath, $iStage, $iBrag, $imail) = @_;

    #Get Brag Status of Build and generate PostBuild results
    my $iPostBuildResult;
    if (defined($iBrag) and "$iBrag" eq "FINAL") {
	$iBrag = &BragStatus::main($iDir, $iSnapshot, $iProduct, $iLinkPath);
    $iPostBuildResult=&GenPostBuildResult::generatesPostBuildSummary($iLogsPublishLocation, $iLinkPathLocation, $iProduct, $iSnapshot, $imail);
    } else {
	$iBrag = "TBA";
    }
    # change to roms\techview dir for roms link
    my $iROMLocation = $iLogsPublishLocation;
    $iROMLocation =~s/logs/roms\\techview/g;
          
    # check to see of the report.html already exists to extract previous results
    my ($iStagesFromFile);
    my $iReportFileNameWithPath = "$iSnapshot"."_"."$iProduct"."_report.html";
    if (-f $iReportFileNameWithPath) {
	    $iStagesFromFile = extractOldResults($iReportFileNameWithPath) ;
	    print "Updating ".$iSnapshot."_".$iProduct."_report.html\n ";
    } else {
	print "Creating ".$iSnapshot."_".$iProduct."_report.html\n "
    }
    open (SUMMARY, "+> $iSnapshot"."_"."$iProduct"."_report.html") or die "ERROR:Can't open file : $!";

    # Build the final result string before generating report.html file.
    # Builds ResultString based on command line input.  
    # All => Generates results for all the stages
    
    my $printResult = "";
    my $iResultString = "";
    foreach my $iType (split /\|/, $iBuildStages) {
	    if ("$iStage" eq "ALL"){
		$iResultString = printResultRow($iType, $iType, $iStagesFromFile);
	    }
	    else{
		$iResultString = printResultRow($iType, $iStage, $iStagesFromFile);
	    }# pass iStage here & iStagesFromFile.
	    $printResult = $printResult . $iResultString;
    }
    #Calculate the new external status BRAGG(Black Red Amber Green Gold)
	my $iBragg;
	if("$iBrag" eq "Green" && $iBraggflag eq 0)
	{
    $iBragg = "Gold";
	} else {
    $iBragg = $iBrag;
	}
    my $html_start = "\n
                    <HTML>
                    <HEAD>" .
                    $gStyleSheet .
                    "<TITLE>" . "$iSnapshot "."$iProduct ". "Build Report</TITLE>
                    
                    <BODY BGCOLOR=\"FFFFFF\">
                    </HEAD>
                    <BODY>
                    <TABLE width=\"100%\" border =\"1\" cellpadding=\"0\">
                    <TR><TD bgcolor=\"#006699\"><font color=\"#FFFFFF\"><font size=\"5\">
                    <B>" . "$iSnapshot "."$iProduct ". "Build Report "."</B>
                    <br><i><b><font size=\"3\">Build Status  : $iBrag </font></b></i>
                    <br><i><b><font size=\"3\">BRAGG  : $iBragg </font></b></i>
                    <br><i><font size=\"3\">Released By : </font></i>
                    <br><i><font size=\"3\">Reason : </font></i>
                    </TD></TR>
                    </TABLE>
                    
                    <font size=\"2\"><p>
                        [ <a class =\"hoverlink\" href = \"http://web.intra/Softeng/SwE/prodintegbuild/integration/System_Build/BuildResults.html\"> Help</a>  ]
                        [ Logs <a class =\"hoverlink\" href = \"" . setBrowserFriendlyLinks($iLinkPathLocation)."\"> UK </a>  <a class =\"hoverlink\" href = \"" . setBrowserFriendlyLinksForCN($iLinkPath )."\"> CN </a>   <a class =\"hoverlink\" href = \"" . setBrowserFriendlyLinksForIN($iLinkPath )."\"> IN </a> ]
                        [ <a class =\"hoverlink\" href = \"http://web.intra/Softeng/SwE/prodintegbuild/integration/docs/guides/CBR_Archive_Guide.html\"> CBR Setup</a>  ] 
                        ".
                                        
                        "</p>
                        <br> <i>Results Generated On ".localtime()."</i>
                    </font><br><br>".

                    "<br><table border=\"1\" cellpadding=\"0\" cellspacing=\"0\" width=\"100%\" align=\"top\">
                    <tr bgcolor=\"#006699\" align=\"top\"><th colspan=5><font color=\"#ffffff\">Build Results</font></th></tr>
                      <tr bgcolor=\"#006699\" align=\"top\">
                          <th width=\"10%\"></th>
                          <th width=\"15%\"><font color=\"#ffffff\">Errors</font></th>
                          <th width=\"15%\"><font color=\"#ffffff\">Warnings</font></th>
						  <th width=\"15%\"><font color=\"#ffffff\">Advisorynotes</font></th>" .
                          printDefectsColumn() .
                      "</tr>" .
                   
                        $printResult.
 				 
			    "</table><br>"
  
                   .&GenAutoSmokeTestResult::generateSTHTMLSummary($iLogsPublishLocation."AutoSmokeTest", $iSnapshot, $iProduct, $iLinkPathLocation."AutoSmokeTest").
		      
		       $iPostBuildResult.
		       
                      "</BODY>
                      </html>
                      ";
                      
                      
    print SUMMARY $html_start;
    
    close SUMMARY;
}



# Entry point into the GenResult module
sub main
{
    my ($iDir, $iSnapshot, $iProduct, $iLinkPath, $iStage, $iBrag, $imail) = @_;
    
    # set file names, so that they can be accessed globally
    $iGTFileName    = "GT.summary.html";
    $iTVFileName    = "TV.summary.html";
    $iTVEBSFileName = "TV.EBS.summary.html";
    $iBUILDFileName = "$iSnapshot"."_Symbian_OS_v"."$iProduct".".summary.html";
    $iCBRFileName   = "$iSnapshot"."_Symbian_OS_v"."$iProduct"."_cbr.summary.html";
    $iCDBFileName   = "$iSnapshot"."_Symbian_OS_v"."$iProduct"."_cdb.summary.html";
    $iROMFileName   = "techviewroms"."$iSnapshot"."_Symbian_OS_v"."$iProduct". ".log";
	
    
    
    $iDir =~  s/[^\\]$/$&\\/; #add trailing backslash, if missing
    $iLogsPublishLocation  = $iDir;
    

    if (-e $iLinkPath) {
        $iLinkPathLocation = $iLinkPath;
    } else {
        # if no link path is specified, then use current directory location
        #print "WARNING:" .$iLinkPath. " does not exist, linking with relative paths\n";
        $iLinkPathLocation = $iLogsPublishLocation;
    }
    
    if (-e $iLogsPublishLocation) {
        
        $iGTLogFileLocation      = $iLogsPublishLocation.$iGTFileName;
        $iTVLogFileLocation      = $iLogsPublishLocation.$iTVFileName;
        $iTVEBSLogFileLocation   = $iLogsPublishLocation. $iTVEBSFileName;
        $iBUILDLogFileLocation   = $iLogsPublishLocation.$iBUILDFileName;
        $iCBRLogFileLocation     = $iLogsPublishLocation.$iCBRFileName;
        $iROMLogFileLocation     = $iLogsPublishLocation.$iROMFileName;
        $iCDBLogFileLocation     = $iLogsPublishLocation.$iCDBFileName;
		
        

        &generateHTMLSummary($iDir, $iSnapshot, $iProduct, $iLinkPath, $iStage, $iBrag, $imail);
        
    }
    else {
        die "ERROR: Report not created: $! \n";
    }
}
1;
