#!/usr/bin/perl

# Display the contents and environment of an HTTP CGI request

# Denis Howe 2001-09-25

# ############################################################################ #

use Cwd;
$| = 1;

print "Content-type: text/html
Set-Cookie: Showenv=Foo; Path=/

<html>
<head><title>Current environment</title></head>
<body>

<h1>Current environment</h1>

";
%misc = (
	"Current directory" => shownull(getcwd()),
	"Running as user"   => shownull(getlogin() || getpwuid($<)),
	"ARGC"              => $#ARGV+1,
	'Script path ($0)'  => $0,
	"Script modified"   => scalar(gmtime([stat $0]->[9])) . " GMT",
	"Calls"				=> $ENV{calls}++,	# Perl for ISAPI persistence test
	"Time"				=> scalar(gmtime()) . " GMT",
	);
showhash("Script execution environment", %misc);

if (@ARGV)
{
	foreach (0..$#ARGV) {$ARGV{'$' . $_+1,} = $ARGV[$_]};
	showhash("Command line arguments", %ARGV);
}
else
{
	print "<h2>No command line arguments</h2>\n\n";
}

showhash("Environment variables", %ENV);

$method = $ENV{REQUEST_METHOD} || "GET";
if ($method eq "POST")
{
	sysread(STDIN, $input, $ENV{CONTENT_LENGTH});
	print "<h2>Form POST data (", length($input),
		" bytes)</h2>\n\n", URL2html($input), "\n<p>\n";
	if ($ENV{CONTENT_TYPE} =~ m|multipart/form-data|i)
	{
		$ENV{CONTENT_TYPE} =~ /boundary=/i;
		foreach (split($', $input))
		{
			s|--$||;	# Each segment ends with --
			print "<h2>Content (", length($_), " bytes)</h2>\n\n",
			'<table border="1" cellspacing="0"><tr><td><pre>', $_,
				"</pre></td></tr></table>\n";
		}
		$input = "";
	}
}
else
{
  $input = $ENV{QUERY_STRING};
  print "<h2>No Form data</h2>\n\n" unless ($input);
}

if ($input)
{
  foreach (split /&/, $input) {/=/ ? ($form{$`} = $') : ($form{$_} = "")};
  showhash("Form Fields", %form);
}

$method = $form{method} if ($form{method});
$post = $method eq "POST";

print '<form action="', $ENV{SCRIPT_NAME}, '" method="', $method, '">
  Next time this form will return its results using
  GET:<input name="method" type="radio" value="GET" ',
  $post || "checked", '>
  POST:<input name=method type="radio" value="POST" ',
  $post && "checked", '>
  <P>
  Text: <input name="text" type="text" value="', $form{text}, '"><BR>
  Input file: <input name="file" type="file"><br>
  <input type="submit" value="Submit">
<form>

</body>
</html>
';
exit 0;

# ############################################################################ #

# Turn a hash into an HTML TABLE

sub showhash
{
	my ($title, %hash) = @_;

	print "<h2>", $title, '</h2>

<table border="1" cellspacing="0" cellpadding="3">
<tr><td><b>Key</b></td><td><b>Value</b></td></tr>
';
	foreach (sort keys %hash)
	{
		print "<tr><td>$_</td>";
		local $_ = $hash{$_};
		$_ = URL2html($_);
		# If no spaces, give the browser a place to break long lines
		/ / || s|.{80}|$&<font color="red">-</font> |g;
		print "<td>$_</td></tr>\n";
	}
	print "</table>\n\n";
}


sub shownull
{
	$_[0] eq "" ? "&nbsp;" : $_[0];
}

sub URL2html
{
	local ($_) = shift;

	s/%([0-9a-f][0-9a-f])/pack("H", $1)/ieg;
	s/&/&amp;/g; s/</&lt;/g; s/\$/&dollar;/g;

	$_;
}

# ############################################################################ #
