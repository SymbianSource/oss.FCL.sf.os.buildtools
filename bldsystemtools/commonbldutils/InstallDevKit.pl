#!perl

# InstallDevKit.pl - Source Code Integration Script

# Copyright (c) 1997-2009 Nokia Corporation and/or its subsidiary(-ies).
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
# Versions:
# 1.0  Initial 
# 
#


use strict;
use Win32::Registry;
use Getopt::Long;
use File::Path;
use File::Glob;

my $Platform = "";


# ------------------------------------- Global variables -----------------------------------

# main array.  Each element contains:	display text for this option
#					list of DevKit packages to be installed by this option


my @AllTheOptions=(
	["GT source",
				["com.symbian.src.GT-general",
				"com.symbian.src.GT-restricted-part1",
				"com.symbian.src.GT-restricted-part2",
				"com.symbian.src.GT-restricted-part3",
				"com.symbian.src.GT-restricted-part4",
				"com.symbian.src.GT-restricted-part5",
				"com.symbian.src.GT-restricted-part6"],
				
				["com.symbian.src.confidential",
				"com.symbian.src.GT-confidential-networking"] ],	

				
	["UI source",
				["com.symbian.src.TechView-restricted",
				"com.symbian.src.TechView-general"],
				 
				["com.symbian.src.TechView-confidential-networking"] ],	


	["GT WINS binaries",
				["com.symbian.api.GT-restricted",
				"com.symbian.api.GT-shared",
				"com.symbian.api.GT-wins",
				"com.symbian.api.StrongCrypto",

				"com.symbian.bin.GT-restricted",
				"com.symbian.bin.GT-restricted-data",

				"com.symbian.bin.GT-shared",
				"com.symbian.bin.GT-shared-data",
				
				"com.symbian.bin.GT-wins-shared",
				"com.symbian.bin.GT-wins-udeb",
				"com.symbian.bin.GT-wins-urel",

				"com.symbian.bin.StrongCrypto-wins-udeb",
				"com.symbian.bin.StrongCrypto-wins-urel",

				"com.symbian.debug.GT-wins",
				
				"com.symbian.tools.cpp",
				"com.symbian.tools.cpp-custom",
				"com.symbian.tools.java",
				"com.symbian.tools.libraries",
				"com.symbian.tools.shared",
				"com.symbian.tools.shared-custom",
				"com.symbian.tools.wins"],
				 
				["com.symbian.bin.GT-confidential",
				"com.symbian.bin.TechView-confidential"] ], 


	["GT WINSCW binaries",
				["com.symbian.api.GT-restricted",
				"com.symbian.api.GT-winscw",
				"com.symbian.api.GT-shared",
				"com.symbian.api.StrongCrypto",
				
				"com.symbian.bin.GT-winscw-shared",
				"com.symbian.bin.GT-winscw-udeb",
				"com.symbian.bin.GT-winscw-urel",

				"com.symbian.bin.StrongCrypto-winscw-udeb",
				"com.symbian.bin.StrongCrypto-winscw-urel",
				
				"com.symbian.bin.GT-restricted",
				"com.symbian.bin.GT-restricted-data",
				
				"com.symbian.bin.GT-shared",
				"com.symbian.bin.GT-shared-data",
				
				"com.symbian.debug.GT-winscw",
				
				"com.symbian.tools.cpp",
				"com.symbian.tools.cpp-custom",
				"com.symbian.tools.java",
				"com.symbian.tools.libraries",
				"com.symbian.tools.shared",
				"com.symbian.tools.shared-custom",
				"com.symbian.tools.winscw"],
				 
				["com.symbian.bin.GT-confidential",
				"com.symbian.bin.TechView-confidential"] ], 

	["GT ARM binaries",
				["com.symbian.api.GT-restricted",
				"com.symbian.api.GT-arm", 
				"com.symbian.api.GT-shared",
				"com.symbian.api.StrongCrypto",
				
				"com.symbian.bin.GT-arm",
				"com.symbian.bin.GT-arm-data",
				
				"com.symbian.bin.StrongCrypto-arm",

				"com.symbian.bin.GT-restricted",
				"com.symbian.bin.GT-restricted-data",
				
				"com.symbian.bin.GT-shared",
				"com.symbian.bin.GT-shared-data",

				"com.symbian.bin.GT-romimages",
				
				"com.symbian.tools.boardsupport",
				"com.symbian.tools.cpp",
				"com.symbian.tools.cpp-custom",
				"com.symbian.tools.java",
				"com.symbian.tools.libraries",
				"com.symbian.tools.shared",
				"com.symbian.tools.shared-custom",
				"com.symbian.tools.arm"],
				 
				["com.symbian.bin.GT-confidential",
				"com.symbian.bin.TechView-confidential"] ], 


	["UI WINS binaries (needs GT to run)",
				["com.symbian.api.TechView-restricted",
				"com.symbian.api.TechView-shared",
				"com.symbian.api.TechView-wins",

				"com.symbian.debug.TechView-wins",

				"com.symbian.bin.TechView-wins-shared",
				"com.symbian.bin.TechView-wins-udeb",
				"com.symbian.bin.TechView-wins-urel",

				"com.symbian.bin.Techview-restricted",
				"com.symbian.bin.Techview-restricted-data",
				"com.symbian.bin.Techview-shared",
				"com.symbian.bin.Techview-shared-data",
				
				"com.symbian.tools.cpp",
				"com.symbian.tools.cpp-custom",
				"com.symbian.tools.java",
				"com.symbian.tools.libraries",
				"com.symbian.tools.shared",
				"com.symbian.tools.shared-custom",
				"com.symbian.tools.wins"],
				 
				[] ],


	["UI WINSCW binaries (needs GT to run)",
				["com.symbian.api.TechView-restricted",
				"com.symbian.api.TechView-shared",
				
				"com.symbian.debug.TechView-winscw",
				"com.symbian.api.TechView-winscw",

				"com.symbian.bin.TechView-winscw-shared",
				"com.symbian.bin.TechView-winscw-udeb",
				"com.symbian.bin.TechView-winscw-urel",

				"com.symbian.bin.Techview-restricted",
				"com.symbian.bin.Techview-restricted-data",
				"com.symbian.bin.Techview-shared",
				"com.symbian.bin.Techview-shared-data",
				
				"com.symbian.tools.cpp",
				"com.symbian.tools.cpp-custom",
				"com.symbian.tools.java",
				"com.symbian.tools.libraries",
				"com.symbian.tools.shared",
				"com.symbian.tools.shared-custom",
				"com.symbian.tools.winscw"],
				 
				[] ],


	["UI ARM binaries (needs GT to run)",
				["com.symbian.api.TechView-arm",
				"com.symbian.api.TechView-restricted",
				"com.symbian.api.TechView-shared",

				"com.symbian.bin.Techview-arm",
				"com.symbian.bin.Techview-arm-data",

				"com.symbian.bin.Techview-restricted",
				"com.symbian.bin.Techview-restricted-data",
				"com.symbian.bin.Techview-shared",
				"com.symbian.bin.Techview-shared-data",

				"com.symbian.bin.Techview-romimages",

				"com.symbian.tools.arm",
				"com.symbian.tools.boardsupport",
				"com.symbian.tools.cpp",
				"com.symbian.tools.cpp-custom",

				"com.symbian.tools.java",
				"com.symbian.tools.libraries",
				"com.symbian.tools.shared",
				"com.symbian.tools.shared-custom"],
				 
				[] ],
				
				
				
	["Documentation (html, examples, tool and source)",
				["com.symbian.doc.intro-pages",
				"com.symbian.doc.sdl-connect-examples",
				"com.symbian.doc.sdl-core",
				"com.symbian.doc.sdl",
				"com.symbian.doc.sdl-cpp-examples",
				"com.symbian.doc.sdl-java-examples",
				"com.symbian.doc.sdl-shared-examples",
                                "com.symbian.doc.system"],
				 
				["com.symbian.src.sdl",
				"com.symbian.tools.xbuild"] ]


			
				 );


