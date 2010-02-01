#!perl -w 
#
# StartBuild.pl
#
# Script to bootstrap the starting of Daily and Test builds
# Uses a config file containing details of which test source is needed.
# Performs a delta sync to the baseline changelist number, copies only the
# necessary files to clean-src, then syncs down any other files specified
# in the config file into clean-src.

use strict;
use File::Copy;
use Getopt::Long;
use FindBin;
use Sys::Hostname;
use lib "$FindBin::Bin/..";
use BxCopy;
use PreBldChecks;
use BuildLaunchChecks;

use PC_P4Table;
my $gXMLEnvRef; # Reference to hash containing environment data read from the XML file
my %gBuildSpec;

# default opts are daily manual
my $CFG_BUILD_SUBTYPE = "Daily";

# Process the commandline
my ($iBuildSubTypeOpt) = ProcessCommandLine();

my $hostname = &GetHostName();

my $PUBLISH_LOCATION_DAILY = "\\\\builds01\\devbuilds";
my $PUBLISH_LOCATION_TEST  = "\\\\builds01\\devbuilds\\test_builds";
my $BUILDS_LOCAL_DIR       = "d:\\builds";

# Define the source root directory (assumes it's 3 levels up)
my $sourcedir = Cwd::abs_path("$FindBin::Bin\\..\\..\\..\\..");

# Define the pathnames for the XML files
my $BuildLaunchXML = "$sourcedir\\os\\buildtools\\bldsystemtools\\commonbldutils\\BuildLaunch.xml";
my $PostBuildXML   = "$sourcedir\\os\\buildtools\\bldsystemtools\\commonbldutils\\PostBuild.xml";

sub main() {
    
    print "Starting\n ";
    
    prepBuildLaunch();
    doLoadEnv();      # populate gBuildEnv with ENV
    doSubstDrive();
    doLogsDirCreate();
    doManualBuild();  # spawn build clients and do build
}

# load the env from BuildLaunch.xml
sub doLoadEnv() {

    # User may have edited environment variables above (see call to Notepad)
    # So re-read the XML file and store current values in %$gXMLEnvRef
    $gXMLEnvRef = PreBldChecks::XMLEnvironment($BuildLaunchXML);
    
    $gBuildSpec{'Product'}          = $gXMLEnvRef->{'Product'};
    $gBuildSpec{'SnapshotNumber'}   = $gXMLEnvRef->{'SnapshotNumber'};
    $gBuildSpec{'ChangelistNumber'} = $gXMLEnvRef->{'ChangelistNumber'};
    $gBuildSpec{'BuildsDirect'}     = $gXMLEnvRef->{'BuildsDirect'};
    $gBuildSpec{'Platform'}         = $gXMLEnvRef->{'Platform'};
    $gBuildSpec{'BuildBaseName'}    = 'Symbian_OS_v'.$gBuildSpec{'Product'};
    $gBuildSpec{'ThisBuild'}        = $gBuildSpec{'SnapshotNumber'}."_".$gBuildSpec{'BuildBaseName'};
    $gBuildSpec{'LogsDir'}          = $gXMLEnvRef->{'LogsDir'};
    $gBuildSpec{'BuildDir'}         = $gXMLEnvRef->{'BuildDir'};       # substed drive letter
    $gBuildSpec{'BuildsDirect'}     = $gXMLEnvRef->{'BuildsDirect'}; # build dir
    $gBuildSpec{'ThisBuildDir'}     = $gBuildSpec{'BuildsDirect'} . $gBuildSpec{'ThisBuild'};
    $gBuildSpec{'Type'}             = $gXMLEnvRef->{'Type'};
    $gBuildSpec{'CurrentCodeline'}  = $gXMLEnvRef->{'CurrentCodeline'};
    $gBuildSpec{'BuildSubType'}     = $gXMLEnvRef->{'BuildSubType'};
    $gBuildSpec{'SubstDir'}         = $gXMLEnvRef->{'SubstDir'};
    $gBuildSpec{'CleanSourceDir'}   = $gXMLEnvRef->{'CleanSourceDir'};
    
    doValidate();
}

