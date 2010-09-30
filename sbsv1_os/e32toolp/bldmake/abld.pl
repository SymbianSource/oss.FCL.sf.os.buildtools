# Copyright (c) 1997-2009 Nokia Corporation and/or its subsidiary(-ies).
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


use FindBin;		# for FindBin::Bin
use Getopt::Long;

my $PerlLibPath;    # fully qualified pathname of the directory containing our Perl modules

BEGIN {
# check user has a version of perl that will cope
	require 5.005_03;
# establish the path to the Perl libraries: currently the same directory as this script
	$PerlLibPath = $FindBin::Bin;	# X:/epoc32/tools
	$PerlLibPath =~ s/\//\\/g;	# X:\epoc32\tools
	$PerlLibPath .= "\\";
}

use lib $PerlLibPath;
use E32env;
use CheckSource;
use FCLoggerUTL;
use featurevariantparser;

if (defined $ENV{ABLD_TOOLSMOD_COMPATIBILITY_MODE} &&  ($ENV{ABLD_TOOLSMOD_COMPATIBILITY_MODE} eq 'alpha')) {
		
			$ENV{MAKE} = 'make' unless defined $ENV{MAKE};
}

# command data structure
my %Commands=(
	BUILD=>{
		build=>1,
		program=>1,
		what=>1,
		function=>'Combines commands EXPORT,MAKEFILE,LIBRARY,RESOURCE,TARGET,FINAL',
		subcommands=>['EXPORT','MAKEFILE', 'LIBRARY', 'RESOURCE', 'TARGET', 'FINAL'],
		savespace=>1,
        instructionset=>1,
		debug=>1,
		no_debug=>1,
		logfc=>1,
		checksource=>1,
		wrap=>1, #To support Compiler wrapper option along with BUILD command
	},
	CLEAN=>{
		build=>1,
		program=>1,
		function=>'Removes everything built with ABLD TARGET',
		what=>1,
	},
	CLEANALL=>{
		program=>1,
		function=>'Removes everything built with ABLD TARGET',
		what=>1,
	},
	CLEANEXPORT=>{
		function=>'Removes files created by ABLD EXPORT',
		what=>1,
		noplatform=>1,
	},
	CLEANMAKEFILE=>{
		program=>1,
		function=>'Removes files generated by ABLD MAKEFILE',
		what=>1,
		hidden=>1,
	},
	EXPORT=>{
		noplatform=>1,
		what=>1,
		function=>'Copies the exported files to their destinations',
	},
	FINAL=>{
		build=>1,
		program=>1,
		function=>'Allows extension makefiles to execute final commands',
	},
	FREEZE=>{
		program=>1,
		remove=>1,
		function=>'Freezes exported functions in a .DEF file',
	},
	HELP=>{
		noplatform=>1,
		function=>'Displays commands, options or help about a particular command',
		notest=>1,
	},
	LIBRARY=>{
		program=>1,
		function=>'Creates import libraries from the frozen .DEF files',
	},
	LISTING=>{
		build=>1,
		program=>1,
		function=>'Creates assembler listing file for corresponding source file',
		source=>1,	
	},
	MAKEFILE=>{
		program=>1,
		function=>'Creates makefiles or IDE workspaces',
		what=>1,
		savespace=>1,
		instructionset=>1,
		debug=>1,
		no_debug=>1,
		logfc=>1,
		wrap=>1, #To support Compiler wrapper option along with MAKEFILE command
        },
	REALLYCLEAN=>{
		build=>1,
		program=>1,
		function=>'As CLEAN, but also removes exported files and makefiles',
		what=>1,
		subcommands=>['CLEANEXPORT', 'CLEAN', 'CLEANALL'],
	},
	RESOURCE=>{
		build=>1,
		program=>1,
		function=>'Creates resource files, bitmaps and AIFs',
	},
#	ROMFILE=>{
#		function=>'Under development - syntax not finalised',
#		noverbose=>1,
#		nokeepgoing=>1,
#		hidden=>1,
#	},
	ROMFILE=>{
		noverbose=>1,
		build=>1,
		program=>1,
		function=>'generates an IBY file to include in a ROM'
	},
	SAVESPACE=>{
		build=>1,
		program=>1,
		what=>1,
		function=>'As TARGET, but deletes intermediate files on success',
		hidden=>1, # hidden because only used internally from savespace flag
	},
	TARGET=>{
		build=>1,
		program=>1,
		what=>1,
		function=>'Creates the main executable and also the resources',
		savespace=>1,
		checksource=>1,
		wrap=>1, #To support Compiler wrapper option along with TARGET command
	},
	TIDY=>{
		build=>1,
		program=>1,
		function=>'Removes executables which need not be released',
	}
);

