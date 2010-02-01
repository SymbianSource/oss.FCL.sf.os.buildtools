#!perl -w
# This script reads data from specified Windows Event Logs and writes the information to a file
# Output is ScanLog-compatible. First this script establishes a time range by reading the specified Build Log.
# For info. on Win32::EventLog, see "Win32 Perl Programming" Page 171 et seq.
use FindBin;
use Sys::Hostname;
use Win32;
use Win32::EventLog;
use Getopt::Long;
use strict;
# For Date calculations
{
no warnings;
use lib "$FindBin::Bin/../buildsystemtools/lib"; # For running in source
}
use Date::Manip;

# Set TimeZone because Date:Manip needs it set and then tell it to IGNORE the TimeZone
&Date_Init("TZ=GMT","ConvTZ=IGNORE");

# Check if HiRes Timer is available
my $gHiResTimer = 0; #Flag - TRUE if HiRes Timer module available
if (eval "require Time::HiRes;") {
  $gHiResTimer = 1;
} else {
  print "Cannot load HiResTimer Module\n";
}

# Capture the name of this script for Help display etc.
$0 =~ m/([^\\]+?)$/;
my $gThisFile = $1;
# Process command line

my ($gComputer, $gBuildLogstart, $gBuildLogend, $gOutLogFile, @gEventSourcesUser) = ProcessCommandLine();
$gComputer = (defined $gComputer)? uc $gComputer: hostname();

# Open logfile, if specified
my $gOutLogHandle = \*OUTLOGFILE;
if (defined $gOutLogFile)
{
    open ($gOutLogHandle, ">$gOutLogFile") or die "Failed to open $gOutLogFile";
    my $iTime = gmtime(time);
    PrintStageStart(0,"Windows Event Log Extracts",$gThisFile);
    print "Logfile: $gOutLogFile  Opened: $iTime\n";
    print $gOutLogHandle "Output file: $gOutLogFile  Opened: $iTime\n";
}
else
{
    $gOutLogHandle = \*STDOUT;
    PrintStageStart(0,"Windows Event Log Extracts",$gThisFile);     # Start logging Generic Info. as pseudo Build Stage
    print "Logging to STDOUT\n";
}
print $gOutLogHandle "Data extracted from Windows Event Logs for Computer: $gComputer\n";

# Establish time range. Get build start  time from specified Build Log file.
unless (defined $gBuildLogstart)
{
    my $iMsg = "No Build Log specified";
    print $gOutLogHandle "ERROR: $iMsg\n";
    PrintStageEnd(0);     # Stop logging Generic Info.
    Usage("$iMsg");
}

unless (defined $gBuildLogend)
{
    my $iMsg = "No Build Log specified";
    print $gOutLogHandle "ERROR: $iMsg\n";
    PrintStageEnd(0);     # Stop logging Generic Info.
    Usage("$iMsg");
}


my ($gStartSecs, $gStopSecs) = GetTimeRange($gBuildLogstart, $gBuildLogend);

unless (defined $gStartSecs)
{
    my $iMsg = "Invalid Build Log: $gBuildLogstart";
    print $gOutLogHandle "ERROR: $iMsg\n";
    PrintStageEnd(0);          # Stop logging Generic Info.
    Usage("$iMsg");
}

# Establish time range. Get build  end time from specified Build Log file.
# Determine which Event Logs are to be read. Default is "All three". Specifying one only is really a debug convenience.
my @gEventSourcesDefault = ('Application','Security','System');
my @gEventSources;
if (@gEventSourcesUser)  # Event Log(s) specified by user.
{
    foreach my $iSrcU (@gEventSourcesUser)
    {
        my $iOKFlag = 0;
        foreach my $iSrcD (@gEventSourcesDefault)
        {
            if (lc $iSrcU eq lc $iSrcD)
            {
                push (@gEventSources, $iSrcD);
                $iOKFlag = 1;
                last;
            }
        }
        unless ($iOKFlag)
        {
            my $iMsg = "Invalid Event Log Filename: $iSrcU";
            print $gOutLogHandle "ERROR: $iMsg\n";
            PrintStageEnd(0);     # Stop logging Generic Info.
            Usage("$iMsg");
        }
    }   # End foreach my $iSrcU (@gEventSourcesUser)

}
else    # Default to "All logs"
{
    @gEventSources = @gEventSourcesDefault;
}

PrintStageEnd(0);     # Stop logging Generic Info.

# Finally read the required Event Log(s)
$Win32::EventLog::GetMessageText = 1;   # Ensure that we get the message content from each Event Log entry.
for (my $iIndx = 0; $iIndx < @gEventSources; )
{
    my $iEventSource=$gEventSources[$iIndx];
    ++$iIndx;
    print "Reading Event Log: $iEventSource\n";
    ReadEventLog ($iIndx,$iEventSource);
}

close OUTLOGFILE;
exit (0);

