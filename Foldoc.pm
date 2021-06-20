#!/usr/bin/perl

# Stuff used by FOLDOC search and build scripts

# Denis Howe 1997-12-21 - 2018-04-08

use strict;
use warnings;
use Data::Dumper;

use vars qw($dicbase $dictionary
	$keybase $keyfile $keylen $keyline $offsetbase $offsetfile
	$offsetlen $root_url $server_name $num_entries);

# Set the (virutal) hostname for this machine used in redirects
our $server_name = "foldoc.org";
our $root_url = "http://$server_name";		# No trailing /
for ($ENV{SERVER_PORT})
{
	$root_url .= ":$_" if ($_ && $_ ne "80"); # Natalie Kubler
}

# Find the URI for the directory containing this script
our $script_name = $ENV{SCRIPT_NAME} || '';
$_ = $script_name; s|/.*?$||;
our $home_dir_url = $root_url . $_;

our $dicbase	 = 'Dictionary';
our $dictionary	 = $dicbase;
our $keybase	 = 'keys';
our $keyfile	 = $keybase;
our $offsetbase	 = 'offsets';
our $offsetfile	 = $offsetbase;
our $keylen		 = 63;					# Excluding \n
our $keyline	 = $keylen + 1;			# Include \n
our $maxoffset   = 1E8-1;				# Must be > dictionary size
our $offsetlen	 = length $maxoffset;	# Digits in integer
our $offsetline	 = $offsetlen + 1;		# Include \n
our $num_entries = (-s $keyfile || 0) / $keyline;

# Format into which to insert RFC number to get URL - Thanks Dave Collins
our $rfc_url_fmt = "http://www.faqs.org/rfcs/rfc%s.html";

# Declare early so we can use it without ()

