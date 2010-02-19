#!perl

# Copyright (c) 2005-2009 Nokia Corporation and/or its subsidiary(-ies).
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

use File::Path;
use Data::Dumper;

$Data::Dumper::Deepcopy = 1;

#-----------------GLOBAL VARIABLES------------------------#

my $command;
my $source;
my $target;
my $component;
my $flag = 0;
my $plats = 0;

my @temp;
my %output;
my %project_platforms;
my @components;

my $platform;

#--------------------------------------------------------#

#Check that correct number of arguments were specified by the user
#If not then print out Usage instructions to the command window	
Usage() if (@ARGV!=1);

$platform = $ARGV[0];

my %logfiles = (
		"GT2.log" => "M:\\logs\\$platform\\GT2.log",
		"TV2.log" => "M:\\logs\\$platform\\TV2.log",
		"JAVA2.log" => "M:\\logs\\$platform\\java2.log",
	       );

foreach my $file (keys %logfiles)
{
	$plats = 0;
	
	open(LOGFILE, $logfiles{$file}) || warn "Warning: can't open $logfiles{$file} : $!";

	while(my $line = <LOGFILE>)
	{
		my $exists = 0;
		if($line =~ m%^=== Stage=.*\s==\s(.*)\n%i)
		{
			$component = "$1 ";
		}
	   
		if($line =~ m%-- abld -what\s(.*)%i)
		{
			foreach my $entry (@components)
			{
				$exists = 1 if($entry eq $component);
			}
		
			push @components, $component if ($exists == 0);
		
			$command = "$1 -what";
			$flag = 1;
			@temp =();
		}
	
		if(($line =~ m%Chdir (M:)?(.*)%i)&&($flag == 1))
		{
			$source = "$2 ";
			$target = $component.$source.$command;
		}
	
		if(($line =~ m%^(\\EPOC32\\.*)\n%i)&&($flag == 1))
		{
			push @temp, $1;
		}
		# Match ..\..\..\..\..\..\..\..\..\..\epoc32
		if(($line =~ m%^((\.\.\\){1,}EPOC32\\.*)\n%i)&&($flag == 1))
		{
			push @temp, $1;
		}
	
		if(($line =~ m%^\+\+\+ HiRes End%i)&&($flag == 1))
		{
			$flag = 0;
			my @files = @temp;
			$output{$target} = \@files;
		}
	
		if($line =~ m%^project platforms%i)
		{
			$plats = 1;
			next
		}
	
		if($plats == 1)
		{
			$plats = 0;
			$line =~ s/^\s+//;
			$line =~ s/\n$//;
			my @platforms = split(/ /, $line);
			$project_platforms{$component} = \@platforms;
		}
	}
}

foreach my $comp (@components)
{
	$comp =~ s/\s$//;
	my %abldcache;
	my %self;
	my $path;
	
	foreach my $hashelement (keys %output)
	{
		$hashelement =~ /(.*)\s(\\src.*?)\s/;
		my $temp_element = $1;
		if ($temp_element eq $comp)
		{
			$path = $2;
			$path =~ s/\\src/src/;
			my $newkey = $hashelement;
			$newkey =~ s/.*\s\\src/\\src/;
			$newkey = "'".$newkey."'";
			$abldcache{$newkey} = $output{$hashelement};
			$abldcache{"'plats'"} = $project_platforms{$comp." "};
		}
	}
	
	$self{abldcache} = \%abldcache;
	
	mkpath ("M:\\abldcache\\$path", 0, 0744);
		
	open OUTFILE, "> M:\\abldcache\\$path\\cache"
		or die "ERROR: Can't open M:\\abldcache\\$path\\cache for output\n$!";
			
	print OUTFILE Data::Dumper->Dump(per_key('$self->{abldcache}->', $self{abldcache})), "\n";
		
	close OUTFILE;
}

sub per_key
{
	my($name, $href) = @_;
	my @hkeys = keys %$href;
	([@$href{@hkeys}], [map {"$name\{$_}"} @hkeys])
}
	

sub Usage
	{
	 print <<USAGE_EOF;
	 
USAGE
----------
perl abldcache <platform>

USAGE_EOF

	exit 1;
	}