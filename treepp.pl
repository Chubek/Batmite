#!/usr/bin/perl

use strict;
use warnings;

my $PREFIX = "TREEPP";

while (<STDIN>) {
    chomp;  # Remove newline character
    my $processed_line = process_line($_);
    print "$processed_line\n";
}

sub process_line {
    my ($line) = @_;

    if (my ($name, $storage, $parent, $value, $left, $right) = parse_line($line)) {
        $storage //= "%heap";
        $parent  //= "NULL";
        $left    //= "NULL";
        $right   //= "NULL";

        return instantiate_tree($name, $storage, $parent, $value, $left, $right);
    }

    return $line;
}

sub parse_line {
    my ($line) = @_;

    if ($line =~ /^\s*%tree\s*(?:%(\w+)\s*)?%name\s+(\w+)\s*(?:%parent\s+(\w+)\s*)?%value\s+([^\s%]+)\s*(?:%left\s+(\w+)\s*)?(?:%right\s+(\w+)\s*)?$/) {
        return ($2, $1, $3, $4, $5, $6);
    }

    return;
}

sub substitute_storage {
    my ($storage) = @_;
    return $storage eq "static" ? "$PREFIX" . "_STATIC" : "";
}

sub substitute_type {
    my ($storage) = @_;
    return $storage eq "heap" ? "$PREFIX" . "_PTR" : "$PREFIX" . "_NONPTR";
}

sub substitute_initfunc {
    my ($storage) = @_;
    return $storage eq "heap" ? "$PREFIX" . "_ALLOC" : "$PREFIX" . "_NONALLOC";
}

sub instantiate_tree {
    my ($name, $storage, $parent, $value, $left, $right) = @_;

    return substitute_storage($storage) . ' ' . substitute_type($storage) . ' ' . "$name = " .
           substitute_initfunc($storage) . "($parent, $value, $left, $right);";
}

