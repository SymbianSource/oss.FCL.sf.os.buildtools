use FindBin;
use lib "$FindBin::Bin";
use LWP::UserAgent;
use Getopt::Long;

my($tcl_delta_cache, $log_dir, $product, $number);

GetOptions (
   'tcl_delta_cache=s' => \$tcl_delta_cache,
   'log_dir=s'         => \$log_dir,
   'product=s'         => \$product, 
   'number=s'          => \$number,
   'version=s'		   => \$ver_dp_tools # like DP00562
);

my $full_ver_latest_green = '';
# if user doesn't specify the detail dp tools build number throught the parameter "-version"
# auto connect to intweb service to get latest green build number list
unless( defined($ver_dp_tools) )
{
	# Alternative method of getting the BRAG status - use the HTTP interface to Autobuild
	my $parameters = "product=$product&number=$number";
	my $sLogsLocation = "http://intweb:8080/esr/query?$parameters";
	my $roUserAgent = LWP::UserAgent->new;
	my $roResponse = $roUserAgent->get($sLogsLocation);
	my $ver_info = $roResponse->content;
	print "--------------------Retrieve build and brag information-------------------------\n";
	print "$ver_info\n";
	print "--------------------------------------------------------------------------------\n";
	my @lst_ver = ();
	while ($ver_info =~ m/snapshot\s+=\s+dp.*/gi)
	{
		$ver = $&;
		push(@lst_ver, $ver);
	}

	my @lst_brag = ();
	while ($ver_info =~ m/==\s+brag\s+=.*/gi)
	{
		$brag = $&;
		push(@lst_brag, $brag);
	}

	my $scalar_lst_brag = @lst_brag;
	my $index;
	for($index = 0; $index < $scalar_lst_brag; $index++)
	{
		if($lst_brag[$index] =~ /green/i)
		{
			last;
		}
	}

	my $ver_latest_green;
	if($index == $scalar_lst_brag)
	{
		print "No green build found for DP Tools! Build will be terminated!\n";
		exit 0;
	}
	else
	{ 
		if($lst_ver[$index] =~ /(dp.*)/i)
		{
			$ver_latest_green  = $1;
			print "Found green dp build: $ver_latest_green\n";
		}
	}
	$full_ver_latest_green = "$ver_latest_green"."_DeveloperProduct";
}
else
{
	# use the build number specified by users 
	$full_ver_latest_green = "$ver_dp_tools"."_DeveloperProduct";
	print "Use specified dp build: $ver_dp_tools\n";
}

my $unzip_exe = "$tcl_delta_cache\\DP\\master\\sf\\dev\\hostenv\\dist\\unzip-5.40\\unzip.exe";
my $cbr_tools_zip = "\"\\\\builds01\\devbuilds\\DeveloperProduct\\$full_ver_latest_green\\SF_Package\\CBR tools_windows.zip\"";
my $cmd_unzip_cbr_tools = "$unzip_exe -o $cbr_tools_zip > $log_dir\\cbrtools_unzip.log";
print "unzip command: $cmd_unzip_cbr_tools\n";

print "Unzip the zip package of cbr tools from the server \"builds01\"\n";
system($cmd_unzip_cbr_tools);
print "check the detailed of unzip process from cbrtools_unzip.log\n";