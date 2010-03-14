#!perl
# Copyright (c) 2000-2009 Nokia Corporation and/or its subsidiary(-ies).
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
#

use strict;

use Getopt::Long;
use Cwd;
use XML::Simple;
use FindBin;
use lib "$FindBin::Bin";

my $Now = &Today;
my $IncludesRestrictedSource = 0;
my $ZippedCatA = 0;
my $ZippedCatX = 0;

my $WorkPath = uc cwd;
$WorkPath =~s-/-\\-go;            # replace forward slash with backslash
$WorkPath =~s/^(.:)(\S+)$/$2/o;   # remove drive letter
my $WorkDrv = $1;
$WorkPath =~s-^(.*[^\\])$-$1\\-o; # ensure it ends with a backslash

my %HTMLFileErrors = ();
my %ASCIIFileErrors = ();
my %Components = ();
my %ComponentsUsed = ();
my @UnrepresentedComponents = ();

my %Cmdopts = ();
unless (GetOptions( \%Cmdopts, "cats|c=s", "dir|d=s", "export|e", "full|f:i",
        "genpkg|g=s", "help|h", "licensee|l=s", "manifest|m=s", "nosub|n", "overrideexpiry|o",
        "project|p=s", "report|r=s", "showfiles|s", "xclude|x=s", "zip|z=s",
        "outdir=s"))
  {
  print "For help, use -h option\n";
  exit 1;
  }

if (@ARGV && ($ARGV[0]=~/help/io || $ARGV[0]=~/\?/io))
  {
  &Usage();
  }
  
# Open Schedule12 File for Component name checking
if ($Cmdopts{'report'})
{
    my $Build = $Cmdopts{'report'};
    my $Version = $1 if ( $Build =~ /Symbian_OS_v(.*)/i );
    
    # Define the source root directory (assumes it's 3 levels up)
    my $sourcedir = Cwd::abs_path("$FindBin::Bin\\..\\..\\..");
    my $Schedule12File = "$sourcedir\\os\\deviceplatformrelease\\symbianosbld\\cedarutils\\Symbian_OS_v"."$Version"."_Schedule12.xml";
    my $xml = new XML::Simple;
    my $Schedule12 = $xml->XMLin($Schedule12File);
    
    my $CommonReplaceable = %$Schedule12->{'CR'};
    for (keys %$CommonReplaceable)
    {
        $Components{$_} = "Common Replaceable";
        $ComponentsUsed{$_} = 0;
    }
    
    my $CommonSymbian = %$Schedule12->{'CS'};
    for (keys %$CommonSymbian)
    {
        $Components{$_} = "Common Symbian";
        $ComponentsUsed{$_} = 0;
    }
    
    my $OptionalReplaceable = %$Schedule12->{'OR'};
    for (keys %$OptionalReplaceable)
    {
        $Components{$_} = "Optional Replaceable";
        $ComponentsUsed{$_} = 0;
    }
    
    my $OptionalSymbian = %$Schedule12->{'OS'};
    for (keys %$OptionalSymbian)
    {
        $Components{$_} = "Optional Symbian";
        $ComponentsUsed{$_} = 0;
    }
    
    my $ReferenceTest = %$Schedule12->{'REF'};
    for (keys %$ReferenceTest)
    {
        $Components{$_} = "Reference/Test";
        $ComponentsUsed{$_} = 0;
    }
    
    my $ReferenceTest = %$Schedule12->{'TEST'};
    for (keys %$ReferenceTest)
    {
        $Components{$_} = "Reference/Test";
        $ComponentsUsed{$_} = 0;
    }
    
    my $ReferenceTest = %$Schedule12->{'RT'};	# v9.1 style combined Ref/Test
    for (keys %$ReferenceTest)
    {
        $Components{$_} = "Reference/Test";
        $ComponentsUsed{$_} = 0;
    }
}

# Handle -h flag
# --------------
if ($Cmdopts{'help'})
  {
  &Usage();
  }

# --------------
# Handle -c flag
# --------------
my $Categories = 'EFGOT';
if ($Cmdopts{'cats'})
  {
  if ($Cmdopts{'cats'} =~ /[^A-GIOTX]/i)
    {
    &NotifyError("Unrecognised category list \"$Cmdopts{'cats'}\" ignored");
    }
  else
    {
    $Categories = uc($Cmdopts{'cats'});
    }
  }

# --------------
# Handle -d flag
# --------------
my @TopDirs;
if (!$Cmdopts{'dir'})
  {
  $TopDirs[0] = $WorkPath;
  }
else
  {
  if (!(-e $Cmdopts{'dir'}))
    {
    die "$Cmdopts{'dir'} does not exist\n";
    }
  if (-d $Cmdopts{'dir'})
    {
    $TopDirs[0] = $Cmdopts{'dir'};
    }
  else
    {
    @TopDirs = &ReadDirFile($Cmdopts{'dir'});
    }
  @TopDirs = &MakeAbs($WorkPath, @TopDirs);
  foreach my $p (@TopDirs)
    {
    $p = &ValidateIncPath($p);
    }
  }

# --------------
# Handle -e flag
# --------------
my $ForceExport = $Cmdopts{'export'} ? 1 : 0;

# --------------
# Handle -f flag
# --------------
my $Full = $Cmdopts{'full'} || 0;


# --------------
# Handle -g flag
# --------------
my $PkgFile;
my $GenPkg = $Cmdopts{'genpkg'} ? 1 : 0;
if ($GenPkg)
  {
  $PkgFile = $Cmdopts{'genpkg'};
  if (index($PkgFile, "\.") < 0)
    {
    $PkgFile .= "\.xml";
    }
  if ((-e $PkgFile) and (-f $PkgFile))
    {
    unlink ($PkgFile) or die "Can't overwrite $PkgFile\n";
    }
  open PKGLIST, ">$PkgFile" or die "Can't open $PkgFile\n";
  }


# --------------
# Handle -l flag
# --------------
my $Recipient = 'generic';
if ($Cmdopts{'licensee'})
  {
  $Recipient = lc($Cmdopts{'licensee'});
  }

# --------------
# Handle -m flag
# --------------
my $Manifest = $Cmdopts{'manifest'} ? 1 : 0;
if ($Manifest)
  {
  my $MfsFile = $Cmdopts{'manifest'};
  if (index($MfsFile, "\.") < 0)
    {
    $MfsFile .= "\.txt";
    }
  if ((-e $MfsFile) and (-f $MfsFile))
    {
    unlink ($MfsFile) or die "Can't overwrite $MfsFile\n";
    }
  open MFSLIST, ">$MfsFile" or die "Can't open $MfsFile\n";
  }


# --------------
# Handle -n flag
# --------------
my $SubDirs = $Cmdopts{'nosub'} ? 0 : 1;

# --------------
# Handle -o flag
# --------------
my $OverrideExpiry = $Cmdopts{'overrideexpiry'} ? 1 : 0;