{
	my $debug; for ($ENV{QUERY_STRING}) { $debug = $_ && s/debug// }

sub debug
{
	my (@s) = @_;
	return unless ($debug);
	map {$_ = "UNDEF" unless defined($_)} @s;
	print "Status: 200\nContent-type: text/html\n\n" if ($debug++ < 2);
	print "D: @s\n";
}}

# Set $_ to the new (relative) URL and return true to redirect or set
# $_ to the query and return false.  Used for index.cgi and missing().

sub check_redirect
{
	($_) = @_;							# NOT local, set caller's $_

	s|^/||;								# Drop initial /
	debug "check_redirect", $_;

	# Redirect legacy URLs
	# Test: http://foldoc.org/index.cgi?xyzzy --> /?xyzzy
	# Test: http://foldoc.org/home.html		  --> /
	return 1 if (s/^index.cgi// + s/^home.html//);

	# Redirect to /pub/misc or /pub
	# Test: http://foldoc.org/x/dates --> /pub/misc/dates
	if (m!.+?/(.+)!)
	{
		my $f = "pub/misc/$1";
		if (-r $f) {$_ = $f; return 1}
	}
	# Test: http://foldoc.org/jokes --> /pub/jokes
	my $f = "pub/$_";
	if (length $_ > 2 && -r $f) {$_ = $f; return 1}

	# Redirect misc simple URLs
	return 1 if (s/denis-cv.html/Denis Howe CV.pdf/i);

	$_ = url2text($_);
	debug "url2text -> ($_)";

	# No query string
	# Test: http://foldoc.org/foo
	unless (s/.*\?(.)/$1/)
	{
		# Drop extra initial "/"s except /dev/null
		# Test: http://foldoc.org//Fairchild
		# Test: http://foldoc.org/%2fdev%2fnull
		s|^/+([^d])|$1| && return 1;
		# Drop trailing /s except "/", "s///"
		s|([^/])/$|$1| && return 1;
		$_ = "home-page" if ($_ eq "");
		return;
	}

	# Legacy query string parameters
	# Test: http://foldoc.org?query=foo&action=Search
	# Test: http://foldoc.org/?query=%2F&action=Search
	s/query=//;
	s/&action=.*//;

	# Empty query
	# Test: http://foldoc.org?query=&action=Search
	# Test: http://foldoc.org?query=0&action=Search
	return 1 if (! /\S/					# Redirect to home
	# Superfluous verbiage
	# Test: http://foldoc.org/what+does+%22foo%22+mean%3f
	  	|| s/what\s+(?:does\s+)?(.+)\s+mean.*/$1/i
	# Test: http://foldoc.org/what+is+a+foo%3f
		|| s/what\s+[i']s\s+(?:an?\s+)?(.+?)\??/$1/i
		|| s/^\s*"\s*(.+?)\s*"\s*$/$1/	# Quotes won't help
		|| s/([^?])\?$/$1/);			# Zap trailing "?"

	# Legacy action parameter
	# Test: http://foldoc.org/?action=Home
	# Test: http://foldoc.org/?action=Feedback
	# Test; http://foldoc.org/?action=Random
	my $action;
	if ($action = (/action=([^&]+)/)[0]
		and $action = {Home		=> "",
					   Feedback => "help.html",
					   Random   => "random-entry"}->{$action})
	{
		$_ = $action;
		return 1
	}

	# Query string --> URL path
	# Test: http://foldoc.org/?fo	--> /fo
	# Test: http://foldoc.org/?%25	--> /%
	# Test: http://foldoc.org/?%2F	--> //
	# Test: http://foldoc.org/?%3F	--> /?
  	# http://foldoc.org/?query=c%2Fc%2B%2B --> /C%2fC++
	$_ = text2url($_);

	return ($_ ne "");
}

# Return -1,0,1 if s1 comes before, same or after s2.  If $whole is
# false, truncate s1 to the length of s2 for each kind of comparison.
# If case is false always ignore case.  Note: "_" matches \w!

sub diccmp
{
	local($_);
	my ($s1, $s2, $whole, $case) = @_;

# If either string contains no alphanumeric characters,
# compare the original strings using normal ASCII collating

	if ($s1 =~ /\w/ && $s2 =~ /\w/)
	{

# Compare alphanumerics ignoring case

		# (my $ac1 = lc $s1) =~ s/\W//g;
		# (my $ac2 = lc $s2) =~ s/\W//g;
		# ?? $_ = cmpn($ac1, $ac2, $whole) and return $_;

# Compare ignoring internal non-alphanumerics and case

		(my $ac1 = lc $s1) =~ s/(?<=\w)\W+(?=\w)//g;
		(my $ac2 = lc $s2) =~ s/(?<=\w)\W+(?=\w)//g;
		$_ = cmpn($ac1, $ac2, $whole) and return $_;

# Same alphanumerics - compare non-alphanumerics

		(my $n1 = $s1) =~ s/\w//g;
		(my $n2 = $s2) =~ s/\w//g;
		$_ = cmpn($n1, $n2, $whole) and return $_;
	}
	else				# Force ASCII ordering
	{$s1 = lc $s1; $s2 = lc $s2; $case = 1};

# Compare case

	$case && cmpn($s1, $s2, $whole);
}

# Compare strings s1 and s2.  If whole is false then truncate s1 to
# the length of s2.

sub cmpn
{
	my ($s1, $s2, $whole) = @_;

	($whole ? $s1 : substr($s1, 0, length($s2))) cmp $s2;
}



# Compare the key of QUERY with the keys in the keys file.
# Return the indexes of first and last matching entry.

# Test cases:

# Don't treat "0" as false or undefined query

# "microsoft" should match "Microsoft", ignoring "Microsoft Access"

sub find_entries
{
	my ($query) = @_;

	my ($min, $max, $min_old, $max_old, $exact);

	# Normalise the query to match in the keys file.

	my $key = make_key($query);
	die "Empty key for query ($query)" unless (length $key);
	debug "Query ($query)  Key ($key)";

	# Check for initial special entries

	return (0, 0) if ($query =~ /^free on-line dictionary/i);
	return (1, 1) if ($query eq 'Acknowledgements');
	return (2, 2) if ($query =~ /missing.*def/i);

	# Perform binary search on (sorted) keys file.  $min
	# and $max are entry numbers in the keys and offsets
	# files both of which have fixed length lines.

	open my $KEY, $keyfile
		or die "\nCan't open $keyfile: $!";
	# Try for match without stemming first
	my $stemmed = 0;

binsrch:
	$min = 2;			# Skip Intro & Ack
	$max = $num_entries - 1;
	while ($max - $min > 1)
	{
		my $mid = int(($min + $max)/2);
		my $midkey = getkey($KEY, $mid)
			or return (2, 1);			# Error
		# Compare whole strings with case significant
		my $cmp = diccmp($midkey, $key, 1, 1);
		debug qq{$min $mid $max "$key" <=> "$midkey" -> $cmp};
		$min = $mid if ($cmp <= 0);
		$max = $mid if ($cmp >= 0);
	}
	$min_old = $min; $max_old = $max;

	# Try for case-sensitive match for whole string
	my $case = 1; my $whole = 1;

range:
	$min = $min_old; $max = $max_old;

	# Find the last non-matching key at or before $min

	while ($min >= 0)
	{
		last if (diccmp(getkey($KEY, $min), $key, $whole, $case));
		$min--;
	}

	# Find the first non-matching key at or after $max

	while ($max < $num_entries)
	{
		last if (diccmp(getkey($KEY, $max), $key, $whole, $case));
		$max++;
	}

	# Shrink to matching range, if any
	$min++; $max--;
	# $min..$max are now the numbers of the matching entries.
	debug("Case $case  Whole $whole  Stemmed $stemmed  Min $min  Max $max");

	# If no exact match, maybe try for case-insensitive prefix match for
	# "stem" of term

	if ($min > $max)							# No match
	{
		if ($case) {$case = 0; goto range}		# Try case-insensitive
		if ($whole) {$whole = 0; goto range}	# Try prefix match
		if (!$stemmed)							# Try stem
		{
			my $stem = singular($key);
			if ($stem ne $key)
			{
				$key = $stem;
				$stemmed = 1;
				goto binsrch;
			}
		}
		goto binsrch
			if ($key =~ s/\+//g);				# Double-encoded "+"?
	}
	close $KEY;

	return ($min, $max);
}



# Read an entry from file-handle $SOURCE, convert
# Denis's simple mark-up to HTML and return it

sub foldoctohtml
{
	my ($SOURCE) = @_;

	my $heading = <$SOURCE>; chomp $heading;
	$heading = "<h2>" . text2html($heading) . "</h2>";

	# Save all lines which begin with tab or newline (one article).

	my $article = '';
	my $preformatted = 0;
	while ($_ = <$SOURCE>, /^[\t\n]/)
	{
		# Concatenate lines into $article.

		s/^\t//;		# Strip one initial tab

		# Convert e-mail addresses, eg. <fred@foo.edu>
		# to {<fred@foo.edu> (fred@foo.edu)} which
		# will get converted to a link below.

		s/<([^<@>\s]+@[^<@>\s]+)>/{<$1>(mailto:$1)}/g unless (/^\s/);

		# Translate special characters to HTML.  This will
		# also happen inside cross-references but it's
		# simpler to do it globally here and fix xrefs later.

		$_ = text2html($_);

		# If more whitespace followed the initial
		# tab, mark the text as preformatted

		if (/^[ \t]/)		# Extra initial whitespace
		{
			if (! $preformatted)
			{
				$article .= "<pre>";
				$preformatted = 1;
			}
			# Temporarily change '{' to ^A in preformatted lines
			# to protect it from the transformations below.
			s/\{/\001/g;
		}
		elsif (/^$/)		   		# Formatted blank line becomes <p>
		{
			s|^$|<p></p>| unless ($preformatted);
		}
		else					   	# No extra whitespace - normal text
		{
			if ($preformatted)
			{
				$article .= "</pre>";
				$preformatted = 0;
			}
			# Protect quoted { from transforms below
			s/\\\{/\001/g;
			# Italicise subjects in <..> but not e-mail addresses
			s!^(\d+\. )?&lt;([^@]+?)&gt;!
				"<p>&lt;<i>" . subjects($2) . "</i>&gt;</p>\n<p>\n"
					. ($1 || "")!e;
			# Format date stamp
			s|^\((\d\d\d\d-\d\d-\d\d)\)|<p class="updated">Last updated: <a href="/new.html">$1</a></p>|;
		}
		$article .= $_;
	} # article
	$article .= "</pre>" if ($preformatted);

	seek $SOURCE, -length(), 1;	# Rewind to start of following heading

	# Transformations which may extend over multiple lines must be
	# done to the whole article.

	$_ = $article;

	# rfc:N pseudo URLs
	s|\{\(rfc:(.*?)\)\}|"{Full text (" . sprintf($rfc_url_fmt, $1) . ")}"|eg;

	# {TITLE (img:SRC)} all on one line
	s|\{(.*?)\(img:(.*?)\)\}|<figure><img src="$2" title="$1" /><figcation>$1</figcation></figure>|g;

	# An explicit external URL, eg.
	#
	#   {James Brule, 1985, "Fuzzy systems - a tutorial"
	#   (http://life.anu.edu.au/complex_systems/fuzzy.html)}
	#
	# becomes
	#
	#   <a href="http://life.anu.edu.au/complex_systems/fuzzy.html">
	#   James Brule, 1985, "Fuzzy systems - a tutorial"</a>.

	# s|\{\(ftp|{FTP(ftp|g;		# Label unlabelled FTP links
	# s|\{\(|{MORE(|g;			# Label unlabelled links

	# Newsgroup links -> Google groups
	s|\{news:([^}]+)\}|<a href="http://groups.google.com/group/$1">$1</a>|g;

	# External cross-refs with/out anchor text
	s|\{\(([^)]*)\)\}|<em><a href="$1">$1</a></em>|gi;
	s|\{([^}]*\S)\s*\(([^)]*)\)\}|<em><a href="$2">$1</a></em>|gi;

	# Transform "{Unix manual pages}: foo(7), bar(1)."
	s|^({Unix manual pages?}:) (.*?)\.$|$1 . ' ' . man_pages($2) . '.'|ems;

	# An internal cross-reference like
	#
	#   See also {AT&T}.
	#
	# becomes
	#
	#   See also <a href="?AT%26T">AT&amp;T</a>.
	#
	# The anchor() subroutine converts spaces to
	# %20 and quotes other HTML special characters
	s/\{([^}]+)\}/anchor($1)/eg;
	s/\001/{/g;							# Restore {
	s/\\\}/}/g;					    	# \} -> } for consistency
	s|__(.+?)__|<i>$1</i>|g;			# Italics

	return "$heading\n$_";				# Heading + body
}

