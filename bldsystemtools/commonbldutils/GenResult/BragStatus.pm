# Copyright (c) 2005-2009 Nokia Corporation and/or its subsidiary(-ies).
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
# Script summarise and hotlink logfiles by reading
# HTMLscanlog generated files
# This initial version is phase 1 of 3.
# 1. HTML scanlog input --> HTML report output
# 2. HTML scanlog input --> XML report output + XSLT to HTML
# 3. XML scanlog input  --> XML report output + XSLT to HTML
# 
#

#!/usr/bin/perl -w
package BragStatus;
use FindBin;
use FileRead;
require GenResult;
use strict;

use constant SINGLE_SMOKETEST_FAILURE   => 1;
use constant PLATFORM_SMOKETEST_FAILURE => 2;
use constant PLATFORM_SMOKETEST_SUCCESS => 0;

my $gBragStatus = "Green";
my $iHTMLFileName = "testlog.html";
my $iTraceFileName = "trace.txt";
my $iDevkitFileName = "Devkit\.log";

my $iCfgFileLocation = $FindBin::Bin;
#Read in the products from a cfg file
my $text = FileRead::file_read("$iCfgFileLocation\\Product_AutoSmokeTest.cfg");
my %iProducts = $text =~ /^\s*(\w+\.?\w+)\s*=\s*(.+)$/mg ;
#Read in the smoketest list from a cfg file
my $Smoketext = FileRead::file_read ("$iCfgFileLocation\\AutoSmoketests.cfg");
my %iTests = $Smoketext =~ /^\s*(\w+\s*\w*\s*)=\s*(.+)$/mg ;

my $iNumberOfTests = scalar(my @iTempArray = values %iTests);
my $iLogsPublishLocation = "";

# Entry point into the BragStatus module
sub main
{
    my ($iDir, $iSnapshot, $iProduct, $iLinkPath) = @_;
    # set file names, so that they can be accessed globally
    ${GenResult::iGTFileName}    = "GT.summary.html";
    ${GenResult::iTVFileName}    = "TV.summary.html";
    ${GenResult::iBUILDFileName} = "$iSnapshot"."_Symbian_OS_v"."$iProduct".".summary.html";
    ${GenResult::iCBRFileName}   = "$iSnapshot"."_Symbian_OS_v"."$iProduct"."_cbr.summary.html";
    ${GenResult::iROMFileName}   = "techviewroms"."$iSnapshot"."_Symbian_OS_v"."$iProduct". ".log";
   
    my $iLinkPathLocation = "";
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
     #Set the Files for the Smoketest package 
     ${GenResult::iGTLogFileLocation}    = $iLogsPublishLocation.${GenResult::iGTFileName};
     ${GenResult::iTVLogFileLocation}    = $iLogsPublishLocation.${GenResult::iTVFileName};
     ${GenResult::iBUILDLogFileLocation} = $iLogsPublishLocation.${GenResult::iBUILDFileName};
     ${GenResult::iCBRLogFileLocation}   = $iLogsPublishLocation.${GenResult::iCBRFileName};
     ${GenResult::iROMLogFileLocation}   = $iLogsPublishLocation.${GenResult::iROMFileName};

     #################################### 
     #BUILD RESULTS 
     ####################################
     CheckBuildResults();
     }
    else
     {
     #Something is seriously wrong if there is no logs
     setBragStatus("Black");
     }

    ###############################
    #SMOKETEST
    ###############################
    CheckSmokeTest($iProduct, $iSnapshot."_Symbian_OS_v".$iProduct);
    ###############################
    CheckDevkit($iProduct);
    #CBR EXIST
    ###############################
    CheckCBRs($iProduct, $iSnapshot);	
    return $gBragStatus;
}

#########################################################
# Name:CheckSmokeTest
# Input: Product
# Outout: None
# Description: Checks the smoketest tables for any errors
#########################################################
sub CheckSmokeTest
{
    my $iProduct  = shift;
    my $iFileName = shift;
    my $iResult = 0;
    my @iProductList = ($iProducts{$iProduct} =~ m/\S+/ig);
    my $iplatform_counter = 0;

     
    # Parse results from dabs/autorom smoketest solution
    # Passing 1 as the second argument ensures that the function acts for brag status only.
    $iResult = &GenAutoSmokeTestResult::printSTResultRow(1,($iLogsPublishLocation."AutoSmokeTest\\"),@iProductList);

    if($iResult == 1)
    {
        #Some tests failed for $iPlatform
        setBragStatus("Amber");
    }
    if($iResult == 2)
    {
        #Platform Failure
        setBragStatus("Red");
    }
    
    if($iResult == -1)
    {
        # BRAG status set to TBA as smoke tests do not appear to have been run 
        setBragStatus("TBA");
    }
}

