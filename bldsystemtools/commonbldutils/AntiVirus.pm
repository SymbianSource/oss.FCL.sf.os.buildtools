package AntiVirus;
use strict;

use File::Copy;
use Win32::Process;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw{Start Stop Scan WaitTillAntiVirusStarts};

# Start:
# Description: attempts to start all supported anti-virus services/processes
# Revised April 2007 to support McAfee only, Sophos and WebRoot having passed into history!
# Arguments: none
# Returns: none
sub Start()
{
    my @iMcAfeeCommands = (
    {AppName => 'net.exe', Params => 'start McAfeeFramework'},
    {AppName => 'net.exe', Params => 'start McShield'},
    {AppName => 'net.exe', Params => 'start McTaskManager'},
    # Must supply full pathname, as these applications are not in "PATH"
    {AppName => 'C:\\Program Files\\Network Associates\\Common Framework\\UpdaterUI.exe', Params => '/StartedFromRunKey'},
    {AppName => 'C:\\Program Files\\Network Associates\\Common Framework\\UdaterUI.exe', Params => '/StartedFromRunKey'},
    {AppName => 'C:\\Program Files\\McAfee\\Common Framework\\UpdaterUI.exe', Params => '/StartedFromRunKey'},
    {AppName => 'C:\\Program Files\\McAfee\\Common Framework\\UdaterUI.exe', Params => '/StartedFromRunKey'},
    {AppName => 'C:\\Program Files\\Common Files\\Network Associates\\TalkBack\\tbmon.exe', Params => ''},
    {AppName => 'C:\\Program Files\\Network Associates\\VirusScan\\SHSTAT.EXE', Params => '/STANDALONE'},
    {AppName => 'C:\\Program Files\\McAfee\\VirusScan\\SHSTAT.EXE', Params => '/STANDALONE'});

    # Execute all "START" commands
    for my $iCmd(@iMcAfeeCommands)
    {
        ExecuteProcess(20,$iCmd);
    }

}

# WaitTillAntiVirusStarts
# Description:  
# Sometimes the  Antivirus::Stop() is invoked before the Antivirus services are started in the machine.
# because of which the Antivirus starts when the build is ongoing, and the active Antivirus disrupts/slows down the build
# 
# If the Antivirus services fail to start beyond the specified timeout period,reports error and aborts the build.
#
# Arguments : Waiting time in seconds before next attempt is made to check AV service status, max number of attempts
# Returns   :  returns nothing if AV running, aborts build if AV not running even after the waiting period
sub WaitTillAntiVirusStarts{
    my $waitingTime  = shift;
    my $retries      = shift;
	
	my @waitList      = shift;
     
    my $defaultWaitingTime  = 30;  # Waiting time in seconds, before next attempt is made to check AV service status
    my $defaultRetries      = 5;   # Try upto 5 times
    
    # assign default values to waitingtime,retries if values not specified
    unless($waitingTime)
	{
        $waitingTime = $defaultWaitingTime;
    }
    unless($retries)
	{
        $retries = $defaultRetries;
    } 
	
    my $attempt = 0; 
    ## If AV not active, wait and retry
    while(1)
	{ 
        if(IsAntiVirusActive(@waitList))
		{
            return; ## AV is active, all fine, proceed
        }
        $attempt++;
        if($attempt > $retries) 
		{
            last;
        } 
        print  "REMARK: One or more Antivirus services not active yet (At ".scalar localtime().") \n";
        print  "Waiting $waitingTime secs before rechecking status (Attempt $attempt of $retries) ...\n\n";
        sleep($waitingTime);        
    } 
    
    ## Antivirus is not active even after waiting $waitingTime secs $retries times, report error and abort the build
    
    print "ERROR: RealTimeBuild : Antivirus is not active even after waiting for $waitingTime secs x $retries attempts\n";
    print "Antivirus cannot be reliably stopped,abandon build.";
}


# IsAntiVirusActive
# Description:  
# Runs 'net start' command to get a list of active services,checks if the Antivirus services are in the list
# 
# Arguments : None
# Returns   : 
# 			returns 0  even if one Antivirus Service is inactive
# 			returns 1 if All AntiVirus Services active
sub IsAntiVirusActive{

	my @waitList = shift;
	
    my @AntiVirusServices = @waitList;

    print "Checking Antivirus services status ...\n"; 
    my $iCmd={AppName => 'net.exe', Params => 'start'};
    
    # Check if net.exe is accessible
    unless(-e $iCmd->{'AppName'})
    {
       my $iExecutable = FindFileFromPath($iCmd->{'AppName'});
        unless ($iExecutable)
        {
            print "REMARK: File not found $iCmd->{'AppName'}\n";
            print "REMARK: Unable to check Antivirus status\n";
            return 0; 
        }
        $iCmd->{'AppName'} = $iExecutable;
    }
 
    my $iCommand = "\"$iCmd->{'AppName'}\" $iCmd->{'Params'}" ;
    print "Running: $iCommand\n";
    my @iOutput = `$iCommand`;
	 
    return &ParseServiceStatus(\@iOutput,\@AntiVirusServices);
}