# The argument is the entry body starting with a blank line immediately after
# a heading.  If it only contains cross-references, return its target(s).

sub target_entry
{
	local ($_) = @_;

	# Extract and delete all cross-references
	# alone on a line preceded by optional number
	my @targets;
	push @targets, $1
		while (s|^\t(?:\d+\.\s+)?\{([^()]+?)\}\.?$||m);
	# Return target(s) if nothing left but white

	return /\S/ ? () : @targets;
}

# Return an anchor which will display as the given string
# and which links to a query for that string.  Assume
# cross-ref like "{AT&T}" is HTML encoded as "AT&amp;T".
# Tranform this to <a href="/AT%26T">AT&amp;T</a>.

sub anchor
{
	local ($_) = @_;					# $_ used for URL

	my $label = text2html($_);			# Visible string
	s/\n/ /g;
	$_ = html2text($_);					# Restore "&amp;" etc.
	$_ = "/" . text2url($_);			# Encode as URL
	$_ = qq(<a href="$_">$label</a>);

	return $_;
}

# Return a line read from FILEHANDLE at OFFSET, without \n

sub line_at
{
    my ($fh, $offset) = @_;

	use Carp;
    seek $fh, $offset, 0
		or confess "Can't seek file $fh offset $offset: $!";
    my $line = <$fh>; return unless (defined $line);
    chomp $line;

    return $line;
}

