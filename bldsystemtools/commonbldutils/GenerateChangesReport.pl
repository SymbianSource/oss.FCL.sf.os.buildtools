#! perl

use strict;
use Getopt::Long;

# TODO:
# Improve performance by not accessing P4 for every source line in every MRP file
# Handle situation where clean-src dir is missing by accessing MRP file from Perforce
# Use autobuild database to get perforce information directly?
# What should we do about change C reverts change B which reverted change A? 
#  => Hope C has a good description, as this implementation will discard both A and B descriptions.

#note: currently relies on existence of perforce report of previous build

# Parameters passed to script
my $Product = shift;           	# e.g. 9.3
my $Platform = shift;          	# e.g. cedar       
my $CurentBuild = shift;       	# e.g. 03935
my $CurrentCL = shift;         	# e.g. 775517
shift;				# e.g. 03935_Symbian_OS_v9.3
my $CurrCodeLine = shift;   	# e.g. //epoc/master/
my $PreviousBuild = shift;	# the build number of the previous release (eg 03925)
my $LogDirs = shift;           	# e.g. \\builds01\devbuilds
my $CleanSourceDir = shift;	# e.g. M:\clean-src (synched file from perforce)

my $debug = 0; 		       	# set to 1 to print debug logfile and progress information

GetOptions(
  	'v' => \$debug);

# Derived parameters
my $CurrBldName = "$CurentBuild\_Symbian_OS_v$Product";	# e.g. 03935_Symbian_OS_v9.3


# Global variables

my $PreviousLogDir;		# location of the logs associated with the previous release build 
my $PrevFileAndPath;		# name of the previous release build's perforce report and its location
my $PrevBldName;                # e.g. 03925_Symbian_OS_v9.3

my $MainLineCL = 0;             # the CL of the build from which the current build
                                #    was branched if it is on a delivery branch
my $MainLineLine;               # the codeline of the build from which the current
                                #    build was branched if on a delivery branch

my %allDefects;			# hash containing all of the defect fixes
my %allBreaks;			# hash contains all of the delivered breaks
my %changeToComponents;	# hash containing lists of components affected by a given change
my %reverted;			# hash of reverted changelists

# Tidy up directories to ensure they are in a standard format
$CurrCodeLine =~ s/[^\/]$/$&\//;# ensure a trailing fwdslash for codeline
$LogDirs =~ s/\\$//;		# ensure no trailing back slash for codeline
$CleanSourceDir =~ s/\\$//;	# ensure no trailing back slash for codeline

# add information to the debug log if the debug flag is set
if ($debug)
{
    # Open an error log
    open ERRORLOG, "> Errorlog.txt";
    print ERRORLOG <<"END";
Inputs:

Product: $Product
Platform: $Platform
Current build: $CurentBuild
Current build CL: $CurrentCL
Current Build Name: $CurrBldName
Previous Build: $PreviousBuild
Log Directory: $LogDirs
Clean Source Dir: $CleanSourceDir

Errors:

END
}

# If the previous release was from a delivery branch, then use the build from 
# from which the delivery branch was created by removing the letters (changes
# on the files on the branch will also have been made on the main codeline)
$PreviousBuild =~ s/[a-z]+(\.\d+)?//;

# If the current build is on a delivery branch, then store the information about
# the build from which it was branched as it will be necessary to get the descriptions
# from perforce for versions on the branch and versions on the main codeline up to 
# where the branch was created separately

if ($CurentBuild =~ /[a-z]+/)
{
    my $MainLineBuild = $CurentBuild;
    $MainLineBuild =~ s/[a-z]+(\.\d+)?//;
    # There is insufficient information here anyway, e.g. if M09999 failed and we did 
    # M09999.01 as the original candidate, then there is no way of telling the tool
    
    my $MainLineBldName = "$MainLineBuild\_Symbian_OS_v$Product";
    my $MainLinePerforce = "$LogDirs\\$MainLineBldName\\logs\\$MainLineBuild\_$Product" . "PC_Perforce_report.html";
    ($MainLineCL, $MainLineLine) = GetPrevCodelineandCL($MainLinePerforce, $Platform);
}

# Construct the previous build name
$PrevBldName = "$PreviousBuild\_Symbian_OS_v$Product";

# Construct the name of the peforce report file for the previous external release
# to look similar to this:  03925_9.3PC_Perforce_report.html
my $PerforceReport = $PreviousBuild."_".$Product."PC_Perforce_report.html";