# ParseServiceStatus
# Description:  
# Runs  Compares output of 'net start' command to get a list of active services,checks if the Antivirus services are in the list
# 
# Arguments : Output of 'net start', Antivirus service list
# Returns   : 
# 			returns 0  even if one Antivirus Service is not in the list
# 			returns 1 if All AntiVirus Services are in the list
sub ParseServiceStatus($$)
{
    my $iOutputRef = shift;
    my $iAntiVirusServiceList = shift;
    foreach(@$iOutputRef) 
    {
        chomp ;
        s/^[\t\s]+//g;  # strip whitespace at the beginning of the line
    } 
	
    for my $serviceName(@$iAntiVirusServiceList) 
    { 
        my @match = grep (/^$serviceName$/i, @$iOutputRef); 
        unless(@match)
		{
            print "Antivirus Service \'$serviceName\' inactive\n";
            return 0;
        }
    }
    print "All Antivirus services active.\n";  
    return 1;  
}


# Stop:
# Description: attempts to stop all supported anti-virus services/processes
# Revised April 2007 to support McAfee only, Sophos and WebRoot having passed into history!
# Arguments: none
# Returns: none
sub Stop($$)
{
	# Need to check if the Antivirus services is installed or enabled.
	my @iMcAfeeServices = (
    {AppName => 'net.exe', Params => 'stop McAfeeFramework', Services =>'McAfee Framework Service'},
    {AppName => 'net.exe', Params => 'stop McShield', Services =>'Network Associates McShield'},
    {AppName => 'net.exe', Params => 'stop McTaskManager', Services =>'Network Associates Task Manager'});

	my @iPskillCommands = (    
    {AppName => 'pskill.exe', Params => 'UpdaterUI.exe'},
    {AppName => 'pskill.exe', Params => 'tbmon.exe'},
    {AppName => 'pskill.exe', Params => 'shstat.exe'});

	my @waitList = ();
	my @iMcAfeeCommands = ();

	for my $iTestCmd(@iMcAfeeServices)
	{  	
		my $iExecutable = $iTestCmd->{'AppName'};
		my $iParams = $iTestCmd->{'Params'};
		my $iServices = $iTestCmd->{'Services'};

		my @testCommand = `$iExecutable $iParams 2>&1`;   
		my $iResponse = 0;     

		foreach my $iLine (@testCommand) 
		{
			if ($iLine =~ m/does not exist/i)
			{ 
				print "REMARK: $iServices not installed, just proceed.\n";
				$iResponse = 1;	 
			} 

			if ($iLine =~ m/it is disabled/i)
			{ 
				print "REMARK: $iServices not enabled, just proceed.\n";
				$iResponse = 1;            
			} 

			if (($iLine =~ m/service is not started/i ) or ($iLine =~ m/not valid for this service/i ))
			{  
				print "REMARK: $iServices not started, just wait.\n";
				push @waitList, $iServices;
				push @iMcAfeeCommands, {AppName =>$iExecutable, Params =>$iParams};
				$iResponse = 1;
			}

			if ($iLine =~ m/service was stopped successfully/i)
			{ 
				print "REMARK: Stop Success! $iServices was stopped successfully directly by the test command, just proceed.\n";
				$iResponse = 1;			
			}	
			
			if ($iLine =~ m/service could not be stopped/i)
			{ 
				print "REMARK: Stop Success! $iServices could not be stopped at the moment but will be stopped successfully directly by the test command very soon later, just proceed.\n";
				$iResponse = 1;			
			}
            
            if ($iLine =~ m/System error 5 has occurred/i)
			{ 
				print "WARNING: Access to $iServices is denied, but this won't affect the build, just proceed.\n";
				$iResponse = 1;			
			}
			
		}    
		unless ($iResponse)
		{
			print "ERROR: Unable to parse the output of $iExecutable for $iParams!\n";
			foreach my $iLine (@testCommand) 
		    {
				print $iLine;
			}
			#push @waitList, $iServices;
		    #push @iMcAfeeCommands, {AppName =>$iExecutable, Params =>$iParams};
		}
	}

    # Wait for the waiting Antivirus services to load before attempting to stop the services
	# If Antivirus fails to load after the grace period, the build should be aborted.
	my $gWaitingTime = shift;
	my $gRetries = shift;
	if (@waitList)
	{
		WaitTillAntiVirusStarts($gWaitingTime, $gRetries, @waitList); 
	}
	
	# Execute all "STOP" commands
	push @iMcAfeeCommands, @iPskillCommands;
	for my $iCmd(@iMcAfeeCommands)
	{
		ExecuteProcess(20,$iCmd);
	}
}

