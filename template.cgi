#!/usr/bin/perl

# Denis Howe 2001-03-01 - 2009-01-12 12:10

# Substitute environment variables in file named at start of
# QUERY_STRING.  This script needs to be linked into the directory
# containing the file so relative links will work.  Argument is
# assumed to be basename of file in that directory.

# Test:
# http://wombat.doc.ic.ac.uk/template.cgi?test.html&FOO=bar

# Find directory containing this script
($dir = $0) =~ s|/?[^/]*$||;
$dir .= "/" if ($dir ne "");

# Either run as CGI or batch
print "Content-type: text/html\n\n" if ($ENV{REQUEST_METHOD});

# First thing in query is file to process

@query = split /&/, $ENV{QUERY_STRING};
unless ($file = shift @query) {print "No file specified\n"; exit 0}

# Check for dodgy characters in file
if ($file =~ m![|/<>]!) {print "Bad file \"$file\""; exit 0}

# Add query variables to environment

foreach (@query)
{
  ($key, $_) = split /=/;
  s/\+/ /g;				 # Restore + -> space
  s/%([\da-f]{1,2})/pack(C,hex($1))/eig; # Restore %xx
  s/\r\n/\n/g; s/\n?\r/\n/g;		 # Normalise EOL
  $ENV{$key} = $_;
  # print "KEY $key  VAL $_<BR>\n";
}
$ENV{TIMESTAMP} = "Last update: \$DATE\n";

print "FILE: $file<br>\n"; foreach (sort keys %ENV) {print "$_ = $ENV{$_}<br>\n"}

template($dir . $file);
exit 0;

# Substitute environment variables in arg file

sub template
{
	my $file = shift;
	unless (open IN, "< $file") {print "Can't read $file: $!\n"; exit 0}
	while (<IN>)
	{
		s/\$\{?([-A-Za-z0-9_]+)\}?/defined $ENV{$1} ? $ENV{$1} : $&/eg;
		print;
	}
	close IN;
}

# Local variables:
# compile-command: "perl -w -c template.cgi"
# compile-command: "find . -name '*.html' -print | xargs egrep 'template\\.cgi'"
# End:
