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
# Script to Generate the XML file that is suitable for Diamonds
# 
#
package GenDiamondsXml;
use FindBin;
use lib "$FindBin::Bin/lib";
use strict;
use Text::Template;
use Text::Template 'fill_in_file';
use publishDiamonds;
use ZipDiamondsXml;

my $Debug = 0;
my $MainXML = "Main.xml";
my @start;
if($ENV{BuildSubType} eq "Daily")
{
    @start = ('build.tmpl','schema.tmpl','locations.tmpl','tools.tmpl','content.tmpl','files.tmpl');
}
elsif($ENV{BuildSubType} eq "Test")
{
    @start = ('build.tmpl','schema.tmpl','locations.tmpl','tools.tmpl','files.tmpl');
}

my %states = (
'STARTBUILD' => {
            'START' => \@start
            #~ 'START' => ['files.tmpl']
        },
'GT' => {
            'START' => ['stage.tmpl'],
            'STOP' => ['stage.tmpl', 'faults.tmpl']
        },
'TV' => {
            'START' => ['stage.tmpl'],
            'STOP' => ['stage.tmpl','faults.tmpl']
        },
'ROM' => {
            'START' => ['stage.tmpl'],
            'STOP' => ['stage.tmpl','faults.tmpl']
        },
'CBR' => {
            'START' => ['stage.tmpl'],
            'STOP' => ['stage.tmpl','faults.tmpl']
        },
'CDB' => {
            'START' => ['stage.tmpl'],
            'STOP' => ['stage.tmpl','faults.tmpl']
        },
'BUILD' => {
            'START' => ['stage.tmpl'],
            'STOP' => ['stage.tmpl','faults.tmpl']
        },
'SMOKETEST' => {
            'STOP' => ['smoketest.tmpl']
        },
'ENDBUILD' => {
            'START' => ['diamonds_finish.tmpl', 'status.tmpl']
        }
);

sub main
{
  my ($iStage, $iState, $iServer) = @_;
  print "STAGE: $iStage\t STATE: $iState\n";
  my %vars = ();
  $vars{'iStage'} = $iStage;
  $vars{$iState} = 1;
  my $LogsLocation = $ENV{LogsDir}."\\";
  my @toMerge = ();
  my $BatFile = "SendXmls.bat";
  open (BAT,">>$BatFile") or warn "$BatFile: $!\n";

  foreach my $tmpl (@{$states{$iStage}{$iState}})
  {
    my $suffix = "_".$iStage."_".$iState;
    my $XmlName = $tmpl;
    $XmlName =~ s/\.tmpl/$suffix\.xml/;
    my $outfile = $LogsLocation.$XmlName;
    $tmpl = "$FindBin::Bin/".$tmpl;
    open(OUT,">$outfile");
    print "Processing $tmpl...\n" if $Debug;
    my $template = Text::Template->new(TYPE => 'FILE',  SOURCE => $tmpl)or die "Couldn't construct template: $Text::Template::ERROR";
    my $success = $template->fill_in(OUTPUT => \*OUT, DELIMITERS => [ '[@--', '--@]' ], HASH => \%vars) or warn "$Text::Template::ERROR\n";
    close(OUT);
    if ($success)
    {
      print "Successfully processed $tmpl\n" if $Debug;
      &publishDiamonds::publishToDiamonds($outfile,$iServer) if($ENV{BuildSubType} eq "Daily");
      &ZipDiamondsXml::main($outfile);
      print BAT "perl -e \"use publishDiamonds; &publishDiamonds::publishToDiamonds(\'$XmlName\',\'$iServer\');\"\n";
      unlink ($outfile) or warn "Error in deleting: $!\n";
    }
  }
  close(BAT);
  if ($iStage eq "ENDBUILD")
  {
      &ZipDiamondsXml::main($BatFile);
      unlink ($BatFile) or warn "Error in deleting: $!\n";
      &ZipDiamondsXml::main($FindBin::Bin."/"."publishDiamonds.pm");
      &ZipDiamondsXml::main($FindBin::Bin."/"."send_xml_to_diamonds.pl");
  }
}
1;
