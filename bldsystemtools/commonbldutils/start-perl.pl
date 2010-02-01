# Copyright (c) 2004-2009 Nokia Corporation and/or its subsidiary(-ies).
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
# Program to start a perl script that may run for more than 5 second in a new console
# and return to the caller.
# 
#

use strict;
use Carp;
use Getopt::Long qw{:config pass_through};
use Win32::Process;
my %cpus_to_clients = (2 => 4,
                       4 => 4,
                       8 => 8,
                      16 => 16);

my $n = ProcessCommandLine();

if($n == 0)
{
  exit LaunchCommand(@ARGV);
}
else # $n should be 2, 4 or 8 in this case
{
  my $max = $cpus_to_clients{$n};
  my @exit_codes;
  
  # Now create $max processes. 
  for my $i(1..$max)
  {
    # Make a copy of the initial arg so we can use the # as a placeholder
    # for the client number.
    my @updated_args = @ARGV;
    
    # Update each argument, replacing # with $i; should only be one "#"
    for my $arg(@updated_args)
    {
      $arg =~ s/#/$i/;
    }
    
    push @exit_codes, LaunchCommand(@updated_args); # Push the exit code onto the array.
  }
  
  # Now process the exit codes. If one is non-zero exit with that code.
  # If all are zero exit with 0.
  for my $ec(@exit_codes)
  {
    if($ec != 0)
    {
      exit $ec; 
    }
  }
  
  exit 0;
}

################################################################################
# LaunchCommand                                                                #
# Inputs: List of arguments to pass to perl exe                                #
# Outputs: Exit code of perl process, if it exits within 5 seconds; 0 if not   #
################################################################################
sub LaunchCommand
{
  my @argv = @_;
  print "Starting @argv\n";
  # Create the process
  Win32::Process::Create(my $proc, "$^X", "$^X @argv", 0, CREATE_NEW_CONSOLE, ".") || croak "ERROR: start @argv :$!";

  my $ret = $proc->Wait(5000);      # milliseconds. Return value is zero on timeout, else 1.
  if ($ret == 0)    # Wait timed out
  {                 # No error from child process (so far)
    print "@argv Started\n";
    return 0;
  }
  else              # Child process terminated. Wait usually returns 1.
  {                 # Error in child process?? Get exit code
    my $exitcode;
    $proc->GetExitCode($exitcode);
    if ($exitcode != 0)
    {
      printf "ERROR: @argv failed to start. Exit Code: 0x%04x.\n",$exitcode;
    }
    return $exitcode;
  }
}

################################################################################
# ProcessCommandLine                                                           #
# Inputs: None                                                                 #
# Returns: if specified on the command line, the number of processors;         #
#          otherwise 0 - this indicates that traditional usage of start-perl.  #
# Remarks: If the number of processors is not defined in hash %cpus_to_clients #
#          return an "intelligent guess"                                       #
################################################################################
sub ProcessCommandLine
{
    my ($help, $num_of_cpus);
    GetOptions('h' => \$help, 'n=s' => \$num_of_cpus);
    if (($help)) # Help 
    {
        Usage();
    }
    elsif(defined($num_of_cpus)) # Check that the number of clients is valid
    {
	  unless(defined $cpus_to_clients{$num_of_cpus})
	  {
		  # Report if the number is not valid.
		  my @iValidList = sort {$a <=> $b} keys %cpus_to_clients;
		  printf "ERROR: Argument -n $num_of_cpus not valid. Must be one of: %s.\n", join (', ', @iValidList);
		  
		  # Then try to guess appropriate number:
		  my $cpus = 0;
		  $cpus = 2 if ($num_of_cpus < 4);
		  $cpus = 4 if ($num_of_cpus > 4 && $num_of_cpus < 8);
		  $cpus = 8 if ($num_of_cpus > 8);
		  print "...choosing valid number: $cpus\n";
		  return $cpus;
	  }
      return $num_of_cpus; # Return number if valid
    }
    else ## i.e if(!defined($num_of_cpus))
    {
      return 0;
    }
}

################################################################################
# Usage                                                                        #
# Inputs: None                                                                 #
# Outputs: Usage information for the user.                                     #
# Remarks: None                                                                #
################################################################################
sub Usage
{
    print <<USAGE_EOF;

Usage: start-perl.pl [Parameters]
  start-perl.pl -n %NUMBER_OF_PROCESSORS% %CleanSourceDir%\\os\\buildtools\\bldsystemtools\\buildsystemtools\\BuildClient.pl -d localhost:15011 -d localhost:15012 -d localhost:15013 -w 5 -c Core#
  start-perl.pl %CleanSourceDir%\\os\\buildtools\\bldsystemtools\\buildsystemtools\\BuildClient.pl -d localhost:15011 -d localhost:15012 -d localhost:15013 -w 5 -c Core1
  
  Either start the command with -n <number of processors> followed by a perl script
  usually BuildClient.pl. In this case the -c argument to BuildClient will be used
  as a place holder and the # will be replaced by either 4 or 8.
  
  The script is backwards compatable with its previous usage.

USAGE_EOF
    exit 1;
}