# ReadEventLog
#
# Read from one Event Log and output to supplied logfile handle.
#
# Input: Stage Number, Event Log Name
#
# Output: ScanLog-compatible data to log file
#
sub ReadEventLog
{
    my $iStage = shift;         # Stage number.
    my $iEventSource = shift;   # Name of Event Log file.
    # First argument to "new Win32::EventLog()" may be "Application", "Security" or "System";
    my $iTotalEvents;
    my $iSeparator = "------------------------------------------------------------\n";
    PrintStageStart($iStage,"Windows $iEventSource Event Log Extracts",$gThisFile);

    my $iEventObject = new Win32::EventLog($iEventSource, $gComputer);

    unless ($iEventObject)
    {
        print $gOutLogHandle  "ERROR: Failed to open Event Log: $iEventSource\n";
        PrintStageEnd($iStage);
        return;
    }

    unless ($iEventObject->GetNumber($iTotalEvents))
    {
        print $gOutLogHandle  "ERROR: Cannot read Event Log: $iEventSource\n";
        PrintStageEnd($iStage);
        return;
    }

    unless ($iTotalEvents)    # Check number of events in log.
    {
        print $gOutLogHandle "No event recorded in $iEventSource Log.\n";
    }
    else
    {
        # Reading Flags: EVENTLOG_FORWARDS_READ, EVENTLOG_BACKWARDS_READ, EVENTLOG_SEQUENTIAL_READ, EVENTLOG_SEEK_READ
        my $iFlag = EVENTLOG_BACKWARDS_READ | EVENTLOG_SEQUENTIAL_READ;
        my $iRecNum = 0;     # Ignored unless $iFlag == EVENTLOG_SEEK_READ
        my $iStopFlag = 0;
        my $count = 0;
        while (!$iStopFlag)
        {
            my %iHash;
            unless ($iEventObject->Read($iFlag, $iRecNum, \%iHash))
            {
                $iStopFlag = 1;
            }
            else    # Successful "read"
            {
            my $iEventTime = $iHash{TimeGenerated};
            if ($iEventTime > $gStopSecs)
                { next; }
            if ($iEventTime < $gStartSecs)
                { last; }
            ++$count;
            print $gOutLogHandle $iSeparator;
            # Supported Event Types: EVENTLOG_ERROR_TYPE, EVENTLOG_WARNING_TYPE, EVENTLOG_INFORMATION_TYPE, EVENTLOG_AUDIT_SUCCESS, EVENTLOG_AUDIT_FAILURE
            my $iTxt;
            if ($iHash{EventType} == EVENTLOG_ERROR_TYPE)
                {$iTxt = 'Error'; }
            elsif ($iHash{EventType} == EVENTLOG_WARNING_TYPE)
                {$iTxt = 'Warning'; }
            elsif ($iHash{EventType} == EVENTLOG_INFORMATION_TYPE)
                {$iTxt = 'Information'; }
            elsif ($iHash{EventType} == EVENTLOG_AUDIT_SUCCESS)
                {$iTxt = 'Audit Success'; }
            elsif ($iHash{EventType} == EVENTLOG_AUDIT_FAILURE)
                {$iTxt = 'Audit Failure'; }
            else
                {$iTxt = "*unknown* [$iHash{EventType}]"; }
            print $gOutLogHandle "EventType: $iTxt  Source: $iHash{Source}  RecNum: $iHash{RecordNumber}\n";
            my $iTimeStr = gmtime($iHash{TimeGenerated});
            print $gOutLogHandle "TimeGen:   $iHash{TimeGenerated} ($iTimeStr)\n";
            print $gOutLogHandle "Computer:  $iHash{Computer}\n";
            print $gOutLogHandle "User:      $iHash{User}\n";
            print $gOutLogHandle "EventID:   $iHash{EventID}\n";
            print $gOutLogHandle "Category:  $iHash{Category}\n";
            $iTxt = (defined $iHash{Message})? $iHash{Message}: '*none*';
            print $gOutLogHandle "Message:   $iTxt\n";
            $iTxt = ($iHash{Strings})? $iHash{Strings}: '*none*';
            print $gOutLogHandle "Strings:   $iTxt\n";
            }
        }   # End while (!$iStopFlag)
        print $gOutLogHandle $iSeparator;
        print $gOutLogHandle "Events in specified time range = $count    Events in file = $iTotalEvents\n";
    }   # End unless ($iTotalEvents)
    PrintStageEnd($iStage);
}

# PrintStageStart
#
# Print to log file the ScanLog-Compatible lines to start a stage
#
# Input: Stage, Component Name [,Command Name]
#
# Output: Start time etc.
#
sub PrintStageStart
{
    my $iStage = shift;         # Stage number.
    my $iComponent = shift;     # e.g. Name of Event Log file.
    my $iCommand = shift;
    my $iTime = gmtime(time);
    print $gOutLogHandle "===-------------------------------------------------\n";
    print $gOutLogHandle "=== Stage=$iStage\n";
    print $gOutLogHandle "===-------------------------------------------------\n";
    print $gOutLogHandle "=== Stage=$iStage started $iTime\n";
    print $gOutLogHandle "=== Stage=$iStage == $iComponent\n";
    if (defined $iCommand)
    {
        print $gOutLogHandle "-- $iCommand\n";
    }
    print $gOutLogHandle "++ Started at $iTime\n";

    if ($gHiResTimer)
    {
        print $gOutLogHandle "+++ HiRes Start ".Time::HiRes::time()."\n";
    }
}

