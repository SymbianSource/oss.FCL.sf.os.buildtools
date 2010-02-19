# Copyright (c) 2006-2009 Nokia Corporation and/or its subsidiary(-ies).
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
# Script to check for Missing Stages in MainBuild/PostBuild Logs
# Purpose: This script checks dropped stages in PostBuild/MainBuild Logs
# by reading the stages in Log file and comparing each of the stage against the stages in the corresponding XML file,
# if the stages are missing sends out an e-mail to the system build support team.
# 
#

use strict; 
use Net::SMTP;
use File::Basename;

my %hashlist = ("$ENV{LogsDir}\\"."$ENV{BuildNumber}.xml" => "$ENV{LogsDir}\\"."$ENV{BuildBaseName}.log", "$ENV{SourceDir}\\os\\buildtools\\bldsystemtools\\commonbldutils\\".'postbuild.xml' => "$ENV{LogsDir}\\".'postbuild.log');

foreach my $xmlFile (keys %hashlist)
{
       ReportMissingStages ($xmlFile, $hashlist{$xmlFile});
}

sub ReportMissingStages
{
       my ($XML, $log) = @_;
       my $logFile = basename $log;
       my $XMLFile = basename $XML;
       if ( ! -e $XML)
       {
              &SendEmail("ERROR: $XML File not found");
       }
       elsif ( ! -e $log)
       {
              &SendEmail("ERROR: $log File not found");
       }       
       else
       {
              my %hashXML;
              my %hashLOG;
              open(FH, "<$XML") or die "ERROR: Cannot open $XMLFile: $!\n";
              my @iXML = <FH>;
              close(FH);
              foreach (@iXML)
              {
                     next if(/^\<\!\-\-/);
                     while(/(%(\w+)%)|(%%(\w+)%%)/g)
                     {
                            my $iVarName = $4?$4:$2;
                            if (defined $ENV{$iVarName})
                            {
                                   s/(%\w+%)|(%%\w+%%)/$ENV{$iVarName}/;
                            }
                            else
                            {
                                   s/(%\w+%)|(%%\w+%%)//; #undefined variables become 'nothing'
                            }
                     }
                     s/2>&amp;1/2>&1/g;
                     s/&quot;/"/g;
                     s/&gt;/>/g;
                     s/&lt;/</g;
                                            
                     if(my $line = m/CommandLine="(.*)"/i)
                     {
                            if(! exists $hashXML{$1})
                            {
                                my $XMLEntry = $1;
                                $XMLEntry =~ s/\s+/ /g;
                                $hashXML{$XMLEntry} =1;
                            }
                            else
                            {
                                   $hashXML{$1}+= 1;
                            }
                     }   
              }        
              
              open(IN, "<$log") or die "error: cant open $logFile: $!\n";
              my @iLog = <IN>;
              close IN;
              foreach(@iLog)
              {
                     if(m/^--\s(.*)/)
                     {
                            if(! exists $hashLOG{$1})
                            {
                                   my $logEntry = $1;
                                   $logEntry =~ s/\s+/ /g;
                                   $hashLOG{$logEntry} =1;
                            }
                            else
                            {
                                   $hashLOG{$1}+= 1;
                            }
                     }       
              }
              my @missing = grep ! exists $hashLOG{$_}, keys %hashXML;
              #To remove missingstages.pl stage being reported itself as missing in log file
              @missing = grep !/missingstages.pl/, @missing;
              if(@missing)
              {
                     #To Print each MissingStage in a seperate line
                     my @MissingStages;
                     foreach my $Stage(@missing)
                     {
                            push @MissingStages, "$Stage\n\n";
                     }
                     &SendEmail("Missing Stages found in $logFile: \n\n@MissingStages");
              }
              
       }
}

sub SendEmail
{
 my (@body, @message, $sender_address, $notification_address);                        
  @body = @_;
  $sender_address  =  'I_EXT_sysbuildsupport@nokia.com';
  $notification_address  =  'I_EXT_sysbuildsupport@nokia.com';
     
  push @message,"From: $sender_address\n";
  push @message,"To: $notification_address\n";
  push @message,"Subject: MissingStages found in build $ENV{BuildNumber}\n";
  push @message,"\n";
  push @message,@body;
  
  my $smtp = Net::SMTP->new('smtp.nokia.com', Hello => $ENV{COMPUTERNAME}, Debug   => 0);
  $smtp->mail();
  $smtp->to($notification_address);
  
  $smtp->data(@message) or die "ERROR: Sending message";
  $smtp->quit;
}
  

 
 
 