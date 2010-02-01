use strict;

use Getopt::Long;
use File::Path;
use File::Spec::Functions;

my $gRealTimeBuildErrors = 0;
sub RealTimeBuildError($)
{
	$gRealTimeBuildErrors++;
	print STDERR "ERROR: RealTimeBuild: ", @_, "\n";
	return "RealTimeBuild error";
}

# Process the commandline
my ($iDataSource, $iSrc, $iMRPSrc, $platform, $iDummy, $iVerbose) = ProcessCommandLine();

my ($iDirList)= ProcessList($iDataSource, $iSrc, $iMRPSrc, $platform, $iVerbose);
my @delete;

search_dir($iSrc, $iDirList, \@delete, $iVerbose);

foreach my $leftover (keys %$iDirList)
{
  print "REMARK: LEFTOVER: $leftover ($$iDirList{$leftover})\n";
}

if ($gRealTimeBuildErrors && !$iDummy)
{
  print STDERR "\nWARNING: Files will NOT be deleted, because of earlier real time build errors\n\n";
  $iDummy = 1;
}

foreach my $delete (@delete)
{
  if ($iDummy)
  {
    print "REMARK: $delete is not referenced by any MRP\n";
  } else {
    # Delete the files or directories
    # make sure it is not read only
    #Convert back to \ for dos command
    $delete =~ s#\/#\\#g;
    system("attrib -r /s /d \"$delete\"");
    my $deletenum = rmtree($delete);
    if ($deletenum == 0)
    {
      RealTimeBuildError("failed to deleted $delete");
    } elsif (-d "$delete") {
      RealTimeBuildError("failed to deleted directory $delete"); #Because it still exists
    } elsif ($deletenum > 1) {
      print "REMARK: deleted $deletenum files in directory $delete as they are not referenced by any MRP\n";
    } else {
      print "REMARK: deleted $delete as it is not referenced by any MRP\n";
    }
  }
}

