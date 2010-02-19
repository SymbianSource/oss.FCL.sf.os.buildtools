# Copyright (c) 2009 Nokia Corporation and/or its subsidiary(-ies).
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
# Script summarise and hotlink autosmoketest logs by reading
# testdriver generated files
# 
#

#!/usr/bin/perl -w
package GenAutoSmokeTestResult;
use FindBin;
use FileRead;
require GenResult;
use strict;
#use XML::Parser;

# global vars
my $iSTPublishDir;
my $iSTLinkPath;
my $iHTMLFileName = "testlog.html";
my $iTraceFileName = "trace.txt";
my $iDevkitFileName = "Devkit\.log";

my ($iCfgFileLocation) = $FindBin::Bin;
#Read in the products from a cfg file
my $text = &FileRead::file_read ("$iCfgFileLocation\\Product_AutoSmokeTest.cfg");
#Search for an entry matching (At the beginning of line there should be 1 or more alphanumberic chars
#Followed by a "." followed by more alphanumberic chars followed by 0 or more spaces then an = then 0
#or more spaces then any amount of chars till the end of the line.
#8.1b = EMULATOR_WINSCW ARM4_LUBBOCK ARMV5_LUBBOCK
my %iProducts = $text =~ /^\s*(\w+\.?\w+)\s*=\s*(.+)$/mg ;

#Read in the auto smoketest list from a cfg file
my $Smoketext = &FileRead::file_read ("$iCfgFileLocation\\AutoSmoketests.cfg");
my %iTests = $Smoketext =~ /^\s*(\w+\s*\w*\s*)=\s*(.+)$/mg ;

my $iNumberOfTests = scalar(my @iTempArray = values %iTests);
my $iCountCols = 3 + $iNumberOfTests;
 
# container for smoketest result
my $gSmokeTestResultsRef;

