#!/usr/bin/perl

use strict;
use warnings;

my @parsed_rules;
my $lno = 0;

while (<>) {
    $lno++; 

    next if /^\s*--/;

    my ($lhs, $rhs) = /^\s*(.+)\s*=>\s*\{\{(.+)\}\}\s*$/;

    die "Error: wrong reduction rule at line $lno" unless defined $lhs && defined $rhs;

    push @parsed_rules, { lhs => parse_lhs($lhs), rhs => parse_rhs($rhs) };
}

sub parse_lhs {
    my ($lhs) = @_;

    return unless defined $lhs;

    if ($lhs =~ /([-a-zA-Z0-9=!^<>#|&"'%]+)/) {
        if ($1 =~ /([-a-zA-Z]+)/) {
            return { type => "SymbolicAtom", value => $1 };
        } elsif ($1 =~ /([0-9a-fA-F]+)/) {
            return { type => "LiteralNumericAtom", value => $1 };
        } elsif ($1 =~ /(\\#.+)/) {
            return { type => "LiteralCharAtom", value => $1 };
        } elsif ($1 =~ /(".+")/) {
            return { type => "LiteralStringAtom", value => $1 };
        } elsif ($1 =~ /([-+^=!<>#|&%]+)/) { 
            return { type => "OperatorAtom", value => $1 };
        } else { 
            return { type => "MiscAtom", value => $1 };
        }
    } elsif ($lhs =~ /(\(.+\))/) {                                 
        my @list;  
        foreach my $atom (split /\s+/, $1) {    
            push @list, parse_lhs($atom);
        }

        return { type => "List", value => \@list }; 
    } else {
        die "Error: wrong S-Expression given as LHS for rule at line $lno";
    }
}

