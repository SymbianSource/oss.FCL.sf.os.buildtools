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
# Script that returns the no.of errors, Warnings and Advisory notes for a stage.
# 
#

#!/usr/bin/perl -w
package FaultsData;
#~ use BragStatus;
use strict;
use Date::Calc;

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

my $iGTFileFound    = "1";
my $iTVFileFound    = "1";
my $iTVEBSFileFound = "1";
my $iBUILDFileFound = "1";
my $iCBRFileFound   = "1";
my $iROMFileFound   = "1";
my $iCDBFileFound   = "1";


# stores the list of stages
my $iBuildStages = 'GT|TV|ROM|CBR|CDB|BUILD';

sub stageSummary {
    my ($iDir, $iSnapshot, $iProduct, $iLinkPath, $iStage) = @_;
    my $temp = "";
    if($iStage ne "PREBUILD")
    {
      ##############extract Errors Now################
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
      
      if (-e $iLogsPublishLocation) 
      {
          $iGTLogFileLocation      = $iLogsPublishLocation.$iGTFileName;
          $iTVLogFileLocation      = $iLogsPublishLocation.$iTVFileName;
          $iTVEBSLogFileLocation   = $iLogsPublishLocation.$iTVEBSFileName;
          $iBUILDLogFileLocation   = $iLogsPublishLocation.$iBUILDFileName;
          $iCBRLogFileLocation     = $iLogsPublishLocation.$iCBRFileName;
          $iROMLogFileLocation     = $iLogsPublishLocation.$iROMFileName;
          $iCDBLogFileLocation     = $iLogsPublishLocation.$iCDBFileName;
          
          my @Components = extractErrors($iStage);
          if(@Components)
          {
            #~ foreach my $t (@Components)
            #~ {
              #~ print "FAULTS::@$t[0]\t@$t[1]\t@$t[2]\t@$t[3]\t@$t[4]\t@$t[5]\t@$t[6]\n";
            #~ }
            return @Components;
          }
          #############Update Log Files Locations######################
          getLogFileLocation($iStage)
      }
      else
      {
          print "ERROR: Report not created: $! \n";
      }
    }
}

sub getTime
{
    my ($sec,$min,$hours,$mday,$mon,$year)= localtime();
    $year += 1900;
    $mon +=1;
    my @date = ($year,$mon,$mday,$hours,$min,$sec);
    my $date = sprintf("%d-%02d-%02dT%02d:%02d:%02d", @date);
    return ($date);
}

#------------------------------------------------------------------Functions form GenResult.pm--------------------------------------------------------------
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
    open (CDBLOGFILE, $iCDBLogFileLocation) || warn "RIZ::$!:$iCDBLogFileLocation\n";
    
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
                my @componentdetails = ($iComponent, $iErrors, $iErrorLink, $iWarnings, $iAdvisoryNotes, $iAdvisoryNotesLink);
                push @components, \@componentdetails;
				
            }
			}			
        
		if (m/(Component_)(.*)(\s[0-9]{0,2}:[0-9]{0,2}:[0-9]{0,2}\s([0-9]*)\s([0-9]*)\s([0-9]*)\s([0-9]*))/) 	    {
			if (($4 != 0) || ($5 !=0) || ($6 != 0)) {
                
                $iComponent = $2;
                $iErrors    = $4;
                $iWarnings  = $5;
				$iAdvisoryNotes = $6;
                $iRemarks   = $7;   
                # This  has been added to check the errors which have time in '0:00:00' format.
                # now extract the URL for each warning. At the moment, this is a relative link
                # MUST make it absolute, to avoid problems
                my @componentdetails = ($iComponent, $iErrors, $iErrorLink, $iWarnings, $iAdvisoryNotes, $iAdvisoryNotesLink);
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
#~ sub getResults {
sub extractErrors {
    
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

1;
