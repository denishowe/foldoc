#!/usr/bin/perl

# Search for words in a word list

# Denis Howe 2011-05-31 - 2026-06-12

# http://foldoc.org/words.pl?tri.*bia$

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
print qq{<html><head><title>Words matching $re</title>
<style>
body { font-size: 2em; }
input, button { font-size: 2em; padding: 0.5em; }
a { font-size: 1em; }
</style>
</head>
<body>
<form>
  <b>RE</b>
  <input name="r" type="text" value="$re" style="width: 90%;">
  <input type="submit" value="Find Words">
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
