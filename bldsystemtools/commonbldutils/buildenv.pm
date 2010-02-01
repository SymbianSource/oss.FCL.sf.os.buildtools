# Copyright (c) 2004-2009 Nokia Corporation and/or its subsidiary(-ies).
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
# This module implements Build environment logging
# It collects versions of various tools and Windows hotfixes and writes them to the specified XML file
# 
#

package buildenv;

use strict;
use Carp;
use lib "$FindBin::Bin/lib";

# Module Win32::TieRegistry - Set delimiter to forward slash to avoid doubling all the backslashes!
# Do not ask for ArrayValues sice we are only reading data, not changing/editing anything.
use Win32::TieRegistry( Delimiter=>"/" );

# Main
#
# Inputs
# - $iHostName        - Name of host computer (to be written into the XML file)
# - $iXMLfilePathname - Full pathname of output .XML file
#
#   note: XML file will have been named after the hostname that
#         the script was run on. See BuildEnv.pl.
#
# Description
#   Collects OS information and versions of know tools.
#   Writes resulting build environment info to specified XML file
#
sub Main
{
  my ($iHostName, $iXMLfilePathname)      = @_;
  my (%iToolList)                = &buildenv::GetToolInfo();
  my ($iWinEnvVer, %iHotFixList) = &buildenv::GetWinInfo();
  
  # write the same info in xml - useful for future tools
  &WriteXMLFormat($iHostName, $iXMLfilePathname, $iWinEnvVer, \%iHotFixList, \%iToolList);
}

# WriteXMLFormat
#
# Description
#   Writes build environment info to XML file
#
# Inputs
#   - $iWinVer      - scalar with info on windows version
#   - $iHotFixRef   - ref to hash containing hotfix info
#   - $iToolListRef - ref to hash containing tool info
#
# Outputs
#   Writes XML file
#
sub WriteXMLFormat
{
  use IO;
  use XML::Writer;
  
  # get one scalar and 2 refs to hashes
  my ($iHostName, $iXMLfilePathname, $iWinVer, $iHotFixListRef, $iToolListRef) = @_;
  
  my $DTD = "
    <!DOCTYPE machine_config [
    <!ELEMENT machine_config (operating_sys,tool*)>
    <!ATTLIST machine_config
      name CDATA #REQUIRED
    >
    <!ELEMENT operating_sys (hotfix*)>
    <!ATTLIST operating_sys
      name         CDATA #REQUIRED
      version      CDATA #REQUIRED
      servicepack  CDATA #REQUIRED
      buildnumber  CDATA #REQUIRED
    >
    <!ELEMENT hotfix EMPTY>
    <!ATTLIST hotfix
      name         CDATA #REQUIRED
      installdate  CDATA #REQUIRED
    >
    <!ELEMENT tool EMPTY>
    <!ATTLIST tool
      name      CDATA #REQUIRED
      version   CDATA #REQUIRED
    >
    ]> ";
  
  my $output = new IO::File("> $iXMLfilePathname");
  my $writer = new XML::Writer( OUTPUT => $output, DATA_MODE => 'true', DATA_INDENT => 2  );
  
  $writer->xmlDecl( 'UTF-8' );
  print $output $DTD;
  $writer->comment( 'machine_config  at ' . localtime() );
  $writer->startTag( 'machine_config', 'name' => $iHostName);
  
      # breakdown the winversion string to its component parts:
      $iWinVer =~ m/Microsoft Windows(.*)ver(.*)Service Pack(.*)Build(.*)/;
      $writer->startTag( 'operating_sys', 'name'       => 'Microsoft Windows'.$1,
                                          'version'    => $2,
                                          'servicepack'=> $3,
                                          'buildnumber'=> $4);
          
      foreach my $fixnum (sort keys %$iHotFixListRef)
      {
        $writer->startTag( 'hotfix', name => $fixnum, 'installdate' => $iHotFixListRef->{$fixnum} );
        $writer->endTag( );
      }
      $writer->endTag( ); # operating_sys
      foreach my $toolname (sort {uc $a cmp uc $b} keys %$iToolListRef)
      {
        $writer->startTag( 'tool', name => $toolname, 'version' => $iToolListRef->{$toolname}{'version'} );
        # Look for modules supporting the current tool (e.g Perl modules)
        if (defined $iToolListRef->{$toolname}{'modules'})
        {
            foreach my $modulename (sort {uc $a cmp uc $b} keys %{$iToolListRef->{$toolname}{'modules'}})
            {
                $writer->startTag( 'module', name => $modulename, 'version' => $iToolListRef->{$toolname}{'modules'}{$modulename} );
                $writer->endTag( );
            }
        }
        # Look for other versions of the current tool for which files exist but are not reached via default PATH (e.g ARM RVCT)
        if (defined $iToolListRef->{$toolname}{'multiver'})
        {
            foreach my $multiverdirectory (sort {uc $a cmp uc $b} keys %{$iToolListRef->{$toolname}{'multiver'}})
            {
                $writer->startTag( 'multiversion', name => $multiverdirectory, 'version' => $iToolListRef->{$toolname}{'multiver'}{$multiverdirectory} );
                $writer->endTag( );
            }
        }
        $writer->endTag( );
      }
  $writer->endTag( );     # machine_config
  $writer->end( );
}

