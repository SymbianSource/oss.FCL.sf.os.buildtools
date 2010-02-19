#
# Copyright (c) 2009 Nokia Corporation and/or its subsidiary(-ies). All rights reserved.
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
#
# Description: Post processes result  CSV file generated by the SFCheckSource.pl
# Version: 0.5 $optNoIgnore added
# Version: 0.52 filenameOf added and applied to normalized file names
#

use strict;
use Getopt::Long;
use File::Basename;
use IO::Handle;
use FileHandle;

# Constants
use constant HEADER_LINE => 'Issue,Category,Comment,Distr. ID,Url,Line,Package,PO,Stamp=$build';
use constant LINE_WITH_LXR => '$issue,$category,$comment,"$distrid",=HYPERLINK("http://s60lxr/source/$filename?v=$lxrbuild#$linenum"),$linenum,$package,$PO';
use constant LINE_WITH_SOURCEPATH => '$issue,$category,$comment,"$distrid",=HYPERLINK("$sourcepath$filename"),$linenum,$package,$PO';
use constant LINE_WITHOUT_LXR => '$issue,$category,$comment,"$distrid",$filename,$linenum,$package,$PO';
use constant NON_NOKIA_FILE => 'Non-Nokia-file';
use constant SOURCE_ISSUE => 'source-issue';
my $IGNORE = 'Ignore';
my $IGNORE_MAN ='Ignore-manually';
my $IGNORE_PATTERN ='Ignore-by-filename';  # Default comments

# Global variables
# Tool version
use constant VERSION => "0.52";
my $optNoIgnored = 0;
my $optBuild = "Undefined";
my $optPackageOwnerFile;
my $optManuallyCheckedFile;
my $optConfigFile;
my $optIgnorefilepattern;  # File patterns to ignore
my $optIgnorefilepatternComment = "";  # Comment value for file patterns to ignore
my %packageOwnerHash;
my %manuallyCheckedHash; # Hash of manually ignored cases
my @sfDistributionIdArray = ();  # Distr ID array

##################################################
# Postprocess subroutine
##################################################

sub doIt($) 
{
    my $sourcefile = shift;
    my $lxrbuild = shift;
    my $outputfile = shift;
    my $sourcepath = shift;

    open(IN,$sourcefile) || die "Unable to open file: $sourcefile\"\" for reading.";
    my $headerline = HEADER_LINE();
    $headerline =~ s/\$build/$optBuild/;
    if ($outputfile)
    {
        print OUTPUT "$headerline\n";
    }
    else
    {
        print "$headerline\n";
    }

    # Collect all files marked as ignored here
    my %ignoreFilesHash;

LINE:
    while(<IN>)
    {
        chomp;
        my $line = $_;
        my @items = parse_csv($line);
        my $issue    = $items[0]; 
        my $category = $items[1];
        my $comment  = $items[2];
        my $distrid     = $items[3];
        my $filename = $items[4];
        $filename =~ s/\\/\//g;  # Standardize name 
        $filename =~ s/[a-zA-Z]\:(\/)?//i;  # Remove possible "drive:/" strings
        my $linenum  = $items[5];
        # Sometimes the tool produces bad data, ignore them
        next LINE if (!($issue =~ m/issue/));  # Not issue
        next LINE if ($optNoIgnored && ($comment =~ m/$IGNORE/i));  # Ignore 
        next LINE if !$category;
        next LINE if  ($optConfigFile && !isSFDistribution($distrid));
        my $ignoreThis = $manuallyCheckedHash{$category . filenameOf($filename)};
        if (defined $ignoreThis) 
        {
            next if $optNoIgnored;
            $comment = $IGNORE_MAN;
        }
        elsif ($optIgnorefilepattern && filenameOf($filename) =~ m/$optIgnorefilepattern/i)
        {
            # Ignore by given pattern in file name
            $comment = $optIgnorefilepatternComment;
        }

        # Extract file parts
        # my ($fname, $filepath, $filext)=fileparse($filename, qr/\.[^.]*/);

        my $linePattern = LINE_WITH_LXR();
        if ($lxrbuild eq "")
        {
            $linePattern = LINE_WITHOUT_LXR();
        }
        if ($sourcepath ne "")
        {
            $linePattern = LINE_WITH_SOURCEPATH();
        }

        # Create result line using the pattern
        $linePattern =~ s/\$issue/$issue/;
        $linePattern =~ s/\$category/$category/;
        $linePattern =~ s/\$comment/$comment/;
        $linePattern =~ s/\$distrid/$distrid/;
        $linePattern =~ s/\$sourcepath/$sourcepath/;
        $linePattern =~ s/\$filename/$filename/;
        my $p = packageOf($filename);
        my $po = packageOwnerOf($filename);
        $linePattern =~ s/\$package/$p/;
        $linePattern =~ s/\$PO/$po/;
        if ($lxrbuild ne "")
        {
            $linenum = sprintf("%03d", $linenum); # LXR requires 3 digits
            $linePattern =~ s/\$lxrbuild/$lxrbuild/;
        }
        $linePattern =~ s/\$linenum/$linenum/;

        if ($outputfile)
        {
            print OUTPUT "$linePattern\n";
        }
        else
        {
            print ("$linePattern\n");
        }
    }

    close (IN);

}


