#!perl

# Copyright (c) 2004-2009 Nokia Corporation and/or its subsidiary(-ies).
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
# GT and TV Release notes generator
# How this script works...
# 1.Creates a list of all GT and TV components with their MRP file locations at both the current and previous CL.
# 2.Iterates through the previous CL list for any components that are not in the current CL list and adds these to 
# the currentCL list.
# 3.Runs a p4 print for each MRP file and stores each component and its source(s) to an array. Component names in uppercase
# and source lines in lowercase.
# 4.Iterates through this array extracting each component name and runs "p4 changes -l -s submitted" between the
# previous and current CL for each component source.
# 5.Outputs this data to a HTML file
# 
#

use strict;

#----------------------------GLOBAL DEFINITIONS-------------------------------------#
my $Product = $ARGV[0];
my $Srcpath = $ARGV[1];
my $PrevCL = $ARGV[2];       #Previous external release changelist number
my $CurrentCL = $ARGV[3];    #Current external release changelist number

my @PrevMrpComponents;	  #Array of Components at Previous changelist number
my @CurrMrpComponents;    #Array of Components at Current changelist number
my @NewMrpComponents;     #Array of Merged Components

my @ComponentAndSource;   #Array of all components and source
my @Components;           #Array of component names

my $GTfilename;           #Location of GTComponents.txt
my $TVfilename;			  #Location of TVComponents.txt
my $GTcomponents;         #List of all GTComponents and their MRP file locations
my $TVcomponents;		  #List of all TVComponents and their MRP file locations

my $CurrentMrps;          #List of all GT and TV components at the current CL number
my $PreviousMrps;         #List of all GT and TV components at the previous CL number
my $Platform;             #Platform of product specified, i.e. beech or cedar

my @CompChange;           #Array of component change information
my @CompLines;            #Array of just component changes
my @CompChangelists;      #Array of component changelist numbers

my $CompName;             #Component name
my $Topdir;               #Directory of component source

my @NochangeComponents;   #Array of components which have not been changed (may contain duplicate components)
my @UnchangedComponents;  #Array of non-duplicate components which have not been changed
my @ChangedComponents;    #Array of components which have been changed
my @NewComponents;        #Array of new components
my $ProductName;          #Name of product

my $ChangeExists;         #Flag which indicates any duplicate changes for a component
my $NewComponent;         #Flag which indicates if a component is new or not

my %CodeLine;             #Hash for holding main Codeline for each product

my $Marker = "**TECHVIEWCOMPONENTS**\n";   #Marker for splitting GT and TV Components

#-----------------------------------------------------------------------------------#

#Check that correct number of arguments were specified by the user
#If not then print out Usage instructions to the command window	
Usage() if (@ARGV!=4);

#Check that the inputs are valid
CheckInputs();

#Assign codeline for product
%CodeLine = (
	     "8.0" => "//EPOC/release/8.0",
	     "8.1a" => "//EPOC/release/8.1",
	     "8.1b" => "//EPOC/release/8.1",
	     "9.1" => "//EPOC/master",
	     "9.2" => "//EPOC/master",
	    );

#Create a list of all components and their MRP files at both the current and previous CL's
CreateMRPLists();

#Merge and process the lists
ProcessLists($PreviousMrps, $CurrentMrps);

#Begin creation of release notes using the merged list of MRPs
$NewComponent = 0;
$NewComponent = 1 if ($PrevCL == 0);

$PrevCL++;     # inc changelist number so we don't include the very first submission - it would have been picked up in the last run of this script

$ProductName = "Symbian_OS_v$Product Delivery Release Notes" if($Srcpath =~ m/deliver/i);
$ProductName = "Symbian_OS_v$Product Release Notes" if ($Srcpath =~ m/release/i);
if ($Srcpath =~ m/master/i)
{
	$ProductName = "Symbian_OS_v$Product MCL Release Notes";
}

my ( $s, $min, $hour, $mday, $mon, $year, $w, $y, $i)= localtime(time);
$year+= 1900;
$mon++;

open OUTFILE, "> $ProductName.html"
	or die "ERROR: Can't open $ProductName.html for output\n$!";
print OUTFILE <<HEADING_EOF;
<html>\n\n<head>\n<title>$ProductName</title>\n</head>\n\n
<body bgcolor=\"#ffffff\" text=\"#000000\" link=\"#5F9F9F\" vlink=\"5F9F9F\">\n
<font face=verdana,arial,helvetica size=4>\n\n<hr>\n\n
<a name=\"list\"><h1><center>$ProductName</center></h1></a>
<p><center>Created - $mday/$mon/$year</center>\n
<p><center>----------------------------------------</center>\n
<h2><center>GT Components</center></h2>\n
HEADING_EOF