# --------------
# Handle -outdir flag
# --------------
my $outdir = $Cmdopts{'outdir'};

# --------------
# Handle -p flag
# --------------
my $Project = 'generic';
if ($Cmdopts{'project'})
  {
  $Project = lc($Cmdopts{'project'});
  }

# --------------
# Handle -s flag
# --------------
my $ShowFiles = $Cmdopts{'showfiles'} ? 1 : 0;

# --------------
# Handle -x flag
# --------------
my @XDirs;
if (!$Cmdopts{'xclude'})
  {
  $XDirs[0] = "";
  }
else
  {
  if (!(-e $Cmdopts{'xclude'}))
    {
    die "Exclusion $Cmdopts{'xclude'} does not exist\n";
    }
  if (-d $Cmdopts{'xclude'})
    {
    $XDirs[0] = $Cmdopts{'xclude'};
    }
  else
    {
    @XDirs = &ReadDirFile($Cmdopts{'xclude'});
    }
  @XDirs = &MakeAbs($WorkPath, @XDirs);
  foreach my $p (@XDirs)
    {
    $p = &ValidateExcPath($p);
    }
  }

# --------------
# Handle -z flag
# --------------
my $ZipFile;
my $ZipTmpFile;
my $ZipLogFile;
my $Zip = $Cmdopts{'zip'} ? 1 : 0;
if ($Zip)
  {
   if ( &FindZip == 0 )
   {
      die "Cannot find zip.exe in path. $?\n";
   }

  $ZipFile = $Cmdopts{'zip'};
  if (index($ZipFile, "\.") < 0)
    {
    $ZipFile .= "\.zip";
    }
  $ZipLogFile = $ZipFile . "log";
  $ZipTmpFile = $ZipFile . "tmp";
  if ((-e $ZipFile) and (-f $ZipFile))
    {
    unlink ($ZipFile) or die "Can't overwrite $ZipFile\n";
    }
  if ((-e $ZipTmpFile) and (-f $ZipTmpFile))
    {
    unlink ($ZipTmpFile) or die "Can't overwrite $ZipTmpFile\n";
    }
  open ZIPLIST, ">$ZipTmpFile" or die "Can't open $ZipTmpFile\n";
  }



# --------------
# print Pkg header
# --------------

  if ($GenPkg)
    {
    &PkgPrint ("<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n");
    &PkgPrint ("\n");

    &PkgPrint ("<packagedef version=\"1.0\">\n");
    &PkgPrint ("   <package name=\"$PkgFile\" major-version=\"0\" minor-version=\"0\">\n");
    &PkgPrint ("     <supplier>Symbian Ltd</supplier>\n");
    &PkgPrint ("     <sdk-version>7.0</sdk-version>\n");
    &PkgPrint ("   </package>\n");
    &PkgPrint ("\n");
    &PkgPrint ("   <manifest>\n");
    }


#------ Do the report header ------
my $temp ="IPR Report, ".&DateValToStr($Now);
&DataPrint("$temp\n");
$temp = '-' x length($temp);
&DataPrint("$temp\n");

&DataPrint ("Report type:                  ");
if ($Full < 0)
  {
  &DataPrint ("No IPR data\n") ;
  }
else
  {
  &DataPrint ($Full ? "Full IPR data\n" : "Reduced IPR data\n");
  }
&DataPrint ("Recipient:                    ", ucfirst($Recipient), "\n");
&DataPrint ("Include DTI restricted files: ", $ForceExport ? 'Yes' : 'No', "\n");
&DataPrint ("Include time-expired files:   ", $OverrideExpiry ? 'Yes' : 'No', "\n");
&DataPrint ("List selected files:          ", $ShowFiles ? 'Yes' : 'No', "\n");
&DataPrint ("\n");

#------ Do header for standard section ------
$temp ="Standard source for ".ucfirst($Recipient);
&DataPrint ("$temp\n");
$temp = '-' x length($temp);
&DataPrint ("$temp\n");
&DataPrint ("Categories:                   $Categories\n");
&DataPrint ("Include subdirectories:       ", $SubDirs ? 'Yes' : 'No', "\n");
&DataPrint ("Top level directories:\n");
foreach my $name (@TopDirs)
  {
  &DataPrint ("                              $name\n");
  }
&DataPrint ("\n");

&ProcessDir(@TopDirs, $SubDirs, 1, $Manifest);

#------ Do optional header for extra section ------
if (($Project ne 'generic') and (-e "$Project\.extra"))
  {
  my @ExtraDirs = ReadDirFile("$Project\.extra");
  @ExtraDirs = &MakeAbs($WorkPath, @ExtraDirs);
  foreach my $p (@ExtraDirs)
    {
    $p = &ValidateIncPath($p);
    }
  &DataPrint ("\n");
  $temp ="Extra source for ".ucfirst($Project);
  &DataPrint ("$temp\n");
  $temp = '-' x length($temp);
  &DataPrint ("$temp\n");
  $Categories = 'ABCDEFGIOTX';
  &DataPrint ("Categories:                   $Categories\n");
  &DataPrint ("Include subdirectories:       No\n");
  &DataPrint ("Additional directories:\n");
  foreach my $name (@ExtraDirs)
    {
    if ($name)
      {
      &DataPrint ("                              $name\n");
      }
    }
  &DataPrint ("\n");

  &ProcessDir(@ExtraDirs, 0, 0, 0); # Note, no extra directories in a product manifest
  }

if ($Zip)
  {
   if ( &FindZip == 0 )
   {
      die "Cannot find zip.exe in path. $?\n";
   }

   close ZIPLIST;
   `zip -@ $ZipFile <$ZipTmpFile >$ZipLogFile`;
   unlink ($ZipTmpFile);
  }

if ($Manifest)
  {
  close MFSLIST;
  }

# --------------------------
# print Pkg footer and close
# --------------------------

if ($GenPkg)
  {
  &PkgPrint ("   </manifest>\n");
  &PkgPrint ("</packagedef>\n");
  close PKGLIST;
  }

#------ Do optional warning for restricted export source ------
&ExportWarning() if ($IncludesRestrictedSource);
&NotifyWarning("zip file contains Category A source\n") if ($ZippedCatA);
&NotifyWarning("zip file contains uncategorised source\n") if ($ZippedCatX);

