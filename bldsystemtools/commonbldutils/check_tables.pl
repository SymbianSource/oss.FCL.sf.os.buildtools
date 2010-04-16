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
#!Perl -w

use strict;
use Pod::Usage;
use Getopt::Long;
use FindBin;
use FileHandle;
use Net::SMTP;

#--------------------------- GLOBAL VARIABLES ---------------------------#

my $startDir = $FindBin::Bin;
my %componentList; 		#This has the components from the export table.
my @redundantComponents; #This is used by 2 methods. One populates it and 
						 #the other reads it to remove the redundant 
						 #components from the export table. 

# The location of the export tables
my $srcDir = $ENV{'SourceDir'};
my $platform = $ENV{'Platform'};
my $exportTableLocation =  "$srcDir\\os\\deviceplatformrelease\\symbianosbld\\productionbldcbrconfig\\"; 
  
 
my $help = 0;
my $man = 0;
my $autoclean = 0;
my $autoadd = 0;
my $email = 0;

my @report;
my ($notification_address) = 'SysBuildSupport@symbian.com';
my $message;

# This has the components from the gt and tv components.txt
# We need to manually put into the hash the following because these
# are added by the release tools and are not explicitly mentioned in
# the GTComponents.txt or TechviewComponents.txt
my %mrpHashForProduct=(
	"gt_techview_baseline" => 1,
	"gt_only_baseline" => 1,
	"gt_overwritten"=> 1,
	"unresolved" => 1
	);  

# Just specify the export tables for each product
my %exportTable = (
		"8.0a" => "AutoCBR_Tornado_test_export.csv",
		"8.1a" => "AutoCBR_8.1a_test_export.csv",
		"8.0b" => "AutoCBR_Zephyr_test_export.csv",
		"8.1b" => "AutoCBR_8.1b_test_export.csv",
		"9.0"  => "AutoCBR_9.0_test_export.csv",
		"9.1"  => "AutoCBR_9.1_test_export.csv",
		"9.2" => "AutoCBR_9.2_test_export.csv",
		"9.3" => "AutoCBR_9.3_test_export.csv",
		"Intulo" => "AutoCBR_Intulo_test_export.csv",
		"Future" => "AutoCBR_Future_test_export.csv",
		"9.4" => "AutoCBR_9.4_test_export.csv",
		"9.5" => "AutoCBR_9.5_test_export.csv",
		"9.6" => "AutoCBR_9.6_test_export.csv",
		"tb92" => "AutoCBR_tb92_test_export.csv",
		"tb92sf" => "AutoCBR_tb92sf_test_export.csv",
                "tb101sf" => "AutoCBR_tb101sf_test_export.csv"
		);