# GetWinInfo
#
# Description
#   Gets Windows version. Collects information on Windows hotfixes (patches)
#
# Inputs - None
#
# Returns
#   $iWinEnv - Windows version, SP# and build
#   %iHotFixList - Installed Hotfix patch installation dates
#
sub GetWinInfo
{
  
    my %iHotFixList;
    my $iWinEnv = 'Windows : Unknown version';

    # Extract information from the Windows Registry - First get the OS name and version
    my %iValues;
    my $iRegKey   = 'LMachine/SOFTWARE/Microsoft/Windows NT/CurrentVersion';
    # Get data from hash set up by Win32::TieRegistry
    my $iHashRef = $Registry->{$iRegKey} or  return ($iWinEnv, %iHotFixList);
    # Check that hash element exists before referencing data. Otherwise TieRegistry will think that we want to create a new key/value
    my $iProd = (defined $iHashRef->{'/ProductName'})? $iHashRef->{'/ProductName'}: '';
    my $iVer = (defined $iHashRef->{'/CurrentVersion'})? $iHashRef->{'/CurrentVersion'}: '';
    my $iSPVer = (defined $iHashRef->{'/CSDVersion'})? $iHashRef->{'/CSDVersion'}: '';
    my $iBuild = (defined $iHashRef->{'/CurrentBuildNumber'})? $iHashRef->{'/CurrentBuildNumber'}: '';

    $iWinEnv =$iProd .' ver ' . $iVer . ' ' . $iSPVer . ' Build ' . $iBuild . "\n";

    # Next get the list of patches - First assume "Windows 2003" then "Windows 2000"
    $iRegKey   = 'LMachine/SOFTWARE/Microsoft/Updates/Windows Server 2003';
    $iHashRef = $Registry->{$iRegKey};
    unless (defined $iHashRef)
    {
        $iRegKey   = 'LMachine/SOFTWARE/Microsoft/Updates/Windows 2000';
        $iHashRef = $Registry->{$iRegKey};
        unless (defined $iHashRef)
        {
            return ($iWinEnv, %iHotFixList);
        }
    }
    foreach my $iKey0 (sort keys %$iHashRef)            # Key = service pack identifier; e.g. 'SP-1/', 'SP2/' ... Note trailing delimiter!
    {
        my $iHashRef1 = $iHashRef->{$iKey0};
        unless (ref($iHashRef1)) { next; }               # Skip occasional data item. Reference Type (if any) is 'Win32::TieRegistry'
        foreach my $iKey1 (sort keys %$iHashRef1)        # Key = hotfix reference; e.g. 'Q816093/' etc. Note trailing delimiter!
        {
            my $iHashRef2 = $iHashRef1->{$iKey1};
            unless (ref($iHashRef2)) { next; }           # Skip occasional data item. Reference Type (if any) is 'Win32::TieRegistry'
            foreach my $iKey2 (sort keys %$iHashRef2)    # Key = hotfix property; e.g. '/InstalledDate' etc. Note leading delimiter!
            {
                if ($iKey2 =~ m/^\/InstalledDate/)
                {
                    $iKey0 =~ s/\/$//;   # Remove trailing delimiter (slash) from service pack identifier
                    $iKey1 =~ s/\/$//;   # Remove trailing delimiter (slash) from hotfix reference
                    $iHotFixList{"$iKey0 $iKey1"}= $iHashRef2->{$iKey2};
                }
            }
        }
    }

    return ($iWinEnv, %iHotFixList);
}

