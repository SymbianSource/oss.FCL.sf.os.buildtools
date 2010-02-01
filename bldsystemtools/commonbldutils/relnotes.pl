#!perl

# Release notes generator
# 07/10/1999 - 18/11/99 RH

use strict;

sub PrintLines { print OUTFILE join("\n",@_),"\n"; }	

if (@ARGV!=2 || ! -e $ARGV[0])
  {
#........1.........2.........3.........4.........5.........6.........7.....
  print <<USAGE_EOF;

--------------------------------------------------------------------------
Usage
-----
  perl relnotes.pl <listfile> <path>

Generates an HTML document containing release notes for each
component.

<listfile> is a file containing a list of components and locations
  in the format:
    COMPNAME DIRECTORY [CH#1 CH#2]
  eg
    AGNMODEL AGNMODEL
  Release documentation is collexted for all relevant changelists
  in the range specified by <CH#1> and <CH#2>.

  The first line of the file must contain the default values for
  <CH#1> and <CH#2> separated by spaces.

<path> is a path specifier (which may include wildcards)that,
  combined with the current view and the directory information in
  <listfile>, gives unambiguous access to component source on the
  appropriate branch(es) in the repository.

The file name of the component list is assumed to be the same as the
name of the target product.

It is also assumed that revision specifier <CH#1> is earlier than
revision specifier <CH#2>.

Note
----
Before using this utility, you must switch to a client that gives
visibility to those branches of the repository that contain the
submissions for which you want to extract release note documentation. 

Example for Crystal
-------------------
  Switch to a client that gives visibility to only //EPOC/Main/generic
  and //EPOC/Main/Crystal. Then type:

  perl relnotes.pl crystal.dat //EPOC/Main

  This generates release notes in a file named Crystal.html
--------------------------------------------------------------------------

USAGE_EOF
  exit 1;
  }

my $listfile = $ARGV[0];
my $srcpath = $ARGV[1];
my $productname = $listfile;

$productname =~ s#.*[\\\/]##;    # lose any leading path
$productname =~ s#\.[^\.]+$##;   # lose any trailing extension

$productname = ucfirst lc $productname;  # capitalise only first letter
$productname =~ s/_os_/_OS_/i;   # Just making sure that OS is in caps
$productname =~ s/_gt$/_GT/i;    # Just making sure that GT is in caps
$productname =~ s/_tv$/_TV/i;    # Just making sure that TV is in caps

$srcpath =~ s/\/\.\.\.$//;		# remove trailing /..., which slows things down

open INFILE, "< $listfile" or die "ERROR: Can't read $listfile\n";


my @listfile = <INFILE>;
my $firstline = shift @listfile;

$firstline =~ m/^\s*(\d+)\s+(\d+)/;
my $default_firstchange = $1;
my $default_lastchange = $2;

if (!($default_firstchange > 0) || !($default_lastchange > 0))
  {
  die "ERROR: First line of $listfile must contain non-zero changelist numbers only\n";
  }

my ( $s, $min, $hour, $mday, $mon, $year, $w, $y, $i)= localtime(time);
$year+= 1900;
$mon++;

open OUTFILE, "> $productname.html" or die "ERROR: Can't open $productname.html for output";
print OUTFILE <<HEADING_EOF;
<html>\n\n<head>\n<title>$productname Release Notes</title>\n</head>\n\n
<body bgcolor=\"#ffffff\" text=\"#000000\" link=\"#5F9F9F\" vlink=\"5F9F9F\">\n
<font face=verdana,arial,helvetica size=4>\n\n<hr>\n\n
<a name=\"list\"><h1>$productname Release Notes</h1></a>
<p>Created - $mday/$mon/$year\n
HEADING_EOF

my @newcomponents = ();
my @nochangecomponents = ();

foreach (@listfile)
  {
  my $firstchange = $default_firstchange;
  my $lastchange = $default_lastchange;
  
  my $newComponent = 0;
  
  s/\s*#.*$//;                 # remove comments
  if (/^\s*$/) { next; }       # ignore blank lines
  
  if (/^\s*\S+\s+\S+\s+(\d+)\s+(\d+)/) # get any non-default changelist numbers
    {
    $firstchange = $1;
    $lastchange = $2;
    
    $newComponent = 1 if ($firstchange == 0);
    }
    
  if (/^\s*(\S+)\s+(\S+)/)     # parse component data
    {
    my $compname = uc $1;
    my $topdir = $2;

    my $preform = 0;
    my $changeCount = 0;

    $firstchange++;         # inc changelist number so we don't include the very first submission - it would have been picked up in the last run of this script

    print "Processing $compname\n";
    my @complines = ();

    my $command = "p4 changes -l -s submitted $srcpath/$topdir/...\@$firstchange,$lastchange";
    my @compchange = `$command`;
    die "ERROR: Could not execute: $command\n" if $?;

    foreach my $line (@compchange)
      {
      if ($line !~ /\S/) { next; }      # ignore lines with no text 
      chomp $line;
      $line =~ s/\&/&amp;/g;
      $line =~ s/\</&lt;/g;
      $line =~ s/\>/&gt;/g;
      $line =~ s/\"/&quot;/g;

      if ($line =~ /^Change\s+\d+/i)
        {
        $changeCount+=1;
        $line =~ s/\s+by .*$//;
        if ($preform) 
          { 
          push @complines, "</pre>"; 
          $preform = 0; 
          }
        push @complines, "<p><b>$line</b>";
        push @complines, "<pre>";
        $preform = 1;
        next;
        }

      $line =~ s/^\s//;                 # drop first leading whitespace
      $line =~ s/^\t/  /;               # shorten any leading tab
      if ($changeCount == 0)
        {
        warn "WARNING: Description contains text preceding \"Change\". Printing line to output file:\n$line\n";
        }
      push @complines, $line;
      }
    if ($changeCount == 0)
    	{
    	if ($newComponent)
    		{
    		push @newcomponents, $compname;
    		}
    	else
    		{
    		push @nochangecomponents, $compname;
    		}
    	next;
    	}
	# Component with real change descriptions
	if ($preform)
		{
		push @complines, "</pre>";
		}
	&PrintLines("<h2>$compname</h2>",@complines);
    }
  }
close INFILE;

if (scalar @newcomponents)
	{
	&PrintLines("<h2>New Components</h2>", join(", ", sort @newcomponents));
	}
	
if (scalar @nochangecomponents)
	{
	&PrintLines("<h2>Unchanged Components</h2>", join(", ", sort @nochangecomponents));
	}
	
&PrintLines("</BODY></HTML>");
close OUTFILE;