##########################################################################
#
# Name    : generateSTHTMLSummary()
# Synopsis: Creates a Smoketest HTML report for the specified build.
# Inputs  : Array containing Logs directory location, Product built and 
#			path to link results
# Outputs : HTML code that will be part of the HTML report generated 
#			by GenResult.pm
#
# Note: Test Column Results can be interpreted as follows:
#
#	  OK: 			All test steps passed
#	  Unexecuted:		Test unexecuted or log file not found.
#	  Passed=x, Failed=y:	Results of test steps in the case of at least one failure 	
#
#       General Column Results can be interpreted as follows
#       
#	  OK: 			All smoke tests passing
#	  Unexecuted: 		At least one smoke test was unexecuted 
#	  FAILURES:             At least one failure in the smoke tests
#	  CRITICAL FAILURES:	TestApps smoketest (which tests basic epoc functionality) has failed.      
#
##########################################################################
sub generateSTHTMLSummary
{
	my ($iDir, $iSnapshot, $iProduct, $iLinkPath) = @_;

	$iLinkPath =~  s/[^\\]$/$&\\/; #add trailing backslash, if missing
	$iSTLinkPath = $iLinkPath;
	
	my $html_out = "<table border=\"1\" cellpadding=\"0\" cellspacing=\"0\" width=\"100%\" align=\"top\">";
	$html_out .= "<tr bgcolor=\"#006699\" align=\"top\"><th colspan=" 
	. $iCountCols .
	" rowspan=2><font color=\"#ffffff\">AUTO Smoke Test Results</font></th></tr>"
	."<tr></tr><tr bgcolor=\"#006699\" align=\"top\">";
	
	$iDir =~  s/[^\\]$/$&\\/; #add trailing backslash, if missing
	$iSTPublishDir = $iDir;
	

	if (-e $iSTPublishDir)
	{

		print "\nGenerating Auto Smoke Test Report.";

		my @iProductList = ($iProducts{$iProduct} =~ m/\S+/ig);
		if (@iProductList < 1)
		{
			# this product is not supported?
			$html_out .= "<td><center><b><font color=#ffffff>Smoke Test not supported for $iProduct</font></b></center></td></tr></table>";
			return $html_out;
		}
		else
		{
			# Header of the table
			$html_out .= "<th><font color=\"#ffffff\">Platform</font></th>
						  <th><font color=\"#ffffff\">SUMMARY</font></th>";
			foreach my $iTestName (sort { $iTests{$a} <=> $iTests{$b} } keys %iTests)
			{
				$html_out .= "<th><font color=\"#ffffff\">$iTestName</font></th>"
			}
			$html_out .= "<th><font color=\"#ffffff\">Defects</font></th></tr>";
			
			#iFlag = 0 for html mode, 1 for brag status mode
			my $iFlag = 0; #The second value is a dummy value. It is only used when deriving Brag status.
		 
			$html_out .= printSTResultRow($iFlag,$iFlag, @iProductList);
			# $html_out .= printDEVKITRow(@iProductList) 
			$html_out .= "</table>";
			return $html_out;
		}
	}
	else
	{
		print "REMARK: Auto Smoke Test Report not created: $! \n";
		return;
	}
}
############################################################
# Name: printSTResultRow
# Description: This function prints out the table rows for the auto smoketest build report
#	       file that is published in the ESR database. It is also used in determining
#	       the brag status and is called from Bragstatus.pm. If the iFlag value is set to
#	       0 then it will process the html results. Otherwise it returns a brag status of 0-green,1-Amber(Some tests failed)
#	       2-Red(All platforms failed); -1-TBA (smoke test results are not present for some reason).
#
############################################################
sub printSTResultRow
{	 
	my ($iFlag, $iLogPublishLocation,  @iProductList) = @_;
	my $iFileName = "Test Summary Report\.htm";  
 
	#Counts the number of platforms that have failed to be smoketested.
	my $iplatform_counter = 0;

 	#Test and DEBUG COUNTER
	my $iBragStatus = 0;	#0=Green,1=Amber,2=Red, -1=TBA
	my $iFullRowSet;
	my $iHTMLfileName = $iFileName;  
	
	# Process the results for each platform eg winscw, armv5 h4
	foreach my $iPlatform (@iProductList)
      {
		my @iPlatformSubDirs = split /_/, $iPlatform;
		my $iTempPath;
		 
		# Get the full path name to the results file for this platform.
		foreach my $iTempDir (@iPlatformSubDirs)
		{
			$iTempPath .= "$iTempDir\\";
		}  

		if($iFlag == 1)
		{
		$iSTPublishDir = $iLogPublishLocation;
		}  
 
		# Process the results if the results log exists
		if (-e $iSTPublishDir.$iTempPath.$iFileName)  {

		 
		# Read in the results log
		my $resultsFile = "$iSTPublishDir"."$iTempPath"."$iFileName";
		open(RESULTSFILE, "<$resultsFile");
		local $/ = undef; # undefine the input record separator to read in as one line.
		my $results = <RESULTSFILE>;
		close(RESULTSFILE);
			
		# Parse to make reading the file simpler
		$results =~ s/\<TD\>//ig;
		$results =~ s/\<\/TD\>//ig;
		$results =~ s/\<td BGCOLOR \= .*?\>//ig;
		
		my $iTestResults = "";
		my $unexecutedStatus 		= 0;
		my $failureStatus 		= 0;
		my $criticalFailureStatus 	= 0;

			
		# Add one table cell within the row for each smoke test 
		foreach my $iTestName (sort { $iTests{$a} <=> $iTests{$b} } keys %iTests)
			{
			my $testScript = "$iTests{$iTestName}";
			my $passed = 0;
			my $failed = 0; 
			my $testInLogFile = 0;
 
			# Extract the script execution line for this test from the results.
			if (	$results =~ /($testScript)\.script(?:\d)?(?:\.htm)?\s*(?:UDEB|UREL)\s*(\d*)\s*passed,\s*(\d*)\s*failed/i)
			{		 
				$testInLogFile = $1; 
 				$passed = $2;
				$failed = $3; 
 			}

  			# Find result of test execution
			if (!($testInLogFile))
				{
				$unexecutedStatus = 1;
				$iTestResults .= "<td><font color=orange>";
				$iTestResults .= "Unexecuted"."</font></td>";
				$iBragStatus = -1;# At least one test is unexecuted
				}
			else
				{
 				if (($failed==0) && ($passed > 0))
 					{
					$iTestResults .= "<td><font color=green>";
					$iTestResults .= "OK"."</font></td>";
  					}
  				else 
   					{
   					if ($failed > 0)
  						{ 
 						# Differentiate between the basic TestApps test (which just fires up
						# the emulator and runs exes) and application tests (e.g. messaging). 
    						if ($testScript eq "smoketest_testapps")
    							{
							$criticalFailureStatus = 1;
							$iTestResults .= "<td><font color=red>";
							$iBragStatus = 2;# Critical failures  
    							}
    						else
    							{
							$failureStatus = 1;
							$iTestResults .= "<td><font color=orange>";
							$iBragStatus = 1; # At least one test has failed
    							}
						$iTestResults .= "Passed="."$passed"." Failed="."$failed"."</font></td>";
  						}

 						}
					 }
			} # foreach my $iTestName
 
			# Leave blank cell for defects 
			$iTestResults .= "<td>&nbsp</td>";

			 	
			# Print out platform e.g. winscw (emulator) to start a new row in the results table
			my $iRow = "<tr><td><a class =\"hoverlink\" href=\"" .&GenResult::setBrowserFriendlyLinks($iSTLinkPath.$iTempPath.$iHTMLfileName) ."\">"
				.@iPlatformSubDirs[1]." ( ".@iPlatformSubDirs[0];
			if (defined @iPlatformSubDirs[2])
				{
					$iRow .= " @iPlatformSubDirs[2] ";
				}
			$iRow .= " ) </a></td><td>";
				
 
 			# Print the overall summary cell 
			if ("$criticalFailureStatus")
				{
				$iRow .= "<font color=red>";
				$iRow .= "CRITICAL FAILURES";  
				}
				else 
  					{
     					if ("$failureStatus")
     						{
      					$iRow .= "<font color=orange>";
						$iRow .= "FAILURES";  
      					}
     					else 
     						{
        					if ("$unexecutedStatus")
        						{
          						$iRow .= "<font color=orange>";
							$iRow .= "Unexecuted";  
        						}
        					else
        						{
							$iRow .= "<font color=green>";
							$iRow .= "OK";  
        						}
      					}
    					}


			# Put the whole row together
			$iRow .= "$iTestResults";
			$iRow .= "</td>"; # end the last cell TD??
			$iFullRowSet .= $iRow;

		} # if (-e $iSTPublishDir.$iTempPath.$iFileName)
		 

		 
	else # results file doesn't exist.
		{
 
		# smoke test directory for that platform has not been produced 
		# - this is usually a sign that ROMs have not been made,
		# or that the smoke tests haven't been run.
			
		my $iRow = "<tr><td>"
		.@iPlatformSubDirs[1]." ( ".@iPlatformSubDirs[0];
		if (defined @iPlatformSubDirs[2])
			{
			$iRow .= " @iPlatformSubDirs[2] ";
			}
		$iRow .= " ) </td><td>Smoke Test Not Run</td>";
		foreach my $iTestName (sort { $iTests{$a} <=> $iTests{$b} } keys %iTests)
			{
			$iRow .= "<td><s>OK</s></td>";
			}
		$iRow .= "<td>&nbsp;</td></tr>";
		$iFullRowSet .= $iRow;
			
		if($iFlag == 1) # BRAG status mode
			{
			$iplatform_counter++; #Platform Failed to be smoketested
			$iBragStatus = 1; # Amber
			}
	} # if ( -e $iSTPublishDir.$iTempPath)
	}# end foreach my $iPlatform (@iProductList) 
	
	# Return result depending on what the calling mode was
	if($iFlag == 1)#bragstatus mode
		{
		if($iplatform_counter > 0) 
			{
			$iBragStatus = -1; # not all platforms have been smoketested.
			}
		return $iBragStatus;
		}
	else #Smoketest HTML mode
		{
		return $iFullRowSet;
		}
} # end sub
sub printDEVKITRow
{
#access log file - Devkit.log on Devbuilds/Buildnumber/logs
#open Devkit log file
#if there are no ERROR: lines then print OK in General Column
#else print Failed in General column
#for all tests print N/A'

#my $iDevkitLogFileLocation   = $iSTPublishDir.$iDevkitFileName;

    open (DevkitLOGFILE, $iSTPublishDir.$iDevkitFileName);
    my @iDevkitLog = <DevkitLOGFILE>;
    my $iRow = "<tr><td>";

    $iRow .= "DEVKIT</td>";
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
	      if ($iErrorCount > 0)
	      {
		$iRow .= "<td>Failed</td>";
	  }
	     else
	      {
	      $iRow .= "<td>OK</td>";
	      }
	      
    
    

foreach my $iTestName (sort { $iTests{$a} <=> $iTests{$b} } keys %iTests)
		{
			$iRow .= "<td>N/A</td>";
		}
		
	$iRow .= "<td>&nbsp;</td></tr>";

return $iRow	
}


1;