foreach my $element(@ComponentAndSource)
	{
	my $Preform = 0;
	my $ChangeCount = 0;
	my $Exists = 0;
	my $IsAFile = 0;
	
	if($element =~ /\*\*TECHVIEWCOMPONENTS\*\*/)
		{
		print OUTFILE "<h2><center>Techview Components</center></h2>\n";
		}
	
	if($element =~ /^([A-Z].*)/)  #Look for component names in array
		{
		$CompName = $1;
		@CompChangelists = ();
		}
	
	elsif($element =~ /^([a-z].*)/)  #Look for source directories in array
		{
		$Topdir = $1;
		$Topdir =~ s/\s+$//;  #drop any trailing spaces

		
		if($Topdir =~ /.*\s+.*/)
			{
			$Topdir = "\"$Topdir\"";
			}
		
		my $command = "p4 changes -l -s submitted $Srcpath/$Topdir...\@$PrevCL,$CurrentCL";
		@CompChange = `$command`;
		die "ERROR: Could not execute: $command\n" if $?;
		
		foreach my $line(@CompChange)
			{	
			if ($line !~ /\S/) { next; }      # ignore lines with no text 
	      	chomp $line;
	      	$line =~ s/\&/&amp;/g;
      		$line =~ s/\</&lt;/g;
     		$line =~ s/\>/&gt;/g;
      		$line =~ s/\"/&quot;/g;
	      		
			if($line =~ /^Change\s(\d+)\s/)
				{
				my $Change = $1;
				
				$ChangeExists = 0;
				
				$line =~ s|\s+by.*||;
				if ($Preform) 
          			{ 
          			push @CompLines, "</pre>"; 
          			$Preform = 0; 
          			}
          		
          		#Check if this change has already been accounted for in this component
          		foreach my $ChangeList(@CompChangelists)
         			{
	          		if($ChangeList == $Change)
	          			{
		          		$ChangeExists = 1;
	          			}
         			}
          		
         		#If the change is not a duplicate then add it to the changes array and output the change
         		#to Relnotes.
          		if($ChangeExists == 0)
          			{
	          		$ChangeCount+=1;
	          		push @CompChangelists, $Change;
       				push @CompLines, "<p><b>$line</b>";
        			push @CompLines, "<pre>";
    				}
    			
    			$Preform = 1;
        		next;
				}
				
			$line =~ s/^\s//;                 # drop first leading whitespace
   			$line =~ s/^\t/  /;               # shorten any leading tab
      		
   			if($ChangeExists == 0)
   				{
   				push @CompLines, $line;
				}
			}
		
		if ($ChangeCount == 0)
   			{
    		if ($NewComponent)
    			{
    			push @NewComponents, $CompName;
    			}
    		else
    			{	
    			push @NochangeComponents, $CompName;
    			}
    			next;
    		}
    		
    	# Component with real change descriptions
		if ($Preform)
			{
			push @CompLines, "</pre>";
			}
		
		#Populate the changed components array with all changed components
		foreach my $entry(@ChangedComponents)
			{
			if($entry eq $CompName)
				{
				$Exists = 1;
				}
			}
			
		if($Exists == 0)
			{
			&PrintLines("<h2>$CompName</h2>",@CompLines);
			push @ChangedComponents, $CompName;
			}
		
		else
			{
			&PrintLines("",@CompLines);
			}
		}
		
		@CompLines = ();
	}

#Get rid of any duplicate component entries in the Unchanged Components list.
for(my $ii = 0; $ii < @NochangeComponents; $ii++)
	{
	if($NochangeComponents[$ii] ne $NochangeComponents[$ii + 1])
		{
		push @UnchangedComponents, $NochangeComponents[$ii];
		}
	}

#Check for components which have been changed but still appear in the unchanged components list.
#This can occur when a component has more than one one source. i.e.one source could be changed while the other source
#remains unchanged.
foreach my $changed(@ChangedComponents)
	{
	foreach my $unchanged(@UnchangedComponents)
		{
		if($changed eq $unchanged)
			{
			$unchanged = "";       #Empty this array element
			}
		}
	}

#Get rid of any empty elements in the unchanged component array
my @FinalUnchangedList;
foreach my $element(@UnchangedComponents)
	{
	if($element ne "")
		{
		push @FinalUnchangedList, $element;
		}
	}

