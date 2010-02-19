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
# Script to generate a html report giving basic info on build.
# It needs to be run in the context of a build client, otherwise
# it would not generate the complete report as it uses the ENV
# variables for most of the information.
# 
#

use strict;
use FindBin;
use lib "$FindBin::Bin";
use PC_P4Table;

use Getopt::Long;


my $iClientSpec = $ENV{CurrentCodeline} . "/".$ENV{Platform}."/generic/utils/".$ENV{Platform}."_clientspec.txt";

&PC_P4Table::generateHTMLSummary($ENV{SnapshotNumber},
				 $ENV{Product},
				 $ENV{ChangelistNumber},
				 $iClientSpec);