# Look for $PerforceReport in the build logs directory and the log archive directory
$PreviousLogDir = "$LogDirs\\$PrevBldName\\logs\\";

$PrevFileAndPath = $PreviousLogDir.$PerforceReport;

if (! -d $CleanSourceDir)
{
    # if the report is found in neither directory then die
    if ($debug==1)
    {
      print ERRORLOG "Clean-src directory does not exist! ($CleanSourceDir)\n";
    }
    die "ERROR: Clean-src directory does not exist";
}

if (! -e $PrevFileAndPath)
{ 
    $PreviousLogDir = "$LogDirs\\logs\\$PrevBldName\\";  
    $PrevFileAndPath = $PreviousLogDir.$PerforceReport;
}
if (! -e $PrevFileAndPath)
{
    # if the report is found in neither directory then die
    if ($debug==1)
    {
      print ERRORLOG "Could not find Perforce report of previous external release! ($PrevFileAndPath)\n";
    }
    die "ERROR: Cannot find previous Perforce report";
}

# Parse the Perforce report to extract the previous build's change list and codeline path
my ($PreviousCL, $PrevCodeLine) = GetPrevCodelineandCL($PrevFileAndPath, $Platform);

# Create the path of the current build's log directory
my $CurrentLogDir = "$LogDirs\\$CurrBldName\\logs\\";

# Obtain the component lists (arrays are passed back by reference, each element containing a component
# name separated by one or more spaces from its associated mrp file as it appears in the component files)
my ($GTprevCompList, $GTlatestCompList, 
    $TVprevCompList, $TVlatestCompList) = GetGTandTVcomponentLists($CurrentLogDir, $PreviousLogDir);

# Consolidate the lists of components in to two hashes: one for the current build and one for the previous
# release build. These contain an index to distinguish between GT and TechView components and another index
# with the names of the components. The mrp files are the elements being indexed.
my ($PrevMRP, $CurrMRP) = CreateMRPLists($GTprevCompList, 
                                         $GTlatestCompList, 
                                         $TVprevCompList, 
                                         $TVlatestCompList);

# For each component, extract its source directories from its MRP file and add the information to a list 
my (@ComponentAndSource) = ProcessLists($Product, 
                                        $PrevCodeLine, 
                                        $Platform , 
                                        $PrevMRP, 
                                        $CurrMRP, 
                                        $PreviousCL,
                                        $CleanSourceDir);

# Put together the HTML file using the components list with their associated source files
(my $ChangesFileHTML) = CreateReleaseNotes($Product, 
                                           $CurrCodeLine,
                                           $MainLineLine,
                                           $PreviousCL, 
                                           $CurrentCL, 
                                           $MainLineCL,
                                           @ComponentAndSource);

if ($debug)
{
    close ERRORLOG;
}

print "FINISHED!! - $ChangesFileHTML\n";

exit;

#
#
# Gets component lists from the builds' log directories. Reads the contents 
# of the files in to arrays and returns references to these arrays.
#
# Inputs:  Current and previous build's logfile locations
# Outputs: Arrays containing contents of previous and current GTcomponents.txt
#          and TVcomponents.txt files (list of components with their associated
#          mrp files). An example array elment might contain:
#          "ChatScripts	\sf\os\unref\orphan\comtt\chatscripts\group\testtools_chatscripts.mrp"
#
sub GetGTandTVcomponentLists
{
    my ($CurrLogPath, $PrevLogPath) = @_;

    # Data to return: array of refs to arrays of contents of files
    my @return;

    # Files to read from
    my @FileNames = (
        $PrevLogPath."GTcomponents.txt",
        $CurrLogPath."GTcomponents.txt",
        $PrevLogPath."TechViewComponents.txt",
        $CurrLogPath."TechViewComponents.txt",
    );

    foreach my $FileName (@FileNames)
    {
        if (!open(DAT, $FileName)) 
        { 
            if ($debug)
            {
                print ERRORLOG "Could not open $FileName!\n";
            }
            die "ERROR: Could not open $FileName: $!";
        }
        push @return, [<DAT>];
        close DAT;
    }

    return @return;
}