# Scan:
# Description: performs the virus scan on the specified directores
# Revised April 2007 to support McAfee only, Sophos having passed into history!
# Revised February 2008 to support further McAfee filename changes.
# Arguments: directory in which to place scan output file (logfile);
# array ref to array containing a list of the directories to scan
# Returns: none
sub Scan($$)
{
    my $iOutFilesDir = shift;
    my $iDirsToScan = shift;

    # Name(s) of output files. User only supplies directories
    my $iOutFileName = 'Anti-virus';

    # Define McAfee commands, newest version first. McAfee keep changing the names of their files. Thus if an
    # executable is not found, we do not treat this as an error, we simply go on to thwe next command definition.
    # Note: Must supply full pathname, as these applications are not in "PATH"
    my @iMcAfeeCommands =(
    # CSScan.exe send most of its output to STDOUT. So define file a second time for us to write this data
    {AppName => 'C:\\Program Files\\McAfee\\VirusScan Enterprise\\csscan.exe',
     Params => join(" ", @$iDirsToScan) . " /SUB /CLEAN /ALLAPPS /LOG $iOutFilesDir\\$iOutFileName.log",
     LogFile => "$iOutFilesDir\\$iOutFileName"},  # Filename without .LOG extension
    {AppName => 'C:\\Program Files\\Common Files\\Network Associates\\Engine\\scan.exe',
     Params => join(" ", @$iDirsToScan) . " /SUB /NOBREAK /CLEAN /NORENAME /RPTCOR /RPTERR /REPORT=$iOutFilesDir\\$iOutFileName.log",
     LogFile => ''} # The older "SCAN.EXE" writes everything to its report file. So no further logging required.
    );
   
    print "Scanning: @$iDirsToScan\n"; 

    # Execute "SCAN" commands in order until one is successful.
    for my $iCmd(@iMcAfeeCommands)
    {
            # First remove/rename any existing output file. This is an unlikely situation in a normal build;
            # but it could cause confusion if, for example, a scan was re-run manually.
            unless (RemoveExistingFile($iCmd->{'LogFile'})) { next; }
            if (RunCommand($iCmd)) { return; }     # Success
    }
    # Arriving at the end of this loop means that no command succeeded! Report failure!
    print "WARNING: No Virus Scan accomplished. Possibly no suitable executable found.\n";
}

# RunCommand:
# Description: Runs specified command using Perl "backticks"
# passing its output for parsing to the sub ParseOutput().
# Arguments: the command to execute as a hashref (filename of executable and parameters/args to pass to it)
# Returns: TRUE on success
sub RunCommand($)
{
    my $iCmd = shift;   # Hashref - Command spec.
  
    unless(-e $iCmd->{'AppName'})
    {
        print "REMARK: File not found $iCmd->{'AppName'}\n";
        return 0;    # FALSE = Failure
    }
    my $iCommand = "\"$iCmd->{'AppName'}\" $iCmd->{'Params'}" ;
    print "Running: $iCommand\n";
    my @iOutput = `$iCommand`;
    
	# Parse the output flagging any errors
    return &ParseOutput(\@iOutput,$iCmd->{'LogFile'});  # Return TRUE or FALSE
}

# ParseOutput:
# Description: Parse output for warnings and errors.
# The ScanLog-compatible "WARNING: " is prepended to any line containing
# any of these messages or errors, and all lines are printed to STDOUT.
# Arguments: reference to the array of output lines from executed command; Name of logfile (if any)
# Returns: TRUE on Success
# Remarks: note that errors in starting/stopping processes or services do not
# constitute errors in terms of the build process. Failure to start or stop
# the services will not affect the compilation except, at worst, to slow it
# down if stopping the antivirus fails.
sub ParseOutput($)
{
    my $iOutputRef = shift;
    my $iLogFile = shift;

    my $fh = \*LOGFILE;

    if($iLogFile)
    {
        unless (open $fh, ">>$iLogFile.log")
        {
            print ("WARNING: Failed to open log file: $iLogFile");
            return 0;   # FALSE = Failure
        }
    }
    else
    {
        $fh = \*STDOUT;
    }

    for my $line(@$iOutputRef) # For each line of output...
    {
        $line =~ s/\s+$//;     # Remove trailing spaces (McAfee CSSCAN pads each line to 1024 chars!!)
        # Does it match an error as returned by PSKill or net stop/start
        if($line =~ /The specified service does not exist as an installed service\./i or
           $line =~ /The .*? service is not started\./i or
           $line =~ /The requested service has already been started./i or
           $line =~ /The service name is invalid\./i or
           $line =~ /Process does not exist\./i or
           $line =~ /Unable to kill process/i or
           $line =~ /error/i or
           $line =~ /is not recognized as an internal or external command/i)
        {
            print "WARNING: $line\n";
        }
        else # No errors/warnings so just print the line on its own
        {
            print $fh "$line\n";
        }
    }
    return 1;   # TRUE = Success
}

