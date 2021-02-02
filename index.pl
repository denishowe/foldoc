#!/usr/bin/perl

# CGI program to search the Free On-line Dictionary of Computing.
# Invoked as 404 handler via symlink not-found.cgi.

# Denis Howe <dbh@doc.ic.ac.uk>
# 1999-11-10 - 2018-04-08

# SET REQUEST_URI=Charles+W.+Bachman& SET QUERY_STRING=debug& perl index.cgi
# HTTP_HOST=foldoc.org REQUEST_URI=/ABCL%2fc%2b QUERY_STRING=debug perl index.cgi

# ############################################################################################### #
# Dictionary, keys, offsets and contents are in same
# directory as this program.  Make it the current directory.

BEGIN
{
	$_ = $0; s|/*[^/]*$||;
	chdir $_ or die "$!: $_" if ($_);
}

use strict;
use warnings;
use lib ".";
use Foldoc;

$| = 1;

# When handling a 404 the query string is passed
# in the REQUEST_URI but not in the QUERY_STRING

$_ = $ENV{REQUEST_URI} || "";
$_ .= "?$ENV{QUERY_STRING}" if (($ENV{QUERY_STRING} || "") ne "");

# Maybe redirect and exit or leave $_ as query term

debug "URL:", $_;

# Test: http://wombat.doc.ic.ac.uk/foo  --> foldoc.org/foo
if ($ENV{HTTP_HOST} && $ENV{HTTP_HOST} ne $server_name || check_redirect($_))
{
	s|^/*|$root_url/|
		unless (/^http/);
	# 301 permanent redirect is better for search engine optimisation
	print "Location: $_\nStatus: 301 Moved Permanently\n\n";

	exit 0;
}

# $_ is now decoded query term
debug "Query ($_)";

home() if ($_ eq "home-page");			# Special case - exits

my $query = $_;

our $off_fh;
open $off_fh, $offsetfile or die "\nCan't open $offsetfile: $!";
our $dic_fh;
open $dic_fh, $dictionary or die "\nCan't open $dictionary: $!";

my ($min, $max);
# Test: http://foldoc.org/random-entry
if ($query eq "random-entry")
{
	# Different versions of different browsers require one or other
	# of these.  Apache translates "Expires: 0" to current time.
	$ENV{HEADERS} = "Expires: 0\nPragma: no-cache\nCache-Control: no-cache\n";
	$ENV{HTMLCOMMENTBOX} = 0;			# No comments on /random-entry URL
	srand;
	$min = $max = int(rand($num_entries));
}
else
{
	# This causes Firefox to cache, whatever other headers we give
	$ENV{HEADERS} = "Last-Modified: " . last_modified() . "\n";
	$ENV{HTMLCOMMENTBOX} = 1;
	($min, $max) = find_entries($query);
}
debug "Min ", $min, "  Max ", $max;

# If a query matched a single entry which contains nothing but
# a cross-reference then print the referenced entry instead.

my $via;
# Test: http://foldoc.org//
# Test: http://foldoc.org/3GL
if ($min == $max)
{
	$query = nthhead($dic_fh, $off_fh, $min);
	# Read entry from after heading up to next heading
	my $entry = "";
	$entry .= $_ while (defined($_ = <$dic_fh>) && /^\s/);

	# Is entry just a reference to a target entry that exists?
	my @target = target_entry($entry);
	if (@target == 1)
	{
		my $t = $target[0];
		my ($newmin, $newmax) = find_entries($t);
		debug "target_entry '$entry' -> '$t' -> (", $newmin, ",", $newmax, ")";
		if ($newmin <= $newmax)			# Target entry exists
		{
			$min = $newmin; $max = $newmax;
			$via = $query;				# Note how we got here
			# Change title for single hit
			$query = nthhead($dic_fh, $off_fh, $min);
		}
	}
}

# Print the hits if any

my $query_url = text2url($query);
my $elsewhere = qq{
<p>
Try this search on
<a href="http://www.wikipedia.org/wiki/Special:Search?search=$query_url">Wikipedia</a>,
<a href="http://www.onelook.com/cgi-bin/cgiwrap/bware/dofind.cgi?word=$query_url">OneLook</a>,
<a href="http://www.google.com/search?q=define:$query_url">Google</a>
</p>
};

$ENV{URL} = "$root_url/$query_url";
my $query_html = text2html($query);
my $index;
if ($min > $max)	# No hits
{
	# Test: http://foldoc.org/queezil
	$ENV{STATUS} = "404 No match";	# Add 404 header
	$ENV{TITLE} = "No match for $query_html";
	$ENV{CONTENT} = qq{<p>Sorry, the term <em>$query_html</em> is not in the dictionary.  Check
the spelling and try removing suffixes like "-ing" and "-s".</p>

<p><a href="/?Missing definition">Why is this definition missing?</a></p>
};
}
else				# One or more hits
{
	$ENV{STATUS} = "200 OK";
	$ENV{TITLE} = "$query_html from FOLDOC";
	$ENV{CONTENT} = "";
	for $index ($min .. $max)
	{
		seeknth($dic_fh, $off_fh, $index); # Position dictionary at hit
		$ENV{CONTENT}
			.= (defined($via) && "<h3>$via &#8669;</h3>\n")
			. foldoctohtml($dic_fh);		# Entry as HTML
	}
}
$ENV{CONTENT}
	.= '<p class="vertical-space"></p>'
	. listneighbors($min)
	. $elsewhere;

close $off_fh;
close $dic_fh;

print template();

exit 0;

##################################################################

# Return some headings before and after INDEX

sub listneighbors
{
	my ($index) = @_;

	my ($len, @a) = 0;
	# Add term after, before, 2 after, 2 before, ...
	for (my $offset = 0; $len < 60; $offset = ($offset > 0 ? 0 : 1) - $offset)
	{
		my $i = $index+$offset;
		next unless (0 <= $i && $i < $num_entries);
		my $h = nthhead($dic_fh, $off_fh, $i);
		$len += max(length($h), 3) + 1;
		$h = anchor($h);
		$h = "<b>$h</b>" unless ($offset);
		$offset < 0 ? unshift @a, $h : push @a, $h;
	}
	my $neighbours = join " &diams; ", @a;

	return qq{<h3>Nearby terms:</h3>
<p class="neighbours">
$neighbours
</p>
};
}


# Serve home page, previously built by Makefile
# from home.inc.html and template.html, and exit

sub home { serve("home.html") }			# Exits


# Output $page and exit

sub serve
{
	print file_contents(@_);

	exit 0;
}


sub min
{
  $_[0] < $_[1] ? $_[0] : $_[1];
}

sub max
{
  $_[0] < $_[1] ? $_[1] : $_[0];
}
