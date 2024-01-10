# This is free and unencumbered software released into the public domain.
#
# Anyone is free to copy, modify, publish, use, compile, sell, or distribute
# this software, either in source code form or as a compiled binary, for any
# purpose, commercial or non-commercial, and by any means.
#
# In jurisdictions that recognize copyright laws, the author or authors of
# this software dedicate any and all copyright interest in the software to
# the public domain. We make this dedication for the benefit of the public
# at large and to the detriment of our heirs and successors. We intend this
# dedication to be an overt act of relinquishment in perpetuity of all
# present and future rights to this software under copyright law.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
# THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
# IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
# CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#
# For more information, please refer to <http://unlicense.org/>


use strict;
use warnings;

sub process_here_string {
    my $lhs = shift;
    my $input = shift;

    # Replace newlines with '\n' literal
    $input =~ s/\n/\\n/g;

    # Escape double quotes
    $input =~ s/"/\\"/g;

    return "$lhs = \"$input\";\n";
}

# Read the input file or use STDIN
my $file_name = shift || '-';
open my $fh, '<', $file_name or die "Cannot open file: $!";

# Process each here-string and preserve other text
my $output = '';
my $current_lhs = '';
my $current_text = '';
while (my $line = <$fh>) {
    if ($line =~ /([a-zA-Z_][a-zA-Z_0-9* ]+)\s*=\s*<<<\s+END_(\w+)_STR/) {
        # Process the previous text
        $output .= $current_text if $current_text;

        my $lhs = $1;
        my $end_tag = "END_$2_STR";
        my $here_str = '';
        while (my $here_line = <$fh>) {
            last if $here_line =~ /\b$end_tag\b/;
            $here_str .= $here_line;
        }
        my $processed_str = process_here_string($lhs, $here_str);
        $output .= $processed_str;

        # Reset current_text and current_lhs
        $current_text = '';
        $current_lhs = '';
    } else {
        # Preserve other text
        $current_text .= $line;

        # Capture preceding LHS
        $current_lhs = $1 if $line =~ /^(\w+)\s*=/;
    }
}

# Append any remaining text
$output .= $current_text if $current_text;

close $fh;

# Output the processed content
print $output;