if (scalar @NewComponents)
	{
	&PrintLines("<h2>New Components</h2>", join(", ", sort @NewComponents));
	}
	
if (scalar @FinalUnchangedList)
	{
	if($Srcpath =~ m/deliver/i)
		{
		&PrintLines("<h2>Unchanged Components (Delivery)</h2>", join(", ", sort @FinalUnchangedList));
		}
	elsif($Srcpath =~ m/release/i)
		{
		&PrintLines("<h2>Unchanged Components</h2>", join(", ", sort @FinalUnchangedList));
		}
	else
		{
		&PrintLines("<h2>Unchanged Components (MCL)</h2>", join(", ", sort @FinalUnchangedList));
		}
	}

&PrintLines("</BODY></HTML>");
close OUTFILE;

#-------------------------------------------SUB-ROUTINES----------------------------------------------#

# CheckInputs
#
# Outputs the required platform and an error message if CL numbers are input incorrectly by the user
#
#
sub CheckInputs
	{
	#Assign appropriate platform
	if($Product eq "8.1a"||$Product eq "8.0")
		{
		$Platform = "beech";
		}

	elsif($Product eq "8.1b"||$Product eq "9.0"||$Product eq "9.1"||$Product eq "9.2")
		{
		$Platform = "cedar";
		}

	else
		{
		print "Product not recognised or not entered as first command line argument!!\n";
		exit 1;
		}

	#Protect against CL numbers being input incorrectly
	if($PrevCL >= $CurrentCL)
		{
		print "Changelist numbers must be entered in the order <Previous> <Current>\n";
		exit 1;
		}
        
        #Remove any trailing / from $Srcpath
        $Srcpath =~ s|/$||;
	}

# CreateMRPLists
#
# Outputs two lists of components and their MRP file locations at the previous and current CL's
#

sub CreateMRPLists
	{
	my $Prod;       #Temporary variable for product.  Needed because of 8.0a directory in Perforce
	
	#Change directory name to 8.0a if product is 8.0
	if($Product eq "8.0")
		{
		$Prod = "8.0a";
		}
	else
		{
		$Prod = $Product;
		}
		
	#Obtain GT and TV MRP File locations from Options.txt
	my $command = "p4 print -q $CodeLine{$Product}/$Platform/product/tools/makecbr/files/$Prod/options.txt 2>&1";
	my $OptionsFile = `$command`;
	die "ERROR: Could not execute: $command\n" if $?;
	
	my @OptionsFile = split /\n/m, $OptionsFile;
	foreach my $line(@OptionsFile)
		{
		if($line =~ /^Techview component list:(.*)/i)
			{
				$TVfilename = $1;
				$TVfilename =~ s|\\|\/|g;
				$TVfilename =~ s|/src/.*?/|$CodeLine{$Product}/$Platform/|;
			}
		elsif($line =~ /^GT component list:(.*)/i)
			{
				$GTfilename = $1;
				$GTfilename =~ s|\\|\/|g;
				$GTfilename =~ s|/src/.*?/|$CodeLine{$Product}/$Platform/|;
			}
		}

	#Create List of Previous MRPs
	my $PrevGT = "p4 print -q $GTfilename...\@$PrevCL 2>&1";
	$GTcomponents = `$PrevGT`;
	die "ERROR: Could not execute: $PrevGT\n" if $?;
	
	my $PrevTV = "p4 print -q $TVfilename...\@$PrevCL 2>&1";
	$TVcomponents = `$PrevTV`;
	die "ERROR: Could not execute: $PrevTV\n" if $?;
	
	$GTcomponents = $GTcomponents.$Marker;
	$PreviousMrps = $GTcomponents.$TVcomponents;

	#Create List of Current MRPs
	my $CurrGT = "p4 print -q $GTfilename...\@$CurrentCL 2>&1";
	$GTcomponents = `$CurrGT`;
	die "ERROR: Could not execute: $CurrGT\n" if $?;
	
	my $CurrTV = "p4 print -q $TVfilename...\@$CurrentCL 2>&1";
	$TVcomponents = `$CurrTV`;
	die "ERROR: Could not execute: $CurrTV\n" if $?;
	
	$GTcomponents = $GTcomponents.$Marker;
	$CurrentMrps = $GTcomponents.$TVcomponents;
	}

# ProcessLists
#
# Inputs - Two lists of Components and their MRP file locations at the previous and current CL's
#
# Outputs a merged list containing all Components in uppercase and their sourcelines in lowercase
#
# Description
# This function creates a list of all components and their MRP files. The MRP files are then used
# to obtain the source for each component. This information is then input to an array in the form
# [COMPONENT1] [source] [COMPONENT2] [source] [source] [COMPONENT3] [source] ..........
#