# Holds list of packages already installed
my %InstalledOptions=();


my $UserChoices = "";
my $DevKitPackagesDirectory = "";
my $CustKitPackagesDirectory = "";
my $TargetDirectory = "";
my $InstallCustKit = "";
my $BuildFromClean = 0;

# start the program
main();




# --------------------------------- Start of Main() ----------------------------------------
sub main()
{
	if (@ARGV)
	{
		CommandLineInterface();
	}
	else
	{
		UserInterface();
	}


	# create target directory (copes with multiple-levels, not possible with unzip)
	if ( ! (-e $TargetDirectory) )
	{
		mkpath ($TargetDirectory);
	}


	# get user's options & sort numerically
	my @ListOfUserChoices = sort { $a <=> $b } split(/ */, $UserChoices);

	# install options, ignoring duplicates
	for (my $index = 0; $index < scalar(@ListOfUserChoices); $index++ )
	{
		my $UserChoice = (@ListOfUserChoices)[$index];
		
		if ( ($index > 0) && ($UserChoice eq (@ListOfUserChoices)[$index-1]) )
		{
			next;		# duplicate option and already dealt with it
		}
	
		elsif ($UserChoice !~ /\d/)
		{
			print "\n\nIgnoring unrecognised option '$UserChoice' at index $index.\n";
			next;		#invalid option - ignore
		}
		
		
		# install the option
		print "\n\nInstalling option $UserChoice ($AllTheOptions[$UserChoice]->[0])\n";
		InstallOption($UserChoice);
	
		
	}
		
	

	system("rd /q /s $TargetDirectory\\[sdkroot]") if (-e "$TargetDirectory\\[sdkroot]");
        
	
	CheckBuildPrerequisites();
    CheckKSA();
    CheckSupplementary();

        #remove target directory at end of Devkit Install
        print "\n\Removing target directory\n";
        system("rd /q /s $TargetDirectory");
        
        

}

