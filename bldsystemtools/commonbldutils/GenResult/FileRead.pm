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
#

#!/usr/bin/perl -w
package FileRead;
use strict;
##########################################################################
#
# Name    :  file_read()
# Synopsis:  Reads in the contents of a file into an array
# Inputs  :  Filename
# Outputs :  array
#
##########################################################################
sub file_read
{
    my ($filename) = @_;

    local($/) = undef;
    local(*FILE);
 
    open(FILE, "<$filename") || die "open $filename: $!";
    my @slurparr = <FILE>;
    close(FILE) || die "close $filename: $!";

    return $slurparr[0];
}

1;