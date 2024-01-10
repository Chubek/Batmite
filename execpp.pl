#!/usr/bin/perl

use strict;
use warnings;

while (my $line = <>) {
    chomp $line;
    my $command;
    my $result;

    if ($line =~ /(.*?)<:(.*?) :>/) {
	print $1;
	$command = $2;
	$command =~ s/:>//;
	$command =~ s/<://;
        $result = `$command`;
        print $result;
    } else {
        print $line;
    }
}

