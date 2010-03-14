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
# Script summarise and hotlink autosmoketest logs by reading
# testdriver generated files
# 
#

#!/usr/bin/perl -w
package GenPostBuildResult;
use GenResult;
use strict;
use Net::SMTP;

##########################################################################
# 
# Name      :  getAVResults()
# Synopsis  :  To parse a logfile, and ouput results into a common
#              data format for processing.
#
# Inputs    :  $iLogsPublication
# Output    :  A single variable that is passed to the final results HTML 
#              table.
#
##########################################################################
sub getAVResults {

my ($iLogsPublishLocation) = @_;

my $iAVFileName = "anti-virus.log";
my $iAVError = "";
my $iAVLogFileLocation = $iLogsPublishLocation.$iAVFileName;
my $iAVResult = "<font color = \"Red\">WARNING: Potential virus found, check anti-virus.log</font>";
my $iAVWarning = "";
my $oldIdeFile = 0;
my $errorFound = 0;

# mcafee specifics
my $iTotal      = 0;
my $iClean      = 0;

     if(-e $iAVLogFileLocation) {
    
	# id header from antivirus.log
	my $iAVName = getAVProductName($iAVLogFileLocation);
	
        open (AVLOGFILE, $iAVLogFileLocation) or die "ERROR: Can't open file: $!";
        
        my @iAVLog = <AVLOGFILE>;
        
         if ($iAVName eq "SOPHOS") {
            
            foreach (@iAVLog){
               if(m/No viruses were discovered/i){
                 $iAVResult = "<font color = \"green\">No viruses were discovered</font>";
                 $iAVError = "";
               }
               elsif(m/(is older than \d+ days)+/i){
                 $oldIdeFile = 1;
               }
               elsif(m/errors? (was|were) encountered/i) {
                 $errorFound = 1;
               }
            }
            
	  } elsif ($iAVName eq "MCAFEE") {
	    
            foreach (@iAVLog){
               if (m/Total files:\s{1}\.*\s*([0-9]+)/i) {
                  $iTotal += $1;                  
               }
               elsif (m/Clean:\s{1}\.*\s*([0-9]+)/i) {                  
                 $iClean  += $1;
               }
	    }
            
            if ($iTotal eq $iClean) {
                  $iAVResult = "<font color = \"green\">No viruses were discovered</font>";
                  $iAVError = "";
            }
	  } elsif ($iAVName eq "UNKNOWN") {
            $iAVResult = "<font color = \"Red\"> WARNING: Cannot Identify Anti-Virus product</font>";
            $iAVError = "";
         }
	  
	# generate-html-output
	if( $oldIdeFile) {
	  $iAVWarning = "<font color = \"Red\"> Virus Definition file needs to be updated</font>";
	}
	if($oldIdeFile && $errorFound) {
	  $iAVWarning .= "<br>";
	}
	if( $errorFound) {
	  $iAVWarning .= "<font color = \"Red\"> Error(s) encountered. See anti-virus.log</font>";
	}	
     }
     else{
      $iAVResult = "<font color = \"Red\">WARNING: Anti-virus.log file not found </font>";
      $iAVError = "";
     }

  close AVLOGFILE;
  
return ($iAVResult,$iAVWarning,$iAVError);
}

#
# Identify AV Product
# - Sophos
# - McAfee
# - UnKnown
sub getAVProductName($) {
  
  my $iAVLogFileLocation = shift;
 
  my $iMcAfee = 0;
  my $iSophos = 0;
  
  open (AVLOGFILE, $iAVLogFileLocation) or die "ERROR: Can't open file: $!";
  
  my @iAVLog  = <AVLOGFILE>;
  
  foreach (@iAVLog){
    
    if(m/McAfee VirusScan for Win32/i) {
      $iMcAfee = 1;
      last;
    }
    
    if(m/Sophos Anti-Virus/i) {
      $iSophos = 1;
      last;
    }
  }
  
  # does not recognise "both"
  return ($iMcAfee ? "MCAFEE" :
         ($iSophos ? "SOPHOS" : "UNKNOWN"));
  
}

