# Copyright (c) 1999-2009 Nokia Corporation and/or its subsidiary(-ies).
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

use Getopt::Long;
GetOptions("v", "x=s@");

if (@ARGV<2)
	{
#........1.........2.........3.........4.........5.........6.........7.....
	print <<USAGE_EOF;

Usage:
  delta_zip zipfile dir1 [dir2 ...] [-x excludezip ] [-x pattern]

Create <zipfile> which contains the tree rooted at <dir1>,
excluding all files listed in <excludezip>, and optionally
all files which match the specified Perl patterns.

This is done with "zip zipfile -@", with the appropriately 
filtered list of files supplied as standard input.
 
USAGE_EOF
	exit 1;
	}

my $zipfile = shift;
die "$zipfile already exists\n" if (-e $zipfile);

#--------
# Find the basic list of files
#

my %filelist;
my $filecount = 0;
my $arg = shift;

while ($arg ne "")
	{
	if (-d $arg)
		{
		add_dir($arg);
		}
	elsif (-e $arg)
		{
		add_file($arg);
		}
	else
		{
		print "Cannot find $arg - ignored\n";
		}
	print "$filecount files after processing $arg\n";

	$arg = shift;
	next;
	}

#--------
# Remove excluded files
#

foreach $arg (@opt_x)
	{
	if (-e $arg)
		{
		exclude_zip($arg);
		}
	else
		{
		exclude_pattern($arg);
		}
	print "$filecount files after excluding $arg\n";
	$arg = shift;
	}

print "Invoking \"zip $zipfile -@\"\n";

open ZIPOUT, "| zip $zipfile -@";
foreach $arg ( sort keys %filelist)
	{
	if ($filelist{$arg} ne "")
		{
		print ZIPOUT "$filelist{$arg}\n";
		}
	}

close ZIPOUT;
die "Problems creating zip file\n" if ($? != 0);

exit 0;


#------------------------------------------------------------

sub add_file
	{
	my ($file) = @_;
	my $key = lc $file;

	$key =~ s-/-\\-g;	# convert / to \ for path separators
	$key =~ s/^\\//;	# remove leading \ since it won't appear in zip files
	if ($filelist{$key} ne "")
		{
		die "Duplicate file $file\n";
		}
	$filelist{$key} = $file;
	$filecount += 1;
	}

sub exclude_file
	{
	my ($file) = @_;
	my $key = lc $file;

	$key =~ s-/-\\-g;	# convert / to \ for path separators
	$key =~ s/^\\//;	# remove leading \ since it won't appear in zip files
	if ($filelist{$key} ne "")
		{
		delete $filelist{$key};
		$filecount -= 1;
		}
	}

sub exclude_pattern
	{
	my ($pattern) = @_;
	my $key;

	foreach $key (keys %filelist)
		{
		if ($key =~ /$pattern/i && $filelist{$key} ne "")
			{
			delete $filelist{$key};
			$filecount -= 1;
			}
		}
	}

sub add_dir
	{
	my ($dir) = @_;
	opendir LISTDIR, $dir or print "Cannot read directory $dir\n" and return;
	my @list = grep !/^\.\.?$/, readdir LISTDIR;
	closedir LISTDIR;

	if ($opt_v)
		{
		print "Scanning $dir...\n";
		}
	my $name;
	foreach $name (@list)
		{
		my $filename = "$dir\\$name";
		if (-d $filename)
			{
			add_dir($filename);	# recurse
			}
		else
			{
			add_file($filename);
			}
		}
	}

sub exclude_zip
	{
	my ($excludezip) = @_;

	die "$excludezip does not exist\n" if (!-e $excludezip);
	print "Reading exclusions from $excludezip...\n";

	my $line;
	open ZIPEX, "unzip -l $excludezip |";
	while ($line=<ZIPEX>)
		{
		#    4492  10-12-99  17:31   epoc32/BLDMAKE/AGENDA/ARM4.MAKE
		if ($line =~ /..-..-..\s+..:..\s+(.*)$/)
			{
			exclude_file($1);
			}
		}
	close ZIPEX;
	die "Problem reading $excludezip\n" if ($? != 0);
	}