#
#
# Creates two list of components and their associated mrp files - one for the previous 
# build and one for the current build
#
# Inputs: the contents of the GT and TV components files
# Outputs: Two lists of components and their mrp files, one from the previous build
#          and one from the current build
#
#
sub CreateMRPLists
{
    # references to the contents of the components files              
    my $GTprevFile = shift; 
    my $GTlatestFile = shift; 
    my $TVprevFile = shift; 
    my $TVlatestFile = shift; 

    my %PreviousMrps;    #Hash of all Components and their MRP file locations for the previous build
    my %CurrentMrps;     #Hash of all Components and their MRP file locations for the current build
    
    # Add mrp files to a hash indexed under GT or TV and by component names 
    foreach my $case (
        [\%PreviousMrps, 'GT', $GTprevFile],
        [\%CurrentMrps,  'GT', $GTlatestFile],
        [\%PreviousMrps, 'TV', $TVprevFile],
        [\%CurrentMrps,  'TV', $TVlatestFile],
        )
    {
        foreach my $element (@{$case->[2]})
          {
            if ( $element =~ /(.*)\s+(\\sf\\.*)$/ )
            {
                ${$case->[0]}{$case->[1]}{uc($1)} = lc($2);
            }
          }
    }
    
    return \%PreviousMrps, \%CurrentMrps;
}