# --------------------------------- Start of CheckSupplementary() ----------------------------------------


sub CheckSupplementary() 
{#Call InstallSupplementaryKit.pl to test supplementary packages
    my $scriptFileSupplementaryKits = "$ENV{ProductPath}\\SupplementaryProducts\\InstallSupplementaryKit.pl";    
    my $JarFileDir = "$ENV{ProductPath}\\SupplementaryProducts";    
    my $SuppTargetDirectory = "$TargetDirectory\\SuppKit";
    
    if (-e $JarFileDir )  {
        my @JarFiles = <$JarFileDir\\*.jar>;
        if ( scalar(@JarFiles) > 0 ) {
            foreach my $JarFile (@JarFiles) {
                system("perl $scriptFileSupplementaryKits -p $Platform -t $SuppTargetDirectory -j $JarFile");
            }
        } else {
            print "Warning: No Supplementary Kits Packages exists in $JarFileDir \n";
        }
    } else {
        print "Warning: Supplementary Kits Path: $JarFileDir do not exist! \n";
    }
}


# --------------------------------- Start of CheckKSA() ----------------------------------------


sub CheckKSA()
{#KSA files added in BuildKit::addKSA(); Only check the existence of Setup.exe
    my $KSAFile="$DevKitPackagesDirectory\\Setup.exe";
	if ( ! ( -e $KSAFile ) ) 
	{
		print "\n ERROR: KSA files does not exist: $KSAFile\n";
		die "ERROR: KSA files does not exist: $KSAFile \n"; 
	}
}

# --------------------------------- Start of CheckBuildPrerequisites() ----------------------------------------


sub CheckBuildPrerequisites()
# checks target system for:
#	Perl 5
#	Java
#	path environment variables:
#		gcc/bin
#		epoc32/tools
#      	vcvars having been executed (path to link.exe)

{
	my $DisplayString = "";
	
	my $RegObj = 0;
	my $Value = '';
	my $Type = 0;
	
	my $REG_ACTIVE_PERL = "SOFTWARE\\ActiveState\\ActivePerl";
	my $REG_PERL_DIRECTORY = "SOFTWARE\\Perl";
	
	my $REG_JAVA_RUNTIME	= "SOFTWARE\\JavaSoft\\Java Runtime Environment\\1.3";   # look for 1.3
	my $REG_JAVA_RUNTIME_HOME = "JavaHome";
	my $path = $ENV{"Path"};

	
	# Check Perl key - should be able to assume it's installed as this is a Perl script!
	
	# look for directory entry first
	if ( ( $HKEY_LOCAL_MACHINE->Open("$REG_PERL_DIRECTORY", $RegObj) ) && ( $RegObj->QueryValueEx("", $Type, $Value) ) )
	{
		if (! -e $Value)	# { print "  The Perl directory listed in the registry at $Value does not exist\n";  }
		{
			$DisplayString = $DisplayString . "  Perl installation required\n";
		}
	}
	else
	{
		$DisplayString = $DisplayString . "  Perl installation required\n";
	}
	$RegObj->Close(); 


	# Check Java key
	if ( (! $HKEY_LOCAL_MACHINE->Open("$REG_JAVA_RUNTIME", $RegObj) ) || (! $RegObj->QueryValueEx($REG_JAVA_RUNTIME_HOME, $Type, $Value) ) )
	{
		$DisplayString = $DisplayString . "  Java 1.3 installation required\n";
	}
	$RegObj->Close(); 
	

	
	# check whether vcvars has been run (can link.exe be found on path?)
	my $success = 0; #FALSE
	foreach my $Directory (split(/;/, $path))
	{
		if ( ( $Directory =~ m/bin/i ) && (-e "$Directory\\link.exe") )
		{
			$success = 1; #TRUE
		}
	}
	if (!$success) 
	{
		$DisplayString = $DisplayString . "Run vcvars.bat\n"; 
	}
	
	# print info if anything to show
	if ( $DisplayString ne "" )
	{
		print "\n\nBuild requirements:\n$DisplayString\n";
	}




}

