#
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
#!/usr/bin/perl

package GetDPComp ;

use strict;
use LWP::UserAgent;
use Getopt::Long;

# LRtrim
#
# Description
# This function removes the space on the left and right
sub LRtrim( $ ) {
  my $result = shift ;
  $result =~ s/^\s+// ;
  $result =~ s/\s+$// ;
  return $result ;
}

sub GenerateComponentVersion( $  $ ) {
  my $inputVersion = shift ;
  $inputVersion = LRtrim($inputVersion);
  my $iBaselineComponentName = shift ;
  $iBaselineComponentName = LRtrim($iBaselineComponentName);
  my %ComponentVersion = ( );
  print "envsize -vv $iBaselineComponentName $inputVersion \n" ;
  my @envsizeoutput = `envsize -vv $iBaselineComponentName $inputVersion `;
  foreach my $line ( @envsizeoutput ) {
    if ($line =~ /^Adding up size of / ) {
      $line =~ s/^Adding up size of //;
      $line = LRtrim( $line ) ;
      my ($component, $release) = split(/\s+/, $line);
      $ComponentVersion{$component} = $release ;
    }
  }
  return  %ComponentVersion ; 
}

sub ValidateVersion( $ $ ) {
  my $inputVersion = shift ;
  $inputVersion = LRtrim($inputVersion);
  my $iBaselineComponentName = shift ;
  $iBaselineComponentName = LRtrim($iBaselineComponentName);
  my $retval = 1 ;

  if( (!defined $inputVersion) || ($inputVersion eq "" ) ){
    $retval = 0 ;
    print "\nERROR: No valid version specified. \n";
  }elsif ( CheckBuild( $inputVersion, $iBaselineComponentName ) == 1 ){
    print "\nUser specified build: $inputVersion is using. \n";
  }elsif ( lc($inputVersion) eq "latest") {  
    $inputVersion = GetLatestBuild( $iBaselineComponentName ); 
    $inputVersion = LRtrim( $inputVersion );
    if ($inputVersion eq "nobuild" )  {
      $retval = 0 ;
      print "\nERROR: No build available. \n";
    } else {
      print "\nLatest build: $inputVersion is using.\n";
    }
  }elsif ( lc($inputVersion) eq "green" ){
    $inputVersion = GetLatestGreenBuild( $iBaselineComponentName ) ;
    $inputVersion = LRtrim( $inputVersion );
    if ($inputVersion eq "amberbuild" )  {
      $retval = 0 ;
      print "\nERROR: No green build available. \n";
    } else {  
      print "\nLatest green build: $inputVersion is using.\n";
    }
  }else {    
    $retval = 0 ;
    print "\nERROR: No Such Build: $inputVersion .\n";
  }
  return ( $inputVersion, $retval) ;
}

sub CheckBuild( $  $ ) {
  my $iVer = shift ;
  $iVer = LRtrim( $iVer );
  my $iBaselineComponentName = shift ;
  $iBaselineComponentName = LRtrim($iBaselineComponentName);
  my $iRet = 0 ;
  my @AllVersions = `latestver -a $iBaselineComponentName`; 

  foreach my $build ( @AllVersions ) {
    $build = LRtrim( $build );
    if (lc( $build ) eq lc( $iVer ) ) {
      $iRet = 1 ;
      last ;
    }
  }
  return $iRet ;
}

sub GetLatestBuild( $ ) {
  my $iBaselineComponentName = shift ;
  $iBaselineComponentName = LRtrim($iBaselineComponentName);
  my $latestbuild = "nobuild";
  my @AllBuilds = `latestver -a $iBaselineComponentName`; 
  
  foreach my $build ( @AllBuilds  ) {
    my $status = BragFromAutobuild2HttpInterface( $build , $iBaselineComponentName  );
    if ( ( lc( $status ) eq "green" ) or ( lc( $status ) eq "amber" )  ){
      $latestbuild = $build ;
      last ;
    }
  }
  return $latestbuild ;
}

sub GetLatestGreenBuild( $ ) {
  my $iBaselineComponentName = shift ;
  $iBaselineComponentName = LRtrim($iBaselineComponentName);
  my $greenbuild = "amberbuild";
  my @AllBuilds = `latestver -a $iBaselineComponentName`; 

  foreach my $build ( @AllBuilds  ) {
    my $status = BragFromAutobuild2HttpInterface( $build , $iBaselineComponentName );
    if ( lc( $status ) eq "green" ) {
      $greenbuild = $build ;
      last ;
    }
  }
  return  $greenbuild ; # buildnumber or "amberbuild"
}

# Usage
# Just call the sub-route called BragFromAutobuild2HttpInterface like this
# my $status = BragFromAutobuild2HttpInterface("M04735_Symbian_OS_v9.5" , "gt_techview_baseline");
# my $status = BragFromAutobuild2HttpInterface("DP00454_DeveloperProduct" , "sf_tools_baseline");
# $status should be green or amber etc.

## @fn BragFromAutobuild2HttpInterface($sVer)
#
# Queries the HTTP interface to Autobuild2 DB to determine the BRAG status of a CBR.
#
# @param sVer string, CBR for which the BRAG status is to be determined.
#
# @return string, BRAG status of the queried CBR. "TBA" if BRAG was indeterminable.

sub BragFromAutobuild2HttpInterface( $  $ )
{
	my $sVer = shift ;
    $sVer = LRtrim( $sVer );
	my $iBaselineComponentName = shift ;
    $iBaselineComponentName = LRtrim($iBaselineComponentName);
    my $sBrag = "TBA";
	my $sSnapshot = "";
	my $sProduct = "";
    if (( lc( $iBaselineComponentName ) eq "sf_tools_baseline" ) or ( lc( $iBaselineComponentName ) eq "developer_product_baseline" ) ) 
    {
    	if ( $sVer =~ /([\w\.]+)\_DeveloperProduct/i )
        {
            $sSnapshot = $1;
            $sProduct = "DP";
        }
        else
        {
            return $sBrag; # i.e. "TBA"
        }	
    }elsif  (( lc( $iBaselineComponentName ) eq "gt_techview_baseline" ) or ( lc( $iBaselineComponentName ) eq "gt_only_baseline" ) ) 
    {
    	if ( $sVer =~ /([\w\.]+)\_Symbian_OS_v([\w\.]+)/i )
        {
		#print $1, "\n", $2, "\n";
            $sSnapshot = $1;
            $sProduct = $2;
        }
        else
        {
            return $sBrag; # i.e. "TBA"
        }
    }    
    
	my $parameters = "snapshot=$sSnapshot&product=$sProduct";
	# Alternative method of getting the BRAG status - use the HTTP interface to Autobuild
	my $sLogsLocation = "http://intweb:8080/esr/query?$parameters";
	
	my $roUserAgent = LWP::UserAgent->new;
	my $roResponse = $roUserAgent->get($sLogsLocation);
 
	if ($roResponse->is_success and $roResponse->content =~ /\=\=\s*BRAG\s*\=\s*([a-z|A-Z]+)/)
	{
		$sBrag = $1;
		$sBrag =~ s/\s//g;  # remove any whitespace padding
		return $sBrag;
	}
	else
	{		
		return $sBrag; # i.e. "TBA"
	}
}


1;