#
# Output warnings for any missing attributes. If any
# are missing, the output a RealTimeBuild ERROR to halt the build
#
sub doValidate() {
    
    # 1. validate all env vars are set    
    # Note: Validate of TestBuild.cfg, not done here
    my $iWarnCount = 0;
    my $key;
    my $value;
    
    while(($key, $value) = each(%gBuildSpec)) {
        
        # do something with $key and $value
        if ($value eq "") {
            print "\nWARNING: Attribute $key is missing from Specification ";
            $iWarnCount++;
        }
    }
    
    die "\nERROR: RealTimeBuild: Attributes missing from BuildLaunch.xml" if $iWarnCount > 0;    
}

# Create Logs dir
sub doLogsDirCreate() {
    
    if (!(-e $gBuildSpec{'LogsDir'})) {
        
        print "=== CREATING LOGS DIRECTORY ===\n";
        
        my $cmd = "mkdir $gBuildSpec{'LogsDir'}";        
        system($cmd);

    } else {
        print "REMARK: Logs dir " .$gBuildSpec{'LogsDir'}."already exists!\n";
    }
}

#
sub doSubstDrive() {
    
    # Ensure trailing backslashes are removed
    my $iSubstDrv = $gBuildSpec{'BuildDir'};
     
    $iSubstDrv =~ s/\\{1}$//;
      
    print "=== CREATING BUILD DIRECTORY ===\n";
    
    mkdir($gBuildSpec{'SubstDir'}, 0666) or die "ERROR: Could not create \"$gBuildSpec{'SubstDir'}\": $!";
    
    print "=== SUBST'ING BUILD DIRECTORY ===\n";
    `subst $iSubstDrv /d 2>&1`;
    system "subst $iSubstDrv $gBuildSpec{'SubstDir'} 2>&1" and die "ERROR: Could not subst \"$gBuildSpec{'SubstDir'}\" to \"substdrive\" : $!";
    
    
}

# Perform the manual build by running
# 1. BuildLaunch.xml
# 2. Core/Glue xml
# 3. PostBuild.xml
#
sub doManualBuild() {
    
        # Start the BuildClients
        print "Starting the BuildClients\n";
        my $profile = 1;#($gProfile ? "-p" : "");
        system "start \"Launch BuildClient\" cmd /k perl $sourcedir\\os\\buildtools\\bldsystemtools\\buildsystemtools\\BuildClient.pl -d localhost:15000 -d localhost:15001 -d localhost:15002 -w 5 -c Launch $profile";
        
        #
        # BUILDING
        #
        print "=== Build started ===\n";
        
        # Start the BuildServer for the main build
        print "Starting the Launch BuildServer\n";
        my $command = "perl $sourcedir\\os\\buildtools\\bldsystemtools\\buildsystemtools\\buildserver.pl -p 15000 -p 15001 -p 15002 -t 5 -c 5 -d $BuildLaunchXML -l $gBuildSpec{'LogsDir'}\\".$gBuildSpec{'ThisBuild'}.".log";
        system ($command) and die "Error: $!";
        
        print "Starting the Glue BuildServer\n";
        my $gGlueXMLFile = $gBuildSpec{'BuildDir'} . '\\clean-src' . '\\os\\deviceplatformrelease\\symbianosbld\\cedarutils\\Symbian_OS_v' . $gBuildSpec{'Product'} . '.xml';
        $command = "perl $sourcedir\\os\\buildtools\\bldsystemtools\\buildsystemtools\\buildserver.pl -p 15000 -p 15001 -p 15002 -t 5 -c 5 -d $gGlueXMLFile -e $BuildLaunchXML -l $gBuildSpec{'LogsDir'}\\".$gBuildSpec{'BuildBaseName'}.".log";
        system ($command) and die "Error: $!";
        
        print "Starting the Postbuild BuildServer\n";
        $PostBuildXML = $gBuildSpec{'CleanSourceDir'} . '\\os\\buildtools\\bldsystemtools\\commonbldutils\\PostBuild.xml';
        $command = "perl $sourcedir\\os\\buildtools\\bldsystemtools\\buildsystemtools\\buildserver.pl -p 15000 -p 15001 -p 15002 -t 5 -c 5 -d $PostBuildXML -e $BuildLaunchXML -l $gBuildSpec{'LogsDir'}\\postbuild.log";
        system ($command) and die "Error: $!";
          
        print "=== Build finished ===\n";
        
        exit 0;
}