##################################################
# Show usage help
##################################################
sub usage
{
    print "SFPostProcessResults.pl by matti.parnanen\@nokia.com, version " . VERSION() .  "\n";
    print "Generates hyperlinks to filenames using LXR or plain filename links\n";
    print "Usage:\n";
    print "   perl SFPostProcessResults.pl -input csv-file-from-sfchecksource -lxrbuild LXR-buildname [-outputfile different-csv-file-name]\n";
    print "   perl SFPostProcessResults.pl -input csv-file-from-sfchecksource -sourcepath source-path [-outputfile different-csv-file-name]\n";
}


##################################################
# Parse command line and extract options
##################################################
sub parseCmdLine
{

    
    my $opt1;
    my $opt2;
    my $opt3;
    my $opt4;

    if( ! GetOptions(
			 'inputfile=s' => \$opt1,
			 'lxrbuild:s' => \$opt2,
			 'output:s' => \$opt3,
			 'pofile:s' => \$optPackageOwnerFile,
			 'configfile:s' => \$optConfigFile,
			 'oldoutput:s' => \$optManuallyCheckedFile,
			 'sourcepath:s' => \$opt4,
		     'help'     => \&usage,
             'noignored' => \$optNoIgnored,  # Do not included items marked as Ignore
			 'build:s' => \$optBuild,
             'ignorefile:s' => \$optIgnorefilepattern,   #Ignore file pattern
             'ignorecomment:s' => \$optIgnorefilepatternComment,   #Comment used for these
		     '<>'       => \&usage))
		{
		&usage;
		exit(1);
		}

    if (lc($opt1) eq lc($opt3))
    { 
        &usage;
        exit(1);
    }

   return ($opt1, $opt2, $opt3,$opt4);

}

#
# Taken from  Mastering Regular Expressions
#
sub parse_csv {
  my $text = shift; ## record containing comma-separated values
  my @new = ();
  push(@new, $+) while $text =~ m{
    "([^\"\\]*(?:\\.[^\"\\]*)*)",?
      | ([^,]+),?
      | ,
    }gx;
    push(@new, undef) if substr($text, -1,1) eq ',';
    return @new; ## list of values that were comma-spearated
}


##################################################
# Read the content of old output
##################################################
sub readPackageOwnerFile
{
    my($filename) = $optPackageOwnerFile;
    if (!$filename)
    {
        return;
    }

    my $fh = new FileHandle "<$filename";
    if (!defined($fh))
    {
        return;
    }

    my  @lines = <$fh>;
    my $line;
    foreach $line (@lines)
    {
       # Example line
       #ui,mw,classicui,ari.t.valtaoja@nokia.com,Nokia/S60/A&F/UFO,Beijing,1279685+166558

       $line = lc($line);
       my (@parts) = split(/\,/,$line);  # Split line with "," separator
       # print ("DEBUG:readPackageOwnerFile::$parts[1]/$parts[2]=$parts[3]\n");
       $packageOwnerHash{$parts[1] . "/" . $parts[2]} = $parts[3] ;
    }

    close ($fh);
}