# GetToolInfo
#
# Description
#   Collects OS information and versions of known tools.
#
# Inputs - None
#
# Returns
#   %iToolList - Tool versions
#
sub GetToolInfo
{
    my %iToolList;
    my $iToolName;

    GetPerlInfo(\%iToolList);
    
    GetMetrowerksInfo(\%iToolList);

    GetArmInfo(\%iToolList);

    GetJavaInfo(\%iToolList);

    # Location of reltools is assumed to be C:\Apps\RelTools\
    $iToolName = 'RelTools';
    my $iRelToolsVerTxt = 'C:\\Apps\\RelTools\\Version.txt';
    $iToolList{$iToolName}{'version'} = 'Unknown';

    if (-e $iRelToolsVerTxt)
    {
        my @iReltools = `type $iRelToolsVerTxt 2>&1`;
        # Get RelTools version (must start with numeric value). Assumed to be in first line of file
        if ($iReltools[0] =~ m/(^[0-9]{0,2}[0-9]{0,2}.*)(\n$)/) {
            $iToolList{$iToolName}{'version'} = $1;
        }
    }
    
    # Perforce Client (Typical output "Rev. P4/NTX86/2003.2/56831 (2004/04/13).")
    my $iToolNameVer = 'Perforce version';
    my $iToolNameRel = 'Perforce release';
    my @iP4Env = `P4 -V 2>&1`;
    $iToolList{$iToolNameVer}{'version'} =  'Unknown';
    $iToolList{$iToolNameRel}{'version'} =  'Unknown';
    foreach (@iP4Env)
    {
        if (m/Rev\.\s+(\S+)\s+\((.+)\)/)
        {
            $iToolList{$iToolNameVer}{'version'} =  $1;
            $iToolList{$iToolNameRel}{'version'} =  $2;
        }
    }

    # NSIS Compiler
    $iToolName = 'NSIS version';
    my @iNSIS_ver = `MakeNSIS.exe /VERSION 2>&1`;
    $iToolList{$iToolName}{'version'} =  'Unknown';
    if ($iNSIS_ver[0] =~ m/v(\d+\.\d+)/i)
    {
        $iToolList{$iToolName}{'version'} =  $1;
    }

    # PsKill utility (SysInternals)
    # PsKill v1.11 - Terminates processes on local or remote systems
    $iToolName = 'PsKill';
    my @iPSKillVer = `PsKill 2>&1`;
    $iToolList{$iToolName}{'version'} = 'Unknown';
    foreach (@iPSKillVer)
    {
        if (m/PsKill v(\d+\.\d+)/) { $iToolList{$iToolName}{'version'} =  $1; last;}
    }

    GetSophosInfo(\%iToolList);    # Sophos Anti-virus

    GetMcAfeeInfo(\%iToolList);    # McAfee Anti-virus

    GetGPGInfo(\%iToolList);       # GPG (Command line encryption program)

    GetWinTapInfo(\%iToolList);    # Win-TAP
    
    return %iToolList;  
}

