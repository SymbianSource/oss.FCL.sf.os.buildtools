# Copyright (c) 2009 Nokia Corporation and/or its subsidiary(-ies).
# All rights reserved.
# This material, including documentation and any related 
# computer programs, is protected by copyright controlled by 
# Nokia. All rights are reserved. Copying, including 
# reproducing, storing, adapting or translating, any 
# or all of this material requires the prior written consent of 
# Nokia. This material also contains confidential 
# information which may not be disclosed to others without the 
# prior written consent of Nokia.
#
# Contributors:
#     matti.parnanen@nokia.com
#     pasi.kauraniemi@nokia.com
# 
# Description: Replace S60 header with Symbian Foundation license header.
#              Output file (results) is compatibe for SFMakeLxrLinks.pl as input.
#
use strict;
use File::Find;
use File::Basename;
use Getopt::Long;
use IO::Handle;
use FindBin qw($Bin);
use FileHandle;

####################
# Constants
####################

# Tool version
use constant VERSION => '2.1';
# Version history: 0.8 Added copyright year pick-up
# Version history: 0.9- Bug fixesg
# Version history: 0.95- EPL header support added
# Version history: 0.96 Minor script adjustments
# Version history: 0.97 Assembly files (.s, .cia, .asm) checked as well
# Version history: 0.98 Support for -oem added. Also @file tag removed from template
# Version history: 0.99 Testing -oem option
# Version history: 1.0 Comment column added for PostProcess script
# Version history: 1.01 Modify option bug fixed
# Version history: 1.1 Description bug fixed
# Version history: 1.2 Digia copyrights moved to SF as well. Also R/O attribute removed only for files modified
# Version history: 1.3 Distribution policy files handled as well. With -create also created
# Version history: 1.31 Fixes to distribution file handling (only non-empty directories acknowledged)
# Version history: 1.32 .pm files checked as well
# Version history: 1.4 Bug fixes and "ignorefile" agrument added
# Version history: 1.41 Bug fix in Description pick-up
# Version history: 1.42 Bug fix in -ignore option (also missing .s60 file creation need to be ignored). Default value set to ignore option
# Version history: 1.43 Description statistics fixed, .hpp added, description pick-up improved
# Version history: 1.5 -verify option implemented, ignorefile default value extended, statistics go to log
# Version history: 1.51 Copyright year pick-up bug fixed, ignorefilepattern comparison case-insensitive
# Version history: 1.52 current s60 dumped to result
# Version history: 1.53 abld.bat added ti ignorefile default
# Version history: 1.54 -verify statistics improved
# Version history: 1.55 -eula option added
# Version history: 1.56 .mmh files added, extra Non-Nokia check added for "No Copyright" case for weired headers
# Version history: 1.57 Changes to -verify
# Version history: 1.58 @echo on ... @echo off added to .cmd and .bat headers
# Version history: 1.59 EPL warning log entry --> info
# Version history: 1.60 and 1.61 -ignorelist option added
# Version history: 1.62 Uppercase REM text allowed
# Version history: 1.63 Internal directory check added to -verify
# Version history: 1.64 Symbian --> Symbian.*Ltd in $ExternalToNokiaCopyrPattern
# Version history: 1.65 Bug fixed in normalizeCppComment
# Version history: 1.70 Changes to better cope with ex-Symbian sources,
#                       Pasi's better "@rem" taken into use for .bat and .cmd files
# Version history: 1.71 Config file support added (option -config) for non 3/7 IDs
# Version history: 1.72 handleVerify checks improved to include also file start
# Version history: 1.73 \b added to Copyright word to reduce if "wrong" alarms
# Version history: 1.74 incomplete copyright check added to -verify
# Version history: 1.75 Support for ignoring generated headers (@sfGeneratedPatternArray) added
# Version history: 1.76 .script extension added (using Cpp comments e.g. // Text)
# Version history: 1.77 Reporting and logging improvements for wk19 checks (need to check / patch single files)
# Version history: 1.80 Few Qt specific file extensions added, -lgpl option added, 
#                       C++ comment fix in handleOem
# Version history: 1.90 checkNoMultipleLicenses function added, and call to handleVerify* added
# Version history: 2.0 handleDistributionValue() changes IDs 0-->3/7 and 3-->7, 
#                      isGeneratedHeader() checks for file content added.
# Version history: 2.01 checkPortionsCopyright implemented and applied
# Version history: 2.02 Extra license word taken out from EPL header
# Version history: 2.1 -verify -epl support added and switchLicense() tried first for SFL --> EPL switching

my $IGNORE_MAN ='Ignore-manually';
my $IGNORE ='Ignore';
my $INTERNAL = 'internal';
use constant KEEP_SYMBIAN => 0;
use constant REMOVE_SYMBIAN => 1;


#file extention list that headers should be replace
my @extlist = ('.cpp', '.c', '.h', '.mmp', '.mmpi', '.rss', '.hrh', '.inl', '.inf', '.iby', '.oby',
            '.loc', '.rh', '.ra', '.java', '.mk', '.bat', '.cmd', '.pkg', '.rls', '.rssi', '.pan', '.py', '.pl', '.s', '.asm', '.cia',
            '.s60', '.pm', '.hpp', '.mmh', '.script', 
            '.pro', '.pri');  # Qt specific

# Various header comment styles
my @header_regexps = 
(
'^\s*(\#.*?\n)*',           # Perl, Python
'^\s*(\@echo\s*off\s*\n)?\n*(@?(?i)rem.*?\n)*(\@echo\s*on\s*)?', # Windows command script
'^\s*(\;.*?\n)*',           # SIS package file
'\s*\/\*[\n\s\*-=].*?\*\/',  # C comment block
'(\s*\/\/.*\n)+',           # C++ comment block  (do not use /s in regexp evaluation !!!)
'^\s*((\/\/|\#).*?\n)*'       # Script file comment
);

# Comment regular expression (Indeces within @header_regexps)
use constant COMMENT_PERL => 0;
use constant COMMENT_CMD => 1;
use constant COMMENT_SIS_ASM => 2;
use constant COMMENT_C => 3;
use constant COMMENT_CPP => 4;
use constant COMMENT_SCRIPT => 5;

my $descrTemplateOnly = '\?Description';
my $linenumtext = "1";  # Use this linenumer in LXR links

# Copyright patterns
my $copyrYearPattern = 'Copyright\b.*\d{4}\s*([,-]\s*\d{4})*';
my $copyrYearPattern2 = '\d{4}(\s*[,-]\s*\d{4})*';
use constant DEFCOPYRIGHTYEAR => "2009";  # For error cases

my $NokiaCopyrPattern = '\bCopyright\b.*Nokia.*(All Rights)?';
my $NonNokiaCopyrPattern = '\bCopyright\b.*(?!Nokia).*(All Rights)?';
my $CopyrPattern = '\bCopyright\b';
my $RemoveS60TextBlockPattern = 'This material.*Nokia';
my $CC = 'CCHAR';
my $BeginLicenseBlockPattern = 'BEGIN LICENSE BLOCK';
my $OldNokiaPattern = 'Nokia\s*Corporation[\.\s]*\n';
my $NewNokiaText =  "Nokia Corporation and/or its subsidiary(-ies).\n";  # Used in substitu to text
my $NewNokiaPattern = "Nokia Corporation and/or its subsidiary";
my $OldNokiaPattern2 =  "This material.*including documentation and any related.*protected by copyright controlled.*Nokia";
my $PortionsNokiaCopyrPattern = 'Portions.*Copyright\b.*Nokia.*(All Rights)?';
my $NewPortionsNokiaCopyrPattern = 'Portions\s*Copyright\b.*' . $NewNokiaPattern;

# Move these copyrights to Nokia !!!
my $ExternalToNokiaCopyrPattern = 'Copyright\b.*(Symbian\sLtd|Symbian\s*Software\s*Ltd|Digia|SysopenDigia).*(All\s+Rights|All\s+rights)?';
my $PortionsSymbianCopyrPattern = 'Portions\s*Copyright\b.*(Symbian\sLtd|Symbian\s*Software\s*Ltd).*(All\s+Rights|All\s+rights)?';

###############
# SFL headers
###############
# SFL C/C++ style
#
my $SFLicenseHeader = 
'/*
* Copyright (c) 2009 Nokia Corporation and/or its subsidiary(-ies).
* All rights reserved.
* This component and the accompanying materials are made available
* under the terms of "Eclipse Public License v1.0"
* which accompanies this distribution, and is available
* at the URL "http://www.eclipse.org/legal/epl-v10.html".
*
* Initial Contributors:
* Nokia Corporation - initial contribution.
*
* Contributors:
*
* Description:
*
*/'. "\n";

# Test string to test header have been changed
my $SFLHeaderTest = 'Symbian\s*Foundation\s*License.*www\.symbianfoundation\.org\/legal\/sfl';

# Partial SFL  header template (# will be replaced by actual comment syntax char)
# Prepare for cases where someone adds spaces to string. 
my $SFLicenseHeaderPartial_template = 
$CC . '\s*This\s*component\s*and\s*the\s*accompanying\s*materials\s*are\s*made\s*available\s*\n' .
$CC . '\s*under\s*the\s*terms\s*of\s*the\s*License\s*\"Symbian\s*Foundation\s*License\s*v1\.0\"\s*\n' .
$CC . '\s*which\s*accompanies\s*this\s*distribution\,\s*and\s*is\s*available\s*\n' .
$CC . '\s*at\s*the\s*URL\s*\"http\:\/\/www\.symbianfoundation\.org\/legal\/sfl\-v10\.html\"\s*\.';
 
# SFL other comment styles (replace # with actual comment starter)
#
my $SFLicenseHeader_other_template = 
'#
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
#
';



###############
# EPL headers
###############
# C/C++ style
my $EPLLicenseHeader = 
'/*
* Copyright (c) 2009 Nokia Corporation and/or its subsidiary(-ies).
* All rights reserved.
* This component and the accompanying materials are made available
* under the terms of "Eclipse Public License v1.0"
* which accompanies this distribution, and is available
* at the URL "http://www.eclipse.org/legal/epl-v10.html".
*
* Initial Contributors:
* Nokia Corporation - initial contribution.
*
* Contributors:
*
* Description: 
*
*/' . "\n";

# Test string to test header have been changed
my $EPLHeaderTest = 'Eclipse\s*Public\s*License.*www\.eclipse\.org\/legal\/epl';

# Partial EPL header  (replace # with actual comment starter)
# Prepare for cases where someone adds spaces to string. 
my $EPLLicenseHeaderPartial_template = 
$CC . '\s*This\s*component\s*and\s*the\s*accompanying\s*materials\s*are\s*made\s*available\s*\n' .
$CC . '\s*under\s*the\s*terms\s*of\s*\"Eclipse\s*Public\s*License\s*v1\.0\"\s*\n' .
$CC . '\s*which\s*accompanies\s*this\s*distribution,\s*and\s*is\s*available\s*\n' .
$CC . '\s*at\s*the\s*URL\s*\"http\:\/\/www\.eclipse\.org\/legal\/epl\-v10\.html\"\s*\.';


# EPL other comment styles (replace # with comment starter)
#
my $EPLLicenseHeader_other_template = 
'#
# Copyright (c) 2009 Nokia Corporation and/or its subsidiary(-ies).
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
#
';

##############
# LGPL headers
##############
my $LGPLLicenseHeader = 
'/*
* Copyright (c) 2009 Nokia Corporation and/or its subsidiary(-ies).
* All rights reserved.
*
* This program is free software: you can redistribute it and/or modify
* it under the terms of the GNU Lesser General Public License as published by
* the Free Software Foundation, version 2.1 of the License.
* 
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
* GNU Lesser General Public License for more details.
*
* You should have received a copy of the GNU Lesser General Public License
* along with this program.  If not, 
* see "http://www.gnu.org/licenses/old-licenses/lgpl-2.1.html/".
*
* Description:
*
*/';