if ($Cmdopts{'report'})
    {
    #------ Produce Distribution Policy File Error Report --------
    my ( $s, $min, $hour, $mday, $mon, $year, $w, $y, $i)= localtime(time);
    $year+= 1900;
    $mon++;
    
    my $builddir = $outdir;
    if (!defined $builddir)
    	{
    	# Assume default setup for Symbian build machines...
    	$builddir = Cwd::abs_path("$FindBin::Bin\\..\\..\\..\\..");
    	$builddir.= "\\logs\\cedar";
    	}
    open HTMLOUTFILE, ">> $builddir\\$Cmdopts{'report'}_Distribution_Policy_Report.html";
    open ASCIIOUTFILE, ">> $builddir\\$Cmdopts{'report'}_Distribution_Policy_Report.txt";
    
    foreach my $key (sort keys %ComponentsUsed)
    {
        push @UnrepresentedComponents, $key if ($ComponentsUsed{$key} == 0);
    }
    
    my $UnrepCKLComponents = @UnrepresentedComponents;
    my $NonCompliantFiles = scalar(keys %ASCIIFileErrors);
    
    print HTMLOUTFILE <<HEADING_EOF;
    <html><head><title>Distribution Policy File Report for $Cmdopts{'report'}</title></head>
    <body>
    <h1><center>Distribution Policy File Report<br>for<br>$Cmdopts{'report'}</center></h1>
    <h2><center>Created - $mday/$mon/$year</center></h2>
    <hr width=60% size=1 noshade> <p><p><p><p>
    
    <TABLE BORDER Align=center>
    <TH COLSPAN=2><font color=red>Report Summary</font></TH>
    <TR><TD>Total number of Non-compliant Files</TD><TD><b>$NonCompliantFiles</b></TD></TR>
    <TR><TD>Total number of Unrepresented CKL Components</TD><TD><b>$UnrepCKLComponents</b></TD></TR>
    </TABLE><p><p><p><p>
    
    <TABLE BORDER ALIGN=center>
    <TH COLSPAN=2>Non-Compliant Files</font></TH>
    <TR><TH>File Location</TH><TH>Errors</TH></TR>
HEADING_EOF
    
    print ASCIIOUTFILE <<HEADING_EOF;
Distribution Policy File Report for $Cmdopts{'report'}
Created - $mday/$mon/$year
================================
    
HEADING_EOF

    foreach my $key (sort keys %ASCIIFileErrors)
    {
        my $path = lc $key;
        $path =~ s/^.*?\\master\\.*?\\src\\/\\src\\/i;
        print HTMLOUTFILE "<TR><TD><font face=verdana size=4>$path</TD><TD>@{$HTMLFileErrors{$key}}</TD></TR>";
        print ASCIIOUTFILE "@{$ASCIIFileErrors{$key}}";
    }
    print HTMLOUTFILE "</TABLE><p><p><p><p>";
    
    if (@UnrepresentedComponents != 0)
    {
        print HTMLOUTFILE "<TABLE BORDER ALIGN=center>";
        print HTMLOUTFILE "<TR><TH>Unrepresented Components</TH></TR>";
        foreach my $component (@UnrepresentedComponents)
        {
            print HTMLOUTFILE "<TR><TD>Component '$component' as recorded in
                Schedule 12 of the CKL has no representation in any of the source directories that are used to build this product</TD></TR>";
            
            print ASCIIOUTFILE "Unrepresented Component, Component '$component' as recorded in Schedule 12 of the CKL has no representation in any of the source directories that are used to build this product.\n";
        }
        print HTMLOUTFILE "</TABLE>";
    }
    
    close HTMLOUTFILE;
    close ASCIIOUTFILE;
    }



sub ProcessDir
{
my $ForManifest = pop @_;
my $ObeyExcludes = pop @_;
my $Subdirs =  pop @_;
my $Category = 'X';
my $ExpiryDate = 0;
my $NoExport = 0;
my $Skip = 0;
my $Name;
my $FoundFile;
my $FoundPol;
my $PathName;
my $Text;
my @AllFiles;
my @Recipients;
my %LicExpDates;

foreach $PathName (@_)
  {
  if (!$PathName) { next; }
  if ($ForManifest)
    {
    my $path = $PathName;
#   $path =~ s/^\\//; # remove any leading backslash
    $path =~ s/\\$//; # remove any trailing backslash
    &MfsPrint ("COMPONENT\t$path\n");
    }
  if ($ObeyExcludes)
    {
    foreach my $exclude (@XDirs)
      {
      my $ex = $exclude;
      my $pn = $PathName;
      if (uc $ex eq uc $pn)
        {
        $Skip = 1;
        last;
        }
      }
    if ($Skip)
      {
      next;
      }
    }
  $FoundFile = 0;
  $FoundPol = 0;
  opendir(HERE, $PathName);
  @AllFiles = readdir(HERE);
  close(HERE);
  foreach my $Name (@AllFiles)
    {
    if (-d "$PathName$Name") { next; }
    if (lc($Name) eq 'distribution.policy')
      {
      $FoundPol = 1;
      ($Category, $ExpiryDate, $NoExport, $Text, %LicExpDates) = &IprStatus("$PathName$Name");
      
      if ($Cmdopts{'report'})
        {
        my ($HTMLErrors, $ASCIIErrors) = &CheckFileContents("$PathName$Name");
        @{$HTMLFileErrors{"$PathName"}} = @{$HTMLErrors} if (@{$HTMLErrors} > 0);
        @{$ASCIIFileErrors{"$PathName"}} = @{$ASCIIErrors} if (@{$ASCIIErrors} > 0);
        }
      }
    else
      {
      $FoundFile = 1;
      }
    }
  if ($FoundFile and (!$FoundPol)) { &NotifyError("no policy file in $PathName"); }
  if ((!$FoundFile) and $FoundPol)
    {
    &NotifyNote("unnecessary policy file in $PathName");
    $FoundFile = 1;    # Force a report of a directory containing only a policy file
    }

  &ConditionalRep($FoundFile, $PathName, $Category, $ExpiryDate, $NoExport, $Text, %LicExpDates);

  if ($Subdirs)
    {
    foreach my $Name (@AllFiles)
      {
      if (-d "$PathName$Name")
        {
        if ($Name eq '.') { next; }
        if ($Name eq '..') { next; }
        &ProcessDir("$PathName$Name\\", 1, $ObeyExcludes, 0);
        }
      }
    }
  }
}

