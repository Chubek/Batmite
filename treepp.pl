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

    my $pattern = qr{
        ^%tree\s*
        (?:%static|%heap)?\s*
        %name\s+(\w+)\s*
        (?:(?:%parent\s+(\w+)\s*)?)?
        %value\s+([^\s%]+)\s*
        (?:(?:%left\s+(\w+)\s*)?)?
        (?:(?:%right\s+(\w+)\s*)?)?$
    }sx;

    $line =~ s/$pattern/instantiate_tree("$1", "$2", "$3", "$4", "$5", "$6", "$7", "$8")/e;

    return $line;
}

sub handle_default {
    my ($variable, $default) = @_;
    return defined($variable) && $variable =~ /\S/ ? $variable : $default;
}

sub substitute_storage {
    my ($storage) = @_;
    return $storage eq "%static" ? "$PREFIX" . "_STATIC" : "";
}

sub substitute_type {
    my ($storage) = @_;
    return $storage eq "%heap" ? "$PREFIX" . "_PTR" : "$PREFIX" . "_NONPTR";
}

sub substitute_initfunc {
    my ($storage) = @_;
    return $storage eq "%heap" ? "$PREFIX" . "_ALLOC" : "$PREFIX" . "_NONALLOC";
}

sub instantiate_tree {
    my ($name, $storage, $parent, $value, $left, $right) = @_;

    $storage = handle_default($storage, "%heap");
    $parent  = handle_default($parent, "NULL");
    $left    = handle_default($left, "NULL");
    $right   = handle_default($right, "NULL");

    return substitute_storage($storage) . ' ' . substitute_type($storage) . ' ' . "$name = " .
           substitute_initfunc($storage) . "($parent, $value, $left, $right);";
}

