#!/usr/bin/env perl

use strict;
use warnings;

my %instruction_map;

while (my $line = <STDIN>) {
    chomp($line);

    # Ignore comment lines
    next if $line =~ /^\s*--/;

    # Parse instruction lines
    if ($line =~ /\S/) {
        my ($opcode, $types) = parse_instruction($line);
        if (defined $opcode) {
            $instruction_map{$opcode} = $types;
        } else {
            warn("Error parsing line: $line\n");
        }
    }
}

# Print the parsed instruction map
print "Parsed Instructions:\n";
foreach my $opcode (sort keys %instruction_map) {
    my $types_str = join(', ', @{$instruction_map{$opcode}});
    print "$opcode: Types: [$types_str]\n";
}

sub parse_instruction {
    my ($line) = @_;

    # Regular expression patterns for components
    my $opcode_pattern    = qr/([a-zA-Z_]\w*)/;
    my $group_pattern     = qr/([a-zA-Z_]\w*)/;
    my $type_list_pattern = qr/(%(?:i8|i16|i32|i64|u8|u16|u32|u64|f32|f64|string|memloc|none)(?:\s*,\s*%(?:i8|i16|i32|i64|u8|u16|u32|u64|f32|f64|string|memloc|none))*)/;

    if ($line =~ /^$opcode_pattern(?:\s+$group_pattern)?\s+\|\|\s+$type_list_pattern;$/) {
        my ($opcode, $group, $types_str) = ($1, $2, $3);
        my @types = split(/\s*,\s*/, $types_str);
        @types = map { s/%//r } @types;  # Remove '%' from each type
        return ($opcode, \@types);
    }

    return;
}