sub CheckFileContents
{
  my $Location = shift;
  $Location = lc $Location;
  
  my $path = $Location;
  $path =~ s/\\distribution.policy//;  # Remove file name from end of path
  
  my @HTMLFileErrors = ();
  my @ASCIIFileErrors = ();
  my $Category;
  my $OSDclass;
  my $ComponentName;
  
  my $CategoryLineFound = 0;
  my $OSClassLineFound = 0;
  
  open(DPFile, $Location);
  
  while (<DPFile>)
  {
    # Check Comment Lines
    if ($_ =~ /^\s*#(.*)$/)
    {
        if ($1 =~ /#/)
        {
            push @HTMLFileErrors, "<font face=verdana size=4><b>Line = </b>$_</font><br><font face=arial size=4 color=red>Comment line contains # as part of the comment.</font><p>\n";
            push @ASCIIFileErrors, "$path, Comment line contains # as part of the comment.\n";
        }
        next;
    }
    
    # Check Source Category Line
    if ($_ =~ /^\s*Category.*$/i)
    {
        $CategoryLineFound++;
        if (!($_ =~ /^\s*Category\s+\w{1}\s*$/i))
        {
            push @HTMLFileErrors, "<font face=verdana size=4><b>Line = </b>$_</font><br><font face=arial size=4 color=red>Line Syntax is incorrrect.</font><br>\n";
            push @ASCIIFileErrors, "$path, Category line syntax is incorrect.\n";
            
            if ($_ =~ /^\s*Category(.*?)\w{1}\s*(.*)$/i)
            {
                if (!($1 =~ /^\s+$/))
                {
                    push @HTMLFileErrors, "<font face=arial size=4 color=red>The word Category and the Source-Category should be seperated by a whitespace not '$1'.</font><br>\n";
                    push @ASCIIFileErrors, "$path, The word Category and the Source-Category should be seperated by a whitespace not '$1'.\n";
                }
                if ($2 ne "")
                {
                    push @HTMLFileErrors, "<font face=arial size=4 color=red>Trailing characters '$2' after the Source-Category are not allowed.</font><br>\n";
                    push @ASCIIFileErrors, "$path, Trailing characters '$2' after the Source-Category are not allowed.\n";
                }
                
                push @HTMLFileErrors, "<p>\n";
                next;
            }
        }
        if ($_ =~ /^\s*Category\s+(\w{1})\s*$/)
        {
            $Category = uc $1;
            if ($Category !~ /[A-GIOT]/)
            {
                push @HTMLFileErrors, "<font face=verdana size=4><b>Line = </b>$_</font><br><font face=arial size=4 color=red>Category $Category is not a defined Source-Category.</font><p>\n";
                push @ASCIIFileErrors, "$path, Category $Category is not a defined Source-Category.\n";
            }
            next;
        }
    }
    
    # Check OS Class Line
    if ($_ =~ /^\s*OSD.*$/i)
    {
        $OSClassLineFound++;
        if (!($_ =~ /\s*OSD:\s+\w+.?\w+\s+.*\s*$/i))
        {
            push @HTMLFileErrors, "<font face=verdana size=4><b>Line = </b>$_</font><br><font face=arial size=4 color=red>OSD line syntax is incorrect</font><br>\n";
            push @ASCIIFileErrors, "$path, OSD line syntax is incorrect.\n";
            
            if (!($_ =~ /OSD:\s+/i))
            {
                push @HTMLFileErrors, "<font face=arial size=4 color=red>OSD line does not begin with 'OSD: '</font><br>\n" ;
                push @ASCIIFileErrors, "$path, OSD line does not begin with 'OSD: '.\n";
            }
            
            if ($_ =~ /OSD:\s+(.*)\s+(.*)/i)
            {
                my $class = $1;
                my $compname = lc $2;
                $compname =~ s/\s+$//;
                # Workaround for this particular string
                if (($_ =~ /Optional:/)&&($_ =~ /Test/)&&($_ =~ /RTP/))
                {
                    $class = "Optional: Test";
                    $compname = "rtp";
                }
                if ((!($class =~ /^Common Replaceable$/i))&&(!($class =~ /^Common Symbian$/i))&&(!($class =~ /^Optional Replaceable$/i))&&(!($class =~ /^Optional Symbian$/i))
                    &&(!($class =~ /^Reference\/Test$/i))&&(!($class =~ /^Reference\\Test$/i))&&(!($class =~ /^Test\/Reference$/i))&&(!($class =~ /^Test\\Reference$/i)))
                {
                    push @HTMLFileErrors, "<font face=arial size=4 color=red>OSD Class '$class' is not a defined OSD Class.</font><br>\n" ;
                    push @ASCIIFileErrors, "$path, OSD Class '$class' is not a defined OSD Class.\n";                  
                }
                
                if (!($compname =~ /[a-z]+/))
                {
                    push @HTMLFileErrors, "<font face=arial size=4 color=red>No Component name specified on OSD line.</font><br>\n" ;
                    push @ASCIIFileErrors, "$path, No Component name specified on OSD line.\n";
                    
                }
                
                foreach my $key (sort keys %ComponentsUsed)
                {
                    my $lowercasename = lc $key;
                    $lowercasename =~ s/\s+$//;
                    if ($compname eq $lowercasename)
                    {
                        $ComponentsUsed{$key} = 1;
                        last;
                    }
                }
            }
            push @HTMLFileErrors, "<p>\n";
            
            next;
        }
        if ($_ =~ /\s*OSD:\s+(\w+.?\w+)\s+(.*)\s*$/)
        {
            my $OSDclass = $1;
            my $ComponentName = $2;
            my $OSDLineError = 0;
            
            if ($OSDclass eq "")
            {
                push @HTMLFileErrors, "<font face=verdana size=4><b>Line = </b>$_</font><br><font face=arial size=4 color=red>OSD Class is not specified.</font><br>\n";
                push @ASCIIFileErrors, "$path, OSD Class is not specified.\n";
                $OSDLineError = 1;
            }
            if ($ComponentName eq "")
            {
                if ($OSDLineError == 0)
                {
                    push @HTMLFileErrors, "<font face=verdana size=4><b>Line = </b>$_</font><br><font face=arial size=4 color=red>No Component Name specified on the OSD line.</font><br>\n";
                    push @ASCIIFileErrors, "$path, No Component Name specified on the OSD line.\n";
                    $OSDLineError = 1;
                }
                else
                {
                    push @HTMLFileErrors, "<font face=arial size=4 color=red>No Component Name specified on the OSD line.</font><br>\n";
                    push @ASCIIFileErrors, "$path, No Component Name specified on the OSD line.\n";
                }
            }
            if (($OSDclass ne "")&&(!($OSDclass =~ /^Common Replaceable$/i))&&(!($OSDclass =~ /^Common Symbian$/i))&&(!($OSDclass =~ /^Optional Replaceable$/i))&&(!($OSDclass =~ /^Optional Symbian$/i))
                    &&(!($OSDclass =~ /^Reference\/Test$/i))&&(!($OSDclass =~ /^Reference\\Test$/i))&&(!($OSDclass =~ /^Test\/Reference$/i))&&(!($OSDclass =~ /^Test\\Reference$/i)))
            {
                if ($OSDLineError == 0)
                {
                    push @HTMLFileErrors, "<font face=verdana size=4><b>Line = </b>$_</font><br><font face=arial size=4 color=red>OSD Class '$OSDclass' is not a defined OSD Class.</font><br>\n";
                    push @ASCIIFileErrors, "$path, OSD Class '$OSDclass' is not a defined OSD Class.\n";
                    $OSDLineError = 1;
                }
                else
                {
                    push @HTMLFileErrors, "<font face=arial size=4 color=red>OSD Class '$OSDclass' is not a defined OSD Class.</font><br>\n";
                    push @ASCIIFileErrors, "$path, OSD Class '$OSDclass' is not a defined OSD Class.\n";
                }
            }
            if((defined $Category)&&($Category eq 'D')&&(!($OSDclass =~ /^Common Symbian$/i)))
            {
                if ($OSDLineError == 0)
                {
                    push @HTMLFileErrors, "<font face=verdana size=4><b>Line = </b>$_</font><br><font face=arial size=4 color=red>All Category 'D' code must be assigned to a CKL component of OSD Class 'Common Symbian'.</font><br>\n";
                    push @ASCIIFileErrors, "$path, All Category 'D' code must be assigned to a CKL component of OSD Class 'Common Symbian'.\n";
                    $OSDLineError = 1;
                }
                else
                {
                    push @HTMLFileErrors, "<font face=arial size=4 color=red>All Category 'D' code must be assigned to a CKL component of OSD Class 'Common Symbian'.</font><br>\n";
                    push @ASCIIFileErrors, "$path, All Category 'D' code must be assigned to a CKL component of OSD Class 'Common Symbian'.\n";
                }
            }
            if((defined $Category)&&($OSDclass =~ /^Common Symbian$/i))
            {
                if (($Category eq 'E'))
                {
                    if ($OSDLineError == 0)
                    {
                        push @HTMLFileErrors, "<font face=verdana size=4><b>Line = </b>$_</font><br><font face=arial size=4 color=red>A 'Common Symbian' OSD Class component must not contain Source Category '$Category' code.</font><br>\n";
                        push @ASCIIFileErrors, "$path, A 'Common Symbian' OSD Class component must not contain Source Category '$Category' code.\n";
                        $OSDLineError = 1;
                    }
                    else
                    {
                        push @HTMLFileErrors, "<font face=arial size=4 color=red>A 'Common Symbian' OSD Class component must not contain Source Category '$Category' code.</font><br>\n";
                        push @ASCIIFileErrors, "$path, A 'Common Symbian' OSD Class component must not contain Source Category '$Category' code.\n";
                    }
                }
            }
            
            push @HTMLFileErrors, "<p>\n" if ($OSDLineError != 0);
            
            #Check $ComponentName and OSD-Class against data in Schedule12 of the CKL
            if ($ComponentName ne "")
            {
                my $componentmatch = 0;
                my $OSDmatch = 0;
                my $Schedule12OSDClass;
                my $component = lc $ComponentName;
                $component =~ s/\s+$//;
                my $osdclass = lc $OSDclass;
                $osdclass =~ s/\s+$//;
 
                foreach my $Schedule12Component (sort keys %Components)
                {
                    my $schedule12component = lc $Schedule12Component;
                    $schedule12component =~ s/\s+$//;
                    if ($component eq $schedule12component)
                    {
                        $componentmatch = 1;
                        $ComponentsUsed{$Schedule12Component} = 1;
                    }
                    if ($componentmatch == 1)
                    {
                        $Schedule12OSDClass = $Components{$Schedule12Component};
                        my $schedule12osdclass = lc $Schedule12OSDClass;
                        $schedule12osdclass =~ s/\s+$//;
                        $OSDmatch = 1 if ($schedule12osdclass eq $osdclass);
                        
                        if (($osdclass eq "reference\\test")||($osdclass eq "test\\reference")||($osdclass eq "test\/reference"))
                        {
                            $OSDmatch = 1 if ($schedule12osdclass eq "reference\/test");
                        }
                        last;
                    }
                }
                
                if ($componentmatch == 0)
                {
                    push @HTMLFileErrors, "<font face=arial size=4 color=red>Component '$ComponentName' is not listed in Schedule 12 of the CKL.</font><p>\n";
                    push @ASCIIFileErrors, "$path, Component '$ComponentName' is not listed in Schedule 12 of the CKL.\n";
                }
                if (($componentmatch == 1)&&($OSDmatch == 0))
                {
                    if (($Category == 'T') && (($osdclass eq "reference\\test")||($osdclass eq "test\\reference")||($osdclass eq "test\/reference")||($osdclass eq "reference\/test")))
                    {
                        
                    }
                    else
                    {
                        push @HTMLFileErrors, "<font face=arial size=4 color=red>According to Schedule 12 of the CKL, component '$ComponentName' should be assigned to OSD Class '$Schedule12OSDClass' not '$OSDclass'.</font><p>\n";
                        push @ASCIIFileErrors, "$path, According to Schedule 12 of the CKL component '$ComponentName' should be assigned to OSD Class '$Schedule12OSDClass' not '$OSDclass'.\n";
                    }
                }
            }
        }
    }
  }
  push @HTMLFileErrors, "<font face=arial size=4 color=red>Category Line is missing.</font><p>" if ($CategoryLineFound == 0);
  push @ASCIIFileErrors, "$path, Category Line is missing.\n" if ($CategoryLineFound == 0);
  push @HTMLFileErrors, "<font face=arial size=4 color=red>OSD Line is missing.</font><p>" if ($OSClassLineFound == 0);
  push @ASCIIFileErrors, "$path, OSD Line is missing.\n" if ($OSClassLineFound == 0);
  
  push @HTMLFileErrors, "<font face=arial size=4 color=red>File contains $CategoryLineFound Category Lines.</font><p>" if ($CategoryLineFound > 1);
  push @ASCIIFileErrors, "$path, File contains $CategoryLineFound Category Lines.\n" if ($CategoryLineFound > 1);
  push @HTMLFileErrors, "<font face=arial size=4 color=red>File contains $OSClassLineFound OSD Lines.</font><p>" if ($OSClassLineFound > 1);
  push @ASCIIFileErrors, "$path, File contains $OSClassLineFound OSD Lines.\n" if ($OSClassLineFound > 1);
  
  return \@HTMLFileErrors, \@ASCIIFileErrors;
}

sub IprStatus
{
my $Location = shift;
my $ThisCategory = 'X';
my $CatSet = 0;
my $Expiry = 0;        # 0 represents no expiry date set
my $Restricted = 0;
my $ThisLine = 0;
my $Description;
my %ShipData;
open(IPR, $Location);
while (<IPR>)
  {
  $_ = lc $_;
  $ThisLine += 1;

  s/\s*#.*$//;                                        # ignore comments and blank lines
  if ($_ =~ /^$/) { next; }

  if ($_ =~ /category\s+(\w)/)                        # CATEGORY statements
    {
    my $aCat=uc($1);
    if (($aCat =~ /[^A-GIOT]/))
      {
      &ErrorLoc("illegal Category statement", $ThisLine, $Location);
      $ThisCategory = 'X';
      $CatSet = 1;
      next;
      }
    if ($CatSet)
      {
      &ErrorLoc("repeated Category statement", $ThisLine, $Location);
      if ($ThisCategory le $aCat) { next; }
      }
    $ThisCategory = uc($1);
    $CatSet = 1;
    next;
    }

  if ($_ =~ /authorized\s+(\w+)\s*(.*)/)              # AUTHORIZED statements
    {
    my $aRec = lc($1);
    my $Rest = $2;
    my $found = 0;
    my $ShipUntil = 0;
    my $Repeat = 0;
    my @Recipients = keys(%ShipData);
    foreach my $name (@Recipients)
      {
      if ($aRec eq $name)
        {
        $Repeat = 1;
        &ErrorLoc("repeated recipient \"$aRec\"", $ThisLine, $Location);
        last;
        }
      }
    if ($Rest =~ /until\s+(\d+)\W(\d+)\W(\d+)/) # UNTIL Authorized qualifier
      {
      my $D = $1;
      my $M = $2;
      my $Y = $3;
      $ShipUntil = $Y*10000 + $M*100 + $D;
      if (not &IsValidDate($D, $M, $Y))
        {
        &ErrorLoc("illegal date \"$D/$M/$Y\"", $ThisLine, $Location);
        $ShipUntil = $Now - 1;
        }
      }
    else
      {
      if ($Rest =~ /\w+/)
        {
        &ErrorLoc("unknown \"Authorized\" qualifier: \"$Rest\"", $ThisLine, $Location);
        $ShipUntil = $Now - 1;
        }
      }
    if ((!$ShipData{$aRec}) or ($ShipData{$aRec} > $ShipUntil))
      {
      $ShipData{$aRec} = $ShipUntil;
      }
    next;
    }

  if ($_ =~ /expires\s+(\d+)\W(\d+)\W(\d+)/)          # EXPIRES statements
    {
    my $D = $1;
    my $M = $2;
    my $Y = $3;
    my $E = $Y*10000 + $M*100 + $D;
    if (not &IsValidDate($D, $M, $Y))
      {
      &ErrorLoc("illegal date \"$D/$M/$Y\"", $ThisLine, $Location);
      $E = $Now - 1;
      next;
      }
    if ((!$Expiry) or ($Expiry > $E))
      {
      $Expiry = $E;
      }
    next;
    }

  if ($_ =~ /export\s+(\w*)restricted/)               # EXPORT statements
    {
    if ($1 ne 'un') { $Restricted = 1; }
    next;
    }

  if ($_ =~ /description\s+(.*)/)                     # DESCRIPTION statements
    {
    $Description = $1;
    next;
    }

  if ($_ =~ /^\s*osd/)                                # Ignore OSD: statements
    {
    next;
    }

  if ($_ =~ /\S/)                                     # Anything else
    {
    $_ =~ /(.*)$/;
    &ErrorLoc("unrecognised statement \"$1\"", $ThisLine, $Location);
    }
  }
close(IPR);

if (!$CatSet)
  {
  &ErrorLoc("missing Category statement", $ThisLine, $Location);
  }
else
  {
  if ((scalar keys %ShipData != 0) and ($ThisCategory =~ /[^B-C]/i))
    {
    &NotifyError("category $ThisCategory source should not name recipients"); 
    }
  }
return ($ThisCategory, $Expiry, $Restricted, $Description, %ShipData);
}

sub Today
{
my ($Sec, $Min, $Hr, $Daym, $Mnth, $Yr, $Wkday, %YrDay, $IsDST) = localtime(time);
return (($Yr+1900)*10000+($Mnth+1)*100+$Daym);
}

sub IsValidDate
{
my $Dy =  shift;
my $Mth = shift;
my $Yr =  shift;
if ($Yr < 1900) { return 0; }
if (($Mth < 1) or ($Mth > 12)) { return 0; }
if (($Dy <1) or ($Dy > &DayinMonth($Mth, &IsLeap($Yr)))) { return 0; }
return 1;
}

sub IsLeap
{
my $aYear = shift;
return (!($aYear%4) && ($aYear%100 || !($aYear%400))) ? 1 : 0;
}

sub DayinMonth
{
my @dim = (31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31,
           31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31);

my $Monthnum = shift;
my $Leap = shift;
return $dim[$Leap*12 + $Monthnum - 1];
}

sub DateValToStr
{
my $Date = shift;
my $temp = $Date%100;
my $DatStr = "$temp\/";
$Date -= $temp;
$Date /= 100;
$temp = $Date%100;
$DatStr .="$temp\/";
$Date -= $temp;
$Date /= 100;
$DatStr .= "$Date";
}

sub DataPrint
{
if ($Full >= -1)
  {
  print @_;
  }
}

sub PkgPrint
{
print PKGLIST @_;
}

sub MfsPrint
{
my $mfsname = uc $_[0];
print MFSLIST "$mfsname";
}

sub ErrorLoc
{
my $msg = shift;
my $line = shift;
my $loc = shift;
&NotifyError("$msg");
&ErrorPrint("       in line $line of $loc");
}

sub NotifyError
{
my $msg = shift;
&ErrorPrint("ERROR: $msg");
}

sub NotifyWarning
{
my $msg = shift;
&ErrorPrint("WARNING: $msg");
}

sub NotifyNote
{
my $msg = shift;
&ErrorPrint("Note: $msg");
}

sub ErrorPrint
{
my $msg = shift;
print STDERR "$msg\n";
}

sub ExportWarning
{
print STDERR <<ENDEXPORTSTRING;
WARNING: The selected code contains export-restricted source.
Any external release must contain the following notice.

"The delivery of this software is subject to UK Export Control and is made
under Open Individual Export Licence (OIEL) no OIEL I/006318/99, which covers
Sweden, USA, Japan, Finland and Hungary.  The recipient of this software agrees
that it will not export or re-export the software directly or indirectly to any
country which at the time of export requires an export licence or other
governmental approval, without first obtaining such licence or approval."

ENDEXPORTSTRING
}

sub ConditionalRep
{
my $Found = shift;
my $Path = shift;
my $Cat = shift;
my $Expire = shift;
my $NoExp = shift;
my $Description = shift;
my %LDates = @_;

if (index($Categories, $Cat) < 0) { return; }
if ($NoExp and !$ForceExport) { return; }
if ($NoExp) { $IncludesRestrictedSource = 1; }
my $Printed = 0;

if ($Full > 1)                    # write one line of tab-separated data per directory
  {
  if ($Found)
    {
    my @Recipients;
    my $NamePrinted = 0;
    &DataPrint ("$Path\t", "$Cat\t");          # directory and category
    if ($NoExp) { &DataPrint ('Restricted'); } # export status
    &DataPrint ("\t");
    @Recipients = keys(%LDates);
    foreach my $name (@Recipients)         # comma-separated list of recipients
      {
      if ($NamePrinted)
        {
        &DataPrint (', ');
        }
      &DataPrint ($name);
      $NamePrinted = 1;
      }
    &DataPrint ("\t");
    @Recipients = keys(%LDates);        # earliest of any expiry dates
    foreach my $name (@Recipients)
      {
      my $Date = $LDates{$name};
      if ($Date)
        {
        if (($Expire <= 0) or ($Date < $Expire))
          {
          $Expire = $Date;
          }
        }
      }
    if ($Expire > 0)
      {
      my $Str = &DateValToStr($Expire);
      &DataPrint ("$Str");
      }
    &DataPrint ("\t");
    &DataPrint ("$Description\n");             # show descriptive text, if it exists
    }
  }

else                              # use a multi-line report format
  {
  if ($Found or ($Full >= 0))
    {
    &DataPrint ("Directory: $Path\n");
    }

  if ($Full >= 0)
    {
    if (!$Found)
      {
      &DataPrint ("No files\n\n");
      return;
      }
    &DataPrint ("Category $Cat\n");
    $Printed = 1;
    }
  if (($Full > 0) or ($NoExp)) # Always report inclusion of export restricted code
    {
    my $Str = "Export ";
    $Str .= $NoExp ? "restricted" : "unrestricted";
    &DataPrint ("$Str\n");
    }
  if ($Full > 0)
    {
    if ($Expire > 0)
      {
      my $Str = &DateValToStr($Expire);
      &DataPrint ("Expires on $Str\n");
      $Printed = 1;
      }
    my @Recipients = keys(%LDates);
    foreach my $name (@Recipients)
      {
      my $Str = "Can ship to ".ucfirst($name);
      my $Date = $LDates{$name};
      if ($Date)
        {
        $Str .= " until ";
        $Str .= &DateValToStr($Date);
        }
      &DataPrint ("$Str\n");
      $Printed = 1;
      if ($name eq $Recipient) { $Expire = $LDates{$name}; }
      }
    }
  }
if ($ShowFiles or $Zip or $GenPkg or $Manifest)
  {
  my @flist;
  my $name;
  my $shippable;

  return if (&HasExpired($Expire) and !$OverrideExpiry) ;

  if (!&CanShip($Recipient, keys(%LDates)))
    {
    if ($ShowFiles)
      {
      &DataPrint ("    Files not shippable to $Recipient\n\n");
      }
    return;
    }

  opendir(HERE, $Path);
  @flist = readdir(HERE);
  close(HERE);
  foreach my $name (@flist)
    {
    if (-d "$Path$name") { next; }
    if ($ShowFiles)
      {
      &DataPrint ("    $Path$name\n");
      $Printed = 1;
      }

    if ($GenPkg)
      {
      # --------------------------
      # print filespec to Pkg file
      # --------------------------
        &PkgPrint ("      <item src=\"$Path$name\"  dest=\"[sdkroot]$Path$name\"\/>\n");
      }   

    if ($Manifest)
      {
      # --------------------------
      # print filespec to manifest file
      # --------------------------
      &MfsPrint ("  $Path$name\n");
      }   

    if ($Zip)
      {
      if ($Cat eq 'A')
        {
        $ZippedCatA = 1;
        }
      if ($Cat eq 'X')
        {
        $ZippedCatX = 1;
        }
      print ZIPLIST "$Path$name\n" or die "Can't write to $ZipTmpFile\n";
      }
    }
  }
if ($Printed) { &DataPrint ("\n"); }
}

sub CanShip
{
my $to = shift;
my @list = @_;
my $count;
my $name;

return (1) if ($to eq 'all');
$count = @list;
if ($count)
  {
  return (0) if ($to eq 'generic');
  foreach my $name (@list)
    {
    return(1) if ($to eq $name);
    }
  return(0);
  }
return(1);
}

sub ReadDirFile
{
my $filename = shift;
my @dlist;

open(DIRLIST, $filename) or die "Can't open $filename\n";
while (<DIRLIST>)
  {
  $_ = lc $_;
  s/\s*#.*$//;              # remove comments
  s/\s*$//;                 # remove trailing whitespace
  if ($_ =~ /^$/) { next; } # ignore blank lines
  if (-d $_)                # entry is a valid directory
    {
    push(@dlist, $_);
    next;
    }
  else
    {
    &NotifyError("Unrecognised directory \"$_\" in \"$filename\" ignored");
    }
  }
close DIRLIST;
@dlist;
}

sub HasExpired
{
my $date = shift;
return ($date and ($date < $Now))
}

sub Strip
{
# Remove excess occurrences of '..' and '.' from a path
return undef unless $_[0]=~m-^\\-o;     # Must start with backslash
my $P=$_[0];
$P=~s-^\\\.{2}$-\\-o;                   # Convert plain "\.." to "\"  We are at the root anyway; can't go any higher!
$P=~s-\\\.$-\\-o;                       # Remove backslash-dot from end of line
$P=~s-\\(?!\.{2}\\)[^\\]*\\\.{2}$-\\-o; # Catch dotdot at end of text. Remove last directory.
while ($P=~s-\\\.\\-\\-go) { }          # Convert backslash-dot-backslash to backslash
while ($P=~s-\\(?!\.{2}\\)[^\\]*\\\.{2}(?=\\)--go) { }  # Convert backslash-fname-backslash-dotdot-backslash to backslash
$P;
}

sub Split
{
# return the section of a file path required - Path, Base, Ext or File
my ($Sect,$P)=@_;
$Sect=ucfirst lc $Sect;
if ($Sect eq 'Path')
  {
  if ($P=~/^(.*\\)/o)
    {
    return $1;
    }
  return '';
  }
if ($Sect eq 'Base')
  {
  if ($P=~/\\?([^\\]*?)(\.[^\\\.]*)?$/o)
    {
    return $1;
    }
  return '';
  }
if ($Sect eq 'Ext')
  {
  if ($P=~/(\.[^\\\.]*)$/o)
    {
    return $1;
    }
  return '';
  }
if ($Sect eq 'File')
  {
  if ($P=~/([^\\]*)$/o)
    {
    return $1;
    }
  return '';
  }
undef;
}

sub ValidateExcPath
{
my $p = $_[0];
if ((!(-e $p)))
  {
  &NotifyWarning("Unrecognised exclusion directory \"$p\" will be ignored");
  return undef;
  }
$p=~s-^(.*[^\\])$-$1\\-o; # ensure it ends with a backslash
$p;
}

sub ValidateIncPath
{
my $p = $_[0];
if ((!(-e $p)))
  {
  &NotifyWarning("Unrecognised inclusion directory \"$p\" will be ignored");
  return undef;
  }
$p=~s-^(.*[^\\])$-$1\\-o; # ensure it ends with a backslash
$p;
}

sub MakeAbs
{
return undef unless $_[0]=~m-^\\-o;	# Ensure that $Path begins with backslash, i.e. starts from root
my ($Path,@List)=@_;
my $BasePath=&Split("Path",$Path);
undef $Path;
my $p;
foreach $p (@List)
  {
  if ($p=~m-^\.{1,2}-o)	# Directory == "." or ".."?
    {
    $p=&Strip($BasePath.$p);
    next;
    }
  if ($p=~m-(^.:)-o)	# Directory starts with drive-letter:
    {
    if (uc $1 eq $WorkDrv) {next;};     # Allow current drive for backward compatability.
    print "Drive specifications not supported\n";
    exit 1;
    }
  if ($p=~m-^[^\.\\]-o)	# Directory does not start with dot or backslash
    {
    $p=$BasePath.$p;
    next;
    }
  if ($p=~m-^\\-o)	    # Directory starts with a backslash
    {
    next;
    }
  if ($p=~m-^\.\\(.*)$-o)	# Directory starts with a dot, then a backslash. What's left becomes $1
    {
    $p=&Strip($BasePath.$1);
    next;
    }
  return undef;			# None of the above
  }
return @List;
}

sub FindZip
{
   my $PathList = $ENV{ 'PATH' };
   my (@PathSplit) = split( ";",$PathList );

   if ( -e ( $WorkPath."zip.exe" ) )        # Check current directory first
   {
     return 1;
   }
   foreach my $p ( @PathSplit )
   {
      if ( -e ( $p."\\zip.exe" ) )
      {
         return 1;
      }
   }
   return 0;
}

sub Usage
{
print <<ENDHERESTRING;
IPRTOOL.PL   Version 1.41  Copyright (c) 2000, 2001 Symbian Ltd.
                           All rights reserved
Usage:
    perl iprtool.pl [options] [help|?]

where options are:
    -c[ats] ABCDEFGIOTX      report the listed categories (default: EFGOT)
    -d[ir] <path>[<file>]    start scan at the specified directory; if a file
                             specification, scan all directories listed in the
                             file (defaults to the current working directory)
    -e[xport]                include files subject to DTI export restrictions
    -f[ull] [2|1|0|-1|-2]    set the extent of the summary of the content of
                             the policy file for each directory:
                               2  one line of tab-separated data per directory
                               1  full policy data for each directory
                               0  directory name and category (the default)
                              -1  no IPR information
                              -2  suppress all summary output, except errors
    -g[enpkg] <pkgfile>      create an XML package file for the selected files
    -l[icensee] <IDstr>      specify a recipient by name (not code name)
    -m[anifest] <outfile>    write a file list in manifest format to <outfile>
    -n[osub]                 do not include subdirectories in the report
    -o[verrideexpiry]        include source whose expiry date is in the past
    -p[roject] <prj>         include specific source directories listed in
                             <prj>.extra (overrides any exclusions)
    -r[eport] <product>      produces an ASCII and a HTML report on the syntax
                             and semantics of all the distribution policy files
    -s[howfiles]             list the files in each reported directory
    -x[clude] <path>[<file>] specify head(s) of whole directory tree(s) to
                             exclude from the scan (format as for the -d flag) 
    -z[ip] <zipfile>         create a zipfile of the selected files

-----------------------------------------------------------------------------

This tool provides the ability to create zips of selected source and/or to 
construct reports, either for external distribution or for internal audit 
purposes.

The types of report available include:

·	a full description of the IPR status of each directory
·	a listing of all directories containing code of a specified category or set of categories

In each case the report may refer to one or more specific directories, with or without their included subdirectories, or the whole source directory tree.

Command line options are:
Option	Action	Default	See Note
-c[ats] <catIDs>	restrict report to the specified category or categories, where <catIDs> can be any combination  of one or more of A, B, C, D, E, F, G and X	report all categories	5
-d[ir] <path>[<file name>]	start scan at the specified directory or, if a file specification, scan all directories listed in the file	start scan at the current directory	2, 3
-e[xport]	include files that are subject to DTI export restrictions	don’t include export-restricted files	
-f[ull] 2|1|0|-1|-2	set extent of the summary of the content of the policy file for each directory:
	 2    one line of tab-separated
	       data per directory
	 1    full, multi-line
	 0    reduced (the default)
	-1    no IPR data, directory
	       names only
	-2   suppress all output other
	       than error reports	reduced - report the directory name and category	
-g[enpkg] <pkgfile>	create an XML package file for the selected files	don’t create an XML package file	
-l[icensee] <Idstr>	specify a particular recipient	assume a ‘generic’ recipient	1
-m[anifest] <outfile>	write a file list in manifest format to <outfile>	don’t create a manifest listing	
-n[osub]	do not include subdirectories in the report	include subdirectories	
-o[verrideexpiry]	include source whose expiry date is in the past	obey expiry dates	
  -p[roject] <prjname>	  specify a particular project, to
	  enable the inclusion of
	  additional category D source	  no additional source	  4
-s[howfiles]	list the files in each reported directory	don’t list files	
  -x[clude] <path>[<file name>]	exclude the specified directory  and its subdirectories or, if a file specification, exclude all directory trees headed by the directories listed in the file	 no exclusions	 2, 3
-z[ip] <zipfile name>	create a zipfile of the selected (reported) files	create a report without zipping	

Notes
1) The convention is that true company names are to be used, not codenames. It is recommended that the name does not include spaces. Names are not validated.
Category B and C source code whose policy file contains Authorized statement(s) will not be included in a zip unless unless an Authorized statement name matches with the Licensee name specified by means of the -l flag.
Filtering of licensee-specific source may be overridden by specifying '-l all'. This should only be used for construction of internal deliveries which need to include source owned by multiple licensees.

2) An example of the content of a directory list file for use with the -d or -x flags is:

 # Example directory listing for use with iprtool.pl

 \\hal
 \\e32toolp

Directories may be listed with absolute paths, as above, or relative paths. Paths are always interpreted with respect to the current working directory, regardless of the location af the directory list file. Do NOT include drive letter.

3) Absolute paths used with the -d and -x flags, and within directory list files, may include drive letters, but their use is not recommended without good reason A valid reason to include a drive letter with the -d or -x flag is if a directory list file needs to be stored outside the drive that is being scanned. It is unlikely that there will ever be a valid reason to include drive letters in the paths listed in a directory listing file.

4) If a project is specified with the -p flag, and a file with the name '<prjname>.extra' is found in the directory from which the tool is run, the report is extended to include the content of all directories listed in that file (reported as though the -n flag were set, so all subdirectories need to be listed). A source file zip will not include category B an C source that is excluded as described in Note 1. Otherwise, this mechanism unconditionally includes the content of all listed directories, regardless of their category, export status or expiry date, and overriding any directories excluded by means of the -x flag. The following is a fictitious example file 'calypso.extra'

 # Additional source directories for  Calypso project deliveries
 
 \\rcomp
 \\rcomp\\group

5) Category X is exceptional. Uncategorised code - ie source in a directory without a distribution.policy file, or with a policy file that does not contain a valid Category statement - is reported as being in category X. No source should be actively classified as category X; any attempt to do so will be reported as an error by the tool.
Errors and warnings
The tool reports (to STDERR) errors and warnings that are found while scanning source directories. The most significant error notification is of missing policy files but the tool also reports on a wide variety of errors in the content of the policy files. Such errors include unrecognised keywords, unexpected duplicate keywords and illegal dates.

Warnings are also issued if a source zip includes source that is in category A or is uncategorised (cat X), or is subject to export restrictions.

ENDHERESTRING
exit 1;
}