# Test string to test header have been changed
my $LGPLHeaderTest = 'GNU\s*Lesser\s*General\s*Public\s*License.*www\.gnu\.org\/licenses/old-licenses\/lgpl-2\.1\.html';

# Partial LGPL header  (replace $CC with actual comment starter)
my $LGPLLicenseHeaderPartial_template = 
$CC . '\s*This\s*program\s*is\s*free\s*software\:\s*you\s*can\s*redistribute\s*it\s*and\/or\s*modify\n' .
$CC . '\s*it\s*under\s*the\s*terms\s*of\s*the\s*GNU\s*Lesser\s*General\s*Public\s*License\s*as\s*published\s*by\n' .
$CC . '\s*the\s*Free\s*Software\s*Foundation\,\s*version\s*2\.1\s*of\s*the\s*License\n';


# LGPL other comment styles (replace # with comment starter)
#
my $LGPLLicenseHeader_other_template = 
'#
# Copyright (c) 2009 Nokia Corporation and/or its subsidiary(-ies). 
# All rights reserved.
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Lesser General Public License as published by
# the Free Software Foundation, version 2.1 of the License.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public License
# along with this program.  If not, 
# see "http://www.gnu.org/licenses/old-licenses/lgpl-2.1.html/".
#
# Description:
#
';


###############
# S60 headers
###############
# C/C++ style
my $S60HeaderPartial_template = 
$CC . " This material, including documentation and any related computer\n" .
$CC . " programs, is protected by copyright controlled by Nokia. All\n" .
$CC . " rights are reserved. Copying, including reproducing, storing\n" .
$CC . " adapting or translating, any or all of this material requires the\n" .
$CC . " prior written consent of Nokia. This material also contains\n" .
$CC . " confidential information which may not be disclosed to others\n" .
$CC . " without the prior written consent of Nokia.";

# Test string to test header have been changed
my $S60HeaderTest = 'is\s*protected\s*by\s*copyright\s*controlled\s*by\s*Nokia';


my @SflHeaders = (\$SFLicenseHeader, \$SFLicenseHeader_other_template, \$SFLicenseHeaderPartial_template, \$SFLHeaderTest);   # contains refs
my @EplHeaders = (\$EPLLicenseHeader, \$EPLLicenseHeader_other_template, \$EPLLicenseHeaderPartial_template, \$EPLHeaderTest); # contains refs
my @S60Headers = (undef,undef,\$S60HeaderPartial_template, \$S60HeaderTest); # contains refs
my @LgplHeaders = (\$LGPLLicenseHeader, \$LGPLLicenseHeader_other_template, \$LGPLLicenseHeaderPartial_template, \$LGPLHeaderTest); # contains refs

# Header styles (indeces within @SflHeaders and @EplHeaders)
use constant CPP_HEADER => 0; 
use constant OTHER_HEADER => 1;

# switchLicense related values
use constant SFL_LICENSE => 3;
use constant EPL_LICENSE => 7;
use constant S60_LICENSE => 0;
use constant LGPL_LICENSE => 4;
use constant LICENSE_CHANGED => 1;
use constant LICENSE_NONE => 0;
use constant LICENSE_ERROR => -1;
use constant LICENSE_NOT_SUPPORTED => -2;

# Distribution policy file values
use constant INTERNAL_DISTRIBUTION_VALUE => "1";
use constant ZERO_DISTRIBUTION_VALUE => "0";
use constant SFL_DISTRIBUTION_VALUE => "3";  
use constant EPL_DISTRIBUTION_VALUE => "7"; # option -epl
use constant TSRC_DISTRIBUTION_VALUE => "950"; #
use constant NONSF_DISTRIBUTION_VALUE => "Other"; #
use constant DISTRIBUTION_FILENAME => "distribution.policy.s60";

my $usage = 'SFUpdateLicenHeader.pl tool, version: ' . VERSION .
'
Usages:
   perl SFUpdateLicenceHeader.pl [-modify] [-epl] [-oem] [-create]  [-ignorefile pattern]
        [-output csv-file] [-log logfile] [-verbose level] [-verify] [-append]
        [-oldoutput old-csv-file]  DIRECTORY|FILE

   Check switch to SFL header in a directory (and subdirectories under that):
      perl SFUpdateLicenceHeader.pl -output csv-file -log logfile DIRECTORY
   Switch to SFL header and modify .policy.s60 files in a directory (and subdirectories under that):
      perl SFUpdateLicenceHeader.pl -modify -output csv-file -log logfile DIRECTORY
   Switch to SFL header and modify .policy.s60 files in a single file:
      perl SFUpdateLicenceHeader.pl -modify -output csv-file -log logfile FILE
   Switch to EPL header and modify .policy.s60 files:
      perl SFUpdateLicenceHeader.pl -modify -epl -output csv-file -log logfile DIRECTORY
   Switch to SFL header and modify/create missing .policy.s60 files:
      perl SFUpdateLicenceHeader.pl -modify -create -output csv-file -log logfile DIRECTORY
   Switch to SFL header and ignore files matching CCM file pattern:
      perl SFUpdateLicenceHeader.pl -modify -ignore "_ccmwaid.inf" -output csv-file -log logfile DIRECTORY
   Switch to SFL header and ignore files matching  CCM or SVN file patterns:
      perl SFUpdateLicenceHeader.pl -modify -ignore "(_ccm|.svn)" -output csv-file -log logfile DIRECTORY
   Switch back to Nokia header (for OEM delivery team):
      perl SFUpdateLicenceHeader.pl -modify -oem -output csv-file -log logfile DIRECTORY
   Verify file header changes
      perl SFUpdateLicenceHeader.pl -verify -output csv-file -log logfile DIRECTORY
   Verify and append logs and results to single file
      perl SFUpdateLicenceHeader.pl -verify -append -output AllResults.csv -log AllLogs.log DIRECTORY
   Verify file header changes and use old result file as add-on configuation (used by -verbose only)
      perl SFUpdateLicenceHeader.pl -verify -oldoutput old-csv-file -output csv-file -log logfile DIRECTORY

For more info, see http://s60wiki.nokia.com/S60Wiki/SFDG-File-Header#SFUpdateLicenceHeader.pl
';

# Logging constants
use constant LOG_ALWAYS => 0;
use constant LOG_INFO => 3;
use constant LOG_ERROR => 1;
use constant LOG_WARNING => 2;
use constant LOG_DEBUG => 4;
my @LOGTEXTS = ("", "ERROR: ", "Warning: ", "Info: ", "DEBUG: ");
my $sep = ",";
my $logFile = "";

# Issue categories in result CSV formatted file
use constant HEADER_CONTEXT => 'header-issue';
use constant DISTRIBUTION_CONTEXT => 'distribution-issue';


####################
# Global variables
####################

# Command line options
my $help = 0;
my $outputfile;  
my $ignorefilepattern;  # File patterns to ignore
# my $optSfl = 1;  # By default sfl is on
my $optEpl = 0;  # Use EPL headers
my $optLgpl = 0;  # Use LGPL v2.1 headers
my $optLogLevel = LOG_INFO;
my $optModify = 0;  # (default mode is check)
my $optCreate = 0;  # (create missing files)
my $optOem = 0;  # OEM delivery to S60 license
my $optAppend = 0;  # Append results
my $optVerify = 0;  # Verify option
my $oldOutputFile;  # Version 1.60 old output file in CSV format
my %manualIgnoreFileHash; # Hash of files ignored
my $optDescription = 0;  # Output also missing description
my $optOutputOK = 0;  # Output also OK issues for -verify 

# The last distribution ID
my $lastDistributionValue = "";

# Config file specific gllobals
my $configFile;
my $configVersion = "";
my @sfDistributionIdArray = ();  # Distribution ID array
my @sfGeneratedPatternArray = ();  # Distribution ID array

#
# Statistics variables
#
my $fileCount = 0;
my $modifiedFileCount = 0;
my $willModifiedFileCount = 0;
my $noDescrcount = 0;
my $otherCopyrCount=0;
my $ExternalToNokiaCopyrCount=0;
my $NokiaCopyrCount=0;
my $NoCopyrCount=0;
my $UnclearCopyrCount=0;
my $SflToS60Changes = 0;
my $EplToS60Changes = 0;
my $SflToEplChanges = 0;
my $EplToSflChanges = 0;
my $LicenseChangeErrors = 0;
my $ignoreCount = 0;
my $unrecogCount = 0;
my $createCount = 0;
my @verifyFailedCount = (0,0,0,0,0,0,0,0,0,0,0); 
my @verifyFailedCountMsgs = ("Distribution file missing",  # Index 0
                             "SFL or EPL distribution ID missing",  #1
                             "SFL or EPL header missing",   #2
                             "Proper copyright missing",    #3
                             "Header vs. distribution ID mismatch",   #4
                             "Internal directory going to SF",         #5
                             "Old Nokia file header used",         #6
                             "Unclear Non-Nokia copyright",         #7
                             "Incomplete copyright",         #8
                             "OK",     #9
                             "OK (Non-Nokia)",     #10
                             "Multiple license"     #11
                              );
use constant VERI_MISSING_FILE => 0;
use constant VERI_MISSING_ID => 1;
use constant VERI_MISSING_HEADER => 2;
use constant VERI_PROPER_COPYRIGHT => 3;
use constant VERI_ID_HEADER_MISMATCH => 4;
use constant VERI_INTERNAL_TO_SF => 5;
use constant VERI_OLD_NOKIA_HEADER => 6;
use constant VERI_UNCLEAR_COPYR => 7;
use constant VERI_INCOMPLETE_COPYR => 8;
use constant VERI_OK => 9;
use constant VERI_OK_NON_NOKIA => 10;
use constant VERI_MULTIPLE_LICENSES => 11;