# PrintStageEnd
#
# Print to log file the ScanLog-Compatible lines to end a stage
#
# Input: Stage
#
# Output: End time etc.
#
sub PrintStageEnd
{
    my $iStage = shift;         # Stage number.
    if ($gHiResTimer)
    {
        print $gOutLogHandle "+++ HiRes End ".Time::HiRes::time()."\n";
    }
    my $iTime = gmtime(time);
    print $gOutLogHandle "++ Finished at $iTime\n";
    print $gOutLogHandle "=== Stage=$iStage finished $iTime\n";
}

#sub GetTimeRange
#
# Establish start and end times for overall build
# Typical start line: === Stage=1 started Mon Oct  4 15:55:31 2004
# Typical end line:   === Stage=115 finished Tue Oct  5 01:47:37 2004
#
# Input: Name of Build Log File to read
#
# Output: Summary timing info to log file
#
# Return: Start/End times in seconds
#
sub GetTimeRange
{

    my ($iBuildLogstart,$iBuildLogend) = @_;

    my ($iStartTime, $iStopTime);
    
# $iStartTime Time read from $iBuildLogstart
    unless (open (INLOGFILE, "<$iBuildLogstart"))
    {
        print $gOutLogHandle "Failed to open input file: $iBuildLogstart\n";
        return undef, undef;
    }
    while(my $iLine = <INLOGFILE>)
    {
        chomp $iLine;
        unless (defined $iStartTime)
        {
            if ($iLine =~ m/^===\s+Stage=\S*\s+started\s+(.+)/)
                { $iStartTime = $1; last; }
        }
    }
    close INLOGFILE;

# $iStopTime Time read from $iBuildLogend

    unless (open (OUTFILE, "<$iBuildLogend"))
    {
        print $gOutLogHandle "Failed to open input file: $iBuildLogend\n";
        return undef, undef;
    }
    while(my $iLine = <OUTFILE>)
    {
        chomp $iLine;
        if (($iLine =~ m/^===\s(.*\s)?finished\s+(.+)/))
            { $iStopTime = $2; }
    }
    close OUTFILE;

    my $iDate = ParseDateString($iStartTime);
    my $iStartSecs = UnixDate($iDate,"%s");

    print $gOutLogHandle "Time range taken for Build start time from Build Log: $iBuildLogstart\n";
    print $gOutLogHandle "Earliest Event: $iStartTime\n\n";

    $iDate = ParseDateString($iStopTime);
    my $iStopSecs = UnixDate($iDate,"%s");

    print $gOutLogHandle "Time range taken for Build end time from Build Log: $iBuildLogend\n";
    print $gOutLogHandle "Latest Event: $iStopTime\n\n";

    my $iSecs = $iStopSecs - $iStartSecs;
    my $iMins = int ($iSecs/60);
    $iSecs %= 60;
    my $iHours = int($iMins/60);
    $iMins %= 60;
    printf $gOutLogHandle "--Time Range between the build START and FINISH:<< %d:%02d:%02d>>\n\n",$iHours,$iMins,$iSecs;

    return $iStartSecs, $iStopSecs;
}


# ProcessCommandLine
#
# Process Commandline. On error, call Usage()
#
# Input: None
#
# Return: Parameters as strings.
#
sub ProcessCommandLine
{

  my ($iHelp, $iComputer, $iBuildLogstart, $iBuildLogend , $iOutFile, @iEventSources);
  GetOptions('h' => \$iHelp, 'c=s' => \$iComputer, 'l=s' => \$iBuildLogstart,'k=s'=> \$iBuildLogend, 'o=s' => \$iOutFile, 's=s' => \@iEventSources);

  if ($iHelp)
  {
    Usage();
  }
  else
  {
    return ($iComputer, $iBuildLogstart, $iBuildLogend,$iOutFile, @iEventSources);
  }
}


# Usage: Display Help and exits script.
#
# Input: Error message, if any
#
# Output: Usage information.
#
# Return: Never returns. Exits with non-zero errorlevel
#
sub Usage
{
    if (@_)
    {
        print "\nERROR: @_\n";
    }

    print <<USAGE_EOF;

    $gThisFile:
      Reads the Windows Event Logs for the specified computer.
      The time range is established by reading the specified Build Log.
      ScanLog-compatible output is written to specified logfile.

    Usage: $gThisFile parameters [options]

    Parameters:
      -l  Build start Log file
      -k  Build End Log file

    Options:
      -h  Help
      -c  Computer name (defaults to local PC)
      -o  Logfile for output (defaults to STDOUT)
      -s  Event Log Source (defaults to "All")
          (Supported logs: "Application", "Security" or "System")


USAGE_EOF

    exit 1;
}

__END__
