#!/usr/bin/perl
use strict;
use LWP::UserAgent;
use Getopt::Long;


my ($iComp, $iLoc, $iType) = ProcessCommandLine();
my $iVersion;
if ($iType eq "green")
{
	$iVersion = GetLatestGreenBuild($iComp)
}
elsif($iType eq "latest")
{
	$iVersion = GetLatestBuild($iComp);  
}
elsif ($iType =~ /DP/i)
{
	if ($iType =~ /_DeveloperProduct/i)
	{
		$iVersion = $iType;
	}
	else
	{
		$iVersion = $iType."_DeveloperProduct";
	}
}
else{
	$iVersion = $iType;
}
chomp($iVersion);

my $pushreloutput = `pushrel -vv $iComp $iVersion $iLoc`;
if (($pushreloutput =~ /^Copying $iComp $iVersion to/) || ($pushreloutput =~ /already present/)){
  print $pushreloutput;
}else{
  print "ERROR: could not pushrel $iComp $iVersion - $pushreloutput\n";
}



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
	$build = LRtrim($build);
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
    $sVer = LRtrim($sVer);
	my $iBaselineComponentName = shift ;
    $iBaselineComponentName = LRtrim($iBaselineComponentName);
    my $sBrag = "TBA";
	my $sSnapshot = "";
	my $sProduct = "";
    if ($sVer =~ /\_DeveloperProduct/i) 
    {
		#DP00420_DeveloperProduct
    	if ($sVer =~ /([\w\.]+)\_DeveloperProduct/i)
        {
            $sSnapshot = $1;
            $sProduct = "DP";
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
 
	if ($roResponse->is_success and $roResponse->content =~ /BRAG\s*\=\s*([a-z|A-Z]+)/)
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



# ProcessCommandLine
#
# Inputs
#
# Outputs
# $iComp - Name of the component to push
# $iLoc -  Remote site reltools.ini location
#
# Description
# This function processes the commandline
sub ProcessCommandLine {

  my ($iHelp, $iComp, $iLoc, $iLatest, $iGreen, $iVer);
  GetOptions('h' => \$iHelp, 'c=s' => \$iComp, 'r=s' => \$iLoc, 'g' => \$iGreen, 'l' => \$iLatest, 'version=s'=>\$iVer);

  if (($iHelp) || (!defined $iComp) || (!defined $iLoc) || ($iVer && $iLatest)|| ($iVer && $iGreen)| ($iGreen && $iLatest))
  {
    &Usage();
  } 
  
  my $iType = ($iGreen)? "green" : "latest";
  $iType = ($iVer)? $iVer:$iType;

  return($iComp,$iLoc,$iType);
}

# Usage
#
# Output Usage Information.
#
sub Usage {
  print <<USAGE_EOF;

  Usage: pushComp.pl [Args/options]

  Args: (required)
  
  -c  [Component name]  Name of component to push 
  -r [Remote reltools.ini location] Remote site reltools.ini location (Target location reltools.ini file)
  -l Latest Build  or -g Latest Green Build or -v specify a build
  
  options:

  -h                    help
  
  Example Commandline
  pushComp.pl -c tools_testexecute -r C:\\epoc32\\relinfo\\reltools.ini -g
  pushComp.pl -c tools_testexecute -r C:\\epoc32\\relinfo\\reltools.ini -l
  pushComp.pl -c tools_testexecute -r C:\\epoc32\\relinfo\\reltools.ini -version DP00500
  

USAGE_EOF
	exit 1;
} 