my %componentFiles = (
		"8.0a" => {"gtonly" => $exportTableLocation."8.0a\\gtcomponents.txt",
				   "tv" => $exportTableLocation."8.0a\\techviewcomponents.txt"},		
		"8.0b" => {"gtonly" => $exportTableLocation."8.0a\\gtcomponents.txt",
				   "tv" => $exportTableLocation."8.0a\\techviewcomponents.txt"},		
		"8.1a" => {"gtonly" => $exportTableLocation."8.1a\\gtcomponents.txt",
				   "tv" => $exportTableLocation."8.1a\\techviewcomponents.txt"},
		"8.1b" => {"gtonly" => $exportTableLocation."8.1b\\gtcomponents.txt",
				   "tv" => $exportTableLocation."8.1b\\techviewcomponents.txt"},
		"9.0"  => {"gtonly" => $exportTableLocation."9.0\\gtcomponents.txt",
				   "tv" => $exportTableLocation."9.0\\techviewcomponents.txt"},
		"9.1"  => {"gtonly" => $exportTableLocation."9.1\\gtcomponents.txt",
				   "tv" => $exportTableLocation."9.1\\techviewcomponents.txt"},
		"9.2"  => {"gtonly" => $exportTableLocation."9.2\\gtcomponents.txt",
				   "tv" => $exportTableLocation."9.2\\techviewcomponents.txt"},
		"9.3"  => {"gtonly" => $exportTableLocation."9.3\\gtcomponents.txt",
				   "tv" => $exportTableLocation."9.3\\techviewcomponents.txt"},		
		"Intulo"  => {"gtonly" => $exportTableLocation."Intulo\\gtcomponents.txt",
				   "tv" => $exportTableLocation."Intulo\\techviewcomponents.txt"},
		"Future"  => {"gtonly" => $exportTableLocation."Future\\gtcomponents.txt",
				   "tv" => $exportTableLocation."Future\\techviewcomponents.txt"},
		"9.4"  => {"gtonly" => $exportTableLocation."9.4\\gtcomponents.txt",
				   "tv" => $exportTableLocation."9.4\\techviewcomponents.txt"},
		"9.5"  => {"gtonly" => $exportTableLocation."9.5\\gtcomponents.txt",
				   "tv" => $exportTableLocation."9.5\\techviewcomponents.txt"},
		"9.6"  => {"gtonly" => $exportTableLocation."9.6\\gtcomponents.txt",
				   "tv" => $exportTableLocation."9.6\\techviewcomponents.txt"},
		"tb92"  => {"gtonly" => $exportTableLocation."tb92\\gtcomponents.txt",
				   "tv" => $exportTableLocation."tb92\\techviewcomponents.txt"},
		"tb92sf"  => {"gtonly" => $exportTableLocation."tb92sf\\gtcomponents.txt",
				   "tv" => $exportTableLocation."tb92sf\\techviewcomponents.txt"},
                "tb101sf"  => {"gtonly" => $exportTableLocation."tb101sf\\gtcomponents.txt",
				   "tv" => $exportTableLocation."tb101sf\\techviewcomponents.txt"}


	);

 
#------------------------ END OF GLOBAL VARIABLES -----------------------#


# Utility function to print the keys of a hash ref (passed in).
sub printHash
{
	my $hashRef = shift;
	
	foreach my $line(sort keys %{$hashRef})
	{
		push @report, $line."\n";
		print $line."\n";
	}
}



# Compare the components in the export table against
# the components in the gt and tv components.txt files.
sub compareTables
{
	my $product = shift;
	
	my $dirty = 0;
	foreach my $key (sort keys %componentList)
	{
		if(exists $mrpHashForProduct{$key})
		{
			delete $mrpHashForProduct{$key};
		}
		else
		{
			push @redundantComponents, $key;
		}
	}
	if (scalar (@redundantComponents) != 0)
	{
		$dirty =1;
		$message = "\n*** The following components can be removed from $exportTable{$product}:\n\n";
		print $message;
		foreach my $line(@redundantComponents)
		{
			print $line."\n";
		}
	}
	
	if (scalar keys %mrpHashForProduct != 0)
	{
		$dirty = 1;
		$message = "\n*** The following components are missing from $exportTable{$product}:\n\n";
		push @report, $message;
		print $message;
		printHash(\%mrpHashForProduct);
		
		if ($email == 1)
		{
			&SendEmail("WARNING: For Symbian_OS_v$product: $exportTable{$product} is not up to date\n ",@report);
		}
	}
	
	if ($dirty == 0)
	{
		print "$exportTable{$product} is up to date\n";
	}
}
# Get the components that are listed in the export table for the 
# product. 