#
#
# Use the contents of the MRP files to create a single list containing the GT and TechView
# components paired with associated source files.
#
# Inputs: Product, Codeline, Previous Codeline, Platform, Both lists of mrps, 
#         Previous Changelist number, Build machine's clean source directory which
#         contains copies of the current build's mrp files.
# Outputs: Array containing all components and their source locations
#
#
sub ProcessLists
{
    my $Product = shift;
    my $PrevCodeLine = shift;
    my $Platform = shift;
    my $PreviousMrps = shift;   #Hash of MRPs at the Previous changelist number
    my $CurrentMrps = shift;    #Hash of MRPs at the Current changelist number
    my $PrevCL = shift;
    my $CleanSourceDir = shift;

    my @PrevGTMrpComponents;    #Array of GT Components at Previous changelist number
    my @CurrGTMrpComponents;    #Array of GT Components at Current changelist number
    my @PrevTVMrpComponents;    #Array of TV Components at Previous changelist number
    my @CurrTVMrpComponents;    #Array of TV Components at Current changelist number
	
    # Isolate hashes
    my $CurrGT = $CurrentMrps->{'GT'};
    my $CurrTV = $CurrentMrps->{'TV'};
    my $PrevGT = $PreviousMrps->{'GT'};
    my $PrevTV = $PreviousMrps->{'TV'};

    # Append the location of the clean source directory for the current build
    # to all the mrp files. If a file appears only in the previous build (i.e.  
    # a component has been removed) its location in perforce is later substituted
    # in place of this path
    foreach my $component (sort keys %$CurrGT)
    {
	$CurrGT->{$component} =~ s|\\sf|$CleanSourceDir|ig;
        $CurrGT->{$component} =~ s|\\|\/|g;
	push @CurrGTMrpComponents, "$component\t$CurrGT->{$component}";
    }

    foreach my $component (sort keys %$CurrTV)
    {
	$CurrTV->{$component} =~ s|\\sf|$CleanSourceDir|ig;
	$CurrTV->{$component} =~ s|\\|\/|g;
	push @CurrTVMrpComponents, "$component\t$CurrTV->{$component}";
    }

    foreach my $component (sort keys %$PrevGT)
    {
	$PrevGT->{$component} =~ s|\\sf|$CleanSourceDir|ig;
	$PrevGT->{$component} =~ s|\\|\/|g; 
	push @PrevGTMrpComponents, "$component"."\t"."$PrevGT->{$component}";
    }

    foreach my $component (sort keys %$PrevTV)
    {
	$PrevTV->{$component} =~ s|\\sf|$CleanSourceDir|ig;
	$PrevTV->{$component} =~ s|\\|\/|g;
	push @PrevTVMrpComponents, "$component"."\t"."$PrevTV->{$component}";
    }
    
    # add any components that appear only in the previous build's list to the 
    # current build's list with its location in perforce.
    foreach my $PrevGTComp(@PrevGTMrpComponents)
    {
    	my $match = 0;
    	#Compare component lists to ensure they contain the same components.
    	foreach my $CurrGTComp(@CurrGTMrpComponents)
    	{
	    $match = 1 if($PrevGTComp eq $CurrGTComp);
	}
	
	#If a component is found in the Previous list which isn't in the Current list, 
        #then insert it into the Current list with the previous build's path
	if($match == 0)
        {
            $PrevGTComp =~ s|\/|\\|g;
            $PrevGTComp =~ s|\Q$CleanSourceDir\E\\|$PrevCodeLine|ig;
            $PrevGTComp =~ s|\\|\/|g;
            push @CurrGTMrpComponents, $PrevGTComp;    
        }
    }

    # add any components that appear only in the previous build's list to the 
    # current build's list with its location in perforce.
    foreach my $PrevTVComp(@PrevTVMrpComponents)
    {
    	my $match = 0;
    	#Compare component lists to ensure they contain the same components.
    	foreach my $CurrTVComp(@CurrTVMrpComponents)
    	{
	    $match = 1 if($PrevTVComp eq $CurrTVComp);
	}
	
	#If a component is found in the Previous list which isn't in the Current list, 
        #then insert it into the Current list
        if($match == 0)
        {
           $PrevTVComp =~ s|$CleanSourceDir|$PrevCodeLine|ig;
	   push @CurrTVMrpComponents, $PrevTVComp;
        }
    }

    # Combine current GT and TV components, with a boundary marker
    my @CurrMrpComponents = (@CurrGTMrpComponents, "**TECHVIEWCOMPONENTS**", @CurrTVMrpComponents);

    # Swap the back slashes for forward slashes
    $CleanSourceDir =~ s/\\/\//g;
    $PrevCodeLine =~ s/\\/\//g;
 
    #Use the MRP file for each component to obtain the source directory locations
    my @ComponentAndSource;
    foreach my $ComponentLine(@CurrMrpComponents)
    {
        #Array to hold mrp file contents
        my @MrpContents;

        # if the file is in the Clean Source Directory then read its contents from there
	if($ComponentLine =~ /.*(\Q$CleanSourceDir\E.*)/)
	{ 
	    my $MrpFile = $1;
	    $MrpFile =~ s/\.mrp.*$/\.mrp/;  #drop any trailing spaces or tabs
            if (-e $MrpFile)
            {
                open(FILE, $MrpFile);
                @MrpContents=<FILE>;
                close FILE;
            }          
	}
        elsif($ComponentLine =~ /.*(\Q$PrevCodeLine\E.*)/)
        {
	    # If a component has been removed between the previous build and the current one then 
	    # its MRP file will only exist at the PrevCL
            @MrpContents = `p4 print -q $1...\@$PrevCL`; # access Perforce via system command 
        }
	elsif($ComponentLine =~ /\*\*TECHVIEWCOMPONENTS\*\*/)
	{
	    push @MrpContents, $ComponentLine;
	}
        
	#Construct an array containing components in uppercase followed by 
        #all their sourcelines in lowercase
	foreach my $line(@MrpContents)
	{
	    if($line =~ /^component\s+(.*)/i)
	    {
		my $ComponentName = uc($1);
		push @ComponentAndSource, $ComponentName;
	    }
	    elsif($line =~ /^source\s+(.*)/i)
	    {
		my $Source = lc($1);
		$Source =~ s/\\/\//g;
		$Source =~ s|/sf/||;
		$Source =~ s|/product/|$Platform/product|ig;
		push @ComponentAndSource, $Source;
            }
	    elsif($line =~ /TECHVIEWCOMPONENTS/)
	    {
		push @ComponentAndSource, $line;
	    }
	}
    }
    return @ComponentAndSource;
}

#
# Format the changes associated with a component
#
# Inputs: 
#   reference to hash of change descriptions by changelist number, 
#	component name, 
#   reference to (formatted) list of names of changed components
#   reference to list of names of unchanged components
#
# Updates: 
#   adds component name to changed or unchanged list, as appropriate
#
sub PrintComponentDescriptions(\%$\@\@)
{
	my ($Descriptions,$CompName,$ChangedComponents,$UnchangedComponents) = @_;
	
	if (scalar keys %{$Descriptions} == 0)
	{
		# no changes in this component
		push @{$UnchangedComponents}, $CompName;
		return;
	}
	push @{$ChangedComponents}, "<a href=\"#$CompName\">$CompName</a>";
	
    # Format the changes for this component
    
	my @CompLines = ("<h2><a name=\"$CompName\"/>$CompName</h2>");
    foreach my $change (reverse sort keys %{$Descriptions})
    {
        # Heading for the change description
        my $summary = shift @{$$Descriptions{$change}};
        $summary =~ s/(on .*)\s+by.*//;
        $summary = "<a href=\"#$change\">Change $change</a> $1";
        push @CompLines, "<p><a name=\"#$CompName $change\"/><b>$summary</b>";
        # Body of the change description
        push @CompLines, "<pre>";
        push @CompLines,
            grep { $_; }	# ignore blank lines
            @{$$Descriptions{$change}};
        push @CompLines, "</pre>";

		# record the component in the cross-reference table
        push @{$changeToComponents{$change}}, "<a href=\"#$CompName $change\">$CompName</a>";
    }

	&PrintLines(@CompLines);
}

