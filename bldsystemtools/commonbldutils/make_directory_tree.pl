#! perl
# Copyright (c) 2006-2009 Nokia Corporation and/or its subsidiary(-ies).
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

use strict;
use Getopt::Long;

sub Usage(;$)
	{
	my ($errmsg) = @_;
	print "\nERROR: $errmsg\n" if (defined $errmsg);
	print <<'EOF';

perl make_directory_tree.pl [options] specfile
perl make_directory_tree.pl [options] -check specfile 
 
Create a tree of empty directories, specified in specfile.
The specification is one or more lines of the form

   path/name/separated/by/forward/slash   # optional comment

Paths should not contain "." or "..". Paths ending in "*"
imply that other subdirectories are permitted by the -check
option, but ignored.

If no specfile is given on the command line, the tool will
read from standard input.

The -check option compares an existing directory tree
with the one which would have been created, and reports 
differences.

Options:

-r rootdir           root of the directory tree 
-o newspecfile       specfile describing the new tree, 
                     mostly for use with the -check option
-fix                 attempt to correct directory names which 
                     have the wrong case - used with -check

If no rootdir is specified, the tree will be assumed to start
in the current directory. 

EOF
	exit 1;
	}

my $rootdir;
my $check;
my $fix;
my $newspecfile;
my $help;
my $verbose;

Usage() if !GetOptions(
	'r=s' => \$rootdir,
	'o=s' => \$newspecfile,
	'check' => \$check,
	'fix' => \$fix,
	'h' => \$help,
	'v' => \$verbose,
	);

Usage() if ($help);

my $line;
my %dirnames;		# actual capitalisation
my %lc_dirnames;	# forced to lowercase
my %wilddirs;

while ($line=<>)
	{
	chomp $line;
	$line =~ s/\s*#.*$//;	# hash is comment to end of line
	$line =~ s/^\s*//;		# remove leading whitespace
	$line =~ s/\s*$//;		# remove trailing whitespace
	
	# also accepts the output of "p4 have"
	if ($line =~ /^\/\/epoc\/master\/(.*)\/[^\/]+$/i)
		{
		# output of p4 have
		$line = $1;
		}
		
	next if ($line eq "");	# ignore blanks

	# tolerate some minor errors in the input format
	$line =~ s/\\/\//g;	# convert any \ to /
	$line =~ s/^\///;	# remove leading /, if present
	
	my $wilddir = 0;
	if ($line =~ /\/\*$/)
		{
		$line = substr $line, 0, -2;	# cut off last two characters
		$wilddir = 1;
		}
	
	my @dirs = split /\//, $line;
	my $path = "";
	my $lc_path = lc $path;
	foreach my $subdir (@dirs)
		{
		my $parent = $path;
		$path .= "/$subdir";
		$lc_path .= lc "/$subdir";
		
		next if (defined $dirnames{$path});	# already seen this one
		if (defined $lc_dirnames{$lc_path})
			{
			my $fixed_path = $lc_dirnames{$lc_path};
			print "WARNING: input file has ambiguous case for $path (should be $fixed_path)\n";
			$path = $fixed_path;	# recover by using the earlier entry?
			next;
			}
		# found a new directory
		@{$dirnames{$path}} = ();	# empty list of subdirs
		$lc_dirnames{$lc_path} = $path;
		push @{$dirnames{$parent}}, $subdir;
		next;
		}
	$wilddirs{$path} = 1 if ($wilddir);		
	}

print "* Processed input file\n";
Usage("No directories specified") if (scalar keys %dirnames == 0);

# %dirnames now contains all of the approved names as keys
# The associated value is the list of subdirectories (if any)

# Subroutine to create a completely new directory tree
sub make_new_tree($)
	{
	my ($root) = @_;
	
	my $errors = 0;
	foreach my $path (sort keys %dirnames)
		{
		next if ($path eq "");	# root directory already exists
		print "** mkdir $root$path\n" if ($verbose);
		if (!mkdir $root.$path)
			{
			print "ERROR: failed to make $root$path: $!\n";
			$errors++;
			}
		}
	
	return ($errors == 0);
	}

