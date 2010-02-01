#This module is used by startbuild.pl
#It asks for some BuildLaunch data from the user and performs some checks on this data
#This is then input to the BuildLaunch.xml file and then opens the file for the user to verify before launching the build.

package BuildLaunchChecks;
use strict;

sub GetUserInput
{
  # Ask for Snapshot, Previous Snapshot and ChangeList numbers
  
  my $Product;
  print "Enter Product number (e.g 9.1/9.5/tb91sf/tb92sf/tb101sf) >";
  chomp($Product = <STDIN>);
  $Product =~ s/\s+//g;
  
  my $Snapshot;
  print "Enter Snapshot number >";
  chomp($Snapshot = <STDIN>);
  $Snapshot =~ s/\s+//g;
  
  my $PrevSnapshot;
  print "Enter Previous Snapshot number >";
  chomp($PrevSnapshot = <STDIN>);
  $PrevSnapshot =~ s/\s+//g;
  
  my $Changelist;
  print "Enter ChangeList number >";
  chomp($Changelist = <STDIN>);
  $Changelist =~ s/\s+//g;
  print "\n";
  
  my $CurrentCodeline;
  print "Enter Codeline (e.g. //epoc/master //EPOC/Release/sf/symtb91 //EPOC/master/sf) >";
  chomp($CurrentCodeline = <STDIN>);
  $CurrentCodeline =~ s/\s+//g;
  print "\n";
  
  my $Platform;
  print "Enter Platform (e.g. beech/cedar/SF) >";
  chomp($Platform = <STDIN>);
  $Platform =~ s/\s+//g;
  print "\n";
  
  my $Type;
  print "Enter Type (e.g Master/MasterSF/Symbian_OS_v9.1/Symbian_OS_vTB91SF) >";
  chomp($Type = <STDIN>);
  $Type =~ s/\s+//g;
  print "\n";
  
  
  
  return $Product,
         $Snapshot,
         $PrevSnapshot,
         $Changelist,
         $CurrentCodeline,
         $Platform,
         $Type;
}