#
#
# Creates the Release Notes html file by extracting the perforce descriptions for each
# change that has been made to the components
#
# Inputs: Product, Source path of the product (i.e.//EPOC/master), the source path on the
#         main codeline if a delivery branch is being used, Previous changelist,
#         Current changelist, changelist from which the branch was made if a branch is being 
#         used, array of components and their source.
# Outputs: Release Notes html file.
#
# Algorithm:
#   Loop through the component&source array
#       Determine whether a boundary, component name, a source dir
#       If a source dir, query perforce to see what changelists have affected it in the period that we're interested in
#       If it has been affected, add the changelist to this component's changelists, unless it's already there
#
#   This is rather inefficient :-(
#
sub CreateReleaseNotes
{
    my $Product = shift;
    my $Srcpath = shift;
    my $MainLinePath = shift;
    my $PrevCL = shift;
    my $CurrentCL = shift;
    my $BranchCL = shift;
    my @ComponentAndSource = @_;

    #Reset all arrays to NULL
    my @PrevGTMrpComponents = ();
    my @CurrGTMrpComponents = ();
    my @PrevTVMrpComponents = ();
    my @CurrTVMrpComponents = ();
    my @CurrMrpComponents = ();
    my @Components = ();
    my @UnchangedComponents = ();
    my @ChangedComponents = ();
    my %changeProcessed = ();		# hash of changelists processed for this component
    my %changeToDescription = ();	# hash of descriptions for non-reverted changelists
    
    $PrevCL++;     # increment changelist number so we don't include the very first submission 
                   #  - it would have been picked up in the last run of this script
    
    my $ProductName = "Symbian_OS_v$Product\_Changes_Report";
    
    open OUTFILE, "> $ProductName.html" or die "ERROR: Can't open $ProductName.html for output\n$!";
    print OUTFILE <<HEADING_EOF;
<html>\n\n<head>\n<title>$ProductName</title>\n</head>\n\n
<body bgcolor="#ffffff" text="#000000" link="#5F9F9F" vlink="5F9F9F">\n
<font face=verdana,arial,helvetica size=4>\n\n<hr>\n\n
<a name="list"><h1><center>$ProductName</center></h1></a>
<p><center>----------------------------------------</center>\n
<h2><center><font color = "blue">GT Components</font></center></h2>\n
HEADING_EOF
    
    my $CompName;
    my $dirCount = 0;


    # Loop through the list of elements running perforce commands to obtain the descriptions
    # of any changes that have been made since the last release build
    foreach my $element(@ComponentAndSource)
    {
        # Is it the boundary?
        if($element =~ /\*\*TECHVIEWCOMPONENTS\*\*/)
		{
			# print out the accumulated GT component, if any
		    &PrintComponentDescriptions(\%changeToDescription, $CompName, \@ChangedComponents, \@UnchangedComponents) if ($dirCount);
		    $dirCount = 0;
		    # no need to clear the hashes, because that will happen at the first TV component
		    
			print OUTFILE "<h2><center><font color = \"blue\">Techview Components</font></center></h2>\n";
		}
        # Is it a component name?
        elsif($element =~ /^([A-Z].*)/)
		{
		    my $newName = $1;
		    
		    &PrintComponentDescriptions(\%changeToDescription, $CompName, \@ChangedComponents, \@UnchangedComponents) if ($dirCount);
		    $dirCount = 0;
		    
		    $CompName = $newName;
		    %changeProcessed = ();
		    %changeToDescription = ();
		    print "Processing $CompName...\n" if ($debug);
		}
        # Is it a source directory?
		elsif($element =~ /^([a-z].*?)\s*$/)
		{
		    my $Topdir = $1;
		    $dirCount++;
	            
	        # If it contains spaces, quote it
		    if($Topdir =~ /.*\s+.*/)
		    {
			$Topdir = "\"$Topdir\"";
		    }

		    # Find the changes that have affected this dir
		    # (Changes come back in reverse chronological order)
            my @CompChange = `p4 changes -l $Srcpath$Topdir...\@$PrevCL,\@$CurrentCL`;

            # if the current release is on a branch then the p4 command also needs to be run
            # to capture changes on the codeline before the files were branched
            if ($MainLinePath)
            {
                # So far, @CompChange contains the info from the delivery
                # branch only
                # The earliest changelist on the delivery branch is the creation
                # of the branch, which is not interesting to anyone.
                # Hence, remove it here:
                
                # Work backwards from the end of the output chopping off the
                # last item till we've chopped off a changelist header
                my $choppedText;
                do
                {
                    # Remove last line
                    $choppedText = pop @CompChange;
                }
                until (!defined $choppedText || $choppedText =~ m/^Change\s\d+\s/);

                # Now append the earlier changes from the main line
                my @extrainfo = `p4 changes -l $MainLinePath$Topdir...\@$PrevCL,\@$BranchCL`;
                push @CompChange, @extrainfo;
            }

            # Normalise the output of P4
            @CompChange = map { split "\n"; } @CompChange;

            # Extract change descriptions into a hash keyed on changelist number
            my %moreChangeDescriptions;
            my $change;
            foreach my $line (@CompChange)
            {
                if ($line =~ /^Change\s(\d+)\s/)
                {
                    my $newchange = $1;
                    $change = "";
                    # ignore if already processed for this component
                    next if ($changeProcessed{$newchange});
                    $changeProcessed{$newchange} = 1;
                    $change = $newchange;
                }
                next if (!$change);
                push @{$moreChangeDescriptions{$change}}, $line;
            }
            
            # Process changes (newest first), extracting the <EXTERNAL> section and 
            # processing any reversion information
            foreach my $change (reverse sort keys %moreChangeDescriptions)
            {
                if ($reverted{$change})
                {
                	print "REMARK: $CompName - deleting description of reverted change $change\n";
                	delete $moreChangeDescriptions{$change};
                	next;
                }

            	my @changeLines = @{$moreChangeDescriptions{$change}};
            	
            	my @revisedLines = ();
            	push @revisedLines, shift @changeLines;		# keep the "Change" line
            	
            	my $line;
            	while ($line = shift @changeLines)
            	{
            		last if ($line =~ /<EXTERNAL>$/);
            		
            		$line =~ s/^\t+//;
					$line =~ s/\&/&amp;/g; 
					$line =~ s/\</&lt;/g; 
					$line =~ s/\>/&gt;/g; 
					$line =~ s/\"/&quot;/g;	# quote the " character as well
					
            		push @revisedLines, $line;
            	}
            	
            	if (scalar @changeLines == 0)
            	{
            		# consumed the whole description without seeing <EXTERNAL>
            		# must be old format
            		@{$changeToDescription{$change}} = @revisedLines;
            		printf ".. unformatted change %d - %d lines\n", $change, scalar @changeLines if ($debug);
            		next;
            	}
            	
            	# Must be properly formatted change description
            	# discard everything seen so far except the "Change" line.
            	@revisedLines = (shift @revisedLines);
            	while ($line = shift @changeLines)
            	{
            		last if ($line =~ /<\/EXTERNAL>$/);
            		
            		$line =~ s/^\t+//;
					$line =~ s/\&/&amp;/g; 
					$line =~ s/\</&lt;/g; 
					$line =~ s/\>/&gt;/g; 
					$line =~ s/\"/&quot;/g;	# quote the " character as well

            		push @revisedLines, $line;
            		
            		# Opportunity to pick information out of changes as they go past
					if ($line =~ /^\s*((DEF|PDEF|INC)\d+):?\s/)
					{
						$allDefects{$1} = $line;
						next;
					}
					if ($line =~ /^(BR[0-9.]+)\s/)
					{
						$allBreaks{$1} = $line;
						next;
					}

            	}
            	
              	# update the description for this change
              	@{$changeToDescription{$change}} = @revisedLines;
            	printf ".. formatted change %d - %d external lines\n", $change, scalar @revisedLines if ($debug);
          	
                # check for reversion information in rest of the formatted description
                # submission checker delivers one <detail reverts=""> line per list element
                foreach my $line (grep /<detail reverts=/, @changeLines)
        		{
        			if ($line =~ /<detail reverts=\s*\"(\d+)\"/)	# changelist surrounded by "
        			{
        				my $oldchange = $1;
        				print "REMARK: Change $change reverts $oldchange\n";
        				$reverted{$oldchange} = $change;
        			}
        		}
            }
		}
	}
	
	# print description of last component
	&PrintComponentDescriptions(\%changeToDescription, $CompName, \@ChangedComponents, \@UnchangedComponents) if ($dirCount);

	# Print additional tables of information
    &PrintLines("<h2>Changed Components</h2>\n<nobr>", join(",</nobr> \n<nobr>", sort @ChangedComponents), "</nobr>") if (@ChangedComponents);
	
    &PrintLines("<h2>Unchanged Components</h2>\n<nobr>", join(",</nobr> \n<nobr>", sort @UnchangedComponents), "</nobr>") if (@UnchangedComponents);

	if (scalar @ChangedComponents)
	{
	    &PrintLines("<h2>Components affected by each change</h2>");
	    
	    &PrintLines("<TABLE>\n");
	    foreach my $change (reverse sort keys %changeToComponents)
	    {
	    	&PrintLines("<TR valign=\"top\"><TD><a name=\"#$change\"/>$change</TD><TD>", join(", ", @{$changeToComponents{$change}}), "</TD></TR>\n");
	    }
	    &PrintLines("</TABLE>\n");
	}
	
	my @allDefectTitles = ();
	foreach my $defect (sort keys %allDefects)
	{
		push @allDefectTitles,$allDefects{$defect};
	}
	&PrintLines("<h2>List of Defect Fixes</h2>", "<pre>", @allDefectTitles, "</pre>") if (scalar @allDefectTitles);
	
	my @allBreakTitles = ();
	foreach my $break (sort keys %allBreaks)
	{
		push @allBreakTitles,$allBreaks{$break};
	}
	&PrintLines("<h2>List of Breaks</h2>", "<pre>", @allBreakTitles, "</pre>") if (scalar @allBreakTitles);
	
    &PrintLines("</BODY></HTML>");
    close OUTFILE;
    
    return "$ProductName.html";
}

sub PrintLines
{
    # Output field and record separators set (locally) to produce newlines
    # between items in list, and another newline on the end
    local $, = "\n";
    local $\ = "\n";
    print OUTFILE @_;
}

#
#
# Extracts the sourcecode path and changelist from a Perforce report file.
#
# Inputs: Location of a perforce report file, Platform (e.g. cedar)
# Outputs: Source path of the product (e.g.//EPOC/master), changelist used in build
#
#
sub GetPrevCodelineandCL
{
    my $FileAndPath = shift;
    my $Platform = shift;

    my $LogFile;
    my $PrevCL;
    my $PrevCodeline;

    if (!open(DAT, $FileAndPath))
    {
        print ERRORLOG "Could not open $FileAndPath!\n" if $debug;
        die "ERROR: Cannot open $FileAndPath: $!\n";
    }
    {
        # Grab complete file in one string
        local $/ = undef;
        $LogFile = <DAT>;
    }
    close DAT;
    
    if ($LogFile =~ m{ClientSpec.*?<td[^>]*>.*?(//.+?)$Platform/.*?</tr>}s)
    {
       $PrevCodeline = $1;
    }
    
    if ($LogFile =~ m{Perforce Change[Ll]ist.*?<td[^>]*>(.*?)</tr>}s)
    {
        # Perforce changelist table data may either be in form of "nnnnnn" or "ssssss @ nnnnnn"
        # ssssss is the snapshot id, which may be a string of digits
        # nnnnnn is the changelist number
        # 
        # Get the later string of digits
        ($PrevCL) = $1 =~ m{(\d+)\D*$};
    }
    
    unless ($PrevCL) { die "ERROR: Unable to parse previous changelist from $FileAndPath\n"; }
    unless ($PrevCodeline) { die "ERROR: Unable to parse previous codeline from $FileAndPath\n"; }
    
    return $PrevCL, $PrevCodeline;
}