sub ProcessLists
	{
	if(@_ != 2)
	{
		print "Could not process MRP lists as both lists were not provided.\n";
		exit 1;
	}
	
	my $PreviousMrps = shift;
	my $CurrentMrps = shift;
	my @MrpContents;
	
	#Do some slight modifications to source path for both lists
	$PreviousMrps =~ s|\\|\/|g;
	$PreviousMrps =~ s|/src/|$CodeLine{$Product}/|ig;
	$PreviousMrps =~ s|/product/|$CodeLine{$Product}/$Platform/product/|ig;
	
	$CurrentMrps =~ s|\\|\/|g;
	$CurrentMrps =~ s|/src/|$CodeLine{$Product}/|ig;
	$CurrentMrps =~ s|/product/|$CodeLine{$Product}/$Platform/product/|ig;
	
	@PrevMrpComponents = split /\n/m, $PreviousMrps;
	@CurrMrpComponents = split /\n/m, $CurrentMrps;
	
	foreach my $PrevComp(@PrevMrpComponents)
		{
		my $match = 0;
		
		#Compare component lists to ensure they contain the same components.
		foreach my $CurrComp(@CurrMrpComponents)
			{
			if($PrevComp eq $CurrComp)
				{
				$match = 1;
				}
			}
		
		#If a component is found in the Previous list which isn't in the Current list, then insert it into the Current list
		if($match == 0)
			{
			push @CurrMrpComponents, $PrevComp;
			}
		}

	#Use the MRP locations of each component to obtain the source for each component
	foreach my $ComponentLine(@CurrMrpComponents)
		{
		if($ComponentLine =~ /.*\s+(.*)/)
			{
			my $MrpFile = $1;
		
			my $Temp = `p4 print -q $MrpFile 2>&1`;
			
			#If a component has been removed between the PrevCL and CurrentCL then its MRP file will
			#only exist at the PrevCL
			unless($Temp =~ /source/i)
				{
				$Temp = `p4 print -q $MrpFile\@$PrevCL 2>&1`;
				}
				
			@MrpContents = split /\n+/m, $Temp;
			}
		elsif($ComponentLine =~ /\*\*TECHVIEWCOMPONENTS\*\*/)
			{
			push @MrpContents, $ComponentLine;
			}
		
		#Construct an array containing components in uppercase followed by all their sourcelines in lowercase
		foreach my $line(@MrpContents)
			{
			if($line =~ /^component\s+(.*)/i)
				{
				my $ComponentName = uc($1);
				push @ComponentAndSource, $ComponentName;
				}
			
			if($line =~ /^source\s+(.*)/i)
				{
				my $Source = lc($1);
				$Source =~ s/\\/\//g;
				$Source =~ s|/src/||;
				$Source =~ s|/product/|$Platform/product|ig;
				push @ComponentAndSource, $Source;
				}
				
			if($line =~ /TECHVIEWCOMPONENTS/)
				{
				push @ComponentAndSource, $line;
				}
			}
		}
	}

# PrintLines
#
# Input - An array containing text information
#
# Outputs each element of the input array seperated by a newline to the OUTFILE
#

sub PrintLines 
	{ 
	print OUTFILE join("\n",@_),"\n"; 
	}

# Usage
#
# Outputs instructions on how to run this script
#

sub Usage
	{
	 print <<USAGE_EOF;

Usage
-----
perl ReleaseNotes.pl <product> <codeline> <previous CL Num> <current CL Num>

Generates an HTML document containing release notes for the specified product.

<product> The product for which the release notes are to be generated
eg
  8.0, 8.1a, 8.1b, 9.0, 9.1


<codeline> The codeline on which the perl tool is to be run
eg
  For MCL - //EPOC/master
  For 8.0 - //EPOC/release/8.0
  For Delivery (MCL) - //EPOC/deliver/master/2004/<snapshot_number>
  For Delivery (8.0) - //EPOC/deliver/product/8.0/2004/<snapshot_number>/src

<previous CL Num> The changelist number of the previous external build

<current CL Num> The changelist number of the current external build candidate


Example for MCL codeline
------------------------

perl ReleaseNotes.pl 9.0 //EPOC/Master 438931 442567

This generates release notes in a file named
Symbian_OS_v9.0 MCL Release Notes.html

USAGE_EOF
  	exit 1;
	}