sub GetBCValue
{
  my($BuildData) = @_;
  $BuildData->{CurrentCodeline} =~ s/\/$//;  #drop any trailing /
  my $cmd = "p4 print -q $BuildData->{CurrentCodeline}/os/buildtools/bldsystemtools/commonbldutils/BCValues.xml\@$BuildData->{ChangelistNumber}";
  my $BCValues = `$cmd`;
  warn "WARNING: Could not open BCValues file" if $?;
  
  my @BCValues = split /\n/m, $BCValues;
  
  my $BCToolsBaseBuildNo;
  
  my $Product_Found = 0;
  foreach my $line (@BCValues)
  {
    $Product_Found = 1 if ($line =~ m/Product name=\"$BuildData->{Product}\"/i);
    
    if (($line =~ m/\"BCToolsBaseBuildNo\" Value=\"(.*)\"/i)&&($Product_Found == 1))
    {
      $BCToolsBaseBuildNo = $1;
      $BCToolsBaseBuildNo =~ s/\s+//g;
      last;
    }
  }
  
  return $BCToolsBaseBuildNo;
}

sub CheckData
{
  my($BuildData) = @_;
  
  my @change;
  my $Error;
  my $BCBaseBuild = "$BuildData->{PreviousBuildPublishLocation}\\$BuildData->{Type}\\$BuildData->{BCToolsBaseBuildNo}"."_Symbian_OS_v$BuildData->{Product}"
         if ((defined $BuildData->{BCToolsBaseBuildNo})&&(defined $BuildData->{Type})&&(defined $BuildData->{Product}));
  my $warnings = 0;
 
  #Check that the Changelist number entered at prebuild is the same as the Changelist entered at startbuild
  if (($ENV{CHANGELIST} != $BuildData->{ChangelistNumber})&&(defined $ENV{CHANGELIST})&&(defined $BuildData->{ChangelistNumber}))
  {
     warn "Warning: Changelist numbers entered at prebuild and startbuild are different\n";
     $warnings++;
  }
  
  #Check that the Changelist number entered is on the CodeLine
  if(defined $BuildData->{ChangelistNumber})
  {
    my $describe = "p4 -s describe $BuildData->{ChangelistNumber} 2>&1";
    push @change, `$describe`;
    warn "ERROR: Could not execute: $describe\n" if $?;
    
    foreach my $line(@change)
    {
     if ($line =~ m/$BuildData->{CurrentCodeline}/i)
     {
       $Error = 0;
       last;
     }
    }
    if (!defined $Error)
    {
     warn "Warning: Change $BuildData->{ChangelistNumber} does not exist on $BuildData->{CurrentCodeline}\n";
     $warnings++;
    }
  }
  
  #Check that the Previous Snapshot is less than the Current Snapshot
  if (($BuildData->{SnapshotNumber} lt $BuildData->{PreviousSnapshotNumber})&&(defined $BuildData->{SnapshotNumber})&&(defined $BuildData->{PreviousSnapshotNumber}))
  {
     warn "Warning: Current snapshot is less than the Previous snapshot\n";
     $warnings++;
  }
  
  #Check that the Previous Snapshot Number exists
  if ((!-e "$BuildData->{PreviousBuildPublishLocation}\\$BuildData->{Type}\\$BuildData->{PreviousSnapshotNumber}"."_Symbian_OS_v$BuildData->{Product}")&&(defined $BuildData->{PreviousSnapshotNumber})&&(defined $BuildData->{Product})&&(defined $BuildData->{Type}))
  {
     warn "Warning: Previous snapshot number does not exist on $BuildData->{PreviousBuildPublishLocation}\\$BuildData->{Type}\n";
     $warnings++;
  }
  
  #Check that CBR exists for the Previous Snapshot
  if ((!-e "$BuildData->{PreviousBuildPublishLocation}\\ComponentisedReleases\\DailyBuildArchive\\Symbian_OS_v$BuildData->{Product}\\gt_techview_baseline\\$BuildData->{PreviousSnapshotNumber}"."_Symbian_OS_v$BuildData->{Product}")&&(defined $BuildData->{PreviousSnapshotNumber})&&(defined $BuildData->{Product}))
  {
     warn "Warning: CBR does not exist for build $BuildData->{PreviousSnapshotNumber}\n";
     $warnings++;
  }
  
  #Check that the BCToolsBaseBuildNo exists on devbuilds
  if ((!-e $BCBaseBuild)&&(defined $BCBaseBuild)&&(defined $BuildData->{BCToolsBaseBuildNo}))
  {
    warn "Warning: $BuildData->{BCToolsBaseBuildNo}"."_"."Symbian_OS_v$BuildData->{Product} does not exist on \\\\Builds01\\devbuilds\\$BuildData->{Type}\n";
    $warnings++;
  }
 return $warnings;
}

sub UpdateXML
{
  my($xmlfile, $BuildData, $Sync) = @_;
  open(XMLFILE, '+<', $xmlfile) || warn "Warning: can't open $xmlfile for append: $!";
  my @initarray = <XMLFILE>;
  
  my $Left;
  my $Right;
  
  foreach my $line (@initarray)
  {
    if (($line =~ m/\"SnapshotNumber\" Value=\"([^\"]+)\"/)&&(defined $BuildData->{SnapshotNumber}))
    {
      $Left  = $`;
      $Right = $';
      $line= $Left . "\"SnapshotNumber\" Value=\"" . $BuildData->{SnapshotNumber} ."\"" . $Right;
      next;
    }
    
    if (($line =~ m/\"PreviousSnapshotNumber\" Value=\"([^\"]+)\"/)&&(defined $BuildData->{PreviousSnapshotNumber}))
    {
      $Left  = $`;
      $Right = $';
      $line= $Left . "\"PreviousSnapshotNumber\" Value=\"" . $BuildData->{PreviousSnapshotNumber} ."\"" . $Right;
      next;
    }
    
    if (($line =~ m/\"ChangelistNumber\" Value=\"([^\"]+)\"/)&&(defined $BuildData->{ChangelistNumber}))
    {
      $Left  = $`;
      $Right = $';
      $line= $Left . "\"ChangelistNumber\" Value=\"" . $BuildData->{ChangelistNumber} ."\"" . $Right;
      next;
    }
    
    if (($line =~ m/\"Platform\" Value=\"([^\"]+)\"/)&&(defined $BuildData->{Platform}))
    {
      $Left  = $`;
      $Right = $';
      $line= $Left . "\"Platform\" Value=\"" . $BuildData->{Platform} ."\"" . $Right;
      next;
    }
    
    if (($line =~ m/\"Product\" Value=\"([^\"]+)\"/)&&(defined $BuildData->{Product}))
    {
      $Left  = $`;
      $Right = $';
      $line= $Left . "\"Product\" Value=\"" . $BuildData->{Product} ."\"" . $Right;
      next;
    }
    
    if (($line =~ m/\"PublishLocation\" Value=\"([^\"]+)\"/)&& (defined $BuildData->{PublishLocation}))
    {
      $Left  = $`;
      $Right = $';
      $line= $Left . "\"PublishLocation\" Value=\"$BuildData->{PublishLocation}\"" . $Right;
      next;
    }
    
    if (($line =~ m/\"CurrentCodeline\" Value=\"([^\"]+)\"/)&&(defined $BuildData->{CurrentCodeline}))
    {
      $Left  = $`;
      $Right = $';
      $line= $Left . "\"CurrentCodeline\" Value=\"$BuildData->{CurrentCodeline}\"" . $Right;
      next;
    }

    if (($line =~ m/\"Type\" Value=\"([^\"]+)\"/)&&(defined $BuildData->{Type}))
    {
      $Left  = $`;
      $Right = $';
      $line= $Left . "\"Type\" Value=\"$BuildData->{Type}\"" . $Right;
      
      next;
    }
    
    if (($line =~ m/\"BuildSubType\" Value=\"([^\"]+)\"/)&&(defined $BuildData->{BuildSubType}))
    {
      $Left  = $`;
      $Right = $';
      $line= $Left . "\"BuildSubType\" Value=\"$BuildData->{BuildSubType}\"" . $Right;
      
      next;
    }
    
    if (($line =~ m/\"BCToolsBaseBuildNo\" Value=\"([^\"]+)\"/)&&(defined $BuildData->{BCToolsBaseBuildNo}))
    {
      $Left  = $`;
      $Right = $';
      $line= $Left . "\"BCToolsBaseBuildNo\" Value=\"" . $BuildData->{BCToolsBaseBuildNo} ."\"" . $Right;
      next;
    }
    
    if (($line =~ m/\"BuildsDirect\" Value=\"([^\"]+)\"/)&&(defined $BuildData->{BuildsDirect}))
    {
      $Left  = $`;
      $Right = $';
      $line= $Left . "\"BuildsDirect\" Value=\"$BuildData->{BuildsDirect}\"" . $Right;
      
      last;
    }
  }
  
  # output the changes to the original file
  seek(XMLFILE,0,0);
  print XMLFILE @initarray;
  truncate(XMLFILE,tell(XMLFILE));
  
  close(XMLFILE);
}

1;

__END__
