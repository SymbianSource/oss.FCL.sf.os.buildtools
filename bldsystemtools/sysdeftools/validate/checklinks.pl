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
# Script to validate the unit links in a system definition or package definition XML file

use strict;

if (! scalar @ARGV) {&help()}


my $debug = 0;
my $skipfilter;	# skip anything with a named filter
my $xslt = "../../../buildtools/bldsystemtools/buildsystemtools/joinsysdef.xsl";
my $xalan = "../../../buildtools/devlib/devlibhelp/tools/doc_tree/lib/apache/xalan.jar";
my $sysdef = shift;
while($sysdef=~/^-/) { #arguments
	 if($sysdef eq '-nofilter') {$skipfilter = shift}
	 elsif($sysdef eq '-v') {$debug = 1}
	 else { &help("Invalid command line option $sysdef")} 
	 $sysdef = shift; 
}
my $dir = $sysdef;
$dir =~ s,[^\\/]+$,,;
my $root="../../../..";
 my $full;
 
if($sysdef=~/system_definition\.xml/) {	# if running on a sysdef, ensure it's joined before continuing
	($full = `java -jar $dir$xalan -in $sysdef -xsl $dir$xslt`) || die "bad XML syntax";
}else {	# assume any other file has no hrefs to include (valid by convention)
	$root='';
	open S, $sysdef;
	$full=join('',<S>);
	close S;
}
$full=~s/<!--.*?-->//sg; # remove all comments;
my $count=1;

my $filter = '';
foreach (split(/</,$full)) {	# loop through all elements
	my $found = 0;
	if(/^component/) {		# save the current filter so we know if we need to skip the named filter
		$filter='';
		if(/filter="([^"]+)"/) {$filter=$1}
	}
	elsif(s/^unit//) {
		my $f=",$filter,";		# commas are the separators - safe to have extra ones for testing
		if(/filter="([^"]+)"/) {$f.=",$1,"}
		if($skipfilter ne '' && $f=~/,$filter,/) {next}	# don't test anything with s60 filter
		if(/\smrp="(.*?)"/) {
			my $file = &fileLocation($1);
			if($debug) {print "MRP ",-s $file," $file\n"}		# debug code		
			if(!(-s $file)){
				print  STDERR "$count: Cannot find MRP file $file\n";	
				$found=1;
			}
		}
		if(/\sbldFile="(.*?)"/) {
			my $file = &fileLocation("$1/bld.inf");
			if($debug) {print "Bld ",-s $file ," $file\n"}		# debug code		
			if(!(-s $file) ){
				print  STDERR "$count: Cannot find bld.inf file $file\n";
				$found=1;
			}
		}
		if(/\sbase="(.*?)"/) {
			my $file = &fileLocation($1);
			if($debug) {print "Base $file\n"}		# debug code		
			if(!(-d $file) ){
				print  STDERR "$count: Cannot find base dir $file\n";
				$found=1;
			}
		}
	}	
	$count+=$found;	
}

exit $count;

sub fileLocation {
	my $file = "$dir$root$_[0]";
	$file=~tr/\//\\/;
	while($file=~s/\\[^\\.]+\\\.\.\\/\\/){}
	return $file;
}
sub help {
	print "$0: ",($_[0] eq '' ? "syntax"  : $_[0]); 
	print "\nSyntax: [-v] [-nofilter filter] system_definition.xml 
Validate the unit links in a system definition or package definition XML
file. This only prints errors in the files. If it exits silently, the links
are all valid.
	Call with -nos60 filter to skip checking presence of fitler=\"s60\" units
	Requires system definition files to be in the standard location
	in deviceplatformrelease,
	and the presence of joinsysdef.xsl and xalan.jar in their expected
	locations.
	Package definition files can be anywhere.";
exit 1;
}
