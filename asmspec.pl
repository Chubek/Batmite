#!/usr/bin/env perl

use strict;
use warnings;

# Global hashmap to store rules
my %rules;

while (my $line = <STDIN>) {
    chomp $line;

    # Ignore comments
    next if $line =~ /^\s*--/;

    # Parse and process rule
    if ($line =~ /^\s*%asm-cond/) {
        my ($opcode, $operands, $action) = parse_rule($line);
        if (defined $opcode) {
            $rules{$opcode} = { operands => $operands, action => $action };
        }
    }
}

# Print parsed rules
print "Parsed Specifications:\n";
foreach my $opcode (keys %rules) {
    print "Opcode: $opcode\n";
    my $operands = $rules{$opcode}->{operands};
    my $action   = $rules{$opcode}->{action};

    # Print each operand with its type
    for my $operand (@$operands) {
        my ($type, $value) = @$operand;
        print "  $type: $value\n";
    }

    print "Action: $action\n";
    print "------------------------\n";
}

sub parse_rule {
    my ($line) = @_;

    # Parse condition
    my ($opcode, $operands) = parse_condition($line);
    return unless defined $opcode;

    # Parse action
    my $action = parse_action($line);
    return unless defined $action;

    return ($opcode, $operands, $action);
}

sub parse_action {
    my ($line) = @_;

    return unless $line =~ /\{\{(.+?)\}\}/;
    return $1;
}

sub parse_condition {
    my ($line) = @_;

    return unless $line =~ /^\s*%asm-cond\s+(\w+)\s+(.+)\s+=>/;
    my $opcode      = $1;
    my $operand_str = $2;

    # Parse operand list
    my @operands = parse_operand_list($operand_str);
    return unless @operands;

    return ($opcode, \@operands);
}

sub parse_operand_list {
    my ($operand_str) = @_;

    my @operands;
    my @tokens = split /\s*,\s*/, $operand_str;

    foreach my $token (@tokens) {
        my $operand = parse_operand($token);
        return unless defined $operand;
        push @operands, $operand;
    }

    return @operands;
}

sub parse_operand {
    my ($token) = @_;

    return unless $token =~ /%reg|%imm/;

    my $type = $token =~ /%reg/ ? 'reg' : 'imm';
    my $value = $type eq 'reg' ? parse_register($token) : parse_immediate($token);

    return $value ? [ $type, $value ] : undef;
}


sub parse_register {
    my ($token) = @_;

    return $1 if $token =~ /^\s*%reg\s*\(\s*(\w+)\s*\)/;
}

sub parse_immediate {
    my ($token) = @_;

    return $1 if $token =~ /^\s*%imm(?:\s*\(\s*(\w+)\s*\)\s*)?/;
}

