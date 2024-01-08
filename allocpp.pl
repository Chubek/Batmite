#!/usr/bin/perl

use strict;
use warnings;

my @c_program;

sub process_line {
    my ($line) = @_;

    if ($line =~ /^#(alloc|realloc)\s*(?:%(\w+))?\s*(\w+)\s*\((.*?)\)\s*$/) {
        my $directive = $1;
        my $lexical_scope = $2 || "global";
        my $identifier = $3;
        my $arguments = $4;

        if ($directive eq 'alloc') {
            handle_alloc($lexical_scope, $identifier, $arguments);
        } elsif ($directive eq 'realloc') {
            handle_realloc($lexical_scope, $identifier, $arguments);
        }
    } else {
        push @c_program, $line;
    }
}

sub handle_alloc {
    my ($lexical_scope, $identifier, $arguments) = @_;
    # Callback for alloc
    print "Alloc directive in $lexical_scope scope: $identifier, $arguments\n";
}

sub handle_realloc {
    my ($lexical_scope, $identifier, $arguments) = @_;
    # Callback for realloc
    print "Realloc directive in $lexical_scope scope: $identifier, $arguments\n";
}

# Read from STDIN line by line
while (my $line = <STDIN>) {
    chomp $line;
    process_line($line);
}

# Print the entire C program
print "\nC Program:\n";
print join("\n", @c_program), "\n";

