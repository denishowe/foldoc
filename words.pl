#!/usr/bin/perl

# Search for words in a word list

# Denis Howe 2011-05-31 - 2012-10-18 14:07

# http://foldoc.org/words.pl?t.*ia$

use strict;
use warnings;

my $file = "words.txt";
my $google = "https://www.google.co.uk/search?q=";

# ############################################################################ #

print "Content-type: text/html\n\n";

unless (open W, $file)
{
	print "Can't read $file: $!"; exit 0;
}
$_ = do { local $/; <W> };
close W;
my @w = split /\n/, $_;

my $re = $ENV{QUERY_STRING} || "";
$re =~ s/.*=//;
$re =~ s/%(..)/chr hex $1/eg;
print qq{<html><head><title>Words matching $re</title></head>
<body>
<form style="font-size: large">
  <b>RE</b>
  <input name="r" type="text" value="$re" style="width: 90%; font-size: large">
  <input type="submit" value="Find Words" style="font-size: large">
</form><p>
};
if ($re)
{
	print q{
<b>Matches:</b>
<p>
}, map("<a href=\"$google$_\">$_</a><br>\n", grep /$re/gm, @w),
	q{
</body>
};
}
