#!/usr/bin/perl

# Build the Free On-line Dictionary of Computing

# Denis Howe 2000-07-04 - 2015-01-31 14:10

use strict;
use warnings;
use Socket;

# Work out the directory containing this script - dictionary
# top directory.  Don't chdir - some output is to current dir.

our $dicdir;
BEGIN
{
	$dicdir = $0 =~ m|(.*)/| ? $1 : ".";
	push @INC, $dicdir;
}
use Foldoc;

# Make filenames absolute

my $keyfile = "$dicdir/$keybase";
my $offsetfile = "$dicdir/$offsetbase";
my $keyfmt = "%-${keylen}s\n";
my $offfmt = "%0${offsetlen}d\n";
my $junk_searches = "$dicdir/junk_searches";

##################################################################
# Argument says what to do

die "Usage: build.pl action\n" unless (@ARGV);
no strict "refs";
$ARGV[0]->();

exit;

##################################################################

# Read the dictionary source in the current directory
# (new), make FOLDOC indexes in this directory and
# contents pages in a subdirectory called contents.

sub index
{
	# Headings with out-of-order or duplicate keys
	my %disorderly = map +($_ => 1),
		"Free On-line Dictionary of Computing", "Acknowledgements",
		"Missing definition", "CSPS", "fixed point",
		"ISIS", "ISOC", "macro", "micro", "MP1", "Pascal";

	open DIC, $dicbase or die "\nCan't read $dicbase: $!";

	umask 0022;
	-d "contents" || mkdir "contents", 0777;

	# Read dictionary, create keys and offsets

	open KEY, ">", $keybase or die "\nCan't write $keybase: $!";
	open OFF, ">", $offsetbase or die "\nCan't write $offsetbase: $!";
	my $previous_heading = "";
	my $previous_key = "";

	$_ = <DIC>;								# Read first heading
	my (@entries, %subject_entries, %initial_entries);
	until (eof DIC)
	{
		my $offset = tell() - length $_;	# Start of heading
		chomp;
		my $heading = $_;
		push @entries, $heading;

		# List heading's key value and file offset in index files

		my $key = make_key($_);
		printf KEY $keyfmt, $key;
		printf OFF $offfmt, $offset;

		# Check order and duplicate keys

		unless ($disorderly{$_})
		{
			print STDERR "** '$previous_heading' >= '$_'\n"
				unless (diccmp($previous_heading, $_, 1, 1) < 0);
			print STDERR "** key($previous_heading) = key($_)\n"
				if ($key eq $previous_key);
			$previous_heading = $_; $previous_key = $key;
		}

		my $initial = $heading =~ /^([A-Za-z])/ ? uc $1 : "other";
		push @{$initial_entries{$initial}}, $heading;

		# Find subjects

		# Read entry from after heading up to next heading
		my $entry = "";
		$entry .= $_ while (defined($_ = <DIC>) && !/^[^\t\n]/);
		# $_ now contains next heading

		my %subject = ();

		if (target_entry($entry))
		{
			$subject{ALIAS} = 1;
		}
		else
		{
			foreach ($entry =~ /^\t(?:\d+\.\s+)?<([^@>]+)>/gm)
			{
				# line starts with optional number and subject areas
				# Collect this entry's comma-separated subjects
				map $subject{$_} = 1, split /,\s*/, $_;
			}
		}
		# Add entry to subject "none" if uncategorised
		$subject{none} = 1 unless (%subject);
		# An entry may list the same subject in multiple numbered
		# sub-entries.	Only list this entry once under each subject.
		foreach (keys %subject) { push @{$subject_entries{$_}}, $heading }
	}
	close DIC;
	close KEY;
	close OFF;

	$num_entries = @entries;
	print STDERR  "$num_entries entries\n";

	# List all entries

	%ENV = (
		TITLE => "All entries from FOLDOC",
		CONTENT => qq{<h2>All Entries</h2>\n<p>}
			. list_entries(@entries) . qq{</p>\n},
		   );
	template("contents/all.html", "../template.html");

	# List entries by initial

	foreach (sort keys %initial_entries)
	{
		my $entries = list_entries(@{$initial_entries{$_}});
		%ENV = (
			TITLE => "Entries beginning with $_ from FOLDOC",
			CONTENT => qq{<h2>Entries beginning with $_</h2>
<p>$entries</p>
},
			   );
		template("contents/$_.html", "../template.html");
	}

	# List the subjects - http://foldoc.org/contents/subject.html

	foreach (keys %subject_entries)
	{
		my @e = @{$subject_entries{$_}};
		next if (@e > 1);
		print STDERR "Small subject \"$_\": @e\n";
		delete $subject_entries{$_};
	}
	my @subjects = sort {lc $a cmp lc $b} keys %subject_entries;
	my @subj_as = map qq{<a href="/contents/}
		. subjectfile($_) . qq{">$_ (} . @{$subject_entries{$_}} . qq{)</a>},
			@subjects;
	my $subjects = columns(@subj_as);
	%ENV = (
		TITLE => "Subjects from FOLDOC",
		CONTENT => qq{<h2>Contents by subject area</h2>

<p>The number of entries for each subject is shown in parentheses.

<a href="/contents/none.html"> Some entries </a> have not been
categorised yet, <a href="/contents/alias.html"> some entries
</a> are just aliases that point to other entries.</p>

<div class="word-list">$subjects</div>
},
		   );
	template("contents/subject.html", "../template.html");

	# List entries in each subject

	foreach (@subjects)
	{
		my @e = @{$subject_entries{$_}};
		my $entries = list_entries(@e);
		my $file = subjectfile($_);
		%ENV = (
			TITLE => "$_ from FOLDOC",
			CONTENT => qq{<h2>$_ entries</h2>\n<p>$entries</p>\n},
			   );
		template("contents/$file", "../template.html");
	}

	# Google sitemap - UTF-8 text file one URL per line
	# https://support.google.com/webmasters/answer/183668?hl=en
	# http://www.google.com/ping?sitemap=http://foldoc.org/sitemap.txt

	my @pages = (qw{
		/
		/Free+On-line+Dictionary
		/contents.html
		/help.html
		/missing.html
		/new.html
	}, map "/contents/" . subjectfile($_), @subjects);
	open SM, ">", "sitemap.txt";
	print SM map "$root_url$_\n", @pages;
	close SM;
}

# Return an HTML table containing anchors for the given entries

sub list_entries
{
	return columns(map anchor($_), @_);
}

# Return an HTML table in a div with the args in 3 columns

sub columns
{
	my $cols = 3;
	my $rows = int((@_+$cols-1) / $cols);
	# my ($k_row, $k_col) = (1, $rows);	# vertical
	my ($k_row, $k_col) = ($cols, 1);	# horizontal
	my $table = "";
	for (my $r = 0; $r < $rows; $r++)
	{
		$table .= join "",
			"<tr>" ,
			map("<td>"
				. ($_[$k_row*$r + $k_col*$_] || "&nbsp;")
				. "</td>", 0..$cols-1),
			"</tr>\n";
	}
	return "<div class=\"word-list\">\n"
		 . "<table>\n$table</table>\n"
		 . "</div>";
}

# ######################################################################### #

# Extract keys from searches on the Dictionary in the Apache logs.
# Write missing.html with the $nmissing most frequently requested
# keys not in the dictionary preceded by their request counts.

sub missing
{
	# Get keys of all headings in dictionary
	print STDERR "Keys, ";
	open DIC, $dictionary or die "\nCan't open $dictionary: $!";
	my $dic_keys;
	while (<DIC>)
	{
		next unless (/^[^\t\n]/);
		chomp;
		$dic_keys .= lc(make_key($_)) . "\n";
	}
	close DIC;

	# Pretend these junk searches are in the dictionary

	my %junk;
	if (open JUNK, $junk_searches)
	{
		my @j = grep ! /^#/, <JUNK>;
		chomp @j;
		print STDERR "junk (" . @j . "), ";
		# Add to dictionary keys
		foreach (@j)
		{
			my $key = lc make_key($_);	# Ignore case of junk
			$dic_keys .= "$key\n";
			$junk{$key} = 1;	   		# Anyone searched for this recently?
		}
		close JUNK;
	}

	# How many queries have we had from each client IP and which clients
	# searched for each key and what was the original query for each key?

	my ($client_hits, $key_clients, $key_query) = read_logs();

	# Ignore request with trailing slash, query
	# string, %XX or request for file that now exists.

	while (my ($k, $q) = each %$key_query)
	{
		delete $key_clients->{$k}
			if ($q =~ /\/$|\?|%[0-9A-F]{2}/ || query_is_file($q));
	}

	# Delete uninteresting clients with too many hits

	foreach (keys %$client_hits)
	{
		delete $client_hits->{$_} if ($client_hits->{$_} > 100);
	}
	list_fans($client_hits);

	# Match queries against dictionary, ignore case and punctuation

	print STDERR "Comparing, ";
	my @frequent;
	while (my ($key, $clients) = each %$key_clients)
	{
		# Ignore search that redirects
		use Data::Dumper;
		$_ = $key_query->{$key}
			or die Dumper $key;
		next if (check_redirect($_));
		delete $junk{$key};						# Junk key was searched for
		# Replace interesting clients list with count
		# Forget keys with no interesting clients
		$key_clients->{$key} = grep $client_hits->{$_}, keys %$clients
			or next;
		($_ = $key) =~ s/s$//;					# Trailing "s" is optional
		# \Q...\E => quote re chars.  m => multi-line
		next if ($dic_keys =~ m/^\Q$_\Es?$/m);	# Found
		push @frequent, $key;				   	# Missing
	}
	print STDERR "sorting, ";
	@frequent = sort {$key_clients->{$b} <=> $key_clients->{$a}} @frequent;
	splice @frequent, 30;				# Just N most frequent missing terms

	@frequent = map "<tr><td>$key_clients->{$_}</td>" .
					    "<td>$key_query->{$_}</td></tr>", @frequent;
	my $missing = join "\n", qq(<table id="missing">), @frequent, qq(</table>\n);
	$missing =~ s/\$/&#36;/g;			# Hide $ from template()

	$ENV{TITLE} = "FOLDOC Missing Terms";
	$ENV{CONTENT} = q{<h2>Frequently requested missing terms</h2>

<p>
The following terms are not defined in the dictionary.
The numbers show how often they have been looked
for.  New terms are added almost every day.
</p>

<p>
Feel free to <a href="help.html">send new definitions</a>.
</p>
} . $missing;
	template("missing.html");

	print STDERR "old junk:\n", map "  $_\n", sort keys %junk;
	print STDERR "done.\n";
}

sub query_is_file
{
	local ($_) = @_;

	# return -e "./_";					# Why "./"?
	return -e $_
		|| s/^pub/_pub/ && -e $_;		# /pub is served from _pub
}

# Pre-process any unprocessed web logs.
# Return hashes read from pre-processed logs.

# client_hits = {client => n_hits, ...}
#   where n_hits is the number of requests from that client IP and

# key_clients = {key => {client => 1, ...}}
#   where clients sent a query with key

# key_query = {key => query}
#   where query is original query term

# dates = {date => 1}
#   where date has been pre-processed

sub read_logs
{
	my ($client_hits, $key_clients, $key_query, $dates) = load_logs();

	# Web server access logs: current, finished and .gz

	my @wwwlogs = glob "/var/log/apache2/foldoc.org/access-*";
	my $old = @{[keys %$dates]};
	my $n = 100;						# Keep n most recent
	print "\n$n/" . @wwwlogs . " logs, $old old\n";
	@wwwlogs = splice @wwwlogs, -$n if (@wwwlogs > $n);
	foreach (@wwwlogs)
	{
		my ($date) = /.*-(\d+)/;				# Extract YYYYMMDD
		next if ($date && $dates->{$date});		# Already processed

		my (%ch, %kc, %kq);
		$_ = "gzip -dc $_ |" if (/\.gz$/);
		open LOG, $_ or die "Can't open $_: $!";
		print STDERR "\n  $_";
		while (<LOG>)
		{
			# 162.158.255.28 [03/Dec/2017:11:54:08 +0000]
			# "GET /amplitude%20modulation HTTP/1.1" 200

			s/^\000*//;					# Zap initial nuls
			my ($client) = /^([0-9.]+)/	# Client IP address
				or next; # warn "No client IP in $_";
			$ch{$client}++;
			# Extract URL
			s/\\"/\001/g;				# Hide escaped "s
			($_) = m|"GET /(\S+)| or next;
			s/\001/"/g;					# Unhide "s
			$_ = url2text($_);
			s/\+/ /g;					# Fix double-encoded plus
			next if (   /\n/			# Ignore query containing \n
					 || ! /\S/			# Ignore empty/whitespace-only queries
					 || /\.php$/);		# Ignore PHP probes
			my $key = lc make_key($_)
				or next;
			# Hash unique clients and remember query
			$kc{$key}{$client} = 1;
			s/\t/%09/g;					# Quote tab for TSV
			$kq{$key} = $_;
		}
		close LOG;
		# Save this log's processed data if complete (log name has date)
		save_log($date, \%ch, \%kc, \%kq)
			if ($date);

		# Add this log's data into result
		map $client_hits->{$_} += $ch{$_}, keys %ch;
		while (my ($key, $c) = each %kc)
		{
			map $key_clients->{$key}{$_} = 1, keys %$c;
		}
		map $key_query->{$_} = $kq{$_}, keys %kq;
	}
	return ($client_hits, $key_clients, $key_query);
}

# Read summarised TSV logs named (YYYYMMDD) into hashes

sub load_logs
{
	my ($client_hits, $key_clients, $key_query, $dates) = ({}, {}, {}, {});

	my @logs = <logs/*>;
	print STDERR " old logs (" . @logs . ")";
	foreach my $log (@logs)
	{
		open my $LOG, $log or die "Can't read $log: $!";
		$log =~ m|.*/(.*)|;
		$dates->{$1} = 1;
		print STDERR " $1";
		my $key;
		while (<$LOG>)
		{
			chomp;
			my ($t, $f0, $f1) = split /\t/, $_;
			# Convert rows into hashes:
			# 0, {client => hits, ...}
			# 1, {key =>
			# 2,	{client => 1, ...}}
			# 3, {key => query, ...}
			if    ($t == 0) { $client_hits->{$f0} += $f1 }
			elsif ($t == 1) { $key = $f0 }
			elsif ($t == 2) { $key_clients->{$key}{$f0} = 1 }
			else            { $key_query->{$f0} = $f1 };
		}
		close $LOG;
	}
	return ($client_hits, $key_clients, $key_query, $dates);
}

sub save_log
{
	my ($log, $client_hits, $key_clients, $key_query) = @_;

	print STDERR "\n  Saving log $log";
	-d "logs" or mkdir "logs", 0777 or die "Can't mkdir logs: $!";
	open my $LOG, ">", "logs/$log" or die "Can't write logs/$log: $!";
	print $LOG map tsv(0, $_, $client_hits->{$_}),
		sort keys %$client_hits;
	foreach my $key (sort keys %$key_clients)
	{
		print $LOG tsv(1, $key),
			map tsv(2, $_), sort keys %{$key_clients->{$key}};
	}
	print $LOG map tsv(3, $_, $key_query->{$_}), sort keys %$key_query;
	close $LOG;
}

sub tsv
{
	die if (grep /\t/, @_);

	return join("\t", @_) . "\n";
}

# List biggest fans

sub list_fans
{
	my ($client_hits) = @_;

	my @hosts = keys %$client_hits;
	@hosts = sort {$client_hits->{$b} <=> $client_hits->{$a}} @hosts;
	for ($_ = 0; $_ < @hosts && $_ < 10; )
	{
		# Convert IP addresses to hostnames
		my $h = $hosts[$_];
		$hosts[$_] = ip_to_name($h);
		$client_hits->{$hosts[$_]} = $client_hits->{$h};
		# Ignore crawlers, bots and spiders
		if ($hosts[$_] =~ /bot|crawl|search|google/)
		{
			splice @hosts, $_, 1;		# Drop this one
			next;
		}
		$_++;
	}
	$#hosts = 9 if ($#hosts > 9);
	print STDERR "\nfans:\n", map "  $_: $client_hits->{$_}\n", @hosts;
}

###############################################################################

# Find entries that changed recently.  Write new.html and rss.xml.  Tweet.

sub new
{
	local %ENV;			# Visible to template()
	my %date;

	open DIC, $dictionary
		or die "\nCan't read $dictionary: $!";
	while (my ($head, $date) = entry_date("DIC"))
	{
		$date{$head} = $date if ($date);
	}
	close DIC;
	# Sort headings newest first
	my @head = sort {$date{$b} cmp $date{$a}} (keys %date);
	@head = @head[0..99];

	%ENV = (
		TITLE => "FOLDOC New Terms",
		CONTENT => join("",
		"<h1>Recent Changes</h1>

The following terms were recently added or changed:\n<p>\n",
		map("$date{$_} <strong>" . anchor($_) . "</strong><br>\n", @head),
		"</p>\n"));
	template("new.html");

	# Fill in the RSS template
	$ENV{LASTBUILDDATE} = $date{$head[0]}; # Date of latest term
	$ENV{DESCRIPTION} = join "", map $date{$_} . " " . rss_entry($_), @head;
	template("rss.xml", "$dicdir/rss-template.xml");

	use Twitter;
	$_ = $head[0]; s/ /+/g;
	my $ret = tweet("Latest FOLDOC update: $root_url/$_");
	print STDERR "Tweeted at ", ($ret->{created_at} || "??"),
		($@ && " ($@)"), "\n";
}

sub rss_entry
{
	my ($heading) = @_;

	return qq(&lt;strong&gt;&lt;a href="http://foldoc.org/)
		. text2url($heading) . qq("&gt;) . text2html($heading)
		. qq(&lt;/a&gt;&lt;/strong&gt;&lt;br&gt;\n);
}

# ######################################################################### #

# Handle command line: build.pl do_template $content $output

# Substitute $content into template.html and write the result to $output

sub do_template
{
	%ENV = (CONTENT => file_contents($ARGV[1]));
	template($ARGV[2]);
}

# ######################################################################### #

# Return (heading, date) of next entry from HANDLE
# Return () on EOF or date="" if entry undated

sub entry_date
{
	my ($SOURCE) = @_;

	my ($head, $last);
	local $_;
	while ($_ = <$SOURCE>)
	{
		if (/^\t/) {$last = $_; next}	# Save line beginning with tab
		next if (/^\n/);				# Ignore blank line
		# Got new heading
		if ($head)
		{
			seek $SOURCE, -length($_), 1
				or die "Can't seek: $!"; # Rewind to start of heading
			return ($head, $last =~ /(\d\d\d\d-\d\d-\d\d)/ && $1);
		}
		chomp ($head = $_);
	}
	return ();
}

{ my %ip_name;

sub ip_to_name
{
	my ($ip_address) = @_;

	$ip_name{$ip_address} ||= ip_to_name_no_cache($ip_address);

	return $ip_name{$ip_address};
}
}

sub ip_to_name_no_cache
{
	my ($ip_address) = @_;

	my $ip_ad = inet_aton($ip_address)
		or return $ip_address;
	my @h = gethostbyaddr $ip_ad, AF_INET
		or return $ip_address;

	return $h[0];
}

# ######################################################################### #