# GetPerlInfo
#
# Description
#   Gets Perl Version (currently usually 5.6.1 or, on a few special machines, 5.8.7)
#   If Perl is found, we go on to list Perl Modules using "PPM query" but under Perl Version
#
# Inputs - Reference to Tool List hash (for return of data)
#
# Outputs - Data returned via supplied hashref
#
sub GetPerlInfo
{
    my $iToolList = shift;
# Typical output from "Perl -v"
# This is perl, v5.6.1 built for MSWin32-x86-multi-thread
# (with 1 registered patch, see perl -V for more detail)
#
# Copyright 1987-2001, Larry Wall
#
# Binary build 635 provided by ActiveState Corp. http://www.ActiveState.com
# Built 15:34:21 Feb  4 2003
#
    my $iToolName = 'Perl';
    my $iVersion;
    my $iBuildNum;
    my @iRetData     = `perl -v 2>&1`;
    $iToolList->{$iToolName}{'version'} = 'Unknown';
    foreach (@iRetData)
    {	# Analyse output from "Perl -v"
        if (m/ (version\s+|v)([0-9]{0,2}\.[0-9]{0,3}[_\.][0-9]{0,2})/)
        {
            if ($iVersion) {  print "ERROR: Perl Version redefined as $2.\n"; last; }	# Error? Can't have version defined twice!?
            $iVersion = $2;
            my $iMatchStr = '^([-\\w]+)\\s+\\[([.\\d]+)\\s*\\]';
            my @iRetData     = `ppm query 2>&1`;				# Ask PPM for a list of modules
            if ($iRetData[0] =~ m/No query result sets -- provide a query term\./i) # This is the response from Perl v5.8.7. Try new-style query!
            {
                $iMatchStr = '([\\-\\w]+)\\s+\\[([\\.\\d]+\w?)([\\~\\]])';
                `ppm set fields \"name version\" 2>&1`;			# Specified required fields. CAUTION: PPM remembers settings from previous "PPM query" call
                @iRetData     = `ppm query * 2>&1`;				# Ask PPM for a list of modules
            }
            foreach (@iRetData)
            {	# Analyse list of modules 
                if (m/$iMatchStr/)
                {
                    $iToolList->{$iToolName}{'modules'}{$1} = ($3 eq '~')? $2 . $3: $2;
                }
            }
            # Check for Inline-Java (which somehow escapes the attention of PPM
            my $iModuleName = 'Inline-Java';
            $iToolList->{$iToolName}{'modules'}{$iModuleName} = GetPerlModuleInfo($iModuleName);
            # Check for XML-DOM (earlier installations also escaped PPM)
            $iModuleName = 'XML-DOM';
            unless (defined $iToolList->{$iToolName}{'modules'}{$iModuleName})
            {
                $iToolList->{$iToolName}{'modules'}{$iModuleName} = GetPerlModuleInfo($iModuleName);
            }
        }
        elsif (m/Binary\s+build\s+(\d+)/i)
        {
          if ($iBuildNum) { print "ERROR: Perl Build Number  redefined as $1.\n"; last; }	# Error? Can't have build defined twice!?
          $iBuildNum = $1;
        }
    }       # End foreach (@iRetData)
    # We have already set $iToolList->{$iToolName}{'version'} = 'Unknown';
    # So if $iVersion is still undefined, leave well alone! Eventually return 'Unknown'.
    if ($iVersion)        # Found version. Have we got a Build Number?
    {
        unless($iBuildNum) { $iBuildNum = 'Build unknown'; }
        $iToolList->{$iToolName}{'version'} = "$iVersion [$iBuildNum]";
    }
    # Next look for "Multiple Versions"
    # For example "\\LON-ENGBUILD54\C$\Apps\Perl.5.10.0"
    my $iAppsRoot = 'C:\Apps';
    my $iPerlExe  = 'bin\Perl.exe';
    my $iAppsDirs = ReadDirectory($iAppsRoot);      # Get arrayref
    unless (defined $iAppsDirs)
    {
        print "ERROR:  Failed to read Apps Directory.\n";
        return;
    }
    foreach my $iAppsDir (@$iAppsDirs)
    {
        if ($iAppsDir =~ m/^Perl\.(\d.*)/i)
        {
            my $iMultiVer = $1;
            $iAppsDir = uc $iAppsDir;       # Source is a Windows directory name, which could be in any case
            $iToolList->{$iToolName}{'multiver'}{$iMultiVer} =  'Unknown';
            $iVersion = '';
            $iBuildNum = '';
            my @iPerlExeRet = `$iAppsRoot\\$iAppsDir\\$iPerlExe -v`;
            foreach (@iPerlExeRet)
            {
                if (m/ (version\s+|v)([0-9]{0,2}\.[0-9]{0,3}[_\.][0-9]{0,2})/)
                { 
                    if ($iVersion) { print "ERROR: Perl Version  redefined as $2.\n"; last; }	# Error? Can't have version defined twice!?
                    $iVersion =  $2;
                }
                elsif (m/Binary\s+build\s+(\d+)/i)
                {
                    if ($iBuildNum) { print "ERROR: Perl Build Number  redefined as $1.\n"; last; }	# Error? Can't have build defined twice!?
                    $iBuildNum = $1;
                }
            }
            # We have already set $iToolList->{$iToolName}{'multiver'}{$iMultiVer} = 'Unknown';
            # So if $iVersion is still undefined, leave well alone! Eventually return 'Unknown'.
            if ($iVersion)        # Found version. Have we got a Build Number?
            {
                unless($iBuildNum) { $iBuildNum = 'Build unknown'; }
                $iToolList->{$iToolName}{'multiver'}{$iMultiVer} = "$iVersion [$iBuildNum]";
            }
        }
    }       # End foreach my $iAppsDir (@$iAppsDirs)
}