# get the path to the bldmake-generated files
# we can perhaps work this out from the current working directory in later versions
my $BldInfDir;
my $PrjBldDir;
BEGIN {
	$BldInfDir=shift @ARGV;
	$PrjBldDir=$E32env::Data{BldPath};
	$PrjBldDir=~s-^(.*)\\-$1-o;
	$PrjBldDir.=$BldInfDir;
	$PrjBldDir=~m-(.*)\\-o; # remove backslash because some old versions of perl can't cope
	unless (-d $1) {
		die "ABLD ERROR: Project Bldmake directory \"$PrjBldDir\" does not exist\n";
	}
}

# check the platform module exists and then load it
BEGIN {
	unless (-e "${PrjBldDir}Platform.pm") {
		die "ABLD ERROR: \"${PrjBldDir}Platform.pm\" not yet created\n";
	}
}
use lib $PrjBldDir;
use Platform;

# change directory to the BLD.INF directory - we might begin to do
# things with relative paths in the future.
chdir($BldInfDir) or die "ABLD ERROR: Can't CD to \"$BldInfDir\"\n";

# MAIN PROGRAM SECTION
{

#	PROCESS THE COMMAND LINE
	my %Options=();
	unless (@ARGV) {
		&Usage();
	}

#	Process options and check that all are recognised
# modified start: added functionality checkwhat
	unless (GetOptions(\%Options, 'checkwhat|cw','check|c', 'keepgoing|k', 'savespace|s', 'verbose|v',
						'what|w', 'remove|r', 'instructionset|i=s',
						'checksource|cs', 'debug','no_debug', 'logfc|fc','wrap:s')) { 
		exit 1;
	}
# modified end: added functionality checkwhat

#	check the option combinations
# modified start: added functionality checkwhat
	if ($Options{checkwhat} ) { 
		$Options{check}=1;
	}
# modified end: added functionality checkwhat
	if (($Options{check} and $Options{what})) {
		&Options;
	}
	if (($Options{check} or $Options{what}) and ($Options{keepgoing} or $Options{savespace} or $Options{verbose})) {
		&Options();
	}
	if ($Options{checksource} and $Options{what}) {
		&Options();
	}


#	take the test parameter out of the command-line if it's there
	my $Test='';
	if (@ARGV && $ARGV[0]=~/^test$/io) {
		$Test='test';
		shift @ARGV;
	}

#	if there's only the test parameter there, display usage
	unless (@ARGV) {
		&Usage();
	}

#	get the command parameter out of the command line
	my $Command=uc shift @ARGV;
	unless (defined $Commands{$Command}) {
		&Commands();
	}
	my %CommandHash=%{$Commands{$Command}};

#	check the test parameter is not specified where it shouldn't be
	if ($Test and $CommandHash{notest}) {
		&Help($Command);
	}

#	check the options are suitable for the commands
#	-verbose and -keepgoing have no effect in certain cases
	if ($Options{what} or $Options{check}) {
		unless ($CommandHash{what}) {
			&Help($Command);
		}
	}
	#Function Call Logger
	if ($Options{logfc}) {
		unless ($CommandHash{logfc}) {
			&Help($Command);
		}
	}
	if ($Options{savespace}) {
		unless ($CommandHash{savespace}) {
			&Help($Command);
		}
	}
	if ($Options{instructionset}) {
		unless ($CommandHash{instructionset}) {
			&Help($Command);
		}
	}
	if ($Options{debug}) {
		unless ($CommandHash{debug}) {
			&Help($Command);
		}
	}
	if ($Options{no_debug}) {
		unless ($CommandHash{no_debug}) {
			&Help($Command);
		}
	}

	if ($Options{keepgoing}) {
		if ($CommandHash{nokeepgoing}) {
			&Help($Command);
		}
	}
	if ($Options{verbose}) {
		if ($CommandHash{noverbose}) {
			&Help($Command);
		}
	}
	if ($Options{remove}) {
		unless ($CommandHash{remove}) {
			&Help($Command);
		}
	}
	if ($Options{checksource}) {
		unless ($CommandHash{checksource}) {
			&Help($Command);
		}
	}
	#Compiler Wrapper support 
	if (exists $Options{wrap}) {
		unless ($CommandHash{wrap}) {
			&Help($Command);
		}
	}

#	process help command if necessary
	if ($Command eq 'HELP') {
		if (@ARGV) {
			my $Tmp=uc shift @ARGV;
			if (defined $Commands{$Tmp}) {
				&Help($Tmp);
			}
			elsif ($Tmp eq 'OPTIONS') {
				&Options();
			}
			elsif ($Tmp eq 'COMMANDS') {
				&Commands();
			}
		}
		&Usage();
	}

#	process parameters
	my ($Plat, $Bld, $Program, $Source)=('','','','');
	my %MakefileVariations;
	my $FeatureVariantArg;
        
#	platform parameter first
	unless ($CommandHash{noplatform}) {
		unless ($Plat=uc shift @ARGV) {
			$Plat='ALL'; # default
		}
		else {
			# Explicit feature variant platforms take the form <base platform>.<variant name>
			# e.g. armv5.variant1.
			# If valid, we actually create and invoke a distinct variation of the "base" makefile
			if ($Plat =~ /^(\S+)\.(\S+)$/)
				{
				$Plat = $1;
				$FeatureVariantArg = uc($2);

				if (!$Platform::FeatureVariantSupportingPlats{$Plat})
					{
					die "This project does not support platform \"$Plat\.$FeatureVariantArg\"\n";
					}
				else
					{						
					$MakefileVariations{$Plat} = &GetMakefileVariations($Plat, $FeatureVariantArg);
					}
				}

			COMPARAM1 : {
				if (grep(/^$Plat$/, ('ALL', @Platform::Plats))) {
					last COMPARAM1;
				}
				if ($Plat =~ /(.*)EDG$/) {
				    my $SubPlat = $1;
				    if (grep(/^$SubPlat$/, ('ALL', @Platform::Plats))) {
					last COMPARAM1;
				    }
				}
#				check whether the platform might in fact be a build, and
#				set the platform and build accordingly if it is
				if ($CommandHash{build}) {
					if ($Plat=~/^(UDEB|UREL|DEB|REL)$/o) {
						$Bld=$Plat;
						$Plat='ALL';
						last COMPARAM1;
					}
				}
#				check whether the platform might in fact be a program, and
#				set the platform, build and program accordingly if it is
				if ($CommandHash{program}) {
					if  (((not $Test) and grep /^$Plat$/, @{$Platform::Programs{ALL}})
							or ($Test and grep /^$Plat$/, @{$Platform::TestPrograms{ALL}})) {
						$Program=$Plat;
						$Plat='ALL';
						$Bld='ALL';
						last COMPARAM1;
					}
				}
#				report the error
				if ($CommandHash{build} and $CommandHash{program}) {
					die "This project does not support platform, build or $Test program \"$Plat\"\n";
				}
				if ($CommandHash{build} and not $CommandHash{program}) {
					die "This project does not support platform or build \"$Plat\"\n";
				}
				if ($CommandHash{program} and not $CommandHash{build}) {
					die "This project does not support platform or $Test program \"$Plat\"\n";
				}
				if (not ($CommandHash{build} or $CommandHash{program})) {
					die "This project does not support platform \"$Plat\"\n";
				}
			}
		}
	}

	#Compiler Wrapper support 
	my $CompilerWrapperFlagMacro = "";
	if(exists $Options{wrap})
	{
		my $error = "Environment variable 'ABLD_COMPWRAP' is not set\n";
		# If tool name for wrapping compiler is set in environment variable
		if($ENV{ABLD_COMPWRAP})
		{
			$CompilerWrapperFlagMacro =" ABLD_COMPWRAP_FLAG=-wrap" .  ($Options{wrap} ? "=$Options{wrap}":"");
		}
		elsif($Options{keepgoing})  
		{
		    # If Tool name is not set and keepgoing option is specified then ignore -wrap option and continue processing
		    print $error;
		    delete $Options{wrap};
		}
		else
		{
		    # Issue error and exit if neither keepgoing option nor tool name is specified		
		    die $error;
		}
	}

#	process the build parameter for those commands which require it
	if ($CommandHash{build}) {
		unless ($Bld) {
			unless ($Bld=uc shift @ARGV) {
				$Bld='ALL'; # default
			}
			else {
				COMPARAM2 : {
					if ($Bld=~/^(ALL|UDEB|UREL|DEB|REL)$/o) {
#						Change for TOOLS, TOOLS2 and VC6TOOLS platforms
						if ($Plat ne 'ALL') {
							if (($Plat!~/TOOLS2?$/o and $Bld=~/^(DEB|REL)$/o) or ($Plat=~/TOOLS2?$/o and $Bld=~/^(UDEB|UREL)$/o)) {
								die  "Platform \"$Plat\" does not support build \"$Bld\"\n";
							}
						}
						last COMPARAM2;
					}
#					check whether the build might in fact be a program, and
#					set the build and program if it is
					if ($CommandHash{program}) {
						if  (((not $Test) and grep /^$Bld$/, @{$Platform::Programs{$Plat}})
								or ($Test and grep /^$Bld$/, @{$Platform::TestPrograms{$Plat}})) {
							$Program=$Bld;
							$Bld='ALL';
							last COMPARAM2;
						}
						my $Error="This project does not support build or $Test program \"$Bld\"";
						if ($Plat eq 'ALL') {
							$Error.=" for any platform\n";
						}
						else {
							$Error.=" for platform \"$Plat\"\n";
						}
						die $Error;
					}
					my $Error="This project does not support build \"$Bld\"";
					if ($Plat eq 'ALL') {
						$Error.=" for any platform\n";
					}
					else {
						$Error.=" for platform \"$Plat\"\n";
					}
					die $Error;
				}
			}
		}
	}

#	get the program parameter for those commands which require it
	if ($CommandHash{program}) {
		unless ($Program) {
			unless ($Program=uc shift @ARGV) {
				$Program=''; #default - means ALL
			}
			else {
#				check that the program is supported
				unless (((not $Test) and grep /^$Program$/, @{$Platform::Programs{$Plat}})
						or ($Test and grep /^$Program$/, @{$Platform::TestPrograms{$Plat}})) {
					my $Error="This project does not support $Test program \"$Program\"";
					if ($Plat eq 'ALL') {
						$Error.=" for any platform\n";
					}
					else {
						$Error.=" for platform \"$Plat\"\n";
					}
					die $Error;
				}
			}
		}
	}

#	get the source file parameter for those commands which require it
	if ($CommandHash{source}) {
		unless ($Source=uc shift @ARGV) {
			$Source=''; #default - means ALL
		}
		else {
			$Source=" SOURCE=$Source";
		}
	}

#	check for too many arguments
	if (@ARGV) {
		&Help($Command);
	}

	if ( $Options{instructionset} )
	{	# we have a -i option.
		if ($Plat eq 'ARMV5')
		{
			if  ( !( ( uc( $Options{instructionset} ) eq "ARM") || ( uc( $Options{instructionset} ) eq "THUMB" ) ) ) {		
				# Only ARM and THUMB options are valid. 
				&Options();
			}
		}
		else
		{ # Can only use -i for armv5 builds. 
			&Options();
		}
	}

#	process CHECKSOURCE_OVERRIDE
	if ($ENV{CHECKSOURCE_OVERRIDE} && (($Plat =~ /^ARMV5/) || ($Plat eq 'WINSCW')) && ($Command eq 'TARGET')  && !$Options{what})
		{
		$Options{checksource} = 1;
		}
	
	my $checksourceMakeVariables = " ";	
	if ($Options{checksource}) {
		$checksourceMakeVariables .= "CHECKSOURCE_VERBOSE=1 " if ($Options{verbose});
	}

#	expand the platform list
	my @Plats;
	unless ($CommandHash{noplatform}) {
		if ($Plat eq 'ALL') {
			@Plats=@Platform::RealPlats;
#			Adjust the "ALL" list according to the availability of compilers
			@Plats=grep !/WINSCW$/o, @Plats unless (defined $ENV{MWSym2Libraries});
			@Plats=grep !/WINS$/o, @Plats unless (defined $ENV{MSDevDir});
			@Plats=grep !/X86$/o, @Plats unless (defined $ENV{MSDevDir});
			@Plats=grep !/X86SMP$/o, @Plats unless (defined $ENV{MSDevDir});
			@Plats=grep !/X86GCC$/o, @Plats unless (defined $ENV{MSDevDir});
			@Plats=grep !/X86GMP$/o, @Plats unless (defined $ENV{MSDevDir});
			if ($CommandHash{build}) {
#				remove unnecessary platforms if just building for tools, or building everything but tools
#				so that the makefiles for other platforms aren't created with abld build
				if ($Bld=~/^(UDEB|UREL)$/o) {
					@Plats=grep !/TOOLS2?$/o, @Plats;
				}
				elsif ($Bld=~/^(DEB|REL)$/o) {
					@Plats=grep /TOOLS2?$/o, @Plats;
				}
			}
		}
        else
        {
			@Plats=($Plat);
		}

		foreach $Plat (@Plats)
			{
			# Skip platforms resolved above
			next if $MakefileVariations{$Plat};
				
			# Implicit feature variant platforms apply when a default feature variant exists and the platform supports it
			# If valid, we actually create and invoke a distinct variation of the "base" makefile
			if ($Platform::FeatureVariantSupportingPlats{$Plat} && featurevariantparser->DefaultExists())
				{
				if($Command eq "REALLYCLEAN")
					{
					my @myfeature = featurevariantparser->GetBuildableFeatureVariants();
					push @{$MakefileVariations{$Plat}}, ".".$_ foreach(@myfeature);
					}
					else
					{
					$MakefileVariations{$Plat} = &GetMakefileVariations($Plat, "DEFAULT");
					}
				}
			else
				{
				# For non-feature variant platforms we always store a single makefile variation of nothing i.e.
				# we use the "normal" makefile generated for the platform
				$MakefileVariations{$Plat} = &GetMakefileVariations($Plat, "");
				}
				
			}

		foreach $Plat (@Plats) {
			foreach my $makefileVariation (@{$MakefileVariations{$Plat}}) {
				unless (-e "$PrjBldDir$Plat$makefileVariation$Test.make") {
					die "ABLD ERROR: \"$PrjBldDir$Plat$makefileVariation$Test.make\" not yet created\n";
				}
			}
		}
		undef $Plat;
	}

#	set up a list of commands where there are sub-commands
	my @Commands=($Command);
	if ($CommandHash{subcommands}) {
		@Commands=@{$CommandHash{subcommands}};
		if ($Command eq 'BUILD') { # avoid makefile listings here
			if ($Options{what} or $Options{check}) {
				@Commands=grep !/^MAKEFILE$/o, @{$CommandHash{subcommands}};
			}
		}
	}
#	implement savespace if necessary
	if ($Options{savespace}) {
		foreach $Command (@Commands) {
			if ($Command eq 'TARGET') {
				$Command='SAVESPACE';
			}
		}
	}

#	set up makefile call flags and macros from the options
	my $KeepgoingFlag='';
	my $KeepgoingMacro='';
        my $NoDependencyMacro='';
	my $VerboseMacro=' VERBOSE=-s';
	if ($Options{keepgoing}) {
		$KeepgoingFlag=' -k';
		$KeepgoingMacro=' KEEPGOING=-k';
	}
	if ($Options{verbose}) {
		$VerboseMacro='';
	}
	my $RemoveMacro='';
	if ($Options{remove}) {
		$RemoveMacro=' EFREEZE_ALLOW_REMOVE=1';
	}
	if ( ($Options{savespace}) and ($Options{keepgoing}) ){
		$NoDependencyMacro=' NO_DEPENDENCIES=-nd';
	}

    my $AbldFlagsMacro="";
	$AbldFlagsMacro = "-iarm " if (uc $Options{instructionset} eq "ARM");
	$AbldFlagsMacro = "-ithumb " if (uc $Options{instructionset} eq "THUMB");

	if ($Options{debug}) {
		$AbldFlagsMacro .= "-debug ";
	}
	elsif($Options{no_debug}) {
		$AbldFlagsMacro .= "-no_debug ";
	}
    
	#Function call logging flag for makmake
	if ($Options{logfc}) {
		#Check the availability and version of logger
		if (&FCLoggerUTL::PMCheckFCLoggerVersion()) {
			$AbldFlagsMacro .= "-logfc ";
		}
	}

	if(!($AbldFlagsMacro eq "") ){
		$AbldFlagsMacro =" ABLD_FLAGS=\"$AbldFlagsMacro\"";
	}

#	set up a list of make calls
	my @Calls;

#	handle the exports related calls first
	if (($Command)=grep /^(.*EXPORT)$/o, @Commands) { # EXPORT, CLEANEXPORT
		unless (-e "${PrjBldDir}EXPORT$Test.make") {
			die "ABLD ERROR: \"${PrjBldDir}EXPORT$Test.make\" not yet created\n";
		}
		unless ($Options {checksource}) {
			if (defined $ENV{ABLD_TOOLSMOD_COMPATIBILITY_MODE} &&  ($ENV{ABLD_TOOLSMOD_COMPATIBILITY_MODE} eq 'alpha')) {
				unless ($Options{what} or $Options{check}) {
					push @Calls, "$ENV{MAKE} -r $KeepgoingFlag -f \"${PrjBldDir}EXPORT$Test.make\" $Command$VerboseMacro$KeepgoingMacro";
				}
				else {
					push @Calls, "$ENV{MAKE} -r -f \"${PrjBldDir}EXPORT$Test.make\" WHAT";
				}
			}
			else {
			
				unless ($Options{what} or $Options{check}) {
					push @Calls, "make -r $KeepgoingFlag -f \"${PrjBldDir}EXPORT$Test.make\" $Command$VerboseMacro$KeepgoingMacro";
				}
				else {
					push @Calls, "make -r -f \"${PrjBldDir}EXPORT$Test.make\" WHAT";
				}
			}
		}
		@Commands=grep !/EXPORT$/o, @Commands;
	}

#	then do the rest of the calls

	COMMAND: foreach $Command (@Commands) {

		if ($Options {checksource} && ($Command eq "TARGET" || $Command eq "SAVESPACE")) {
			if (defined $ENV{ABLD_TOOLSMOD_COMPATIBILITY_MODE} &&  ($ENV{ABLD_TOOLSMOD_COMPATIBILITY_MODE} eq 'alpha')) {
				push @Calls, "$ENV{MAKE} -r -f \"".$PrjBldDir."EXPORT.make\"".$checksourceMakeVariables."CHECKSOURCE";
			}
			else {
				push @Calls, "make -r -f \"".$PrjBldDir."EXPORT.make\"".$checksourceMakeVariables."CHECKSOURCE";
			}
		}

		my $Plat;
		PLATFORM: foreach $Plat (@Plats) {

#			set up a list of builds to carry out commands for if appropriate
			my @Blds=($Bld);
			if (${$Commands{$Command}}{build}) {
				if ($Bld eq 'ALL') {
					unless ($Plat=~/TOOLS2?$/o) { # change for platforms TOOLS, TOOLS2 and VC6TOOLS
						@Blds=('UDEB', 'UREL');
					}
					else {
						@Blds=('DEB', 'REL');
					}
				}
				else {
#					check the build is suitable for the platform - TOOLS, TOOLS2 and VC6TOOLS are annoyingly atypical
					unless (($Plat!~/TOOLS2?$/o and $Bld=~/^(UDEB|UREL)$/o) or ($Plat=~/TOOLS2?$/o and $Bld=~/^(DEB|REL)$/o)) {
						next;
					}
				}
			}
			else {
				@Blds=('IRRELEVANT');
			}

			# You get CHECKSOURCE_GENERIC "for free" if no component is specified in the call
			if ($Options {checksource} && ($Command eq "TARGET" || $Command eq "SAVESPACE") && $Program) {
				foreach my $makefileVariation (@{$MakefileVariations{$Plat}}) {
					if (defined $ENV{ABLD_TOOLSMOD_COMPATIBILITY_MODE} &&  ($ENV{ABLD_TOOLSMOD_COMPATIBILITY_MODE} eq 'alpha')) {
						push @Calls, "$ENV{MAKE} -r -f \"$PrjBldDir$Plat$makefileVariation$Test.make\"".$checksourceMakeVariables."CHECKSOURCE_GENERIC";
					}
					else {
						push @Calls, "make -r -f \"$PrjBldDir$Plat$makefileVariation$Test.make\"".$checksourceMakeVariables."CHECKSOURCE_GENERIC";
					}
				}
			}

			my $LoopBld;
			foreach $LoopBld (@Blds) {
				my $CFG='';
				if ($LoopBld ne 'IRRELEVANT') {
					$CFG=" CFG=$LoopBld";
				}
				if ($Options {checksource}) {
					if ($Command eq "TARGET" || $Command eq "SAVESPACE") {
						foreach my $makefileVariation (@{$MakefileVariations{$Plat}}) {
							if (defined $ENV{ABLD_TOOLSMOD_COMPATIBILITY_MODE} &&  ($ENV{ABLD_TOOLSMOD_COMPATIBILITY_MODE} eq 'alpha')) {
								push @Calls, "$ENV{MAKE} -r -f \"$PrjBldDir$Plat$makefileVariation$Test.make\"".$checksourceMakeVariables."CHECKSOURCE$Program$CFG";	  
							}
							else {	
								push @Calls, "make -r -f \"$PrjBldDir$Plat$makefileVariation$Test.make\"".$checksourceMakeVariables."CHECKSOURCE$Program$CFG";
							}
						}
					}
					next;
				}
				
				unless ($Options{what} or $Options{check}) {
					if ($Program) { # skip programs if they're not supported for a platform
						unless ($Test) {
							unless (grep /^$Program$/, @{$Platform::Programs{$Plat}}) {
								next PLATFORM;
							}
						}
						else {
							unless (grep /^$Program$/, @{$Platform::TestPrograms{$Plat}}) {
								next PLATFORM;
							}
						}
					}
   					my $AbldFlagsMacroTmp="";
					my $CompilerWrapperFlagMacroTemp="";
					if ($Command eq "MAKEFILE")
					{	# Only want ABLD_FLAGS for Makefile
                        $AbldFlagsMacroTmp=$AbldFlagsMacro;
						if(exists ($Options{wrap}))
						{
							# Require ABLD_COMPWRAP_FLAG when --wrap option is specified
							$CompilerWrapperFlagMacroTemp = $CompilerWrapperFlagMacro;
						}
					}
					foreach my $makefileVariation (@{$MakefileVariations{$Plat}}) {
							if (defined $ENV{ABLD_TOOLSMOD_COMPATIBILITY_MODE} &&  ($ENV{ABLD_TOOLSMOD_COMPATIBILITY_MODE} eq 'alpha')) {

								if ( ($Command eq "TARGET") && (-e $PerlLibPath . "tracecompiler.pl") )
								{
									not scalar grep(/tracecompiler\.pl $Plat/,@Calls) and push @Calls, "perl " . $PerlLibPath . "tracecompiler.pl $Plat $Program";
								}
								push @Calls, "$ENV{MAKE} -r $KeepgoingFlag -f \"$PrjBldDir$Plat$makefileVariation$Test.make\""
								." $Command$Program$CFG$Source$VerboseMacro" .
								"$KeepgoingMacro$RemoveMacro$NoDependencyMacro" .
								"$AbldFlagsMacroTmp$CompilerWrapperFlagMacroTemp";

								#Compiler Wrapper support
								if ( exists($Options{wrap}) && ($Options{wrap} eq "") && ($Command eq "TARGET") )
								{
									my $CFGCOMPWRAP='';
									if ($LoopBld ne 'IRRELEVANT')
									{
										$CFGCOMPWRAP =" CFG=COMPWRAP".$LoopBld;	
									}
									push @Calls, "$ENV{MAKE} -r $KeepgoingFlag -f \"$PrjBldDir$Plat$makefileVariation$Test.make\""." TARGET$Program$CFGCOMPWRAP";
								}
							}
							else {	
								push @Calls, "make -r $KeepgoingFlag -f \"$PrjBldDir$Plat$makefileVariation$Test.make\""
								." $Command$Program$CFG$Source$VerboseMacro" .
								"$KeepgoingMacro$RemoveMacro$NoDependencyMacro" .
								"$AbldFlagsMacroTmp$CompilerWrapperFlagMacroTemp";
              
								#Compiler Wrapper support
								if ( exists($Options{wrap}) && ($Options{wrap} eq "") && ($Command eq "TARGET") )
								{
									my $CFGCOMPWRAP='';
									if ($LoopBld ne 'IRRELEVANT')
									{
										$CFGCOMPWRAP =" CFG=COMPWRAP".$LoopBld;	
									}
									push @Calls, "make -r $KeepgoingFlag -f \"$PrjBldDir$Plat$makefileVariation$Test.make\""." TARGET$Program$CFGCOMPWRAP";
								}
							}
						}
						next;
				}

				unless (${$Commands{$Command}}{what}) {
					next COMMAND;
				}
				if ($Program) { # skip programs if they're not supported for a platform
					unless ($Test) {
						unless (grep /^$Program$/, @{$Platform::Programs{$Plat}}) {
							next PLATFORM;
						}
					}
					else {
						unless (grep /^$Program$/, @{$Platform::TestPrograms{$Plat}}) {
							next PLATFORM;
						}
					}
				}
				my $Makefile='';
				if ($Command=~/MAKEFILE$/o) {
					$Makefile='MAKEFILE';
				}

				foreach my $makefileVariation (@{$MakefileVariations{$Plat}}) {
					if (defined $ENV{ABLD_TOOLSMOD_COMPATIBILITY_MODE} &&  ($ENV{ABLD_TOOLSMOD_COMPATIBILITY_MODE} eq 'alpha')) {
					push @Calls, "$ENV{MAKE} -r -f \"$PrjBldDir$Plat$makefileVariation$Test.make\" WHAT$Makefile$Program $CFG";
					}
					else {
					push @Calls, "make -r -f \"$PrjBldDir$Plat$makefileVariation$Test.make\" WHAT$Makefile$Program $CFG";
				    }
				}
			}
		}
	}


#	make the required calls

	my $Call;
	my %checkSourceUniqueOutput;
	unless ($Options{what} or $Options{check}) {
		foreach $Call (@Calls) {
			print "  $Call\n" unless ($Options{checksource} && !$Options {verbose});
			open PIPE, "$Call |";
			$|=1; # bufferring is disabled
			while (<PIPE>) {
				if ($Options {checksource})
					{
					if ($Options{verbose})
						{
						print $_;
						}
					else
						{
						$checkSourceUniqueOutput{$_} = 1;
						}
					}
				else
					{
					print;
					}
			}
			close PIPE;
		}

		print $_ foreach (sort keys %checkSourceUniqueOutput);
	}
	else {
		my %WhatCheck; # check for duplicates
		foreach $Call (@Calls) {
			open PIPE, "$Call |";
			while (<PIPE>) {
				next if (/(Nothing to be done for|Entering directory|Leaving directory) \S+\.?$/o);
#				releasables split on whitespace - quotes possible -stripped out
				while (/("([^"\t\n\r\f]+)"|([^ "\t\n\r\f]+))/go) {
					my $Releasable=($2 ? $2 : $3);
					$Releasable =~ s/\//\\/g;	# convert forward slash into backslash
					unless ($WhatCheck{$Releasable}) {
						$WhatCheck{$Releasable}=1;
						if ($Options{what}) {
							print "$Releasable\n";
						}
						else {
							if (!-e $Releasable) {
								print STDERR "MISSING: $Releasable\n";
							} 
							# modified start: added functionality checkwhat
							elsif ($Options{checkwhat}) {						 
								print "$Releasable\n";
							}
							# modified end: added functionality checkwhat
						}
					}
				}
			}
			close PIPE;
		}
	}
}