sub search_dir
{ 
  my ($dir, $iDirList, $delete, $iVerbose) = @_; 
  my @flist;
  
  print "Processing $dir\n" if ($iVerbose);
  if (opendir(DIRH,"$dir"))
  {
    @flist=readdir(DIRH); 
    closedir DIRH; 
    ENTRY: foreach my $entry (@flist)
    { 
      # ignore . and .. : 
      next if ($entry eq "." || $entry eq "..");
      my $partial_match;
      # Check entry again $iDirList for matches
      foreach my $sourceline (keys %$iDirList)
      {
        if ($sourceline =~ m#^$dir/$entry$#i)
        {
          # Exact match delete entry in %$iDirList
          # Check to see if something has already partial matched
          print "REMARK: $dir/$entry is probably covered more than once\n" if ($partial_match);
          if ($iVerbose)
          {
            if (-d "$dir/$entry")
            {
              print "Keeping directory $dir/$entry ($$iDirList{$sourceline})\n";
            } else {
              print "Keeping file $dir/$entry ($$iDirList{$sourceline})\n";
            }
          }
          delete $$iDirList{$sourceline};
          # No more processing required
          next ENTRY;
        }
        # Check to see if there is reference to inside this directory
        if ($sourceline =~ m#^$dir/$entry/#i)
        {
          # something reference this as a directory need more processing
          $partial_match = 1 if (-d "$dir/$entry");
        }
      }
      if ($partial_match)
      {
        search_dir("$dir/$entry", $iDirList, $delete, $iVerbose) if (-d "$dir/$entry");
        next ENTRY;
      }
      # No match place on deletion list
      push @$delete, "$dir/$entry";
      print "Marking $dir/$entry for delete\n" if ($iVerbose);
    }
  }else{ 
    RealTimeBuildError("can not read directory $dir"); 
  } 
}

# ProcessList
#
# Inputs
# $iDataSource - ref to array of files to process
# $iSrc - real location of source files
# $iMRPSrc - where the mrp thinks they are
#
# Outputs
#
# Description
# This function processes mrp files
sub ProcessList
{
  my ($iDataSource, $iSrc, $iMRPSrc, $platform, $iVerbose) = @_;
  
  my %Sources;
  my @ComponentList;
  my %mrpHash;
  
  # Need the dir swap
  $iDataSource =~ s/^$iMRPSrc/$iSrc/;
  # Read the options.txt
  open OPTIONS, $iDataSource or die RealTimeBuildError("Cannot open $iDataSource $!");
  while(<OPTIONS>)
  {
    if (/^GT\+Techview baseline mrp location:\s*(\S+)\s*$/i)
    {
      $mrpHash{lc $1} = $1;
      next;
    }
    if (/^GT only baseline mrp location:\s*(\S+)\s*$/i)
    {
      $mrpHash{lc $1} = $1;
      next;
    }
    if (/^Strong crypto mrp location:\s*(\S+)\s*$/i)
    {
      $mrpHash{lc $1} = $1;
      next;
    }
    if (/^Techview component list:\s*(\S+)\s*$/i)
    {
      push @ComponentList, $1;
      next;
    }
    if (/^GT component list:\s*(\S+)\s*$/i)
    {
      push @ComponentList, $1;
      next;
    }
  }
  close OPTIONS;
  for (my $i = 0; $i < scalar(@ComponentList); $i++)
  {
    # Fix path
    $ComponentList[$i] =~ s#\\#\/#g;
    # Need the dir swap
    $ComponentList[$i] =~ s/^$iMRPSrc/$iSrc/;
    open IN, $ComponentList[$i] or die RealTimeBuildError("Cannot open ".$ComponentList[$i]." $!");
    while(<IN>)
    {
      my ($mrp) = /^\s*\S+\s+(\S+)\s*$/;
      $mrpHash{lc $mrp} = $mrp;
    }
    close IN;
  }

  my @mrpList = sort values %mrpHash;
  for (my $i = 0; $i < scalar(@mrpList); $i++)
  {
    # Fix path
    $mrpList[$i] =~ s#\\#\/#g;
    # Need the dir swap
    $mrpList[$i] =~ s/^$iMRPSrc/$iSrc/i;
    # Fix the CustKit / Devkit and techviewexamplesdk mrp locations
    $mrpList[$i] =~ s#^/product/CustKit#$iSrc/os/unref/orphan/cedprd/CustKit#i;
    $mrpList[$i] =~ s#^/product/DevKit#$iSrc/os/unref/orphan/cedprd/DevKit#i;
    $mrpList[$i] =~ s#^/product/techviewexamplesdk#$iSrc/os/unref/orphan/cedprd/techviewexamplesdk#i;
    $Sources{"$iSrc/os/unref/orphan/cedprd/SuppKit"} = "clean.pl";
    $Sources{"$iSrc/os/unref/orphan/cedprd/tools"} = "clean.pl";
    $Sources{"$iSrc/os/buildtools/toolsandutils/productionbldtools"} = "clean.pl";
    
    if (open MRP, $mrpList[$i])
    {
      my $mrpfile = $mrpList[$i];
      my $mrpfile_in_source = 0;
      
      while(<MRP>)
      {
        my $dir;
        if (/^\s*source\s+(\S.*\S)\s*$/i)		# must allow for spaces in names
        {
          my $origdir = $1;
          $dir = $origdir;
         
          #Find any relative paths and add them to the end of the mrp location to create a full path
          if (($dir =~ /\.\\/)||($dir =~ /\.\.\\/)||($dir !~ /\\/))
          {
		  $dir =~ s#\.\.#\.#g;		# .. becomes .	
		  $dir =~ s#^\.#\\\.#g;		# add an extra \ incase one is not present at start of path, canonpath wil cleanup multiple \
	  
		  $dir = "\\".$dir if ($dir !~ /\\/);	#add \ to start of path if source line only specifies a file
		  
		  # Fix paths to /
		  $dir =~ s#\\#\/#g;
		  
		  $dir =~ s/$iMRPSrc/$iSrc/i if ($dir =~ /^$iMRPSrc/);
		  
		  $dir = $iSrc.$dir if ($dir !~ /^$iMRPSrc/);
		  
		  $dir = canonpath($dir);
          }
	  
	  # Fix paths to /
	  $dir =~ s#\\#\/#g;
	  
          # Remove any / from the end of the sourceline just in case the directory was ended in one
          $dir =~ s#\/$##;
          # Need the dir swap
          $dir =~ s/^$iMRPSrc/$iSrc/i;
          # Fix the CustKit / Devkit and techviewexamplesdk mrp locations
          $dir =~ s#^/product/CustKit#$iSrc/os/unref/orphan/cedprd/CustKit#i;
          $dir =~ s#^/product/DevKit#$iSrc/os/unref/orphan/cedprd/DevKit#i;
          $dir =~ s#^/product/techviewexamplesdk#$iSrc/os/unref/orphan/cedprd/techviewexamplesdk#i;
          
          if ($mrpfile =~ /^$dir$/i || $mrpfile =~ /^$dir\//i) {
            # mrpfile covered by source statements
            $mrpfile_in_source = 1;
          }

          # ignore location of release notes
          next if ($dir =~ /^\/component_defs/i);
          
          if (!-e $dir) {
            # CBR tools consider missing source as a fatal error
            RealTimeBuildError("$dir does not exist (listed as source in $mrpfile)");
          } elsif (!defined $Sources{$dir}) {
            $Sources{$dir} = $mrpfile;
          } else {
            print "REMARK: $origdir in $mrpfile is already defined in $Sources{$dir}\n";
          }
        }
      }
      close MRP;
      print "REMARK: $mrpList[$i] does not include itself as source\n" if (!$mrpfile_in_source);
    } else {
      RealTimeBuildError("Cannot open ".$mrpList[$i]." $!");
    }
  }
  return \%Sources;
}

# ProcessCommandLine
#
# Inputs
#
# Outputs
# @iDataSource array of multiple (txt file(s) to process)
# $iSrc - real location of files
# $iMRPSrc - where the mrp thinks they are
# @iDummy - do not delete anything
#
# Description
# This function processes the commandline

sub ProcessCommandLine {
  my ($iHelp, $iDataSource, $iSrc, $iMRPSrc, $platform, $iDummy, $iVerbose);
  GetOptions('h' => \$iHelp, 'o=s' =>\$iDataSource, 's=s' =>\$iSrc, 'm=s' =>\$iMRPSrc, 'p=s' =>\$platform,'n' => \$iDummy, 'v' => \$iVerbose);

  if (($iHelp) || (!defined $iSrc) || (!defined $iMRPSrc) || (!defined $platform))
  {
    Usage();
  }

  die RealTimeBuildError("Source directory $iSrc must be an absolute path with no drive letter") if ($iSrc !~ m#^[\\\/]#);
  die RealTimeBuildError("Source directory $iMRPSrc must be an absolute path with no drive letter") if ($iMRPSrc !~ m#^[\\\/]#);
  # Fix the paths
  $iSrc =~ s#\\#\/#g;
  $iMRPSrc =~ s#\\#\/#g;
  $iDataSource =~ s#\\#\/#g;
  if (! -d "$iSrc")
  {
    die RealTimeBuildError("$iSrc is not a directory") ;
  }

  # Need the dir swap
  $iDataSource =~ s/^$iMRPSrc/$iSrc/i;
  if (! -e "$iDataSource")
  {
    die RealTimeBuildError("Cannot open $iDataSource");
  }

  return($iDataSource, $iSrc, $iMRPSrc, $platform, $iDummy, $iVerbose);
}

# Usage
#
# Output Usage Information.
#

sub Usage {
  print <<USAGE_EOF;

  Usage: clean.pl [options]

  options:

  -h  help
  -o  options.txt to process
  -s  Source directory to process
  -m  MRP source directory
  -p  platform of product (beech or cedar)
  -n  Not do anything (dummy run)
  -v  Verbose
  
  Note:
  Due to CustKit using the clean-src directory (%clean-src%) for source
  The files need to be deleted from the %clean-src% directory
  This tool substitutes directory specified by -m with the directory
  specified by -s in all locations
  This means that options.txt and the component lists and mrp's must be
  referenced in the directory
  specified by -m

USAGE_EOF
  exit 1;
}