# Copyright (c) 2003-2009 Nokia Corporation and/or its subsidiary(-ies).
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
# Script to send XML data to diamonds
# 
#
use HTTP::Request::Common qw(POST);
use LWP::UserAgent;

use Getopt::Long;

my $iServer;
my $iUrl;
my $iFile;
my $iHelp;
my $res;

my $import_failed_message  = "XML was not sent successfully to Diamonds via REST interface!\n";
my $import_succeed_message = "XML was sent successfully to Diamonds via REST interface.\n";

my $ua = LWP::UserAgent->new();

GetOptions('s=s' => \$iServer, 'u=s' => \$iUrl, 'f=s' => \$iFile, 'h' => \$iHelp);
if ((!defined $iServer) || (!defined $iUrl) || (!defined $iFile) || ($iHelp))
{
  Usage();
}

my $absoluteUrl = "http://".$iServer.$iUrl;
my $request = HTTP::Request->new(POST => $absoluteUrl);
$request->header('Content-Type' => 'text/xml');

open (FH,"<$iFile") or die "$iFile:$!\n";
my @filecon = <FH>;
my $XmlContent = join("",@filecon);
$request->content($XmlContent);
$res = $ua->request($request);

print "Response status:".$res->code()."\n";
print "Response reason:".$res->message()."\n";

if ($res->code() != 200)
{
  print "ERROR in sending XML data\n";
}
else
{
  print "Server response:".$res->content()."\n";
}

sub Usage()
{
  print <<USE;
  Use:
    send_xml_to_diamonds.pl options
    
    Mandatory options:
    -s    Server address
    -u    Url
    -f    path of XML file
    
    -h    help
    
    Examples:
    Sending a new build to release instance of Diamonds
        send_xml_to_diamonds.pl -s diamonds.nmp.nokia.com -u /diamonds/builds/ -f c:\\build.xml
    
    Updating test results to existing build
        send_xml_to_diamonds.pl -s diamonds.nmp.nokia.com -u /diamonds/builds/123/ -f c:\\test.xml
    
    Sending data for Relative Change in SW Asset metrics
        send_xml_to_diamonds.pl -s diamonds.nmp.nokia.com -u /diamonds/metrics/ -f c:\\relative.xml
    
    Sending data for Function Coverage
        send_xml_to_diamonds.pl -s diamonds.nmp.nokia.com -u /diamonds/tests/coverage/ -f c:\\coverage.xml
    
    Note: If you want to send XML to development version of Diamonds in testing purposes, use
    address: trdeli02.nmp.nokia.com:9001 in the server address:
        send_xml_to_diamonds.pl -s trdeli02.nmp.nokia.com:9001 -u /diamonds/builds/ -f c:\\build.xml
USE
  exit;
}