##################################################
# Get normalized filename starting from "sf/layer/package"
##################################################
sub filenameOf
{
    my($filename) = shift;
    $filename =~ s/\\/\//g;  # Standardize name 
    $filename = lc($filename);

    # There might be some paths before /sf/layer/package if tool run manually in some local directory
    # structure
    my ($tmp1,$tmp2) = split(/sf\//,$filename);
    # print ("DEBUG:sf/" . $tmp2 . "\n");
    return "sf/" . $tmp2;
}


##################################################
# Get package owner
##################################################
sub packageOwnerOf
{
    my($filename) = shift;
    $filename = filenameOf($filename);

    my (@parts) = split(/\//,$filename);  # "sf/layer/package"
    my $owner = $packageOwnerHash{$parts[1] . "/" . $parts[2]};
    if (defined $owner)
    {
        return $owner;
    }
    return "";
}

##################################################
# Get package name
##################################################
sub packageOf
{
    my($filename) = shift;
    $filename = filenameOf($filename);
    my (@parts) = split(/\//,$filename);  # "sf/layer/package"

    return $parts[2];
}


##################################################
# Read the content of cleaned cases manually ignored
# (these are tool reported case cleared manually=
##################################################
sub readManuallyCheckedFile
{
    my($filename) = $optManuallyCheckedFile;
    if (!$filename)
    {
        return;
    }

    my $fh = new FileHandle "<$filename";
    if (!defined($fh))
    {
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
            my $category = $parts[1];
            $fullfilename =~ s/\\/\//g;  # Standardize name 
            # print("\nDEBUG:Marked:$category,$fullfilename as ignored");
            $manuallyCheckedHash{$category . $fullfilename} = "1" ;  # Just some value
       }
    }

    close ($fh);
}

##################################################
# Test  ID is under SF distribution
##################################################
sub isSFDistribution
{
    my $id = shift;
    use constant SFL_DISTRIBUTION_VALUE => "3";  
    use constant EPL_DISTRIBUTION_VALUE => "7";

    if ($id == "")
    {
        return 0;
    }

    if (($id == SFL_DISTRIBUTION_VALUE) || ($id == EPL_DISTRIBUTION_VALUE))
    {
        # Implicit case
        return 1;
    }

    my $otherOkId = grep { $_ eq $id } @sfDistributionIdArray;  # Use exact match
    return $otherOkId;
}


##################################################
# Read configuation file of the
# SFUpdateLicenceHeader.pl to get OK distribution IDs
##################################################
sub readConfigFile
{
    my ($filename) = $optConfigFile;
    if (!$filename)
    {
        return;
    }

    open(IN,$filename) || die "Unable to open file: \"$filename\" for reading.";
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
        }
        elsif ($line =~ /^sf-distribution-id/i) 
        {
            my ($tmp, @parts) = split(/[\s\t]+/,$line); # space as separator
            my $cnt = @parts;
            push(@sfDistributionIdArray, @parts);
            my $cnt = @sfDistributionIdArray;
        }
    }

    # Pre-compile here the source line pattern
    close (IN);
}


##################################################
#            MAIN
##################################################

#
# Command line variables
#
my $inputfile = "";
my $outputfile = "";
my $lxrbuild  = "";
my $sourcepath  = "";

# Initialize
($inputfile,$lxrbuild,$outputfile,$sourcepath) = &parseCmdLine;

&readPackageOwnerFile();
&readManuallyCheckedFile();
&readConfigFile();

if ($outputfile)
{
    open (OUTPUT, ">$outputfile") || die "Couldn't open $outputfile\n";
    OUTPUT->autoflush(1);  # Force flush
}

&doIt($inputfile,$lxrbuild,$outputfile,$sourcepath);

close OUTPUT;