# Normalise a dictionary heading or query for insertion as,
# or comparison with, a key in the keys file.  Preserve case
# since some entries differ only in case.  Preserve most
# punctuation as, e.g., several enties differ only by "/".

sub make_key
{
    local ($_) = shift;

    s/\s//g;							# Zap all whitespace
	s/(www\.)?(\w+)\.com/$2/i;			# Web site hostname as query
	s|(?<=\w)[-\',.\\_]+(?=\w)||g;		# Zap punctuation between alphanum

    return substr($_, 0, $keylen);		# Truncate
}

# Convert a comma and space separated list
# of man page references into anchors

sub man_pages
{
	return join ", ", map man_page($_), split /,\s*/, shift;
}

# Convert a man page reference like "inittab(5)" into an HTML anchor
# element with a URL like https://linux.die.net/man/5/inittab

sub man_page
{
	my ($page_ref) = @_;

	local ($_) = $page_ref;
	s/\((.*)\)//;						# $_ = name, $1 = section
	my $url = "https://linux.die.net/man/$1/$_";

	return "<a href=\"$url\">$page_ref</a>";
}

# Return query in a form more likely to match.  Only used if query
# doesn't match so it doesn't matter if we convert a term into a
# non-term.

sub singular
{
	local ($_) = @_;

	return $_ if (length $_ < 5			# Leave short words alone
				  && !/[A-Z]+s/);		# Except CPUs, URLs, RFCs

	$_ = lc $_;							# Scrap case

	# Singularise
	s/([^b])ies$/$1y/i;					# binaries, not newbies
	s/(h|ss|x)es$/$1/i;					# macintoshes, classes, boxes
	s/s$//i;							# computers

	# -ize etc.
	s/ize$/ise/i;
	s/ized$/ised/i;
	s/ization$/isation/i;

	return $_;
}

# Return a subject filename for SUBJECT

sub subjectfile
{
	local $_ = lc $_[0];

	s/\W+/-/g;

	return $_ . '.html';
}

# Mark up a list of subjects

sub subjects
{
	return join ', ',
		map('<a href="contents/' . subjectfile($_) . "\">$_</a>",
			split(/,\s*/, shift));
}

# Return the contents of $file

sub file_contents
{
	my ($file) = @_;

	local $/;
	open my $f, "<", $file or die "Can't read $file: $!";

	return <$f>;
}

# Substitute environment variables in contents of $template.  Process
# "set" and "if" ... "end" comments.  Write the result to $output_file
# or output to stdout with an HTTP header.  Return the result.

sub template
{
    my ($output_file, $template) = @_;

	$template ||= "template.html";
	# debug "Template", $template, "File", $output_file;

	# Set defaults for common variables
	my @t = localtime;
    my $date = sprintf "%04d-%02d-%02d %02d:%02d",
		1900+$t[5], $t[4]+1, $t[3], $t[2], $t[1];
	map $ENV{$_} ||= "", qw(
		STATUS HEADERS META_DESCRIPTION BOTTOM_ADS RIGHT_ADS);

	map { $ENV{$_->[0]} = $_->[1] if (! defined $ENV{$_->[0]}) }
		[SOURCE			=> $template],
		[URL			=> "$root_url/" . ($output_file || "")],
		[DATE      		=> $date],
		[NUM_TERMS 		=> $num_entries],
		[UPDATED   		=> last_modified()],
		[HTMLCOMMENTBOX => ($ENV{URL} || "") ne "$root_url/random-entry"];

	# Handle <!-- set VAR VALUE --> in content
	$ENV{CONTENT} =~
		s/<!--\s*set\s+(\w+)\s+(.*?)\s*-->\s*/$ENV{$1} = $2, ""/egs;

	my $output = file_contents($template);

	# Handle <!-- if VAR --> ... <!-- end VAR -->
	$output =~
		s/(\s*<!--\s*if\s+(\w+)\s+-->.*<!--\s+end\s+\2\s*-->\n)/$ENV{$2} ? $1 : ""/egs;

	# Substitute $VAR with $ENV{VAR}.  Allow for variable
	# references in substituted value but only one level.

	for (1..2)
	{
		$output =~ s/\$\{?([A-Za-z0-9_]+)\}?/
			defined $ENV{$1} ? $ENV{$1} : $&/eg;
	}

	if ($ENV{STATUS})					# Prepend header
	{
		$output = join "\n",
			"Status: $ENV{STATUS}",
			"Content-type: text/html; charset=utf-8",
			"Access-Control-Allow-Origin: *",
			$ENV{HEADERS},
			"",
			"$output";
	}
	if ($output_file)
	{
		open my $out, ">", $output_file
			or die "Can't write $output_file: $!";
		binmode $out;
		print $out $output;
		close $out;
		chmod 0444, $out				# Set output read-only
	}
    return $output;
}

# Encode string as a URL.  Odd chars -> %XX and space -> '+'.
# Don't encoded "/" or Apache will reject the request with a 404.

sub text2url
{
	local ($_) = @_;
	# SPC=040 "=042 #=043 %=045 &=046 +=053 <=074 >=076 ?=077
	s|([\000-\037\"\#%&+<>?\177-\377])|sprintf('%%%02x', ord($1))|eg;
	s/ /+/g;

	return $_;
}

# Expand URL-quoted characters in the query.  These are + for
# a space or %XX where XX is the ASCI hex character code.

# Treat + as space if there are letters somewhere before and after
# it and it's not in one of the following, not, e.g. ++ C++ F+L.

our %key_with_plus = map +($_ => 1), qw(
2B+D
AssociationofCandC++Users
C++Linda
Computer+ScienceNETwork
C++SIM
FGL+LV
F+L
Hope+C
Pascal+CSP
SASL+LV
);

sub url2text
{
	local ($_) = @_;

	unless ($key_with_plus{$_}) { 1 while (s/(\w.*)\+(.*\w)/$1 $2/g) }

	s/%([\da-f]{2})/chr(hex($1))/eig;

	return $_;
}

# Quote special HTML chars and foreign chars

sub text2html
{
	local($_) = $_[0];

	s/&/&amp;/g;
	s/&amp;(\w+;)/&$1/g;				# Unquote character entities
	s/</&lt;/g;
	s/>/&gt;/g;
	s/é/&eacute;/g;						# e-acute (\202)
	s/É/&Eacute;/g;						# Émile
	s/á/&aacute;/g;						# a-acute (\240)
	s/ó/&oacute;/g;						# o-acute (\242)
	s/£/&pound;/g;						# pound (\243)
	s/ö/&ouml;/g;						# o-umlaut (\246)

	return $_;
}

# Restore special HTML characters to UTF-8

sub html2text
{
	local($_) = $_[0];

	s/&amp;/&/g;
	s/&lt;/</g;
	s/&gt;/>/g;
	s/&aacute;/á/g;
	s/&eacute;/é/g;
	s/&oacute;/ó/g;
	s/&pound;/£/g;
	s/&ouml;/ö/g;

	return $_;
}

# Return heading $n from the dictionary

sub nthhead
{
	my ($dic_fh, $off_fh, $n) = @_;

	seeknth($dic_fh, $off_fh, $n);
	local $_ = <$dic_fh>;
	chomp;
	# print "nthhead returning ($_)";

	return $_;
}

# Position dictionary file handle $dic_fh at the start of heading $n

sub seeknth
{
	my ($dic_fh, $off_fh, $n) = @_;

	my $dic_off = line_at($off_fh, $n * $offsetline);
	$dic_off and seek $dic_fh, $dic_off, 0
		or die "Can't seek $dic_fh $dic_off: $!";
}

# Return the Nth key in the keys file minus trailing spaces.

sub getkey
{
	my ($key_fh, $n) = @_;

	local $_ = line_at($key_fh, $n * $keyline)
		or return;
	s/ .*//;

	return $_;
}

# Return a date string for the HTTP header of the generated
# page, with the dictionary source modification date.

sub last_modified
{
  my @junk = stat($dictionary);
  my @gmt = gmtime($junk[9]);

  my @months = qw{Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec};
  my @days = qw{Sun Mon Tue Wed Thu Fri Sat};

  $gmt[5] += 1900;
  $gmt[5] += 100 if ($gmt[5] < 1970);

  sprintf("%s, %02d %s %d %02d:%02d:%02d GMT",
	  $days[$gmt[6]], $gmt[3], $months[$gmt[4]],
	  $gmt[5], $gmt[2], $gmt[1], $gmt[0]);
}

1;