sub Usage () {
	print <<ENDHERESTRING;
Common usage : abld [test] command [options] [platform[.Feature Variant]] [build] [program]
  where command is build, target, etc.
    (type \"abld help commands\" for a list of commands)
  where options are -c, -k, etc.
    (type \"abld help options\" for a list of options)
  where parameters depend upon the command
    (type \"abld help <command>\" for command-specific help)
  where parameters default to 'ALL' if unspecified
ENDHERESTRING

	print
		"project platforms:\n",
		"   @Platform::Plats\n"
	;

	if (%Platform::FeatureVariantSupportingPlats)
		{
		my @featureVariants;
			
		foreach my $featureVariantSupportingPlat (keys %Platform::FeatureVariantSupportingPlats)
			{
			push @featureVariants, $featureVariantSupportingPlat.".".$_ foreach (featurevariantparser->GetValidVariants());
			}

		if (@featureVariants)
			{
			@featureVariants = map{uc($_)} @featureVariants;
			print
				"feature variant platforms:\n",
				"   @featureVariants\n";		
			}
		}
	exit 1;
}

# modified start: added functionality checkwhat
sub Options () {
	print <<ENDHERESTRING;
Options (case-insensitive) :
  -c or -check          check the releasables are present
  -cw or -checkwhat     combined check and what
  -k or -keepgoing      build unrelated targets on error
  -s or -savespace      delete intermediate files on success
  -v or -verbose        display tools calls as they happen
  -w or -what           list the releasables
  -r or -remove         allow FREEZE to remove exports
  -i thumb or -i arm    override for build ARMV5 platform options
  -cs or -checksource   checks source conformance to Symbian's filename policy
  -debug or -no_debug   enable/disable generation of symbolic debug information for ARM ABI compliant platforms
  -fc or -logfc	        enable function call logging
  -wrap[=proxy]         enable invocation of external wrapper tool

 possible combinations :
	(([-check]|[-what]|[-checkwhat])|([-k][-s][-v][-i [thumb|arm]][-cs][-debug|-no_debug][-fc][-wrap[=proxy]]))
ENDHERESTRING

	exit;
	
}
# modified end: added functionality checkwhat

sub Help ($) {
	my ($Command)=@_;

	my %CommandHash=%{$Commands{$Command}};

	print 'ABLD';
	unless ($CommandHash{notest}) {
		print ' [test]';
	}
	print " $Command ";
	if ($Command eq 'HELP') {
		print '([OPTIONS|COMMANDS]|[<command>])';
	}
	else {
		if ($CommandHash{what}) {
			print '(([-c]|[-w])|';
		}
		if ($CommandHash{savespace}) {
			print '[-s]';
		}
		if ($CommandHash{instructionset}) {
			print '[-i thumb|arm]';
		}
        if ($CommandHash{remove}) {
			print '[-r]';
		}
        if ($CommandHash{checksource}) {
			print '[-cs]';
		}
		unless ($CommandHash{nokeepgoing}) {
			print '[-k]';
		}
		unless ($CommandHash{noverbose}) {
			print '[-v]';
		}
		if ($CommandHash{debug}) {
			print '[-debug|-no_debug]';
		}
		if ($CommandHash{logfc}) {
			print '[-logfc]|[-fc]';
		}
		if ($CommandHash{what}) {
			print '))';
		}
		unless ($CommandHash{noplatform}) {
			print ' [<platform>]';
		}
		if ($CommandHash{build}) {
			print ' [<build>]';
		}
		if ($CommandHash{program}) {
			print ' [<program>]';
		}
		if ($CommandHash{source}) {
			print ' [<source>]';
		}
		if ($CommandHash{wrap}) {
			print '[-wrap[=proxy]]';
		}
	}

	print
		"\n",
		"\n",
		"$CommandHash{function}\n"
	;
	exit;
}

sub Commands () {

	print "Commands (case-insensitive):\n";
	foreach (sort keys %Commands) {
		next if ${$Commands{$_}}{hidden};
		my $Tmp=$_;
		while (length($Tmp) < 12) {
			$Tmp.=' ';
		}
		print "  $Tmp ${$Commands{$_}}{function}\n";
	}

	exit;
}

sub GetMakefileVariations ($$)
	{
	my ($plat, $featureVariantArg) = @_;
	my @variations = ();

	if (!$featureVariantArg)
		{
		push @variations, "";
		}
	else
		{
		my @resolvedVariants = featurevariantparser->ResolveFeatureVariant($featureVariantArg);
# modified start: makefile improvement
		my %temp_hash =("default" => "");
		foreach (@resolvedVariants){
			$temp_hash{$_}="";
		}
			push @variations, ".".$_ foreach (keys %temp_hash);
		}
# modified end: makefile improvement
	return \@variations;
	}