# recursive routine to remove a subtree from %dirnames
sub remove_subtree($);
sub remove_subtree($)
	{
	my ($subdir) = @_;
	my @absent = @{$dirnames{$subdir}};
	delete $dirnames{$subdir};	# delete the parent
	if (defined $wilddirs{$subdir})
		{
		# Remove from %wilddirs as well - directory should exist
		delete $wilddirs{$subdir};
		}
	
	foreach my $dir (@absent)
		{
		remove_subtree("$subdir/$dir");	# recursively delete the children
		}
	}

# recursive routine to check a subtree against %dirnames
sub check_subtree($$$);
sub check_subtree($$$)
	{
	my ($root,$subdir,$expected) = @_;
	
	my $currentdir = $root.$subdir;
	opendir DIR, $currentdir;
	my @contents = grep !/^\.\.?$/, readdir DIR;
	closedir DIR;

	printf ("** checking $currentdir - %d entries\n", scalar @contents) if ($verbose);

	my @confirmed = ();
	foreach my $expected (@{$dirnames{$subdir}})
		{
		push @confirmed,$expected;
		if (!-d "$currentdir/$expected")
			{
			# Note: this does not check the correctness of the case,
			# that comes in the scan through @contents
			print "REMARK: cannot find expected directory $currentdir/$expected\n";
			if ($fix && defined $newspecfile)
				{
				print "** removing $currentdir/$expected/... from specification\n";
				remove_subtree("$subdir/$expected");
				pop @confirmed;	
				}
			}
		}
	@{$dirnames{$subdir}} = @confirmed;	# update the description of the tree

	foreach my $name (@contents)
		{
		if (!-d "$currentdir/$name")
			{
			next; # ignore files
			}
		
		my $newpath = "$subdir/$name";
		if ($expected)
			{
			if (defined $dirnames{$newpath})
				{
				# we expected this one, and it has the correct case
				check_subtree($root,$newpath,1);
				next;
				}
			
			my $lc_newpath = lc $newpath;
			if (defined $lc_dirnames{$lc_newpath})
				{
				# expected directory, but wrong name
				$newpath = $lc_dirnames{$lc_newpath};	# get the correct name
				if ($fix && rename("$currentdir/$name","$root$newpath"))
					{
					print "* corrected $currentdir/$name to $root$newpath\n";
					}
				else
					{
				    print "ERROR: $currentdir/$name should be $root$newpath\n";
				    }
				check_subtree($root,$newpath,1);
				next;
				}
			}

		# unexpected subdirectory
		
		if ($wilddirs{$subdir})
			{
			# unexpected directory in a directory which allows "extras"
			next;
			}
		
		print "REMARK: New subtree found: $newpath\n" if ($expected);
		
		# add unexpected subtrees to the $dirnames structure
		
		@{$dirnames{$newpath}} = ();	# empty list of subdirs
		push @{$dirnames{$subdir}}, $name;
		# no %lc_dirnames entry required
		
		check_subtree($root,$newpath,0);
		}
	
	}

# subroutine to generate a new input file
sub print_leaf_dirs($)
	{
	my ($filename) = @_;
	
	open FILE, ">$filename" or die "Cannot write to $filename: $!\n";
	
	foreach my $path (sort keys %dirnames)
		{
		my @subdirs = @{$dirnames{$path}};

		if (defined $wilddirs{$path})
			{
			print FILE "$path/*\n";	# always print wildcard directories
			next;
			}
					
		next if (scalar @subdirs != 0);	# ignore interior directories
		print FILE "$path\n";
		}

	close FILE;
	}


$rootdir =~ s/\\/\//g if (defined $rootdir);	# convert rootdir to forward slashes

if ($check)
	{
	$rootdir = "." if (!defined $rootdir);
	print "* checking $rootdir ...\n";
	check_subtree($rootdir,"",1);

	}
else
	{
	if (defined $rootdir && !-d $rootdir)
		{
		Usage("Cannot create $rootdir: $!") if (!mkdir $rootdir);
		print "* created root directory $rootdir\n";
		}
	else
		{
		$rootdir = ".";
		}
	
	print "* creating directory tree in $rootdir\n";
	make_new_tree($rootdir);
	}

if (defined $newspecfile)
	{
	print_leaf_dirs($newspecfile);
	print "* created $newspecfile\n";
	}
