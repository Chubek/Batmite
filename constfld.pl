#!/usr/bin/perl

use strict;
use warnings;

my @operations;

while (<>) {
    next if /^\s*--/;
    my ($arity, $opcode, $name) = parse_operation($_);
    push @operations, { arity => $arity, opcode => $opcode, name => $name } if defined $arity;
}

foreach my $op (@operations) {
    print "Arity: $op->{arity}, Opcode: $op->{opcode}, Name: $op->{name}\n";
}

sub parse_operation {
    my ($input) = @_;

    my ($arity, $opcode, $name) = (undef, undef, undef);

    if ($input =~ /^(\s*OperationArity\s+Opcode\s+OperationName\s*)$/) {
        $arity = parse_operation_arity($1);
        $opcode = parse_opcode($1);
        $name = parse_operation_name($1);
    }

    return ($arity, $opcode, $name);
}

sub parse_operation_arity {
    my ($input) = @_;

    if ($input =~ /\b(%unary|%binary)\b/) {
        return $1;
    }

    return undef;
}

sub parse_opcode {
    my ($input) = @_;

    if ($input =~ /\bIdentifier\b/) {
        return $1;
    }

    return undef;
}

sub parse_operation_name {
    my ($input) = @_;

    if ($input =~ /\b(&addition|&subtraction|&multiplication|&division|&modulo|&assign|&logical_and|&logical_or|&bitwise_and|&bitwise_or|&bitwise_xor|&left_shift|&right_shift|&equal_to|&not_equal_to|&greater_than|&less_than|&greater_than_or_equal_to|&less_than_or_equal_to|&unary_plus|&unary_minus|&logical_not|&bitwise_not|&pre_increment|&pre_decrement|&address_of|&dereference)\b/) {
        return $1;
    }

    return undef;
}

