#!/usr/bin/perl

use strict;
use warnings;

# Read the input text from STDIN
my $input_text;
{
    local $/;
    $input_text = <STDIN>;
}

# Process the input text
my $processed_text = process_text($input_text);

# Print the processed text
print $processed_text;

sub process_text {
    my ($text) = @_;

    # Regular expression for matching the tree declarations
    my $pattern = qr{
        %tree\s*
        (?:%static|%heap)?\s*
        %name\s+(\w+)\s*
        (?:(%parent\s+(\w+)\s*)?)?
        %value\s+([^\s%]+)\s*
        (?:(%left\s+(\w+)\s*)?)?
        (?:(%right\s+(\w+)\s*)?)?
        \.
    }sx;

    # Replace occurrences of the specified syntax with C variable initializations
    $text =~ s/$pattern/instantiate_tree("$1", "$2", "$3", "$4", "$5", "$6", "$7", "$8")/eg;

    # Return the processed text
    return $text;
}

sub instantiate_tree {
    my ($name, $storage, $parent, $value, $left, $right) = @_;

    # Determine the variable type and storage specifier
    my ($type, $storage_specifier) = ($storage eq '%heap') ? ('TREEPP_PTR', 'TREEPP_ALLOC') : ('TREEPP_STATIC', 'TREEPP_NOALLOC');

    # Generate the variable initialization code
    my $initialization_code = <<INIT_CODE;
$type $storage_specifier $name = TREEPP_INIT(
    $parent,
    $value,
    $left,
    $right
);
INIT_CODE

    return $initialization_code;
}

