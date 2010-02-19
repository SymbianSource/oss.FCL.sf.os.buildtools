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
# Script generates PC and Perforce table when called from
# BuildLaunch.xml file.
# 
#

#!/usr/bin/perl -w
package PC_P4Table;
use strict;
use Time::Local;

my $iBuildLaunchFileLocation;
my $iLinkPathLocation = "http://IntWeb/bitr/review_release.php";
my $iBuildLaunchFileFound    = "1";
my $iClientSpecFileLocation = "";

my @gProduct_Clientinfo = (
			['7.0s','Symbian_OS_v7.0'],
			['7.0e','Symbian_OS_v7.0_enhance'],
			['7.0','Symbian_OS_v7.0'],
			['8.0a','Symbian_OS_8.0'],
			['8.1a','Symbian_OS_v8.1'],
			['8.1b','Symbian_OS_v8.1'],
			['9.1','master'],
			['9.2','master'],
			['9.3','master'],
			['Future','master'],
			['9.4','master'],
			['9.5','master'],
			['9.6','master'],
			['tb92','master'],
                        ['tb101sf','master']
		   );

#####################################################################
#Sub-Routine Name:getbuildloc
#Inputs          :Product version
#Outputs         :Returns log directory Location for product
#Description     :
#####################################################################
sub getbuildloc
  {
  my $iProducts = shift;
  my $i = 0;
   
  while($i < $#gProduct_Clientinfo+1)
	{
	 if ($iProducts eq $gProduct_Clientinfo[$i][0])
	    {
	    return $gProduct_Clientinfo[$i][1];
	    }	    
	 $i++;
	}
	 
  return("Logs location not Found for product");
 } 
		   
		   
# outline style sheet internally  
my $gStyleSheet = " \n

                <style type=\"text/css\">                    
                    h1,h2,h3
                    {
                        font-family: \"lucida calligraphy\", arial, 'sans serif'; 
                    }

                    p,table,li,
                    {
                        font-family: \"lucida calligraphy\", arial, 'sans serif'; 
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
# Name	   : getBuildTime
# Synopsis : Create a string containing the build timestamp
# Inputs   : None
# Outputs  : GMT timestamp
##########################################################################
sub getBuildTime
{
	my $time = gmtime(time);	# Get current GMT time
	$time .= " GMT";			# Append GMT marker
	return $time;				# Return it
}

##########################################################################
#
# Name    :  generateHTMLSummary()
# Synopsis:  Creates an HTML report for the specified build.
# Inputs  :  Scalar containing the build snapshot and product type
# Outputs :  HTML report, published in current working dir
##########################################################################
sub generateHTMLSummary {
    
    my ($iSnapshot, $iProduct,$iChangeList, $iClientSpec) = @_;
    my $iLogLocation = getbuildloc( $iProduct );
    $iClientSpec =~ s/\/\/cedar/\/cedar/g;
    my $iBuildLaunchFileLocation = "\\Builds01\\devbuilds\\$iLogLocation\\$iSnapshot\_Symbian_OS_v$iProduct\\logs\\BuildLaunch.xml";

    open (SUMMARY, "+> $iSnapshot"."_"."$iProduct"."PC_Perforce_report.html") or die "ERROR:Can't open file : $!";
       
    my $html_start = "\n
                    <HTML>
                    <HEAD>" .
                    $gStyleSheet .
                    "<TITLE>" . "$iSnapshot "."$iProduct ". "PC and Perforce Reference</TITLE>
                    <BODY BGCOLOR=\"FFFFFF\">

                    </HEAD>
                    <BODY>".
		    
                    "<TABLE width=\"100%\" border =\"1\" cellpadding=\"0\" cellspacing=\"0\">" .
		    " <tr bgcolor=\"#006699\" align=\"top\"><th colspan=\"2\"> <font color=\"#ffffff\">PC and Perforce Reference for $iProduct</font></th> </tr>".
		    " <tr align=\"top\"><td colspan=\"2\">
		    
		    <font size=\"2\"><p>
                        [ <a class =\"hoverlink\" href = \"" . $iLinkPathLocation."\">  External Builds Info</a>  ]
                        "."\n </p>
                    </font>
		    </td> </tr>".
			"\n
			<tr>
			<th bgcolor=\"#006699\" align =\"left\" width=\"300\"> <font color=\"#ffffff\">BuildMachineName</font></th>" .
			"<td align = \"left\">".`hostname`."" ."</td>".
		        "</tr>\n".
			"\n
			<tr>
			<th bgcolor=\"#006699\" align =\"left\"> <font color=\"#ffffff\">ClientSpec</font></th>" .
			"<td align = \"left\">$iClientSpec </td>
                        ".
		        "</tr>\n".
			"\n
			<tr>
			<th bgcolor=\"#006699\" align =\"left\"> <font color=\"#ffffff\">Perforce Changelist</font></th>" .
			"<td align = \"left\">$iChangeList </td>" .
		        "</tr>\n".
			"\n
			<tr>
			<th bgcolor=\"#006699\" align =\"left\"> <font color=\"#ffffff\">Build Start Time</font></th>" .
			"<td align = \"left\">".getBuildTime()."" ."</td>".
		        "</tr>\n".
		    "</table>
                      </BODY>
                      </html>
                      ";
                      
                      
    print SUMMARY $html_start;
    
    close SUMMARY;
}