# --------------------------------- Start ofCommandLineInterface() ----------------------------------------


sub CommandLineInterface()
{
	my $help;
	if ( (GetOptions( "options|o=s" => \$UserChoices,
			  "custkit|c=s" => \$CustKitPackagesDirectory,
			  "devkit|d=s" => \$DevKitPackagesDirectory,
			  "target|t=s" => \$TargetDirectory,
			  "help|h|?" => \$help,
			  "buildfromclean|b" => \$BuildFromClean,
			  "platform|p=s" => \$Platform ) == 0 ) || ($help == 1) )
	{
		Usage();
		exit; 
	}

	# check values received
	
	# user options - exit if not numeric or letter A
	if ( $UserChoices !~ m/^[Aa0-8]+$/) 
	{
		print "\n ERROR: Non-valid option(s) supplied: $UserChoices\n";
		die "ERROR: Non-valid option(s) supplied: $UserChoices\n"; 
	}
	

	# check that DevKit is in stated directory, exit if not found
	my @Packages = <$DevKitPackagesDirectory//com.symbian.devkit.*.sdkpkg>;
	if ( scalar(@Packages) == 0 )
	{
		print "\n ERROR: DevKit packages not found in directory: $DevKitPackagesDirectory\n";	
		die "ERROR: DevKit packages not found in directory: $DevKitPackagesDirectory\n";
	}
	
		

	# check that target location to write extracted files to is empty or non-existant

	while ( (substr($TargetDirectory, -1, 1) eq '\\') || (substr($TargetDirectory, -1, 1) eq '/') )
	{
		chop($TargetDirectory); 		# remove final backslashes
	}
		
	my @contents = <$TargetDirectory/*.*>;
	if ( ( (-e $TargetDirectory) && (scalar(@contents) > 0) ) || ($TargetDirectory eq "" ) )
	{
			print "\n ERROR: Non-empty or unspecified target location: $TargetDirectory\n";
			die "ERROR: Non-empty or unspecified target location: $TargetDirectory\n";
	}
	

	if ( ($Platform eq "") && ($ENV{'Platform'} eq "") )
	{
		Usage();
		print "\nN.B. -platform required\n";
		exit; 
	}
	elsif ( ($Platform eq "") )
	{
		$Platform = $ENV{'Platform'} ;
	}



	
	# print values for clarification/logging
	print "  Installing options:      $UserChoices \n";
	print "  DevKit in directory:     $DevKitPackagesDirectory \n";
	print "  Installing to directory: $TargetDirectory \n";


	# convert A in user options to numbers(after displaying)
	$UserChoices =~ s/[aA]/012345678/g;

}


# --------------------------------- Start of UserInterface() ----------------------------------------


sub UserInterface()
{
	print "\n------------------------------------------------------\n\n";
	my $index = 0;
	while ($index < scalar(@AllTheOptions))
	{
		# display option number and text for this option
		print $index . ".  ".$AllTheOptions[$index]->[0]."\n";
		$index++;
	}

	print "\n------------------------------------------------------\n\n";
	
	# get user's choice - must be numeric or 'A' for all
	do
	{
		print "Enter option numbers to install (no separator) or A for [A]ll: ";
		chomp($UserChoices = <STDIN>);
		if ($UserChoices =~ m/[aA]/)
		{
			$UserChoices = "012345678";
		}
	} while ($UserChoices =~ m/[^\d]/)	;
			
	
	# check that Kit is in this directory
	my @Packages = <com.symbian.devkit.*.sdkpkg>;
	while ( scalar(@Packages) == 0 )
	{
		# if not, get location of the packages
		print "Enter path to the DevKit's packages (*.sdkpkg files) : ";
		chomp( $DevKitPackagesDirectory = <STDIN> );
		@Packages = <$DevKitPackagesDirectory//com.symbian.devkit.*.sdkpkg>
	}
	
	
	

	# get location to write extracted files to
	print "Enter directory to extract files to (must be new or empty): ";

	my $invalid = 1; #TRUE

	do	# ensure directory doesn't exist or is empty
	{
		chomp( $TargetDirectory = <STDIN> );
		while ( (substr($TargetDirectory, -1, 1) eq '\\') || (substr($TargetDirectory, -1, 1) eq '/') )
		{
			chop($TargetDirectory); 		# remove final backslashes
		}
		
		my @contents = <$TargetDirectory/*.*>;
		if ( $invalid = ( (-e $TargetDirectory) && (scalar(@contents) > 0) ) || ($TargetDirectory eq "" ) )
		{
			print "Invalid selection - enter the name of an empty or new directory : ";
		}
	} while ( $invalid ) ;


	# get Platform name - try environment, else ask user
	if ($ENV{'Platform'} eq "")
	{
		print "Enter platform name  : ";
		chomp( $Platform = <STDIN> );
	}
	else
	{
		$Platform = $ENV{'Platform'} ;
	}
	
	
	print "\n------------------------------------------------------\n\n";

}


# --------------------------------- Start of InstallOption() ----------------------------------------

sub InstallOption()
{
	my $Option = $_[0] ;
	
	# get array of DevKit packages for this option
	my $Entry = $AllTheOptions[$Option]->[1];
	
	
	# for each package, call InstallPackage() to install the files
	foreach my $Package (@$Entry)
	{
		if (! $InstalledOptions{$Package})
		{
			$InstalledOptions{$Package} = $Option ;
			print "  Installing  $Package\n";
			InstallPackage ( $Option, $Package, );
		}
		else
		{
			print "  Already got $Package\n";
		}
	}
}


# --------------------------------- Start of InstallPackage() ----------------------------------------

sub InstallPackage()
{
	my $Option = $_[0] ;
	my $Package = $_[1] ;
	
	# ensure package exists & is uniquely identified
	
	# try in DevKit directory first
	my $PackageName = $DevKitPackagesDirectory."\\".$Package."_*sdkpkg";
	my @Packages = glob($PackageName);
	
	# ensure the package exists
	if ( scalar(@Packages) == 0 )
	{
		# not found, so try the CustKit directory
		$PackageName = $CustKitPackagesDirectory."\\".$Package."_*sdkpkg";
		@Packages = glob($PackageName);
		if ( scalar(@Packages) == 0 )
		{
			print "\n ERROR: Package $Package not found. \n";
			die "    ERROR: Package $Package not found. \n";	
		}
		elsif ( scalar(@Packages) > 1 )
		{
			print "\n ERROR: Package $Package name matched duplicate CustKit files \n";
			die "    ERROR: Package $Package name matched duplicate CustKit files \n";	
		}
	}
	elsif ( scalar(@Packages) > 1 )
	{
		print "\n ERROR: Package $Package name matched duplicate files \n";
		die "    ERROR: Package $Package name matched duplicate files \n";	
	}

	
	# now able to start reading package & copying files
	
	if (-e $Packages[0]) 
	{
     
		system("unzip -q -o $Packages[0] -x package.xml -d \"$TargetDirectory\"");
                
	}

}	
	
	






# -------------------------- Start of makepath() ------------------------------

sub makepath($)
	{
	my ($path) = @_;

	if (-d $path)
		{
		return -1;
		}
	else
		{
		return mkpath($path);
		}
	}


# --------------------------------- Start of Usage() ----------------------------------------

sub Usage()
{
	print <<ENDOFUSAGETEXT;
	
INSTALLCUSTKIT.PL    Version 1.3    Copyright (c) 2002, 2003 Symbian Ltd
                                    All rights reserved
                                  
Usage:
  perl InstallCustKit.pl  [options]
 
where options are:
  -b[uildfromclean]       combine unpacked files into build from clean location
  -c[ustkit] <path>       path to directory containing CustKit packages
  -d[evkit] <path>        path to directory containing DevKit packages
  -o[ptions] 012345678A   functionality options (A selects all)
  -p[latform] <platform>  build platform - used to create binaries installation directory path
  -t[arget] <path>        path to directory to unpack Kit into
   
ENDOFUSAGETEXT
}