###########################################
#Name: CheckBuildResults
#inputs :None
#Outputs:None
#Description:Checks the same files as the Build Results table.
###########################################
sub CheckBuildResults
{
	my @ListofChecks = qw(GT TV BUILD CBR ROM CDB);
   	my $iCount = "0";
   	while(@ListofChecks)
            {
            my $iFile = shift @ListofChecks;
            # zero errors, means 'None' is displayed
            if (!&GenResult::getHandleErrors($iFile)) 
	     {
	     setBragStatus("TBA");
	     #Should jump up to While loop again
	     next;
             }

	    my $iResultRow;
	    my @iResult = &GenResult::getResults($iFile); 
 	    foreach (&GenResult::getResults($iFile)) {
            undef $iResultRow;
            if (($_->[1] != "0") || ($_->[3] != "0")) 
	       {
		#A Build Results Error
		setBragStatus("Amber");
               }
               if ($_->[5] != "0")
               {
                   $GenResult::iBraggflag=1;
               }
               
           }#foreach
	    $iCount++;
	  }#end while
}
##############################################
# Name: CheckCBRs
# Inputs : product and snapshot number
# Outputs: None
# Description: Checks that the CBRs are created and sets the brag
# 	       status to Red if they havent been
###############################################
sub CheckCBRs
{
    my $iProduct = shift;
    my $iSnapshot = shift;

    my $iCBR_GT_only_Location = "\\\\builds01\\devbuilds\\ComponentisedReleases\\DailyBuildArchive\\Symbian_OS_v$iProduct\\";
    my $iCBR_GT_techview_Location = "\\\\builds01\\devbuilds\\ComponentisedReleases\\DailyBuildArchive\\Symbian_OS_v$iProduct\\";
    #Check to see if its a test build
    if(&GenResult::isTestBuild() eq "1")
       {
	$iCBR_GT_only_Location = "\\\\builds01\\devbuilds\\Test_Builds\\ComponentisedReleases\\TestArchive\\Symbian_OS_v$iProduct\\";
	$iCBR_GT_techview_Location = "\\\\builds01\\devbuilds\\Test_Builds\\ComponentisedReleases\\TestArchive\\Symbian_OS_v$iProduct\\";
       }
       
    if( -e $iCBR_GT_only_Location)
      {
      #Check the GT_ONLY
      if( -e $iCBR_GT_only_Location."\\GT_only_baseline\\$iSnapshot\_Symbian_OS_v$iProduct\\reldata")
      {
      setBragStatus("Green");
      }
      else
      {
      setBragStatus("Red");
      }
      #Check the GT_techview_baseline
      if( -e $iCBR_GT_techview_Location."\\GT_techview_baseline\\$iSnapshot\_Symbian_OS_v$iProduct\\reldata")
      {
      setBragStatus("Green");
      }
      else
      {
      setBragStatus("Red");
      }
      }
      else #No CBRs built so BragStatus is Red
      {
      setBragStatus("Red");
      }
}

#########################################################
# Name:CheckDevkit
# Input: Product
# Outout: None
# Description: Checks the Devkit log file for any errors
#########################################################
sub CheckDevkit
{
    my $iProduct = shift;
    my $iResult = 0;
    my @iProductList = ($iProducts{$iProduct} =~ m/\S+/ig);
    my $iplatform_counter = 0;
    foreach my $iPlatform (@iProductList)
    {
	$iResult = getDEVKITRow($iPlatform);
	if($iResult == 1)
	{
	  #Error in $iPlatform
	  setBragStatus("Amber");
	}
	
    }
}

sub getDEVKITRow
{
###############################################
# Name: getDEVKITRow
# Input: Platform
# Output: 0 - No problems
# 	  1 - error in log file
#
##############################################

    my $iPlatform = $_[0];
    my $iDKdir = "\\SmokeTest\\";	
	
    open (DevkitLOGFILE, $iLogsPublishLocation.$iDKdir.$iDevkitFileName);
    my @iDevkitLog = <DevkitLOGFILE>;   
    my $iErrorCount = 0;
    my $iLineOK = 0;
    
    foreach (@iDevkitLog) {
       if (m/ERROR:/) 
             {
		$iErrorCount++;		 
        }
	     else
	      {
		$iLineOK++;
	}
    }
	      if($iErrorCount > 0) { return 1;}else{return 0;}
	     
}

###############################################
# Name  : setBragStatus
# Inputs: Suggested Brag Status "Green","Amber","Red","Black"
# Outputs: None
# Description: This function sets the brag status
# 	       Brag status can only deteriorate, not improve
###############################################
sub setBragStatus
{
	my $iBstatus = shift;
	if($gBragStatus eq "Green")
	  {
	   $gBragStatus = $iBstatus;
	   return 0;
          }
        if(($gBragStatus eq "Amber") && (($iBstatus eq "Black") || ($iBstatus eq "Red")))
	  {
	  $gBragStatus = $iBstatus;
	  return 0;
  	  }

        if(($gBragStatus eq "Red") && ($iBstatus eq "Black"))
	  {
	  $gBragStatus = $iBstatus;
	  return 0;
  	  }
          
        if($iBstatus eq "TBA") # Set BRAG to "TBA" if the SmokeTests do not appear to have run.
        {
            $gBragStatus = $iBstatus;
            return 0;
        }

#For Everything Else leave gBragStatus as is
        return 0;
}
1;