##########################################################################
#   --- REQ9019 ---
# Name      :  getSidVidResults()
# Synopsis  :  To check if the SID-VID report for ROM images has been created 
#              using tools_imgcheck module during the build.
# Inputs    :  $iLogsPublishLocation
# Output    :  A single variable that is passed to the final results HTML 
#              table.
#
##########################################################################
sub getSidVidResults {
 
my ($iLogsPublishLocation) = @_;

my $iSidVidReportFileName     = "sidvid.xml";
my $iSidVidReportFileLocation = $iLogsPublishLocation.$iSidVidReportFileName;
my $iSidVidReportResult;
     if(-e $iSidVidReportFileLocation) {

         $iSidVidReportFileLocation =~ s/\\/\//g;     # swap backslashes to fwd slashes
         
         # create browser link
         $iSidVidReportFileLocation = "file:///".$iSidVidReportFileLocation;    
         $iSidVidReportResult   ="<a class =\"hoverlink\" href = \"" . $iSidVidReportFileLocation."\">$iSidVidReportFileName</a>";  
     }
     else{
         $iSidVidReportResult = "<font color = \"Red\">WARNING: SID/VID report $iSidVidReportFileName not found</font>";
     }
 
return ($iSidVidReportResult);
}

##########################################################################
# 
# Name      :  CDBfiletest()
# Synopsis  :  To test if the CDB report was created successfully. Submit
#              result to the postbuild results table.
#
# Inputs    :  $iBCPrevious
# Output    :  A single variable that is passed to the final results HTML 
#              table.
#
##########################################################################
sub CDBFileTest{

my  ($iLinkPathLocation, $iProduct, $iSnapshot, $imail)  = @_;

my $iBCPreviousXML = $iLinkPathLocation;
$iBCPreviousXML = $iBCPreviousXML."cdb-info\\bc-prev.xml";
my $iBCBaseXML = $iLinkPathLocation;
$iBCBaseXML = $iBCBaseXML."cdb-info\\bc-base.xml";

my $iPrevTotal = "XML file not found";
my $iPrevPublish = "XML file not found";  
my $iBaseTotal = "XML file not found";
my $iBasePublish = "XML file not found";  

my $size = 0;
my $errorMessageBase = "";
my $errorMessagePrev = "";

my $iBCPreviousHTML = $iLinkPathLocation;
$iBCPreviousHTML = $iBCPreviousHTML."cdb-info\\BC-prev.html";
my $iBCBaseHTML = $iLinkPathLocation;
$iBCBaseHTML = $iBCBaseHTML."cdb-info\\BC-base.html";

if (-e $iBCPreviousXML){ 
   
   $iPrevTotal = "Keyword 'TotalBreaks' not found";
   $iPrevPublish = "Keyword 'PublishedPartner' not found";

   open (BCPREV, $iBCPreviousXML) or die "ERROR: Can't open file: $!";

       my @iBCPrev = <BCPREV>;

          foreach (@iBCPrev){
       
                   if(m/(totalBreaks count=")(\d+)/i){
                          $iPrevTotal = $2;
                   }
                  
                   if(m/(publishedPartner" count=")(\d+)/i){
                          $iPrevPublish = $2;
                   }
          }
    close BCPREV;
    
    if((uc($iLinkPathLocation) !~ m/TEST_BUILD/) && defined($imail) && $iPrevTotal>50){
      &SendEmail($iProduct,$iSnapshot,"The BC_Prev breaks are $iPrevTotal for Symbian v$iProduct $iSnapshot" );}
    
    #--DEF067716--
        
    $size = (stat($iBCPreviousHTML))[7]; 
    
    if ( -e $iBCPreviousHTML){
    	if ($size == 0) {
	    $errorMessagePrev = " [ BC-prev html link invalid ]";
        } else {
            my $bool = 0;
            open (BCPREVHTML, $iBCPreviousHTML) or die "ERROR: Can't open file: $!";
            while(<BCPREVHTML>){
                if(m/<HTML>/){
                    $bool = 1;
                }
            }
            close BCPREVHTML;
            if ($bool == 1){
                $errorMessagePrev = "";
            }else{
                $errorMessagePrev = " [ BC-prev: Not a HTML file ]";
            }            
        }
    } else {
        $errorMessagePrev = " [ BC-prev.html does not exist ]";
    }
    
    #--------------
    
    }

if (-e $iBCBaseXML){
   
   $iBaseTotal = "Keyword 'TotalBreaks' not found";
   $iBasePublish = "Keyword 'PublishedPartner' not found";
           
   open (BCBASE, $iBCBaseXML) or die "ERROR: Can't open file: $!";

       my @iBCBase = <BCBASE>;

          foreach (@iBCBase){
      
                   if(m/(totalBreaks count=")(\d+)/i){
                          $iBaseTotal = $2;                  
                   }
                  
                   if(m/(publishedPartner" count=")(\d+)/i){
                          $iBasePublish = $2;
                   }
           }
    close BCBASE;
    
    if((uc($iLinkPathLocation) !~ m/TEST_BUILD/) && defined($imail) && $iBaseTotal>400){
      &SendEmail($iProduct,$iSnapshot,"The BC_Base breaks are $iBaseTotal for Symbian v$iProduct $iSnapshot" );}
    #--DEF067716--
    
    $size = (stat($iBCBaseHTML))[7]; 
    
    if ( -e $iBCBaseHTML){
    	if ($size == 0) {
	    $errorMessageBase = " [ BC-base html link invalid ]"; 
        }else {
            my $bool = 0;
            open (BCBASEHTML, $iBCBaseHTML) or die "ERROR: Can't open file: $!";
            while(<BCBASEHTML>){
                if(m/<HTML>/){
                    $bool = 1;
                }
            }
            close BCBASEHTML;  
            if ($bool == 1){
                $errorMessageBase = "";
            }else{
                $errorMessageBase = " [ BC-base: Not a HTML file ]";
            }
        }
    } else {
        $errorMessageBase = " [ BC-base.html does not exist ]";
    }
    
    #--------------
    
    }

return ($iPrevTotal, $iPrevPublish, $iBaseTotal, $iBasePublish, $errorMessagePrev, $errorMessageBase);
}

sub SendEmail
{
  my (@body, @message, $sender_address, $notification_address,$iProduct,$iSnap);                        
  ($iProduct,$iSnap,@body) = @_;
  $sender_address  =  'I_EXT_SysBuildSupport@nokia.com';
  $notification_address  =  'I_EXT_SysBuildSupport@nokia.com';
     
  push @message,"From: $sender_address\n";
  push @message,"To: $notification_address\n";
  push @message,"Subject: Break Threshold CDB Notification $iSnap Symbian v$iProduct\n";
  push @message,"\n";
  push @message,@body;
  
  my $smtp = Net::SMTP->new('smtp.nokia.com', Hello => $ENV{COMPUTERNAME}, Debug   => 0);
  $smtp->mail();
  $smtp->to($notification_address);
  
  $smtp->data(@message) or die "ERROR: Sending message";
  $smtp->quit;
}
##########################################################################
# 
# Name      :  CBRTime()
# Synopsis  :  To obtain the time of export for both the gt_techview and
#              gt_only files and to report the status of the exported
#              CBR's.
#
# Inputs    :  Export_gt_only_baseline.log,
#              Export_gt_techview_baseline.log
# Output    :  To display the times in the post built results table.
#              
#
##########################################################################
sub CBRTime{

  my ($iLogsPublishLocation, $iProduct, $iSnapshot) = @_;
  
  
  my $iOnlyResult = "<font color = \"black\"> Export Unsuccessful</font>";              
  my $iTechViewResult = "<font color = \"black\">Export Unsuccessful</font>";  
  my $iOnlyTimes = "";
  my $iTechViewTime = "";
  # Error
  my $iOnlyResultError = "";
  my $iTechViewResultError = ""; 
  my $iExportError = "";
  
  if (-e $iLogsPublishLocation."Export_CBR.log")
  {  
  open (ILOG, $iLogsPublishLocation."Export_CBR.log") or die "ERROR: Can't open file: $!";
  my $iOnlyExportFound = 0;
  my $iTechviewExportFound = 0;
  
  while (my $line = <ILOG>)
  {
    if( $line =~ m/Environment gt_only_baseline.*?successfully exported/i)
    {
      $iOnlyResult = "<font color = \"black\">Export Successful</font>";
      $iOnlyExportFound = 1;
    }

    if( $line =~ m/gt_only_baseline.*?exportenv finsihed at\s+(.*)/i)
    {
      $iOnlyTimes = "<font color = \"black\">".$1."</font>";
    }
  
    if($line =~ m/Environment gt_techview_baseline.*?successfully exported/i)
    {
      $iTechViewResult = "<font color = \"black\">Export Successful</font>";
      $iTechviewExportFound = 1;
    }
    
    if( $line =~ m/gt_techview_baseline.*?exportenv finsihed at\s+(.*)/i)
    {
      $iTechViewTime  = "<font color = \"black\">".$1."</font>";
    }
    
    if( $line =~ m/ERROR: Failed to record delivery using template/i)
    {
      $iExportError = "<font color = \"red\"> Record Delivery Failed </font>";
    }
    
      
  } 
  
  if($iOnlyExportFound == 0)
  {
    $iOnlyResultError = "<font color = \"red\"> [ Export Unsuccessful ]</font>";
    $iOnlyTimes = "--";
  }
  if($iTechviewExportFound == 0)
  {
    $iTechViewResultError = "<font color = \"red\"> [ Export Unsuccessful ]</font>";
    $iTechViewTime = "--";
  }  
  close ILOG;
  
  } else {
  $iOnlyResult = "<font color = \"black\">Cannot find file</font>";
  $iOnlyTimes = "<font color = \"black\">Cannot find file</font>";
  $iOnlyResultError = "<font color = \"red\"> [ File not found ]</font>";
  $iTechViewResult = "<font color = \"black\">Cannot find file</font>";
  $iTechViewTime = "<font color = \"black\">Cannot find file</font>";
  $iTechViewResultError = "<font color = \"red\"> [ File not found ]</font>";
  }
  
  return ($iOnlyResult, $iOnlyTimes, $iTechViewResult, $iTechViewTime, $iOnlyResultError, $iTechViewResultError, $iExportError);
}

##########################################################################
#
# Name    : generatesPostBuildSummary()
# Synopsis: Creates Post Build Table in Build Results.
# Inputs  : Function parameters returned from genResult.pm that are to be
#           implemented in the Post Build Results table.
#	
# Outputs : HTML code that will be part of the HTML report generated 
#           for the final build results table.
##########################################################################
sub generatesPostBuildSummary{

my ($iLogsPublishLocation, $iLinkPathLocation, $iProduct, $iSnapshot, $imail) = @_;
my @CDBResArr = &CDBFileTest($iLinkPathLocation, $iProduct, $iSnapshot, $imail);
my @CBRResTime = &CBRTime($iLogsPublishLocation, $iProduct, $iSnapshot);
my @AVResults = &getAVResults($iLogsPublishLocation);
my $SidVidReportURL =  &getSidVidResults($iLogsPublishLocation);

my $SidVidReportResult = "SID/VID report generated.";

if( $SidVidReportURL =~ /WARNING/){
    $SidVidReportResult = $SidVidReportURL;
    $SidVidReportURL    = "&nbsp"; 
}

my $postbuild_html = "\n
                     <br><table border=\"1\" width=\"100%\" cellpadding=\"0\" cellspacing=\"0\">

        <tr>

                <td align=\"center\" colspan=\"4\" bgcolor=\"#006699\"><font color=\"#FFFFFF\" size=\"2\"><b>Post Build Results</font></td>

        </tr>
        
        <tr>
        
                <td bgcolor=\"#006699\">&nbsp</td>

                <td bgcolor=\"#006699\">&nbsp</td>
                
                <td bgcolor=\"#006699\">&nbsp</td>
                
                <td align=\"center\" bgcolor=\"#006699\"><font color=\"#FFFFFF\" size=\"2\"><b>Defects</font></td>        
        
        </tr>

        <tr>

                <td bgcolor=\"#006699\"><font color=\"#FFFFFF\" size=\"2\"><b>AntiVirus</font></td>

                <td > " . $AVResults[0] . " </td>
                
                <td>&nbsp<b>" . $AVResults[1] . " </td>
                
                <td>&nbsp<b>" . $AVResults[2] . " </td>

        </tr>
        
        <tr>
        
                <td bgcolor=\"#006699\"><font color=\"#FFFFFF\" size=\"2\"><b>SID VID Reports</font></td>
         
                <td>".$SidVidReportResult."</td>
                <td>".$SidVidReportURL."</td>
                <td>&nbsp</td>

         </tr>       

        <tr>

                <td bgcolor=\"#006699\"><font color=\"#FFFFFF\" size=\"2\"><a class =\"hoverlink\" href = \"" . &GenResult::setBrowserFriendlyLinks($iLinkPathLocation."cdb-info\\BC-prev.html")."\"><b>[CDB PREVIOUS]</a></td>

                <td>Total Number of Breaks: <b> " . $CDBResArr[0] . " </td>

                <td>Breaks at Published Partner and Above: <b> " . $CDBResArr[1] . " </td>
                
                <td>&nbsp<b>" . "<font color=\"Red\" size=\"2\">" . $CDBResArr[4] . "  </td>

        </tr>

        <tr>

                <td bgcolor=\"#006699\"><font color=\"#FFFFFF\" size=\"2\"><a class =\"hoverlink\" href = \"" . &GenResult::setBrowserFriendlyLinks($iLinkPathLocation."cdb-info\\BC-base.html")."\"><b>[CDB BASE]</a></td>

                <td>Total Number of Breaks: <b> " . $CDBResArr[2] . " </td>

                <td>Breaks at Published Partner and Above: <b> " .$CDBResArr[3] . " </td>

		<td>&nbsp<b>" . "<font color=\"Red\" size=\"2\">" . $CDBResArr[5] . " </td>

          </tr>";
        
        # If it is a test build then do not evaluate the CBR Export time component, else implement the export table.
          
         if(GenResult::isTestBuild() eq "0"){
          
          $postbuild_html=$postbuild_html."
                  
          <tr>
                <td bgcolor=\"#006699\"><font color=\"#FFFFFF\" size=\"2\"><b>[CBR Export] GT_Only</td>

                <td>Status: <b> " . $CBRResTime[0] . " </td>

                <td>Time of Export: <b> " . $CBRResTime[1]  . " </td>

		<td>&nbsp<b> " . $CBRResTime[4] . "</td>

        </tr>
        <tr>

                <td bgcolor=\"#006699\"><font color=\"#FFFFFF\" size=\"2\"><b>[CBR Export] TechView</td>

                <td>Status: <b> " . $CBRResTime[2] . " </td>

                <td>Time of Export: <b> " . $CBRResTime[3]  . " </td>
                
                <td>&nbsp<b> " . $CBRResTime[5] . "</td>

        </tr>
        <tr>
        
                <td bgcolor=\"#006699\"><font color=\"#FFFFFF\" size=\"2\"><b>Record Delivery Errors</td>
         
                <td>&nbsp <b> " . $CBRResTime[6] . " </td>
	       	<td>&nbsp</td>
		<td>&nbsp</td>
		
         </tr>       
        
        </table>
        <br>
                     ";
         }
         else{
          $postbuild_html=$postbuild_html."
          </table>
        <br>";
         }
return $postbuild_html;
}

1;
