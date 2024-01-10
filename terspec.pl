#!/usr/bin/perl

use strict;
use warnings;

my @raw_rules;
my $acc = "";
my $lhs = "";

for (<>) {
   next if m<^\s*-->;
   
  if (m/^\s*(.*)\s*=>(.*)$/) {
  	$lhs = $1;
	$acc .= $2;
   } elsif (m/^\s*\|\|(.*)\s*$/) {
	$acc .= "++" . $1;
   } elsif (m/^\s*;;\s*$/) {
	push @raw_rules, { "lhs" => $lhs, "rhs" => $acc };
	$acc = "";
	$lhs = "";
   }
}

sub parse_tree {
    my ($tree_str) = @_;

    if ($tree_str =~ /\s*([a-z]+)\s*/) {
        # Operand
        return {  type => "Operand",  value => $1 };
    } elsif ($tree_str =~ /\s*([A-Z]+)\s*/) {
        # Node
        return { type => "Node", value => $1 };
    } elsif ($tree_str =~ /\s*([A-Z]+)\((.+)\)\s*/) {
        # Stub
        my $inner_tree = parse_tree($1);
        return { type => "Inner", node => $inner_tree };
    } elsif ($tree_str =~ /\s*([A-Z]+)\((.+)\)\s*/) {
        # Tree with branches
        my $node_type = $1;
        my $branches_str = $2;
        my @branches = map { parse_tree($_) } split(/\s*,\s*/, $branches_str);
        return { type => "Tree", node_type => $node_type, branches => \@branches };
    } else {
        die "Invalid tree structure: $tree_str";
    }
}


sub parse_lhs {
  my ($lhs) = @_;

  return parse_tree($lhs);
}

sub parse_rhs {
    my ($rhs) = @_;

    my @rhs_parsed = ();

    for my $tree (split /\+\+/, $rhs) {
        my ($tree_str, $cost_str) = split /\s*(.*)\s+(\([0-9]+\))\s*/, $tree, 2;

        my $parsed_tree = parse_tree($tree_str);
        $parsed_tree->{cost} = $cost_str if defined $cost_str;

        push @rhs_parsed, $parsed_tree;
    }

    return @rhs_parsed;
}

use Data::Dumper;

foreach my $rule (@raw_rules) {
    my $lhs_parsed = parse_lhs($rule->{lhs});
    my @rhs_parsed = parse_rhs($rule->{rhs});

    print "LHS: ", Dumper($lhs_parsed), "\n";
    
    print "RHS:\n";
    for my $rhs_tree (@rhs_parsed) {
        print "  ", Dumper($rhs_tree), "\n";
    }
    print "\n";
}