##################################
# Callback for the find function 
# (wanted)
# Note ! "no_chdir" not used
##################################
sub process_file
{

	my $full_filename = $File::Find::name; # Full name needed for result and logs !
    $full_filename =~ s/\\/\//g;  # Standardize name 
	my $filename = $_;  # This in filename in the current working directory !

	#Skip all directory entries
	return if -d;

    if ($ignorefilepattern && $full_filename =~ m/$ignorefilepattern/i)
    {
        printLog(LOG_DEBUG, "File ignored by pattern: ".  $full_filename . "\n");
        $ignoreCount++;
        return;
    }

    # Set initial value from options, turn off later if needed
    my $modify = $optModify;
    my $willmodify = 1; # For statistics only

	#skip non-source code files
	my ($name, $path, $suffix)=fileparse($_, qr/\.[^.]*/);

	my $match = grep {$_ eq lc($suffix)} @extlist;
    if (!$match)
    {
        printLog(LOG_DEBUG, "File ignored: ".  $full_filename . "\n");
        $ignoreCount++;
        return;
    }

    # As there have been cased where e.g. .pkg file has been saved as Unicode format
    # Check that we can really modify file (e.g. Unicode files not supported)
    if (! (-T $filename)) # Text file only !
    {
        printLog(LOG_WARNING, "File not in text format: $full_filename\n");
        return;
    }


    printLog(LOG_DEBUG, "Handling ".  $full_filename . "\n");

	local($/, *FH);
    
    # Open file for reading here, re-open later if modified
    open(FH, "<$filename") or return printLog(LOG_ERROR, "Failed to open file for reading: $full_filename\n");

	my $filecontent = <FH>;  # read whole content into buffer
    # Standardize the new-line handling in files by replacing \r with \n
    # Some files may be using  only \r and it causes problems
    $filecontent =~ s/\r/\n/g;  
	
	my $modifiedFilecontent;
	my $description = "";
	my $contributors = "";

	#comment mark
	my $cm = '\*';
	my $cm2 = '*';
	my $newheader = "";
	my $oldheader = "";
	my $oldheader2;
	my $header_regexp = "";
	my $header_regexp2;
    my $isCcomment = 0;
    my $isCPPcomment = 0;
    my $oldCopyrightYear;
    my $matchPos1;
    my $matchPos2;
    my $unrecog=0;


    # For statisctics....
	$fileCount++;

    ###################
	# Prepare regular expressions 
    # based on file extensions
    ###################

	if (lc($suffix) eq ".s60")
    {
        #
        # Alter exisring distribution policy file 
        #
        my $stat = LICENSE_NONE;
        $stat = &handleDistributionValue(\$filecontent, $full_filename);
        if ($stat eq LICENSE_CHANGED)
        {
            $willModifiedFileCount++;
            if ($modify)
            {
               close(FH); # Close null 
               writeFile(\$filecontent, $filename, $full_filename);
            }
        }
        return; # All done
    }
    
	elsif ( (lc($suffix) eq ".mk" ) or 
          (lc($suffix) eq ".pl") or (lc($suffix) eq ".py") or (lc($suffix) eq ".pm") or # script
          (lc($suffix) eq ".pro") or (lc($suffix) eq ".pri") )   # Qt specific
    {
        # Makefile, Perl or Python script  (# comment)
		$cm = '#';
		$cm2 = '#';
		$newheader = &headerOf(OTHER_HEADER());
		$header_regexp = $header_regexps[COMMENT_PERL];
    }
	elsif ((lc($suffix) eq ".bat" ) or (lc($suffix) eq ".cmd" )) 
    {
        # Windows command script (@rem comment)
		$cm = '@rem';
		$cm2 = '@rem';
		$newheader = &headerOf(OTHER_HEADER());
		$newheader =~ s/\#/\@rem/g;  # use rem as comment start, not #
		#$newheader = "\@echo off\n" . $newheader;  # Disable std output, otherwise rem statements are shown
		#$newheader = $newheader . "\@echo on\n"; # Enable std output
		$header_regexp = $header_regexps[COMMENT_CMD];
    }
	elsif (lc($suffix) eq ".pkg" or lc($suffix) eq ".asm") 
    {
        # SIS package file or Assembly file (; comment)
		$cm = ';';
		$cm2 = ';';
		$newheader = &headerOf(OTHER_HEADER());
		$newheader =~ s/\#/\;/g;  # use ; as comment start
		$header_regexp = $header_regexps[COMMENT_SIS_ASM];
	} 
	elsif (lc($suffix) eq ".s") 
    {
        # Not all .s files are assemby files !!!
        #
        if ($filecontent =~ m/\#include\s*\"armasmdef\.h\"/s)
        {
            # ARM assembly file (C comment)
            $newheader = &headerOf(CPP_HEADER());
            # Match both C and C++ comment syntaxes
            $isCcomment = 1;
            $header_regexp = $header_regexps[COMMENT_C];
            $header_regexp2 = $header_regexps[COMMENT_CPP];  # Use without /s in regexp eval !
        }
        elsif ($filecontent =~ m/[\s\t]+AREA[\s\t]+/s)  # AREA statement
        {
            # RVCT assembly file (; comment)
            $cm = ';';
            $cm2 = ';';
            $newheader = &headerOf(OTHER_HEADER());
            $newheader =~ s/\#/\;/g;  # use ; as comment start
            $header_regexp = $header_regexps[COMMENT_SIS_ASM];
        }
        else
        {
            # Not recognized
            $unrecog = 1;
            printLog(LOG_WARNING, "Assembly file content not recognized, ignored ".  $full_filename . "\n");
        }
	} 
	elsif (lc($suffix) eq ".script" )
    {
        # Test scipt (// comment)
		$cm = '//';
		$cm2 = '//';
		$newheader = &headerOf(OTHER_HEADER());
		$newheader =~ s/\#/\/\//g;  # use // as comment start
		$header_regexp = $header_regexps[COMMENT_SCRIPT];
    }
    else
    {
        # C/C++ syntaxed file
		$newheader = &headerOf(CPP_HEADER());
        # Match both C and C++ comment syntaxes
        $isCcomment = 1;
	    $header_regexp = $header_regexps[COMMENT_C];
	    $header_regexp2 = $header_regexps[COMMENT_CPP];  # Use without /s in regexp eval !
    }

    if ($unrecog)
    {
        close(FH);
        $unrecogCount++;
        return;
    }

    ###################
    # Pick up old header in the very first comment block.
    # If the actual license text is in the later comment block, it may generate
    # UNCLEAR COPYRIGHT CASE (See Consistency checks)
    ###################
    #
    if ($header_regexp2)
    {
        if ($filecontent =~ m/$header_regexp2/)   # Note /s not used by purpose !
        {
            $oldheader = $&;
            $oldheader2 = $&;
            $matchPos2 = $-[0];
            $isCPPcomment = 1;
            printLog(LOG_DEBUG, "Orig C++ header:$matchPos2=($oldheader)\n");
        }
    }

    if ($filecontent =~ m/$header_regexp/s)
    {
        $oldheader = $&;
        $matchPos1 = $-[0];
        $isCPPcomment = 0;
        if ($oldheader2 && ($matchPos2 < $matchPos1)) 
        {
            $oldheader = $oldheader2;  # C++ header was earlier
            $isCPPcomment = 1;  # revert back
        }
        else 
        {
            printLog(LOG_DEBUG, "Orig C or other header:$header_regexp,$matchPos1\n");
            printLog(LOG_DEBUG, "Orig C or other header:($oldheader)\n");
        }
    }

    #
    ###################
    # Process old header
    ###################

    # Handle -verify option
    if ($optVerify)
    {
        if ($optLgpl)
        {
            &handleVerifyLgpl(\$filecontent, \$oldheader, $cm, $full_filename, $File::Find::dir);
        }
        elsif ($optEpl)
        {
            &handleVerifyEpl(\$filecontent, \$oldheader, $cm, $full_filename, $File::Find::dir);
        }
        else
        {
            &handleVerify(\$filecontent, \$oldheader, $cm, $full_filename, $File::Find::dir);
        }

        close(FH);
        return; # All done
    }

    #
    # Try switch license from SFL to EPL / S60-OEM release
    #
    my $switchStat = LICENSE_NONE;
    $switchStat = &switchLicense(\$filecontent, \$oldheader, $cm, $full_filename, $isCPPcomment);
    if ($switchStat eq LICENSE_CHANGED)
    {
        # OK the switch was sucessful
        $willModifiedFileCount++;
        if ($modify)
        {
            close(FH);
            writeFile(\$filecontent, $filename, $full_filename);
        }
        close(FH);
        return;  # All done
    }
    elsif ($switchStat eq LICENSE_NOT_SUPPORTED)
    {
        close(FH);
        return;  # No worth continue
    }
    

    # Otherwise (error or no license) continue to create new header
 
    ###################
    # Consistency checks
    ###################
    if ( (!($oldheader =~ m/$CopyrPattern/is)) && ($filecontent =~ m/$BeginLicenseBlockPattern/s))
    {
        # Looks like header is something weired going on. First comment block contains no copyright, 
        # and still there is "BEGIN LICENSE" block in the file
        $UnclearCopyrCount++;
        printLog(LOG_INFO, "Non-Nokia copyright (#1) ".  $full_filename . "\n");
        printResult(HEADER_CONTEXT() . "$sep"."Non-Nokia copyright $sep$sep"."BEGIN LICENSE BLOCK$sep$full_filename$sep$linenumtext\n");
        close(FH);
        return;
    }

    #
    # Switch license from S60 to SFL/EPL according to options
    #

    my $otherCopyr = 0;
    my $noCopyr = 0;
    my $ExternalToNokiaCopyr = 0;
    my $s60header = 0;

    # First remove all "Nokia copyright" texts + weired "Copyright known-words" from header
    # This because, the header can contain both Nokia and other company copyright statements
    my $testheader = makeTestHeader(\$oldheader, 0, REMOVE_SYMBIAN);
    printLog(LOG_DEBUG, "Cleaned header=($testheader)\n");

    # Now test whether it contain non-Nokia (=Nokia+Symbian) copyright statements
    # The rule is: If this hits, do not touch the header

    if ($testheader =~ m/$NonNokiaCopyrPattern/is)
    {
        # Some other than Nokia & Symbian copyright exist in header
        $otherCopyr = 1;
        $modify = 0;  # !!! Do not modify file !!!
        $willmodify = 0; 
        $otherCopyrCount++;
        my $failReason = "";
        if (!checkPortionsCopyright(\$oldheader, 0, \$failReason))
        {
            printLog(LOG_WARNING, "Non-Nokia copyright (#2) ".  $full_filename . "\n");
            printResult(HEADER_CONTEXT() . "$sep"."Non-Nokia copyright$sep$sep$sep$full_filename$sep$linenumtext\n");
        }
        else
        {
            printResult(HEADER_CONTEXT() . "$sep"."Non-Nokia (portions Nokia) copyright$sep$sep$sep$full_filename$sep$linenumtext\n");
            printLog(LOG_INFO, "Non-Nokia (portions Nokia) copyright ".  $full_filename . "\n");
        }

        close(FH);
        return;  # Quit
    }

    # Test header has Nokia or Symbian copyright statement or it could be some other comment
    # Check the rest of file
    my $wholefile = makeTestHeader(\$filecontent, 1, REMOVE_SYMBIAN);  # Check the rest of file
    if ($wholefile =~ m/$NonNokiaCopyrPattern/is)
    {
        # The header might be empty due to weired file header style.
        # Check the whole file content, it could be non-nokia file?
        $modify = 0;  # !!! Do not modify file !!!
        $willmodify = 0; 
        my $failReason = "";
        if (!checkPortionsCopyright(\$filecontent, 1, \$failReason))
        {
            $UnclearCopyrCount++;
            printLog(LOG_INFO, "Non-Nokia copyright (#2) ".  $full_filename . "\n");
            printResult(HEADER_CONTEXT() . "$sep"."Non-Nokia copyright$failReason$sep$sep$sep$full_filename$sep$linenumtext\n");
        }
        else
        {
            printResult(HEADER_CONTEXT() . "$sep"."Non-Nokia (portions Nokia) copyright$sep$sep$sep$full_filename$sep$linenumtext\n");
            printLog(LOG_INFO, "Non-Nokia (portions Nokia) copyright ".  $full_filename . "\n");
        }
        close(FH);
        return;  # Quit
    }

    # Check if header is already OK.  
    # This is needed to keep Ex-Symbian C++ comment syntaxes. 
    # Also, this avoid unncessary changes in headers.
    # NOTE ! If header need to be converted to a new format the check must return FALSE !!!
    my $license = licenceIdForOption();
    if (checkHeader(\$filecontent, \$oldheader, $cm, $full_filename, $File::Find::dir, \$license))
    {
        if (!checkNoMultipleLicenses(\$filecontent, \$oldheader, $cm, $full_filename, $File::Find::dir))
        {
            printResult(HEADER_CONTEXT() . "$sep"."Multiple licenses$sep$sep$sep$full_filename$sep" ."1\n");
            printLog(LOG_ERROR, "Multiple licenses:".  $full_filename . "\n");
            close(FH);
            return; # Failed
        }
        else
        {
            # Quit here, header OK
            printLog(LOG_INFO, "Header already OK ($license): $full_filename\n");
            close(FH);
            return;  # Quit
        }
    }

    # Check if Ex-Symbian file
    my $testheader = makeTestHeader(\$oldheader, 0, KEEP_SYMBIAN);
    if ($testheader =~ m/$ExternalToNokiaCopyrPattern/is)
    { 
        # External copyright moved to Nokia
        my $txt = $1;
        $txt =~ s/,//;
        $ExternalToNokiaCopyr = 1;
        $ExternalToNokiaCopyrCount++;
        if ($isCPPcomment) 
        {
            # Normalize the C++ header syntax back to C comment
            $modifiedFilecontent = &normalizeCppComment($header_regexp2,$filecontent, \$oldheader);
            printLog(LOG_DEBUG, "Normalized External header=($oldheader)\n");
        }
        if ($testheader =~ /$copyrYearPattern/) 
        {
            if ($& =~ /$copyrYearPattern2/)
            {
                $oldCopyrightYear = $&;
            }
            printLog(LOG_DEBUG, "Old copyright=($oldCopyrightYear)\n");
        }
        printLog(LOG_INFO, "Copyright will be converted to Nokia: $full_filename\n");
        printResult(HEADER_CONTEXT() . "$sep"."Converted copyright$sep$sep$sep$full_filename$sep$linenumtext\n");
    }

    elsif ($oldheader =~ m/$NokiaCopyrPattern/is)
    {
        # Consider it to be Nokia copyright
        $s60header = 1;
        $NokiaCopyrCount++;
        printLog(LOG_DEBUG, "Nokia header=($full_filename)\n");
        if ($isCPPcomment) 
        {
            # Normalize the C++ header syntax back to C comment
            $modifiedFilecontent = &normalizeCppComment($header_regexp2, $filecontent, \$oldheader);
            printLog(LOG_DEBUG, "Normalized Nokia header=($oldheader)\n");
        }
        if ($oldheader =~ /$copyrYearPattern/) 
        {
            if ($& =~ /$copyrYearPattern2/)
            {
                $oldCopyrightYear = $&;
            }
            printLog(LOG_DEBUG, "Old copyright2=($oldCopyrightYear)\n");
        }
    }
    elsif (! ($testheader =~ m/$CopyrPattern/is) )
    {
       # No copyright in the header.
       $NoCopyrCount++;
       $noCopyr = 1;
       # printResult(HEADER_CONTEXT() . "$sep"."No Copyright$sep$sep$sep$full_filename$sep$linenumtext\n");
    }
    else 
    {
         $UnclearCopyrCount++;
         $modify = 0;  # !!! Do not modify file !!!
         $willmodify = 0; 
         printLog(LOG_ERROR, "UNCLEAR copyright ".  $full_filename . "\n");
         printResult(HEADER_CONTEXT() . "$sep"."UNCLEAR COPYRIGHT CASE$sep$sep$sep$full_filename$sep$linenumtext\n");
    }


	# Get description from current header 
    if ($oldheader =~ m/$cm\s*Description\s*\:(.*?)$cm\s*(Version)/s)
    {
        # Description followed by Version
		$description = $1;
        printLog(LOG_DEBUG, "Old description followed by version ($description)\n");
	} else 
    {
        # Description without Version
		# ORIG if ($oldheader =~ m/$cm?\s*Description\s*\:(.*?)$cm\s*(\n)/s)
		if ($oldheader =~ m/$cm?\s*Description\s*\:(.*?)($cm|$cm\/|\n)\s*\n/s)
        {
            $description = $1;
            printLog(LOG_DEBUG, "Old description not followed by version ($description)\n");
        }
	}

    if ($isCcomment)
    {
        $description =~ s/\/\*.*//;  # Remove possible /*
        $description =~ s/\*\/.*//;  # Remove possible */
        $description =~ s/\=//g;  # Remove possible =/
    }

     # Get contributors from old header
	if ( $oldheader =~ m/$cm\s*Contributors\s*\:(.*?)$cm\s*Description\s*\:/s)
    {
		$contributors = $1;
        printLog(LOG_DEBUG, "Old contributors ($contributors)\n");
	}

	# Keep description text
    if($description)
    {
        $newheader =~ s/Description:[ \t]*\n/Description: $description/s;
    }


	#Keep contributor list
	if ($contributors)
    {
		$newheader =~ s/$cm[ \t]*Contributors:[ \t]*\n$cm[ \t]*\n/$cm2 Contributors:$contributors/s;
	}


    ###################
	# Modify the header
    ###################
	if($oldheader)
    {
        {
            # Update the old  header to new one
            # Old header may be just a description comment, e.g. in script
            #
		
            if ($otherCopyr)
            {
                # Other copyright statement, do not touch !
                printLog(LOG_DEBUG, "Non-Nokia file not modified: $full_filename\n");
            }
            elsif ($noCopyr)
            {

                # No copyright statement
                if (!isGeneratedHeader(\$oldheader))
                {
                    # Just add new header
                    $filecontent = $newheader . $filecontent;
                    printLog(LOG_INFO, "New header will be added: $full_filename\n");
                }
                else
                {
                    printLog(LOG_INFO, "Generated file ignored: $full_filename\n");
                }
            }
            else
            {
                # Replace the old external / S60 header
                my $newHeaderCopyrYear;
                if ($newheader =~ /$copyrYearPattern2/) 
                {
                    # This is picked up from newheader template in this script, so should work always !
                    $newHeaderCopyrYear = $&;  # Pick up year from new header
                    printLog(LOG_DEBUG, "Template header copyright=($newHeaderCopyrYear)\n");
                }
                if (!$newHeaderCopyrYear)
                {
                    # Anyway, some weired error happended
                    $newHeaderCopyrYear = DEFCOPYRIGHTYEAR;
                }
                
                # Create new copyright years
                if ($oldCopyrightYear && !($oldCopyrightYear =~ /$newHeaderCopyrYear/))
                {
                    # Keep the old copyright !!!
                    # !!! If adding new copyright year to old header, uncomment the next line !!!
                    # $oldCopyrightYear .= ",$newHeaderCopyrYear";
                }
                if (!$oldCopyrightYear)
                {
                    # Nothing found
                    $oldCopyrightYear = $newHeaderCopyrYear;
                }
                printLog(LOG_DEBUG, "New header copyright:$oldCopyrightYear\n");
                $newheader =~ s/$newHeaderCopyrYear/$oldCopyrightYear/;
                printLog(LOG_DEBUG, "New header:$full_filename,($newheader)\n");
                if ($modifiedFilecontent) 
                {
                    $filecontent = $modifiedFilecontent;  # Use the already modified content as basis
                }

                #
                # SET THE NEW HEADER
                #
                if (!($filecontent =~ s/$header_regexp/$newheader/s))
                {
                    printLog(LOG_ERROR, "FAILED to change file header: ".  $full_filename . "\n");
                    $LicenseChangeErrors++;
                    $modify = 0;  # Can not modify on failure
                    $willmodify = 0; 
                }
                else
                {
                    printLog(LOG_INFO, "File header will be changed: $full_filename\n");
                }
            }
        }
	} 
    else
    {
        if (!isGeneratedHeader(\$filecontent))  # Ensure file is not generated
        {
            # Missing old header, add new header as such
            printLog(LOG_INFO, "Missing header will be added: $full_filename\n");
            $filecontent = $newheader."\n".$filecontent;
        }
        else
        {   
            printLog(LOG_INFO, "Generated file ignored: $full_filename\n");
        }
	}

    if ($description =~ m/^\s*$/g || $description =~ m/$descrTemplateOnly/) 
    {
        $noDescrcount++;
        if ($optDescription)
        {
            printResult(HEADER_CONTEXT() .  "$sep"."Description missing$sep$sep$sep$full_filename$sep$linenumtext\n");
        }
    }
   
    close(FH);

	if ($modify)
    {
        # Re-open the file for modifications
        chmod 0777, $filename if !-w;  # remove first R/O
        open(FH, "+<$filename") or return printLog(LOG_ERROR, "Failed to open file for modifying: $full_filename\n");
		print FH $filecontent or printLog(LOG_ERROR, "Failed to modify file: $full_filename\n");
		truncate(FH, tell(FH));
        $modifiedFileCount++;
        close(FH);
	}

    if ($willmodify)
    {
        # Only for statistics
        $willModifiedFileCount++;
    }

}



##################################
# Callback for the find function
# (postprocess)
# Note ! "no_chdir" not used
##################################
sub postprocess
{
	my $dir = $File::Find::dir; 
    printLog(LOG_DEBUG, "postprocess $dir\n");

    return if (-e DISTRIBUTION_FILENAME); # Already exists ?

    my $full_filename = $dir . "/" . DISTRIBUTION_FILENAME; # Full name needed for results and log
    my $filename = DISTRIBUTION_FILENAME;

    if ($ignorefilepattern && $full_filename =~ m/$ignorefilepattern/i)
    {
        printLog(LOG_DEBUG, "Missing file ignored by pattern: ".  $full_filename . "\n");
        $ignoreCount++;
        return;
    }

    my $filecontent = "";
    my $stat = LICENSE_NONE;
    $stat = &handleDistributionValue(\$filecontent, $full_filename);
    if ($stat eq LICENSE_CHANGED && $optCreate && isDirectoryNonEmpty('.'))
    {
        # Create new distribution file to non-empty directory
        printResult(DISTRIBUTION_CONTEXT() . "$sep"."New file$sep$sep$sep$full_filename$sep$linenumtext\n");
        if ($optModify)
        {
            # Without  -modify it is possible to see what new files will created
            createAndWriteFile(\$filecontent, $filename, $full_filename);
        }
        $createCount++; # For statistics
    }   


}


##################################
# Callback for the find function
# (preprocess). Used by option -verify
# Note ! "no_chdir" not used
##################################
sub preprocess
{
	my $dir = $File::Find::dir; 
    printLog(LOG_DEBUG, "preprocess $dir\n");
    $lastDistributionValue = "";  # Empty first

    if (!isDirectoryNonEmpty('.'))
    {
        # Ignore empty dirs
        return @_; # Return input args
    }
    if (!$optVerify)
    {
        return @_; # Return input args
    }

    #
    # Currently option -verify  required !!!
    #

    my $full_filename = $dir . "/" . DISTRIBUTION_FILENAME; # Full name needed for results and log
    $full_filename =~ s/\\/\//g;  # Standardize name 

    my $filename = DISTRIBUTION_FILENAME;
    if ($ignorefilepattern && $full_filename =~ m/$ignorefilepattern/i)
    {
        if (! ($dir =~ m/$INTERNAL/i) )
        {
            return @_;
        }
    }

    # Check existency of the file
    if (!open(FH, "<$filename"))
    {
         printResult(DISTRIBUTION_CONTEXT() . "$sep"."Distribution policy file missing$sep$sep$sep$full_filename$sep$linenumtext\n");
         $verifyFailedCount[VERI_MISSING_FILE]++;
         return @_;   # Return input args
    }

	my $content = <FH>;  # IF CONTENT CHECKS
    close FH;

    $content =~ s/\n//g;  # Remove all new-lines
    $content =~ s/^\s+//g;  # trim left
    $content =~ s/\s+$//g;  # trim right
    $lastDistributionValue = $content;  # Save to global variable for the sub handleVerify

    printLog(LOG_DEBUG, "$full_filename content=$content\n");

    if ($dir =~ m/$INTERNAL/i)
    {
        if ( ($content eq SFL_DISTRIBUTION_VALUE) || ($content eq EPL_DISTRIBUTION_VALUE) )
        {
            # Internal directory has SFL or EPL distribution value, something is wrong !
            my $comment = "";  # Leave it just empty
            printResult(DISTRIBUTION_CONTEXT() . "$sep"."Internal directory going to SF (current value $content)$sep$comment$sep$sep$full_filename$sep$linenumtext\n");
            $verifyFailedCount[VERI_INTERNAL_TO_SF]++;
        }
    }
    elsif (! (($content eq SFL_DISTRIBUTION_VALUE) || ($content eq EPL_DISTRIBUTION_VALUE)))
    {
         # Neither SFL nor EPL value
         my $comment = getCommentText($content,0,"0,3,7,950", $full_filename);
         my $isSFId = &isSFDistribution($content);
         if (!$isSFId)
         {
            printResult(DISTRIBUTION_CONTEXT() . "$sep"."SFL or EPL value missing (current value $content)$sep$comment$sep$sep$full_filename$sep$linenumtext\n");
            $verifyFailedCount[VERI_MISSING_ID]++;
         }
    }

    return @_;   # Return input args

}

##################################################
# Read distribution file from given directory
##################################################
sub readDistributionValue
{
    
    my $dir = shift;

    my $filename = DISTRIBUTION_FILENAME;
    my $content = "";

    if (open(FH, "<$filename"))
    {
        $content = <FH>; 
        close FH;
    }

    $content =~ s/\n//g;  # Remove all new-lines
    $content =~ s/^\s+//g;  # trim left
    $content =~ s/\s+$//g;  # trim right

    return $content;
}


##################################################
# Make test header from given input text
##################################################
sub makeTestHeader
{
    my $ref = shift;          # Input text reference
    my $isWholeFile = shift;  # $ref is the file content
    my $removeExternalToNokia = shift; # Remove to Nokia transferreable copyright texts

    my $tstheader = "";

    if (!$isWholeFile)
    {
        $tstheader = $$ref;
    }
    else
    {
        # To optimize, whole file == 10k !!!
        # The proper header should be included in that amount of data.
        $tstheader = substr($$ref, 0, 10*1024);
    }
    $tstheader =~ s/$NokiaCopyrPattern//gi;
    $tstheader =~ s/$PortionsNokiaCopyrPattern//gi;
    $tstheader =~ s/$RemoveS60TextBlockPattern//si;
    if ($removeExternalToNokia)
    {
        $tstheader =~ s/$ExternalToNokiaCopyrPattern//gi;
        $tstheader =~ s/$PortionsSymbianCopyrPattern//gi;
    }

    # Take out special texts containing copyright word
    $tstheader =~ s/Copyright\s*\(c\)\s*\.//gi; 
    $tstheader =~ s/COPYRIGHT[\s\n\*\#+;]*(HOLDER|OWNER|notice)//gi;

    return $tstheader;
}


##################################################
# Check whether portions copyright is OK
# Call this for non Nokia cases only !
##################################################
sub checkPortionsCopyright
{
    my $ref = shift;          # Input text reference
    my $isWholeFile = shift;  # $ref is the file content
    my $failReason_ref = shift;  # check failure reason (OUT)

    my $tstheader = "";

    if (!$isWholeFile)
    {
        $tstheader = $$ref;
    }
    else
    {
        # The portions info should be included within first 10 Kb of file
        $tstheader = substr($$ref, 0, 10*1024);  
    }

    if ($tstheader =~ m/$PortionsSymbianCopyrPattern/is)
    {
        # Symbian portions copyright should be converted to Nokia one
        if (!($tstheader =~ m/$PortionsNokiaCopyrPattern/is))
        {
            $$failReason_ref = "(portions Symbian copyright)";
        }   
        else
        {
            $$failReason_ref = "(portions Nokia+Symbian copyright)";
        }   
        return 0;
    }

    if (!($tstheader =~ m/$NewPortionsNokiaCopyrPattern/is))
    {
        # No portions copyright present
        $$failReason_ref = "";
        return 0;
    }

    return 1;  # Should be OK
}


##################################################
# Get comment text by ID or filename
# Returns currently empty or value of the $IGNORE
##################################################
sub getCommentText
{
    my $distributionValue = shift;
    my $contains = shift;
    my $pattern = shift;
    my $fullfilename = shift;

    if ($contains)
    {
        if ($pattern =~ m/$distributionValue/)
        {
            return $IGNORE;
        }
    }
    else
    {
        # Not contains
        if (!($pattern =~ m/$distributionValue/))
        {
            return $IGNORE;
        }
    }

    my $ignoreThis = $manualIgnoreFileHash{lc($fullfilename)};
    if (defined $ignoreThis) 
    {
        printLog(LOG_DEBUG, "$IGNORE_MAN 2: $fullfilename\n");
        return $IGNORE_MAN;
    }

    return "";
}


##################################################
# Write content to file
##################################################
sub writeFile
{
    my $filecontent_ref = shift;
    my $filename = shift;
    my $full_filename = shift;

	my $fh;

    chmod 0777, $filename if !-w;  # remove first R/O
    open($fh, "+<$filename") or return printLog(LOG_ERROR, "Failed to open file for modifying: $full_filename\n");
    print $fh $$filecontent_ref or printLog(LOG_ERROR, "Failed to modify file: $full_filename\n");
    truncate($fh, tell($fh));
    close($fh);

    $modifiedFileCount++;
}

##################################################
# Create file and write content to file
##################################################
sub createAndWriteFile
{
    my $filecontent_ref = shift;
    my $filename = shift;
    my $full_filename = shift;

	my $fh;

    open($fh, ">$filename") or return printLog(LOG_ERROR, "Failed to create file: $full_filename\n");
    print $fh $$filecontent_ref or printLog(LOG_ERROR, "Failed to write  file: $full_filename\n");
    close($fh);
}

##################################
# Check if current directory is empty
##################################
sub isDirectoryNonEmpty
{
  my ($dir) = @_;
  opendir (DIR,$dir) or printLog(LOG_ERROR, "Can't opendir $dir\n");
  for(readdir DIR)
  {
    if (-f $_)
    {
      closedir DIR;
      return 1;
    };
  }
  closedir DIR;
  return 0;
}


##################################################
# Change SFL back to S60, or
# Change SFl to EPL
# Returns LICENSE_CHANGED if function switched the license succesfully
##################################################
# Switch only license text  and URL
my $sflText = '"Symbian Foundation License v1.0"';
my $sflTextPattern = '(the\s*License\s*)?\"Symbian\s*Foundation\s*License\s*v1\.0\"'; 
my $sflUrlPattern = 'http\:\/\/www\.symbianfoundation\.org\/legal\/sfl\-v10\.html';
my $sflUrl = 'http://www.symbianfoundation.org/legal/sfl-v10.html';
my $eplText = '"Eclipse Public License v1.0"';
my $eplUrl = 'http://www.eclipse.org/legal/epl-v10.html';
my $eplUrlPattern = 'http\:\/\/www\.eclipse\.org\/legal\/epl\-v10\.html';
my $eplTextPattern = '"Eclipse\s*Public\s*License\s*v1\.0"';
my $oldEplTextPattern = 'the\s*License\s*"Eclipse\s*Public\s*License\s*v1\.0'; # "the License" is unncessary

sub switchLicense
{
    my $filecontent_ref = shift;
    my $header_ref = shift;
    my $commentChar = shift;
    my $fullfilename = shift;
    my $isCPPcomment = shift;

	my $testValueSfl = "";
	my $testValueEpl = "";
	my $testValueS60 = "";

    if ($isCPPcomment)
    {
        # xSymbian files use this style
        $commentChar = '//';
        # in xSymbian files there are comments like, /// some text
        $$filecontent_ref =~ s/(\/){3,}/\/\//g;  # replace ///+ back to //
    }


    # In from value \* need to be escaped.
    my $FromSFLText = &partialHeaderOf(SFL_LICENSE,$commentChar, \$testValueSfl);
    my $FromEPLText = &partialHeaderOf(EPL_LICENSE,$commentChar, \$testValueEpl);

    $commentChar =~ s/\\//; # Remove \ from  possible  \*
    my $ToS60Text = &partialHeaderOf(S60_LICENSE,$commentChar, \$testValueS60);

    # Note that partial headers are manually quoted in the declaration
    # Otherwise \Q$SFLText\E and \Q$EPLText\E would be needed around those ones
    # because plain text contains special chars, like .

    printLog(LOG_DEBUG, "switchLicense: $fullfilename, $testValueEpl\n");

    if ($$filecontent_ref =~ m/$testValueSfl/s)
    {
        # SFL license

        if ($optOem)
        {
            # Switch from SFL to S60
            if (!($$filecontent_ref =~ s/$FromSFLText/$ToS60Text/s))
            {
                printLog(LOG_ERROR, "FAILED to change SFL license to S60: ".  $fullfilename . "\n");
                $LicenseChangeErrors++;
                return LICENSE_ERROR;
            }
            printLog(LOG_WARNING, "License will be swicthed from SFL to S60: ".  $fullfilename . "\n");
            $SflToS60Changes++;
            return LICENSE_CHANGED;
       }
       elsif ($optEpl)
       {
            # Switch from SFL to EPL
            if (! ( ($$filecontent_ref =~ s/$sflTextPattern/$eplText/s) && ($$filecontent_ref =~ s/$sflUrlPattern/$eplUrl/s) ) )
            {
                printLog(LOG_ERROR, "FAILED to change SFL to EPL: ".  $fullfilename . "\n");
                $LicenseChangeErrors++;
                return LICENSE_ERROR;
            }
            else
            {
                printLog(LOG_INFO, "License will be switched from SFL to EPL: ".  $fullfilename . "\n");
            }
            $SflToEplChanges++;
            return LICENSE_CHANGED;
       }
    }

    if ($$filecontent_ref =~ m/$testValueEpl/s)
    {
        if ($optOem)
        {
             printLog(LOG_ERROR, "Not supported to change EPL to S60: ".  $fullfilename . "\n");
             return LICENSE_NOT_SUPPORTED;
        }
        elsif (!$optEpl)
        {
            # Switch from EPL  to SFL
            if (! ( ($$filecontent_ref =~ s/$eplTextPattern/$sflText/s) && ($$filecontent_ref =~ s/$eplUrlPattern/$sflUrl/s) ) )
            {
                printLog(LOG_ERROR, "FAILED to change EPL to SFL: ".  $fullfilename . "\n");
                $LicenseChangeErrors++;
                return LICENSE_ERROR;
            }
            else
            {
                printLog(LOG_WARNING, "License will be switched from EPL to SFL: ".  $fullfilename . "\n");
            }
            $EplToSflChanges++;
            return LICENSE_CHANGED;
        }

        # EPL text cleanup (remove unncessary "the License")
         if ($$filecontent_ref =~ m/$oldEplTextPattern/s)
         {
             # EPL header contains extra words, get rid of them (allow script replace old header)
             if ($$filecontent_ref =~ s/$oldEplTextPattern/$eplText/s)
             {
                 # Not error if fails
                 printLog(LOG_INFO, "Unnecessary \"the License\" will be removed: $fullfilename\n");
                 return LICENSE_CHANGED;
             }
         }

    }
    else
    {
        return LICENSE_NONE;  # Allow caller decide
    }

}

##################################################
# Verify changes
##################################################
sub handleVerify
{
    my $filecontent_ref = shift;
    my $header_ref = shift;
    my $commentChar = shift;
    my $fullfilename = shift;
    my $directory = shift;

	my $testValueSfl = "";
	my $testValueEpl = "";
    my $FromSFLText = &partialHeaderOf(SFL_LICENSE,$commentChar, \$testValueSfl);
    my $FromEPLText = &partialHeaderOf(EPL_LICENSE,$commentChar, \$testValueEpl);

    if ($lastDistributionValue eq "")
    {
        # Distribution file may be empty if giving single file as input
        # Read it
        $lastDistributionValue = readDistributionValue($directory);
    }

    printLog(LOG_DEBUG, "handleVerify $fullfilename, $$header_ref\n");

    # First check Non-Nokia copyright files
    my $testheader = makeTestHeader($header_ref, 0, REMOVE_SYMBIAN);
    if (($testheader =~ m/$NonNokiaCopyrPattern/is))
    {
        printLog(LOG_DEBUG, "DEBUG:Extra check1 $&\n");
        if (!($testheader =~ m/$ExternalToNokiaCopyrPattern/si))
        {
            # Non-nokia file
            if ($testheader =~ m/$copyrYearPattern/si)
            {
                # Looks like copyright statement
                printResult(HEADER_CONTEXT() . "$sep"."Non-Nokia copyright$sep" . "$IGNORE$sep$lastDistributionValue$sep$fullfilename$sep$linenumtext\n");
                $otherCopyrCount++;
                $verifyFailedCount[VERI_OK_NON_NOKIA]++;
                return 1; # OK
            }
            else    
            {
                # Incomplete copyright ?
                printResult(HEADER_CONTEXT() . "$sep"."Non-Nokia incomplete copyright$sep" . "$IGNORE?$sep$lastDistributionValue$sep$fullfilename$sep$linenumtext\n");
                $verifyFailedCount[VERI_OK]++;
                return 0;  
            }
        }
    }

    # The header might be empty due to weired file header style.
    # Check the whole file content, it could be non-nokia file?
    my $filestart = makeTestHeader($filecontent_ref, 1, REMOVE_SYMBIAN);

    if ($filestart =~ m/$NonNokiaCopyrPattern/is)
    {
        # There is Non-Nokia copyright statement in the file
        if (($filestart =~ m/$testValueSfl/is) || ($filestart =~ m/$testValueEpl/is))
        {
            # Non-Nokia file, but still SFL or EPL header
            printResult(HEADER_CONTEXT() . "$sep"."UNCLEAR Non-Nokia copyright with SFL/EPL$sep" . "$sep$lastDistributionValue$sep$fullfilename$sep$linenumtext\n");
            $verifyFailedCount[VERI_UNCLEAR_COPYR]++;
            return 0;
        }
        elsif ($$filecontent_ref =~ m/$OldNokiaPattern2/is) 
        {
            printResult(HEADER_CONTEXT() . "$sep"."UNCLEAR Old Nokia copyright$sep" . "$sep$lastDistributionValue$sep$fullfilename$sep$linenumtext\n");
            $verifyFailedCount[VERI_OLD_NOKIA_HEADER]++;
            return 0;
        }
        else
        {
            # Non-Nokia file
            my $failReason = "";
            if (!checkPortionsCopyright($filecontent_ref, 1, \$failReason))
            {
                printResult(HEADER_CONTEXT() . "$sep"."UNCLEAR Non-Nokia copyright$failReason$sep" . "$sep$lastDistributionValue$sep$fullfilename$sep$linenumtext\n");
                $verifyFailedCount[VERI_UNCLEAR_COPYR]++;
                return 0;
            }
            else
            {
                # Contains portions copyright
                printResult(HEADER_CONTEXT() . "$sep"."Non-Nokia (portions Nokia) copyright$sep" . "$IGNORE$sep$lastDistributionValue$sep$fullfilename$sep$linenumtext\n");
                return 1;
            }
        }
    }

    #
    # OK, it should be Nokia copyrighted file
    #

    # Note that partial headers are manually quoted in the declaration
    # Otherwise \Q$SFLText\E and \Q$EPLText\E would be needed around those ones
    # because plain text contains special chars, like .
    printLog(LOG_DEBUG, "handleVerify testheaders: $testValueSfl,$testValueEpl,$$header_ref\n");

    if ( !( ($$header_ref =~ m/$testValueSfl/s) || ($$header_ref =~ m/$testValueEpl/s) ||
            ($$filecontent_ref =~ m/$testValueSfl/s) || ($$filecontent_ref =~ m/$testValueEpl/s) 
       )  )
    {
        # Header not found from header or whole file
       if (isGeneratedHeader($header_ref) || isGeneratedHeader($filecontent_ref))
       {
            # OK, it is generated header
            if ($optOutputOK)
            {
                printResult(HEADER_CONTEXT() . "$sep"."OK$sep" . "Generated header$sep$lastDistributionValue$sep$fullfilename$sep$linenumtext\n");
            }
            $verifyFailedCount[VERI_OK]++;
            return 1;  # OK
       }

        my $comment = getCommentText($lastDistributionValue, 0, "0,3,7", $fullfilename);
        if (($$header_ref =~ m/$OldNokiaPattern2/is) || ($$filecontent_ref =~ m/$OldNokiaPattern2/is))
        {
            printResult(HEADER_CONTEXT() . "$sep"."SFL or EPL header missing (old Nokia copyright)$sep$comment$sep$lastDistributionValue$sep$fullfilename$sep$linenumtext\n");
        }
        else
        {
            printResult(HEADER_CONTEXT() . "$sep"."SFL or EPL header missing$sep$comment$sep$lastDistributionValue$sep$fullfilename$sep$linenumtext\n");
        }
        $verifyFailedCount[VERI_MISSING_HEADER]++;
        return 0;
    }

    # Cross header versus distribution ID
    if ($lastDistributionValue ne "")
    {
        # Also other than 3 or 7 may be OK based on the config file
        my $isSFId = &isSFDistribution($lastDistributionValue);
        printLog(LOG_DEBUG, "DEBUG:handleVerify:Other ID OK=$isSFId\n");
        if ( (($$header_ref =~ m/$testValueSfl/s) || ($$filecontent_ref =~ m/$testValueSfl/s)) && !$isSFId)
        {
            my $comment = getCommentText($lastDistributionValue, 0, "0,3,7", $fullfilename);
            printResult(HEADER_CONTEXT() . "$sep"."SFL header vs. distribution id ($lastDistributionValue) mismatch$sep$comment$sep$lastDistributionValue$sep$fullfilename$sep$linenumtext\n");
            $verifyFailedCount[VERI_ID_HEADER_MISMATCH]++;
            return 0;
        }
        if ( (($$header_ref =~ m/$testValueEpl/s) || ($$filecontent_ref =~ m/$testValueEpl/s)) && !$isSFId )
        {
            my $comment = getCommentText($lastDistributionValue, 0, "0,3,7", $fullfilename);
            printResult(HEADER_CONTEXT() . "$sep"."EPL header vs. distribution id ($lastDistributionValue) mismatch$sep$comment$sep$lastDistributionValue$sep$fullfilename$sep$linenumtext\n");
            $verifyFailedCount[VERI_ID_HEADER_MISMATCH]++;
            return 0;
        }
    }

    if (!checkNoMultipleLicenses($filecontent_ref, $header_ref, $commentChar, $fullfilename, $directory))
    {
        printResult(HEADER_CONTEXT() . "$sep"."Multiple licenses$sep$sep$sep$fullfilename$sep" ."1\n");
        printLog(LOG_ERROR, "Multiple licenses:".  $fullfilename . "\n");
        $verifyFailedCount[VERI_MULTIPLE_LICENSES]++;
        return 0; # Failed
    }


    # We should have proper header in place 

    printLog(LOG_DEBUG, "handleVerify: $$filecontent_ref\n");
    # Check New Nokia copyright pattern (added one sentence to the old one)
    if (! (($$header_ref =~ m/$NewNokiaPattern/s) || ($$filecontent_ref =~ m/$NewNokiaPattern/s)) )
    {
        my $comment = getCommentText($lastDistributionValue, 0, "0,3,7,950", $fullfilename);
        printResult(HEADER_CONTEXT() . "$sep"."Proper Nokia copyright statement missing$sep$comment$sep$lastDistributionValue$sep$fullfilename$sep$linenumtext\n");
        $verifyFailedCount[VERI_PROPER_COPYRIGHT]++;
        return 0; # Failed
    }

    if ($optOutputOK)
    {
        printResult(HEADER_CONTEXT() . "$sep"."OK$sep" . "OK$sep$lastDistributionValue$sep$fullfilename$sep$linenumtext\n");
    }
    $verifyFailedCount[VERI_OK]++;

    return 1;

}


##################################################
# Verify changes
##################################################
sub handleVerifyEpl
{
    my $filecontent_ref = shift;
    my $header_ref = shift;
    my $commentChar = shift;
    my $fullfilename = shift;
    my $directory = shift;

	my $testValueSfl = "";
	my $testValueEpl = "";
    my $FromSFLText = &partialHeaderOf(SFL_LICENSE,$commentChar, \$testValueSfl);
    my $FromEPLText = &partialHeaderOf(EPL_LICENSE,$commentChar, \$testValueEpl);

    if ($lastDistributionValue eq "")
    {
        # Distribution file may be empty if giving single file as input
        # Read it
        $lastDistributionValue = readDistributionValue($directory);
    }

    printLog(LOG_DEBUG, "handleVerifyEpl $fullfilename, $$header_ref\n");

    # First check Non-Nokia copyright files
    my $testheader = makeTestHeader($header_ref, 0, REMOVE_SYMBIAN);
    if (($testheader =~ m/$NonNokiaCopyrPattern/is))
    {
        printLog(LOG_DEBUG, "DEBUG:Extra check1 $&\n");
        if (!($testheader =~ m/$ExternalToNokiaCopyrPattern/si))
        {
            # Non-nokia file
            if ($testheader =~ m/$copyrYearPattern/si)
            {
                # Looks like copyright statement
                printResult(HEADER_CONTEXT() . "$sep"."Non-Nokia copyright$sep" . "$IGNORE$sep$lastDistributionValue$sep$fullfilename$sep$linenumtext\n");
                $otherCopyrCount++;
                $verifyFailedCount[VERI_OK_NON_NOKIA]++;
                return 1; # OK
            }
            else    
            {
                # Incomplete copyright ?
                printResult(HEADER_CONTEXT() . "$sep"."Non-Nokia incomplete copyright$sep" . "$IGNORE?$sep$lastDistributionValue$sep$fullfilename$sep$linenumtext\n");
                $verifyFailedCount[VERI_OK]++;
                return 0;  
            }
        }
    }

    # The header might be empty due to weired file header style.
    # Check the whole file content, it could be non-nokia file?
    my $filestart = makeTestHeader($filecontent_ref, 1, REMOVE_SYMBIAN);

    if ($filestart =~ m/$NonNokiaCopyrPattern/is)
    {
        # There is Non-Nokia copyright statement in the file
        if ($filestart =~ m/$testValueEpl/is)
        {
            # Non-Nokia file, but still EPL header
            printResult(HEADER_CONTEXT() . "$sep"."UNCLEAR Non-Nokia copyright with EPL$sep" . "$sep$lastDistributionValue$sep$fullfilename$sep$linenumtext\n");
            $verifyFailedCount[VERI_UNCLEAR_COPYR]++;
            return 0;
        }
        elsif ($$filecontent_ref =~ m/$OldNokiaPattern2/is) 
        {
            printResult(HEADER_CONTEXT() . "$sep"."UNCLEAR Old Nokia copyright$sep" . "$sep$lastDistributionValue$sep$fullfilename$sep$linenumtext\n");
            $verifyFailedCount[VERI_OLD_NOKIA_HEADER]++;
            return 0;
        }
        else
        {
            # Non-Nokia file
            my $failReason = "";
            if (!checkPortionsCopyright($filecontent_ref, 1, \$failReason))
            {
                printResult(HEADER_CONTEXT() . "$sep"."UNCLEAR Non-Nokia copyright$failReason$sep" . "$sep$lastDistributionValue$sep$fullfilename$sep$linenumtext\n");
                $verifyFailedCount[VERI_UNCLEAR_COPYR]++;
                return 0;
            }
            else
            {
                # Contains portions copyright
                printResult(HEADER_CONTEXT() . "$sep"."Non-Nokia (portions Nokia) copyright$sep" . "$IGNORE$sep$lastDistributionValue$sep$fullfilename$sep$linenumtext\n");
                return 1;
            }
        }
    }

    #
    # OK, it should be Nokia copyrighted file
    #

    # Note that partial headers are manually quoted in the declaration
    # Otherwise \Q$EPLText\E would be needed around those ones
    # because plain text contains special chars, like .
    printLog(LOG_DEBUG, "handleVerify testheaders: $testValueEpl,$$header_ref\n");

    if ( !( ($$header_ref =~ m/$testValueEpl/s) || ($$filecontent_ref =~ m/$testValueEpl/s) ) )
    {
        # Header not found from header or whole file
       if (isGeneratedHeader($header_ref) || isGeneratedHeader($filecontent_ref))
       {
            # OK, it is generated header
            if ($optOutputOK)
            {
                printResult(HEADER_CONTEXT() . "$sep"."OK$sep" . "Generated header$sep$lastDistributionValue$sep$fullfilename$sep$linenumtext\n");
            }
            $verifyFailedCount[VERI_OK]++;
            return 1;  # OK
       }

        if (($$header_ref =~ m/$testValueSfl/s) || ($$filecontent_ref =~ m/$testValueSfl/s))
        {
            #  Still SFL header in place
            printResult(HEADER_CONTEXT() . "$sep"."EPL header missing (SFL header used)$sep$sep$lastDistributionValue$sep$fullfilename$sep$linenumtext\n");
        }
        elsif (($$header_ref =~ m/$OldNokiaPattern2/is) || ($$filecontent_ref =~ m/$OldNokiaPattern2/is))
        {
            printResult(HEADER_CONTEXT() . "$sep"."EPL header missing (old Nokia copyright)$sep$sep$lastDistributionValue$sep$fullfilename$sep$linenumtext\n");
        }
        else
        {
            printResult(HEADER_CONTEXT() . "$sep"."EPL header missing$sep$sep$lastDistributionValue$sep$fullfilename$sep$linenumtext\n");
        }
        $verifyFailedCount[VERI_MISSING_HEADER]++;
        return 0;
    }

    # Cross header versus distribution ID
    if ($lastDistributionValue ne "")
    {
        # Also other than 7 may be OK based on the config file
        my $isSFId = &isSFDistribution($lastDistributionValue);
        printLog(LOG_DEBUG, "DEBUG:handleVerify:Other ID OK=$isSFId\n");
        if ( ($$filecontent_ref =~ m/$testValueEpl/s) && ($lastDistributionValue ne EPL_DISTRIBUTION_VALUE) )
        {
            printResult(HEADER_CONTEXT() . "$sep"."EPL header vs. distribution id ($lastDistributionValue) mismatch$sep$sep$lastDistributionValue$sep$fullfilename$sep$linenumtext\n");
            $verifyFailedCount[VERI_ID_HEADER_MISMATCH]++;
            return 0;
        }
    }

    if (!checkNoMultipleLicenses($filecontent_ref, $header_ref, $commentChar, $fullfilename, $directory))
    {
        printResult(HEADER_CONTEXT() . "$sep"."Multiple licenses$sep$sep$sep$fullfilename$sep" ."1\n");
        printLog(LOG_ERROR, "Multiple licenses:".  $fullfilename . "\n");
        $verifyFailedCount[VERI_MULTIPLE_LICENSES]++;
        return 0; # Failed
    }


    # We should have proper header in place 

    printLog(LOG_DEBUG, "handleVerify: $$filecontent_ref\n");
    # Check New Nokia copyright pattern (added one sentence to the old one)
    if (! (($$header_ref =~ m/$NewNokiaPattern/s) || ($$filecontent_ref =~ m/$NewNokiaPattern/s)) )
    {
        printResult(HEADER_CONTEXT() . "$sep"."Proper Nokia copyright statement missing$sep$sep$lastDistributionValue$sep$fullfilename$sep$linenumtext\n");
        $verifyFailedCount[VERI_PROPER_COPYRIGHT]++;
        return 0; # Failed
    }

    if ($optOutputOK)
    {
        printResult(HEADER_CONTEXT() . "$sep"."OK$sep" . "OK$sep$lastDistributionValue$sep$fullfilename$sep$linenumtext\n");
    }
    $verifyFailedCount[VERI_OK]++;

    return 1;

}



##################################################
# Verify changes for LGPL headers
##################################################
sub handleVerifyLgpl
{
    my $filecontent_ref = shift;
    my $header_ref = shift;
    my $commentChar = shift;
    my $fullfilename = shift;
    my $directory = shift;

	my $testValueLgpl = "";
    my $FromLgplText = &partialHeaderOf(LGPL_LICENSE,$commentChar, \$testValueLgpl);

    if ($lastDistributionValue eq "")
    {
        # Distribution file may be empty if giving single file as input
        # Read it
        $lastDistributionValue = readDistributionValue($directory);
    }

    printLog(LOG_DEBUG, "handleVerifyLgpl $fullfilename, $$header_ref\n");

    # Note that partial headers are manually quoted in the declaration
    # Otherwise \Q$SFLText\E and \Q$EPLText\E would be needed around those ones
    # because plain text contains special chars, like .
    printLog(LOG_DEBUG, "handleVerifyLgpl testheaders: $testValueLgpl,$$header_ref\n");

    if ( !( ($$header_ref =~ m/$testValueLgpl/s) || ($$filecontent_ref =~ m/$testValueLgpl/s) )  )
    {
        # Header not found from header or whole file
       if (isGeneratedHeader($header_ref) || isGeneratedHeader($filecontent_ref))
       {
            # OK, it is generated header
            if ($optOutputOK)
            {
                printResult(HEADER_CONTEXT() . "$sep"."OK$sep" . "Generated header$sep$lastDistributionValue$sep$fullfilename$sep$linenumtext\n");
            }
            $verifyFailedCount[VERI_OK]++;
            return 1;  # OK
       }

        my $comment = getCommentText($lastDistributionValue, 0, "0,3,7", $fullfilename);
        if (($$header_ref =~ m/$OldNokiaPattern2/is) || ($$filecontent_ref =~ m/$OldNokiaPattern2/is))
        {
            printResult(HEADER_CONTEXT() . "$sep"."LGPL header missing (old Nokia copyright)$sep$comment$sep$lastDistributionValue$sep$fullfilename$sep$linenumtext\n");
        }
        else
        {
            printResult(HEADER_CONTEXT() . "$sep"."LGPL header missing$sep$comment$sep$lastDistributionValue$sep$fullfilename$sep$linenumtext\n");
        }
        $verifyFailedCount[VERI_MISSING_HEADER]++;
        return 0;
    }

    if (!checkNoMultipleLicenses($filecontent_ref, $header_ref, $commentChar, $fullfilename, $directory))
    {
        printResult(HEADER_CONTEXT() . "$sep"."Multiple licenses$sep$sep$sep$fullfilename$sep" ."1\n");
        printLog(LOG_ERROR, "Multiple licenses:".  $fullfilename . "\n");
        $verifyFailedCount[VERI_MULTIPLE_LICENSES]++;
        return 0; # Failed
    }


    if ($optOutputOK)
    {
        printResult(HEADER_CONTEXT() . "$sep"."OK$sep" . "OK$sep$lastDistributionValue$sep$fullfilename$sep$linenumtext\n");
    }

    $verifyFailedCount[VERI_OK]++;

    return 1;

}


##################################################
# Test if header is already OK
# NOTE ! If header need to be converted to a new format, the 
#        check must return FALSE !!!
##################################################
sub checkHeader
{
    my $filecontent_ref = shift;
    my $header_ref = shift;
    my $commentChar = shift;
    my $fullfilename = shift;
    my $directory = shift;
    my $req_license_ref = shift;  # in/out !!!

	my $testValueSfl = "";
	my $testValueEpl = "";
	my $testValueLgpl = "";

    my $FromSFLText = &partialHeaderOf(SFL_LICENSE,$commentChar, \$testValueSfl);
    my $FromEPLText = &partialHeaderOf(EPL_LICENSE,$commentChar, \$testValueEpl);
    my $FromLGPLText = &partialHeaderOf(LGPL_LICENSE,$commentChar, \$testValueLgpl);

    # Note that partial headers are manually quoted in the declaration
    # Otherwise \Q$SFLText\E and \Q$EPLText\E would be needed around those ones
    # because plain text contains special chars, like .

    my $retLicense = SFL_LICENSE; # default
    my $testValue = $testValueSfl;

    if ($$req_license_ref == EPL_LICENSE)
    {
        $testValue = $testValueEpl;
        $retLicense = EPL_LICENSE;
    }
    elsif ($$req_license_ref == LGPL_LICENSE)
    {
        $testValue = $testValueLgpl;
        $retLicense = LGPL_LICENSE;
    }

    my $ret = 0;
    $ret = ($$header_ref =~ m/$testValue/s);
    if (!$ret)
    {
        # Check the rest of file
        $ret = ($$filecontent_ref =~ m/$testValue/s);
    }

    printLog(LOG_DEBUG, "checkHeader return=$ret\n");

    if ($ret)
    {
        $$req_license_ref = $retLicense;
    }   

    return $ret;
}


##################################################
# Test if file does not contain multiple licenses
# Returns 0 if test failed
##################################################
sub checkNoMultipleLicenses
{
    my $filecontent_ref = shift;
    my $header_ref = shift;
    my $commentChar = shift;
    my $fullfilename = shift;
    my $directory = shift;

    my $usedLicense = SFL_LICENSE;
    my $licenseCnt = 0;
    if (checkHeader($filecontent_ref, $header_ref, $commentChar, $fullfilename, $directory, \$usedLicense))
    {
        printLog(LOG_DEBUG, "checkNoMultipleLicenses SFL: $fullfilename\n");
        $licenseCnt++;
    }

    $usedLicense = EPL_LICENSE;
    if (checkHeader($filecontent_ref, $header_ref, $commentChar, $fullfilename, $directory, \$usedLicense))
    {
        printLog(LOG_DEBUG, "checkNoMultipleLicenses EPL: $fullfilename\n");
        $licenseCnt++;
    }

    $usedLicense = LGPL_LICENSE;
    if (checkHeader($filecontent_ref, $header_ref, $commentChar, $fullfilename, $directory, \$usedLicense))
    {
        printLog(LOG_DEBUG, "checkNoMultipleLicenses LGPL: $fullfilename\n");
        $licenseCnt++;
    }

    if ($licenseCnt > 1)
    {
        return 0; # check failed
    }
    return 1;
}

##################################################
# Change distribution value
# Can also be called with empty file content
##################################################
sub handleDistributionValue
{
    my $filecontent_ref = shift;
    my $filename = shift;
    my $content = $$filecontent_ref;

    if ($optVerify)
    {
        # Ignored
        return LICENSE_NONE;
    }

    $content =~ s/\n//g;  # Remove all new-lines
    $content =~ s/^\s+//g;  # trim left
    $content =~ s/\s+$//g;  # trim right

    if ($content ne "" && $content ne ZERO_DISTRIBUTION_VALUE)
    {
        if ($optEpl && ($content eq SFL_DISTRIBUTION_VALUE ))
        {
            # Allow  switching SFL to EPL
            $$filecontent_ref = EPL_DISTRIBUTION_VALUE; 
            printLog(LOG_INFO, "Distribution value changed from $content to $$filecontent_ref: $filename\n");        
            return LICENSE_CHANGED;
        }
        else
        {
           # Otheriwise do not touch non-zero files ! (agreed with build team)
           $ignoreCount++;
           return LICENSE_NONE;
       }
    }

    if ($optOem)
    {
        # Leave existing (or missing) value as it was
        return LICENSE_NONE;
    }
    elsif ($optEpl)
    {
        $$filecontent_ref = EPL_DISTRIBUTION_VALUE; 
        printLog(LOG_INFO, "Distribution value changed from $content to $$filecontent_ref: $filename\n"); 
        return LICENSE_CHANGED;
    }
    else  # SFL
    {
        $$filecontent_ref = SFL_DISTRIBUTION_VALUE; 
        printLog(LOG_INFO, "Distribution value changed from $content to $$filecontent_ref: $filename\n");        
        return LICENSE_CHANGED;
    }

    return LICENSE_NONE;

}

##################################################
# Select proper 
##################################################
sub licenceIdForOption
{
    if ($optEpl)
    {
        return EPL_LICENSE;
    }
    elsif ($optLgpl)
    {
        return LGPL_LICENSE;
    }
    else  # Must be
    {
        return SFL_LICENSE;
    }
}


##################################################
# Select proper header
##################################################
sub headerOf
{
    my $style = shift;

    if ($style < 0 || $style > 1)
    {
        printLog(LOG_ALWAYS, "INTERNAL ERROR: Header index out of bounds:$style. Exiting.\n");
        exit 1;
    }

    my $ref;
    if ($optEpl)
    {
        $ref = $EplHeaders[$style];
    }
    elsif ($optLgpl)
    {
        $ref = $LgplHeaders[$style];
    }
    else  # SFL
    {
        $ref = $SflHeaders[$style];
    }

    # Return the actual value
    return $$ref;
}

##################################################
# Select proper partial header
##################################################
sub partialHeaderOf
{
    my $license = shift;
    my $commentChar = shift;
    my $testValue_ref = shift;

    my $ref;
    my $ref2;
    if ($license eq EPL_LICENSE)
    {
        $ref = $EplHeaders[2];
        $ref2 = $EplHeaders[3]; 
    }
    elsif ($license eq S60_LICENSE)
    {
        $ref = $S60Headers[2];
        $ref2 = $S60Headers[3];
    }
    elsif ($license eq LGPL_LICENSE)
    {
        $ref = $LgplHeaders[2];
        $ref2 = $LgplHeaders[3];
    }
    elsif ($license eq SFL_LICENSE)
    {
        # SFL License
        $ref = $SflHeaders[2];
        $ref2 = $SflHeaders[3];  # return value 
    }
    else
    {
        printLog(LOG_ALWAYS, "INTERNAL ERROR: Invalid license parameter :$license. Exiting.\n");
        exit 1;
    }

    # Switch to proper comment char
    my $ret = $$ref;
    $ret =~ s/$CC/$commentChar/g;  # Replace the proper comment starter character

    # Return values
    $$testValue_ref = $$ref2;
    return $ret;
}


##################################################
# Print result line
##################################################
sub normalizeCppComment
{
    my $header_regexp2 = shift;
    my $filecontent = shift;
    my $oldheader_ref = shift;  # in/out


    # Normalize the C++ header syntax back to C++ in the file content
    # in order to standardize stuff later on
    $$oldheader_ref =~ s/(\/){3,}/\/\//g;  # replace ///+ back to //
    $$oldheader_ref =~ s/\/\//*/g;  # Replace now // with *
    $$oldheader_ref = "/*\n" . $$oldheader_ref . "*/\n";  # Add /* and */ markers

    # Created saved modified file content into memory
    # This is the best way to do this.
    my $ret = $filecontent;
    $ret =~ s/$header_regexp2/$$oldheader_ref/;   # Note /s not used by purpose !
    return $ret;
}



##################################################
# Print result line
##################################################
sub printResult
{
    my $text = shift;

    if ($outputfile)
    {
        print OUTPUT $text;
    }
    else
    {
        print $text;
    }

    printLog(LOG_DEBUG(), $text);

}

##################################################
# Print log line
##################################################
sub printLog
{
    my $loglevel = shift;
    my $text = shift;

    if ($loglevel > $optLogLevel) 
    {
        return;  # No logging
    }
    if ($logFile) 
    {
        print LOG $LOGTEXTS[$loglevel] . $text;
    }

    return 0;
}


##################################################
# Print log line
##################################################
sub printLogStatisticNumber
{
    my $number = shift;
    my $loglevel = shift;  
    my $text = shift;  # Should contains %d where to put the number

    if ($number == 0)
    {
        return;  # No logging
    }

    if ($text =~ m/\%d/)
    {
        $text =~ s/\%d/$number/;
    }
    else 
    {
        # Add number to the beginning of text
        $text = $number . " " . $text;
    }   
   
    if ($loglevel > $optLogLevel) 
    {
        return;  # No logging
    }
    if ($logFile) 
    {
        print LOG $LOGTEXTS[$loglevel] . $text;
    }

    return 0;
}


##################################################
# Read the content of old output
##################################################
sub readOldOutput
{
    my($filename) = shift;
    my $fh = new FileHandle "<$filename";
    if (!defined($fh))
    {
        printLog(LOG_ERROR, "Could not open file $filename for read\n");
        return;
    }

    my  @lines = <$fh>;
    my $line;
    foreach $line (@lines)
    {
       my (@parts) = split(/\,/,$line);  # Split line with "," separator
       if ($parts[2] =~ m/$IGNORE_MAN/i)
       {
            my $fullfilename = lc($parts[4]);
            $fullfilename =~ s/\\/\//g;  # Standardize name 
            $manualIgnoreFileHash{$fullfilename} = "1" ;  # Just some value
            printLog(LOG_DEBUG, "Manually ignoring file:$fullfilename\n");
       }
    }

    close ($fh);
}

##################################################
# Read configuation file which has  the format:
# sf-update-licence-header-config-1.0
##################################################
sub readConfig
{
    my ($fname) = @_;

    open(IN,$fname) || die "Unable to open file: \"$fname\" for reading.";
    LINE:
    while(<IN>) 
    {
        chomp;
        # tr/A-Z/a-z/;  # Do not lowercase pattern
        my $line = $_;
        $line =~ s/^\s+//;  # trim left
        $line =~ s/\s+$//;  # trim right
        
        next LINE if length($line) == 0; # # Skip empty lines
        next LINE if ($line =~ /^\#.*/); # Skip comments;

        if ($line =~ /^sf-update-licence-header-config.*/i) 
        {
            my ($tmp1, $tmp2) = split(/sf-update-licence-header-config-/,$line);  # Get version
            $configVersion = $tmp2;
        }
        elsif ($line =~ /^sf-distribution-id/i) 
        {
            my ($tmp, @parts) = split(/[\s\t]+/,$line); # space as separator
            my $cnt = @parts;
            push(@sfDistributionIdArray, @parts);
            my $cnt = @sfDistributionIdArray;
            printLog(LOG_DEBUG, "readConfig:sfDistributionIdArray count:$cnt\n");
        }
        elsif ($line =~ /^sf-generated-header/i) 
        {
            my ($tmp, @parts) = split(/[\s\t]+/,$line); # space as separator
            my $cnt = @parts;
            push(@sfGeneratedPatternArray, @parts);
            my $cnt = @sfGeneratedPatternArray;
            printLog(LOG_DEBUG, "readConfig:sfGeneratedPatternArray count:$cnt\n");
        }
    }

    # Pre-compile here the source line pattern
    close (IN);
}


##################################################
# Test  ID is under SF distribution
##################################################
sub isSFDistribution
{
    my $id = shift;

    if (($id == SFL_DISTRIBUTION_VALUE) || ($id == EPL_DISTRIBUTION_VALUE))
    {
        # Implicit case
        return 1;
    }

    my $otherOkId = grep { $_ eq $id } @sfDistributionIdArray;  # Use exact match
    return $otherOkId;
}

##################################################
# Test header contains generated file pattern
##################################################
sub isGeneratedHeader
{
    my $header_ref = shift;

    my $count = grep { $$header_ref =~ m/$_/is } @sfGeneratedPatternArray;
    return $count;
}


##################################################
#                   MAIN
##################################################

GetOptions(
	'h|help' => \$help,     #print help message
	'm|modify' => \$optModify,   #Allow modifications
	'c|create' => \$optCreate,   #Create missing file
	'output:s' => \$outputfile,   #Output (result) file
	'ignorefile:s' => \$ignorefilepattern,   #Ignore file pattern
	'oldoutput:s' => \$oldOutputFile,   #Old output file
    'log:s' => \$logFile,         # Log file
    'verbose:i' => \$optLogLevel, # Logging level
    'epl' => \$optEpl,  # Switch file header to EPL one
    'lgpl' => \$optLgpl,  # Switch file header LGPL v2.1
    'oem' => \$optOem,  # Switch back S60 header for OEM release. 
    'eula' => \$optOem,  # Switch back S60 header for EULA (End-User License Agreement) release. Same as OEM
    'append' => \$optAppend,  # Append result files
    'verify' => \$optVerify,  # Verifies files has correct header
    'configfile:s' => \$configFile,
    'description!' => \$optDescription,  # output missing description
    'okoutput!' => \$optOutputOK  # output also OK entries
	);

die $usage if $#ARGV<0;
die $usage if $help;

if ($logFile) 
{
    my $openmode = ">" . ($optAppend ? ">" : "");
    open (LOG, "$openmode$logFile") || die "Couldn't open $openmode$logFile\n";  # Can not call printLog
    LOG->autoflush(1);  # Force flush
}

printLog(LOG_INFO, "========================\n");

if ($oldOutputFile && $optVerify)
{
    readOldOutput($oldOutputFile);
}

if (!$configFile) 
{
    $configFile = "$Bin/SFUpdateLicenceHeader.cfg";
}

if ($configFile && -e $configFile) 
{
    &readConfig($configFile);
}

if (!$ignorefilepattern)
{
    # Set decent default value
    if ($optOem)
    {
        # Scan through internal stuff all source dirs just in case
        $ignorefilepattern = "(_ccmwaid\.inf|\.svn)";
    }
    else
    {
        $ignorefilepattern = "(abld\.bat|_ccmwaid\.inf|\.svn|/docs/|/internal/|/doc/)";
    }
}

if ($optEpl)
{
    printLog(LOG_INFO, "Option -epl used\n");
}
if ($optLgpl)
{
    printLog(LOG_INFO, "Option -lgpl used\n");
}
if ($optOem)
{
    printLog(LOG_INFO, "Option -oem used\n");
    # Modify ignore to contain also internal dirs just in case
}
if ($optModify)
{
    printLog(LOG_INFO, "Option -modify used\n");
}
if ($optVerify)
{
    printLog(LOG_INFO, "Option -verify used\n");
}
if ($optCreate)
{
    printLog(LOG_INFO, "Option -create used\n");
}

if ($ignorefilepattern)
{
    printLog(LOG_INFO, "Option -ignorefile has value: $ignorefilepattern\n");
}

my $startTime = time;

if ($outputfile) 
{
    my $openmode = ">" . ($optAppend ? ">" : "");
    open (OUTPUT, "$openmode$outputfile") || die "Couldn't open $outputfile\n";
    OUTPUT->autoflush(1);  # Force flush
}

if (! -e $ARGV[0] )
{
    printLog(LOG_ERROR, "$ARGV[0] not found\n");
    if ($logFile)
    {
        close LOG; 
    }
    exit(1);
}

printLog(LOG_INFO,"SFUpdateLicenceHeader.pl version " . VERSION . " statistics:\n");
printLog(LOG_INFO, "Directory/file=@ARGV\n");

#
# Process files in the given directory recursively
#
# NOTE : "no_chdir" option not used --> find changes the current working directory 
find({ wanted => \&process_file, postprocess => \&postprocess, preprocess => \&preprocess },  @ARGV);

if ($outputfile)
{
    close OUTPUT;
}

my $elapsedTime = time - $startTime;

printLogStatisticNumber($fileCount, LOG_INFO, "%d files checked\n") ;
if ($optModify)
{
    printLogStatisticNumber($modifiedFileCount, LOG_INFO, "%d files modified \n") ;
}
else
{
    printLogStatisticNumber($willModifiedFileCount, LOG_INFO, "%d will be modified \n") ;
}
printLogStatisticNumber($ignoreCount, LOG_INFO, "%d files ignored.\n") ;
printLogStatisticNumber($unrecogCount, LOG_INFO, "%d files not recognized.\n") ;
if ($optVerify)
{
    for (my $i=0; $i < @verifyFailedCountMsgs; $i++)
    {
       printLogStatisticNumber($verifyFailedCount[$i], LOG_INFO, "Verify statistics:$verifyFailedCountMsgs[$i]=%d.\n") ;
    }
}
elsif (!$optOem)
{
    printLogStatisticNumber($noDescrcount, LOG_INFO, "%d files has no Description.\n") ;
    printLogStatisticNumber($NokiaCopyrCount, LOG_INFO, "%d files has Nokia copyright.\n") ;
    printLogStatisticNumber($ExternalToNokiaCopyrCount, LOG_INFO, "%d files moved also to Nokia.\n") ;
    printLogStatisticNumber($otherCopyrCount, LOG_INFO, "%d files has non-nokia copyright.\n") ;
    printLogStatisticNumber($NoCopyrCount, LOG_INFO, "%d files has no copyright.\n") ;
    printLogStatisticNumber($UnclearCopyrCount, LOG_INFO, "%d files has UNCLEAR copyright.\n") ;
    printLogStatisticNumber($createCount, LOG_INFO, "%d new files.\n") ;
    if ($optEpl)
    {
        printLogStatisticNumber($SflToEplChanges, LOG_INFO, "%d files changes from SFL to EPL license.\n") ;
    }
    else
    {
        printLogStatisticNumber($EplToSflChanges, LOG_INFO, "%d files changes from SFL to EPL license.\n") ;
    }
}
else
{
    printLogStatisticNumber($SflToS60Changes, LOG_INFO, "%d files changes from SFL to S60 license.\n") ;
    # printLog($EplToS60Changes, LOG_INFO, "%d files changes from EPL to S60 license.\n") ;
    printLogStatisticNumber($LicenseChangeErrors, LOG_INFO, "%d errors upon license change.\n") ;
}

printLog(LOG_INFO,"Time elapsed $elapsedTime.\n") ;

if ($logFile) 
{
    close LOG;
}