# ExecuteProcess:
# Description: Executes specified command using Perl module Win32::Process
# Arguments: the command to execute as a hashref (filename of executable and parameters/args to pass to it)
# Returns: none
sub ExecuteProcess
{
    my $iWaitSecs = shift;
    my $iCmd = shift;           # Hashref - Command spec.
  
    my $iExecutable = $iCmd->{'AppName'};
    unless(-e $iExecutable)
    {
        $iExecutable = FindFileFromPath($iCmd->{'AppName'});
        unless ($iExecutable)
        {
            print "REMARK: File not found $iCmd->{'AppName'}\n";
            return; 
        }
    }
    my $iParams = $iCmd->{'Params'};

    #  my $iFlags = $iDebug? CREATE_NEW_CONSOLE: DETACHED_PROCESS;
    #  my $iFlags = $iDebug? 0: DETACHED_PROCESS;
    my $iFlags = 0;

    # Create a new Perl process (because fork does not work on some versions of Perl on Win32)
    # $^X is the path to the Perl binary used to process this script
    my $iProcess;
    unless (Win32::Process::Create($iProcess, "$iExecutable", "\"$iExecutable\" $iParams", 0, $iFlags, "."))
    {
        print "WARNING: Failed to create process for $iExecutable $iParams.\n";
        my $iExitCode = Win32::GetLastError();
        ReportProcessError($iExitCode);
        return;
    }

    my $iPID = $iProcess->GetProcessID(); 
    print "\nExecuting: $iExecutable $iParams .....\n";
    my $iRetVal = $iProcess->Wait($iWaitSecs * 1000);      # milliseconds. Return value is zero on timeout, else 1.
    if ($iRetVal == 0)    # Wait timed out
    {   # No error from child process (so far)
        print "Spawned: $iExecutable $iParams - PID=$iPID.\n";
        return 1;       # Success
    }
    else          # Child process terminated. Wait usually returns 1.
    {             # Error in child process?? If so, get exit code
        my $iExitCode;
        $iProcess->GetExitCode($iExitCode);
        unless($iExitCode)
        {
            print "Executed: $iExecutable $iParams - PID=$iPID.\n";
            return 1;           # Success
        }
        print "REMARK: Failed in execution of $iExecutable $iParams.\n";
        ReportProcessError($iExitCode);
        return 0;
    }
}

# ReportProcessError:
# Description: prints error code to STDOUT followed by explanatory text, if avalable
# Arguments: Windows error code
# Returns: none
sub ReportProcessError
{
    my $iExitCode = shift;

    my $iMsg = Win32::FormatMessage($iExitCode);
    if (defined $iMsg)
    {
        printf "ExitCode: 0x%04x = %s\n", $iExitCode, $iMsg;
    }
    else
    {
        printf "ExitCode: 0x%04x\n", $iExitCode;
    }
}

# FindFileFromPath:
# Description: Tries to find a file using PATH Environment Variable
# Argument: Filename (Must include extension .EXE, .CMD etc)
# Return: Full pathname of file, if found, otherwise undef
sub FindFileFromPath
{
    my $iFilename = shift;
    my $iPathname;
    my @iPathDirs = split /;/, $ENV{'PATH'};
    foreach my $iDir (@iPathDirs)
    {
        while ($iDir =~ s/\\$//){;}     # Remove any trailing backslash(es)
        $iPathname = "$iDir\\$iFilename";
        if (-e $iPathname)
        {
            return $iPathname;
        }
    }
    return undef;
}

# RemoveExistingFile:
# Description: If specified .LOG file exists, rename to .BAK
# Arguments: File to check
# Returns: TRUE on Success
sub RemoveExistingFile
{
    my $iFilename = shift;       # Full pathname LESS extension

    unless (-e "$iFilename.log") { return 1; }  # Success!

    if (File::Copy::move("$iFilename.log","$iFilename.bak")) { return 1; }  # Success!

    print "WARNING: Failed to rename $iFilename.log\nto $iFilename.bak because of:\n$!\n";
    return 0;   # FALSE = Failure
}

1;