# GetPerlModuleInfo
#
# Description
#   Gets Version for the specified Perl Module 
#
# Inputs - Name of Module 
#
# Retuens - Version text
#
sub GetPerlModuleInfo
{
    my $iModuleName = shift;
    my $iVerTxt = 'Unknown';
    $iModuleName =~ s/-/::/;
    if (eval "require $iModuleName;")
    {
        no strict 'refs';
        $iVerTxt = ${$iModuleName . "::VERSION"};
        use strict;
    }
    return $iVerTxt;
}

# GetMetrowerksInfo
#
# Description
#   Gets Metrowerks Compiler and Linker Versions
#
# Inputs - Reference to Tool List hash (for return of data)
#
# Outputs - Data returned via supplied hashref
#
sub GetMetrowerksInfo
{


    my $iToolList = shift;

    # First get the version of the default Compiler (MWCCSym2), as located by the "permanent" PATH etc.
    my $iToolNameCC = 'Metrowerks Compiler';
    $iToolList->{$iToolNameCC}{'version'} = 'Unknown';
    my @iCCRet     = `mwccsym2 -version 2>&1`;
    foreach (@iCCRet)
    {
        if (m/Version(.*)(\n$)/)
        {
            $iToolList->{$iToolNameCC}{'version'} =  $1;
            last;
        }
    }
    
    # Now get the version of the default Linker (MWLDSym2), as located by the "permanent" PATH etc.
    my $iToolNameLD = 'Metrowerks Linker';
    my @iLDEnv     = `mwldsym2 -version 2>&1`;
    $iToolList->{$iToolNameLD}{'version'} = 'Unknown';
    foreach (@iLDEnv) 
    {
        if (m/Version(.*)(\n$)/) 
        { 
            $iToolList->{$iToolNameLD}{'version'} =  $1;
            last;
        }
    }

    # Next look for "Multiple Versions"
    # For example "\\LON-ENGBUILD54\C$\Apps\Metrowerks\OEM3.1.1\Symbian_Tools\Command_Line_Tools\mwccsym2.exe"
    my $iMWksRoot = 'C:\Apps\Metrowerks';
    my $iMWksCC   = 'Symbian_Tools\Command_Line_Tools\mwccsym2.exe';
    my $iMWksLD   = 'Symbian_Tools\Command_Line_Tools\mwldsym2.exe';
    my $iMWksDirs = ReadDirectory($iMWksRoot);      # Get arrayref
    unless (defined $iMWksDirs)
    {
        print "ERROR:  Failed to read Metrowerks Root Directory.\n";
        return;
    }
    foreach my $iMWksDir (@$iMWksDirs)
    {
        if ($iMWksDir =~ m/^OEM\d+\.\d+/i)
        {
            $iMWksDir = uc $iMWksDir;       # Source is a Windows directory name, which could be in any case
            my @iMWksCCRet = `$iMWksRoot\\$iMWksDir\\$iMWksCC`;
            $iToolList->{$iToolNameCC}{'multiver'}{$iMWksDir} =  'Unknown';
            foreach my $iLine(@iMWksCCRet)
            {
                if ($iLine =~ m/Version(.*)(\n$)/i)
                { 
                    $iToolList->{$iToolNameCC}{'multiver'}{$iMWksDir} =  $1;
                    last;
                }
            }
            my @iMWksLDRet = `$iMWksRoot\\$iMWksDir\\$iMWksLD`;
            $iToolList->{$iToolNameLD}{'multiver'}{$iMWksDir} =  'Unknown';
            foreach my $iLine(@iMWksLDRet)
            {
                if ($iLine =~ m/Version(.*)(\n$)/i)
                { 
                    $iToolList->{$iToolNameLD}{'multiver'}{$iMWksDir} =  $1;
                    last;
                }
            }
        }
    }       # End foreach my $iMWksDir (@$iMWksDirs)

}

