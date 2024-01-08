#!/usr/bin/env perl

use strict;
use warnings;
use Data::Dumper;

sub parse_opcode_pp {
    my ($input) = @_;
    my %opcodes;

    while ($input =~ /^\%\s*([A-Z]+)\s*of\s*(.*?)\s*;/g) {
        my $opcode_name = $1;
        my $operand_list = $2;

        if (defined $opcode_name) {
            my @operands = parse_operand_list($operand_list);
            $opcodes{$opcode_name} = \@operands;
        }
    }

    return \%opcodes;
}

sub parse_operand_list {
    my ($operand_list) = @_;
    my @operands;

    while ($operand_list =~ /\s*([a-z]+)\s*(?:\*\s*([a-z]+)\s*)*/g) {
        push @operands, $1;
        push @operands, $2 if defined $2;
    }

    return @operands;
}

sub traverse_opcodes {
    my ($opcodes) = @_;

    for my $opcode_name (keys %$opcodes) {
        my $operands_ref = $opcodes->{$opcode_name};
        my @operands = @$operands_ref;

        print "Opcode: $opcode_name\n";
        print "Operands: ", join(', ', @operands), "\n";
        print "\n";
    }
}

# Read lines from stdin and parse
while (my $line = <STDIN>) {
    $line =~ s/^\s+//;
    next if $line =~ m/^--\s+.*$/;
    my $opcodes = parse_opcode_pp($line);
    print Dumper($opcodes);
    traverse_opcodes($opcodes);
}