#
sub prepBuildLaunch() {
    
    my %BuildLaunchCheckData;

    #
    # PREPARATION
    #
    
    # Make XML file writable
    print "Making BuildLaunch XML file writable\n";
    chmod(0666, $BuildLaunchXML) || warn "Warning: Couldn't make \"$BuildLaunchXML\" writable: $!";
    
    ($BuildLaunchCheckData{'Product'},
     $BuildLaunchCheckData{'SnapshotNumber'},
     $BuildLaunchCheckData{'PreviousSnapshotNumber'},
     $BuildLaunchCheckData{'ChangelistNumber'},
     $BuildLaunchCheckData{'CurrentCodeline'},
     $BuildLaunchCheckData{'Platform'},
     $BuildLaunchCheckData{'Type'}) = BuildLaunchChecks::GetUserInput();
    
     $BuildLaunchCheckData{'BCToolsBaseBuildNo'} = BuildLaunchChecks::GetBCValue(\%BuildLaunchCheckData);
     
     $BuildLaunchCheckData{'BuildsDirect'}       = $BUILDS_LOCAL_DIR;
     $BuildLaunchCheckData{'BuildSubType'}       = $CFG_BUILD_SUBTYPE;
     $BuildLaunchCheckData{'PreviousBuildPublishLocation'} = $PUBLISH_LOCATION_DAILY;

     # set publish location according to Build SubType
     if ($CFG_BUILD_SUBTYPE eq "Test") {
        $BuildLaunchCheckData{'PublishLocation'}    = $PUBLISH_LOCATION_TEST;
     } else {
        $BuildLaunchCheckData{'PublishLocation'}    = $PUBLISH_LOCATION_DAILY;
     }

    # validate and write any updates    
    my($Warnings) = BuildLaunchChecks::CheckData(\%BuildLaunchCheckData);
    BuildLaunchChecks::UpdateXML($BuildLaunchXML, \%BuildLaunchCheckData, "");
    
    # Open XML file for verification
    print "Opening XML file(s) for verification\n";
    my $command = "start /wait notepad.exe ".$BuildLaunchXML;
    system($command) and die "Error: $!";    
}
 
# Return hostname of this machine
sub GetHostName
{
  my ($iHost) = &hostname() =~ /(\S+?)\./;
  if (!defined($iHost))
  {
    # Not a fully qualified Hostname, use use raw name
    $iHost = &hostname();
  }
  return ($iHost);
}


# new process command line
sub ProcessCommandLine {
  my ($iHelp);
  
  GetOptions('h' => \$iHelp,
	     't:s' => \$iBuildSubTypeOpt);

  if (($iHelp)) {
    Usage();
  } else {
    
    if ((defined $iBuildSubTypeOpt)) {
        $CFG_BUILD_SUBTYPE= "Test";
    }
  }
  
  return ($iBuildSubTypeOpt);
}


sub Usage {
  print <<USAGE_EOF;

  Usage: startbuild.pl [option]

  options:

  -h  -- help
  -t  [optional] Perform a TestBuild.
  
      - Additional source based upon testbuild.cfg will be
        obtained from Perforce. If testbuild.cfg is not correctly filled out
        it will fail during the syncsource stage.
      - TestBuild will be published to TestBuild area on devbuilds and to Test CBR Archive
        
  

USAGE_EOF
  exit 1;
}


#########################################
#              s t a r t
#########################################
main();