# GetArmInfo
#
# Description
#   Looks for directories below C:\Apps\ARM which might contain versions of RVCT compiler etc.
#
# Inputs - Reference to Tool List hash (for return of data)
#
# Outputs - Data returned via supplied hashref
#
sub GetArmInfo
{
    my $iToolList = shift;
    my $iToolName = 'Arm CC';

    # First get the version of the default ARMCC, as located by the "permanent" PATH etc.
    $iToolList->{$iToolName}{'version'} = 'Unknown';
    my @iArmCCRet = `armcc --vsn 2>&1`;
    foreach (@iArmCCRet) 
    {
        if (m/RVCT(.*)(\n$)/)
        { 
            $iToolList->{$iToolName}{'version'} =  $1;
            last;
        }
    }
    # Next look for "Multiple Versions"
    # For example "\\LON-ENGBUILD51\C$\Apps\ARM\RVCT2.2[435]\RVCT\Programs\2.2\349\win_32-pentium\armcc.exe" 
    my $iRVCTRoot = 'C:\Apps\ARM';
    my $iRVCTCC2  = 'RVCT\Programs\2.2\349\win_32-pentium\armcc.exe';   # Applies to RVCT Version 2.x
    my $iRVCTCC3  = 'bin\armcc.exe';                                    # Applies to RVCT Version 3.x
    my $iRVCTDirs = ReadDirectory($iRVCTRoot);      # Get arrayref
    unless (defined $iRVCTDirs)
    {
        print "ERROR:  Failed to read ARM Root Directory.\n";
        return;
    }
    foreach my $iRVCTDir (@$iRVCTDirs)     # Applies to RVCT Version 2.x
    {
        $iRVCTDir = uc $iRVCTDir;          # Source is a Windows directory name, which could be in any case
        if ($iRVCTDir =~ m/^RVCT2\.\d+/i)
        {
            $iToolList->{$iToolName}{'multiver'}{$iRVCTDir} = GetArmVersion("$iRVCTRoot\\$iRVCTDir\\$iRVCTCC2");
        }
        elsif ($iRVCTDir =~ m/^RVCT\d+\.\d+/i)   # Applies to RVCT Version 3.x (and above, until we know otherwise!!)
        {
            $iToolList->{$iToolName}{'multiver'}{$iRVCTDir} = GetArmVersion("$iRVCTRoot\\$iRVCTDir\\$iRVCTCC3");
        }
    }

}

# GetArmVersion
#
# Description
#   Gets Arm Compiler Version for a specified instance.
#
# Inputs - Full pathname of compiler (ARMCC.EXE)
#
# Outputs - Version (as text) or 'Unknown' if not determined
#
sub GetArmVersion
{
    my $iRVCTCC = shift;       # Full pathname of compiler (ARMCC.EXE)
    my @iArmCCEnv = `$iRVCTCC --vsn 2>&1`;
    foreach my $iLine(@iArmCCEnv)
    {
        if ($iLine =~ m/RVCT(.*)(\n$)/i)
        { 
            return $1;
        }
    }
    return 'Unknown';
}

