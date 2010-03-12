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
# This script scans through the changes submitted on the specified codeline, within the range specified, and detects all changes involving a Defect Fix 

# Renaming Parameters  
$Codeline=$ARGV[0];
$OldNumber=$ARGV[1];
$NewNumber=$ARGV[2];
$query="$Codeline\@$OldNumber,$NewNumber";

system("p4 changes $query >changes.tmp");
@changes;
open(TMP,"changes.tmp");
while(<TMP>)
{
    $_=split /\s+/,$_;
    push @changes, $_[1];
}
close(TMP);

#print @changes;
    

foreach $i(@changes){
        system("p4 describe -ds -s $i >>description.tmp");
	open(DES,">>description.tmp");
	print DES "\n\n";
	close(DES);
    }


open(DES,"description.tmp");
$FileFlag=0;
while(<DES>)
{
    if ($_ =~/^Change\s(\d+)\s/){
	@ChangeInfo=split /\s+/,$_;
	$CurrentChange=$ChangeInfo[1];
	}
    
    if ($_=~/([A-Z][A-Z][A-Z]-)/){		#V4 defects
	print "$CurrentChange\n";
	print $_;
    }
	
    if ($_=~/([a-zA-Z]{3}\d{4,6})/){		#TeamTrack defects
 	print "$CurrentChange\n";
 	print $_;
    }
 

}


close(DES);
close(TMP);
system("del description.tmp");
system("del changes.tmp");