sub getExportTableComponents
{

	my $product = shift;
	my $expTable = $exportTableLocation."$product\\".$exportTable{$product};
	
	open(EXP_TABLE,"<$expTable") or die("Cannot open export table:\n$expTable");
	
	foreach my $line (<EXP_TABLE>)
	{
		if ($line =~ /\A([^\#,].+?),/)  #Capture the component name. Ignore '#' or ',' if at beginning of line
		{
			$line = lc($1);
			$line =~ s/\s+//g;
			$line =~ s/\t+//g;
			
			if (not exists $componentList{$line})
			{
				$componentList{$line} = 1;
			}
			else 
			{
				print "Duplicate in export table: $line\n";
			}
		}
	}
	close EXP_TABLE;
}

# Get the components from the gt and techview components.txt
sub getComps
{
	my $tvfile = shift;
	my $product = shift;
	my $rv = shift;
	 
	my @mrpContents = split /\n/, $rv;
	
	foreach my $componentsLine (@mrpContents)
	{
		my $component = lc((split /[\s\t]/, $componentsLine)[0]);
		if (not exists $mrpHashForProduct{$component})
		{
			$mrpHashForProduct{$component} =1;
		}
		else
		{
			print "Duplicate in gt/tv component: $component \n";
		}
	}
	undef @mrpContents;
	
	#We make the assumption that the techviewcomponents.txt is 
	#in the same location as the gtcomponents.txt for a given 
	#product.
	open(TXT1, "<$tvfile") || die("Failed to find the components file for product $product"); 
	undef $/;
	$rv = <TXT1>;
	close(TXT1);

	@mrpContents = split /\n/, $rv;
	foreach my $componentsLine (@mrpContents)
	{
		my $component = lc((split /[\s\t]/, $componentsLine)[0]);
		if (not exists $mrpHashForProduct{$component})
		{
			$mrpHashForProduct{$component} =1;
		}
		else
		{
			print "Duplicate in gt/tv component: $component \n";
		}
	}
}

# Get the location where the gt and techview components.txt 
# are in. Get the contents of the gtcomponents.txt. The 
# contents of the techviewcomponents.txt are gotten in getComps
# function. 
sub getGtAndTvFiles
{
	my $product = shift; 
	
	my $rv;
	my $gtfilename = $componentFiles{$product}->{"gtonly"};
	my $tvfilename = $componentFiles{$product}->{"tv"};
	
	open(TXT2, "<$gtfilename") || die("Failed to find the components file for product $product");
	undef $/;
	$rv = <TXT2>;
	close(TXT2);
	
	getComps($tvfilename, $product, $rv);
	
# 	if ($rv !~ /no such file/)
# 	{
# 		my $tvfilename = "//EPOC/master/beech/product/tools/makecbr/files/$product/techviewcomponents.txt";
# 		getComps($tvfilename, $product, $rv);
# 		return;
# 	}	
# 	
# 	$gtfilename = "//EPOC/master/os/deviceplatformrelease/symbianosbld/productionbldcbrconfig/$product/gtcomponents.txt";
# 	$rv =  `p4 print -q $gtfilename 2>&1`;
# 	
# 	if ($rv !~ /no such file/)
# 	{
# 		my $tvfilename = "//EPOC/master/os/deviceplatformrelease/symbianosbld/productionbldcbrconfig/$product/techviewcomponents.txt";
# 		getComps($tvfilename, $product, $rv);
# 		return;
# 	}
#	die("Failed to find the Components file for product $product");
}

sub autoclean ($)
{
	my $product = shift; 
	my $expTable = $exportTableLocation."$product\\".$exportTable{$product};
	my %redundantComponentsHash;
		
	my $cleanexpTable = $exportTable{$product};
	$cleanexpTable =~ s/\.csv//;
	$cleanexpTable = $startDir."\\"."${cleanexpTable}.csv"; 
    
    if ($autoclean == 1)
    {
        print "********** Removing redundant components **********\n";
    }
	#open the export table
	open(INPUT, "<$expTable") or die ("Could not open $expTable for read\n");
	
	#create the clean table
	open(OUTPUT, ">$cleanexpTable") or die ("Could not create $cleanexpTable\n");
	
	foreach my $key (@redundantComponents)
	{
		#print $key."\n";
		if (not exists $redundantComponentsHash{$key})
		{
			 $redundantComponentsHash{$key} = 1;
		}
	}
	foreach my $line (<INPUT>)
	{
		if ($line =~ /\A([^\#,].+?),/)
		{
			my $component = lc($1);
			$component =~ s/\s+//g;
			$component =~ s/\t+//g;
			
			if ((not exists $redundantComponentsHash{$component}) || 
			    ($autoclean == 0))
			{
				#print "Adding $line in $cleanexpTable\n";
				print OUTPUT $line; 
			}
		}
		else 
		{
			print OUTPUT $line; 
		}
	}
	
	#Warning: This sets the position in INPUT to the beginning of the file!
	my $curPos = tell(INPUT);
	seek(INPUT, 0,0);
    my $firstLine = <INPUT>;
    my @cells = split /,/, $firstLine;
    my $numOfKeys = scalar(@cells) -1;
	#restore the position in INPUT
	seek (INPUT, $curPos,0);
	
	#Now add the missing components
	if (((keys %mrpHashForProduct)> 0) && ($autoadd == 1))
	{
	   print OUTPUT "\n\n\#Automatically added componments - NEED CHECKING!\n";
	   print "**********   Adding missing components   **********\n";
	
       foreach my $missingComponent (sort keys %mrpHashForProduct)
       {
    	   my $categoriesString;
    	   my $counter = 0;
    	   for ($counter = 0; $counter < $numOfKeys; $counter++)
    	   {
    	       $categoriesString = $categoriesString."D E F G,";
    	   }
    	   my $string = $missingComponent.",".$categoriesString;
    	   
    	   #remove the extra ',' from the string
    	   chop($string);
    	   print OUTPUT $string."\n";
       }
	}
	print "Closing files\n";
	close(INPUT);
	close (OUTPUT);
}

# Send Email
sub SendEmail
{
  my ($subject, @body) = @_;
  my (@message);
  
  #return 1; # Debug to stop email sending
  
  push @message,"From: $ENV{COMPUTERNAME}\n";
  push @message,"To: $notification_address\n";
  push @message,"Subject: $subject\n";
  push @message,"\n";
  push @message,@body;
  
  my $smtp = Net::SMTP->new('lonsmtp.intra', Hello => $ENV{COMPUTERNAME}, Debug   => 0);
  $smtp->mail();
  $smtp->to($notification_address);
  
  $smtp->data(@message) or die "ERROR: Sending message because $!";
  $smtp->quit;

}

sub main
{

	GetOptions('help|?' => \$help, 'man' =>\$man, 'remove' =>\$autoclean,
	           'add' => \$autoadd, 'e' => \$email) or pod2usage(-verbose => 2);
	pod2usage(-verbose => 1) if $help == 1;
	pod2usage(-verbose => 2) if $man == 1;
	
	if ($#ARGV < 0)
	{
		pod2usage(-verbose => 0);
	}
	
	print "******** $ARGV[0] ********\n";
	my $prod = shift @ARGV;

        my $isTestBuild = $ENV{'PublishLocation'};

        if ($isTestBuild =~ m/Test/i)

       {
   
         $email = 0 ;

         print "\nThis is a test build, no need to export\n";

         exit 1;

       }

      
	if (not exists $exportTable{$prod})
	{
		print "ERROR: Product is invalid\n";
		print "Aborting...\n";
		exit;
       
	}

	
	getExportTableComponents($prod);
	getGtAndTvFiles($prod);
	compareTables($prod);
	if (($autoclean == 1) || ($autoadd == 1) )
	{
		autoclean($prod);
	}
}

main();

=pod

=head1 NAME

check_tables.pl - Check the export tables for a product against the components that are in the product.

=head1 SYNOPSIS

check_tables.pl [options] <product>

 Options:
   -help			brief help message
   -man 			full documentation
   -remove			Automatically remove redundant components. See below for details.
   -add             Automatically add missing components. See below for details. 
   -e				Sends a notification email if a component is missing from export table.

=head1 OPTIONS

=over 8

=item B<-help>

Prints a brief help message and exits

=item B<-man>

Prints the manual page and exists

=item B<-remove>

Create a clean version of the export table by removing the redundant entries.
The clean table will be placed in the directory where the tool was run from 
and will have the same name as the export table in perforce. You will need to  
copy it to where you have your Perforce changes mapped in your client. 

=item B<-add>

The same as -remove but will automatically add the missing components. The 
componenets are added with categories D E F and G. 

=item B<-e>

Sends a notification email to SysBuildSupport@Symbian.com if any components
are missing from the export table.

=back

=head1 DESCRIPTION

B<This program> will take a product as an argument and will check the 
export table for that product for consistency. It will report any 
redundant entries in the export table and also any components that are
missing. It will also report any duplicate entries in the export table
itself. If no problems are found it will report that the tables are 
up to date. 

=head1 VERSION

$Id: //SSS/master/sf/os/buildtools/bldsystemtools/commonbldutils/check_tables.pl#2 $
$Change: 1761879 $  $DateTime: 2010/02/11 15:53:10 $

=cut