# GetJavaInfo
#
# Description
#   Gets Java Runtime Compiler Version
#
# Inputs - Reference to Tool List hash (for return of data)
#
# Outputs - Data returned via supplied hashref
#
sub GetJavaInfo
{
    my $iToolList = shift;
    my $iToolName = 'Java';

    # First get the version of the default Java installation as located by the "permanent" PATH etc.
    # This probably means running 
    my @iJavaReturn     = `java -version 2>&1`;
    $iToolList->{$iToolName}{'version'} =  'Unknown';
    foreach my $iLine (@iJavaReturn) 
    {
        if ($iLine =~ m/version.*(\"{1})(.*)(\"{1})/i)
        {
            $iToolList->{$iToolName}{'version'} =  $2;
            last;
        }
    }

    # Next look for "Multiple Versions" - Assumed to be in directories matching 'C:\Apps\JRE*'
    # For example "C:\Apps\JRE1.5.0_13\bin\java.exe" 
    my $iJRERoot = 'C:\Apps';
    my $iJREEXE  = 'bin\java.exe';
    my $iJREDirs = ReadDirectory($iJRERoot);      # Get arrayref (list of sub-directories
    unless (defined $iJREDirs)
    {
        print "ERROR:  Failed to read JRE Root Directory: $iJRERoot.\n";
        return;
    }
    foreach my $iJREDir (@$iJREDirs)
    {
        if ($iJREDir =~ m/^JRE\d+\.\d+/i)
        {
            $iJREDir = uc $iJREDir;       # Source is a Windows directory name, which could be in any case
            my @iJREReturn = `$iJRERoot\\$iJREDir\\$iJREEXE -version 2>&1`;
            $iToolList->{$iToolName}{'multiver'}{$iJREDir} =  'Unknown';
            foreach my $iLine(@iJREReturn)
            {
                if ($iLine =~ m/version.*(\"{1})(.*)(\"{1})/i)
                { 
                    $iToolList->{$iToolName}{'multiver'}{$iJREDir} =  $2;
                    last;
                }
            }
        }
    }

}

# GetSophosInfo
#
# Description
#   Gets Sophos Version
#
# Inputs - Reference to Tool List hash (for return of data)
#
# Outputs - Data returned via supplied hashref
#
sub GetSophosInfo
{
    my $iToolList = shift;
    # Sophos Anti-virus
    # Typical output from "sav32cli.exe -v"
    # Sophos Anti-Virus
    # Copyright (c) 1989-2005 Sophos Plc, www.sophos.com
    # System time 11:58:18, System date 04 April 2005
    # Product version           : 3.92.0
    # Engine version            : 2.28.10
    # Virus data version        : 3.92
    # User interface version    : 2.03.048
    # Platform                  : Win32/Intel
    # Released                  : 04 April 2005
    # Total viruses (with IDEs) : 102532
    my $iSophosExe='C:\Program Files\Sophos SWEEP for NT\sav32cli.exe';
    $iToolList->{'Sophos product'}{'version'} = 'Unknown';
    $iToolList->{'Sophos data'}{'version'} = 'Unknown';
    $iToolList->{'Sophos release'}{'version'} = 'Unknown';
    if (-e $iSophosExe)
    {
        my @iSophosVer = `\"$iSophosExe\" -v`;

        # Get Sophos versions
        foreach my $iLine (@iSophosVer)
        {
            if ($iLine =~ m/Product\s+version\s+:\s+(\S+)/)
            {
                $iToolList->{'Sophos product'}{'version'} = $1;
                next;
            }
            if ($iLine =~ m/Virus\s+data\s+version\s+:\s+(\S+)/)
            {
                $iToolList->{'Sophos data'}{'version'} = $1;
                next;
            }
            if ($iLine =~ m/Released\s+:\s+(.+)/)
            {
                $iToolList->{'Sophos release'}{'version'} = $1;
                next;
            }
        }
    }

}

# GetMcAfeeInfo
#
# Description
#   Gets McAfee Versions (Software and data)
#
# Inputs - Reference to Tool List hash (for return of data)
#
# Outputs - Data returned via supplied hashref
#
sub GetMcAfeeInfo
{
    my $iToolList = shift;
    # McAfee Anti-virus
    # Revision March 2007 - Get Versions from Registry in the following location (for Version 8.000?):
    # HKEY_LOCAL_MACHINE\SOFTWARE\Network Associates\ePolicy Orchestrator\Application Plugins\VIRUSCAN8000
    $iToolList->{'McAfee VirusScan'}{'version'} = 'Unknown';
    $iToolList->{'McAfee VirusData'}{'version'} = 'Unknown';

    my $iRegKey = 'LMachine/SOFTWARE/Network Associates/ePolicy Orchestrator/Application Plugins';
    # Get data from hash set up by Win32::TieRegistry
    my $iHashRef = $Registry->{$iRegKey};
    unless (defined $iHashRef) { print "WARNING: Failed to read McAfee version from Registry\n";  return; }
    my @iValidHashKeys;
    foreach my $iHashKey (sort %$iHashRef)
    {
        if ($iHashKey =~ m/^VIRUSCAN\d+/i)
        {
            push @iValidHashKeys,$iHashKey;
        }
    }
    unless (scalar @iValidHashKeys)
    {
        return;             # No valid sub-key
    }
    if ((scalar @iValidHashKeys) > 1)
    {
        print "WARNING: Duplicate McAfee Versions.\n"; 
    }
    
    @iValidHashKeys = sort @iValidHashKeys;
    my $iVersionKey = pop @iValidHashKeys;      # In the unlikely event of there being more than one, get the last one!
    
    # Check that hash element exists before referencing data. Otherwise TieRegistry will think that we want to create a new key/value
    if (defined $iHashRef->{$iVersionKey}{'/Version'})    { $iToolList->{'McAfee VirusScan'}{'version'} = $iHashRef->{$iVersionKey}{'/Version'}; }
    if (defined $iHashRef->{$iVersionKey}{'/DATVersion'}) { $iToolList->{'McAfee VirusData'}{'version'} = $iHashRef->{$iVersionKey}{'/DATVersion'}; }
}

# GetGPGInfo
#
# Description
#   Gets GPG Version (currently usually 
#
# Inputs - Reference to Tool List hash (for return of data)
#
# Outputs - Data returned via supplied hashref
#
sub GetGPGInfo
{
    my $iToolList = shift;

    # Typical output from 'GPG -h'
    #     gpg (GnuPG) 1.4.4
    # Copyright (C) 2006 Free Software Foundation, Inc.
    # This program comes with ABSOLUTELY NO WARRANTY.
    # This is free software, and you are welcome to redistribute it
    # under certain conditions. See the file COPYING for details.

    my $iToolName = 'GnuPG';
    my @iRetData     = `GPG -h 2>&1`;
    $iToolList->{$iToolName}{'version'} = 'Unknown';
    foreach (@iRetData)
    {
        if (m/^\s*gpg\s+\(GnuPG\)\s*(\d+\.\d+\.\d+)/i)
        {
            $iToolList->{$iToolName}{'version'} = $1;
            last;
        }
    }
}

# GetWinTapInfo
#
# Description
#   Gets WinTap Version
#
# Inputs - Reference to Tool List hash (for return of data)
#
# Outputs - Data returned via supplied hashref
#
sub GetWinTapInfo
{
    my $iToolList = shift;

    # Typical output from 'IPCONFIG /ALL'
    # Ethernet adapter TAP-Win32:
    #    Connection-specific DNS Suffix  . :
    #    Description . . . . . . . . . . . : TAP-Win32 Adapter V8
    my $iToolName = 'WinTAP';
    my @iRetData     = `IPCONFIG /ALL 2>&1`;
    $iToolList->{$iToolName}{'version'} = 'Unknown';
    foreach (@iRetData)
    {
        if (m/Description.+TAP-Win32\s+Adapter\s+(V.+)/i)
        {
            $iToolList->{$iToolName}{'version'} = $1;
            last;
        }
    }
}

# ReadDirectory
#
# Read specified directory. Remove '.' and '..' entries (Windows speciality!)
#
# Input: Directory name
#
# Return: Array of subdirectory names, or undef if open fails.
#
sub ReadDirectory
{
    my $iDirName = shift;

	unless (opendir DIRECTORY, $iDirName)
	{
	    print ("ERROR:  Failed to open directory: $iDirName\nERROR:  $!\n");
	    return undef;
	}
	my @iSubDirs = readdir(DIRECTORY);
	closedir DIRECTORY;

	# Remove '.' and '..' from list
	for (my $iIndx = 0; $iIndx < (scalar @iSubDirs); )
	{
	    if ($iSubDirs[$iIndx] =~ m/^\.{1,2}/)
	    {
	        splice @iSubDirs, $iIndx, 1;
	    }
	    else
	    {
	        ++$iIndx;
	    }
	}

    return \@iSubDirs;
}

1;
