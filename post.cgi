#!/usr/bin/perl

# E-mail form contents to webmaster

# Denis Howe 1990-01-01 - 2008-09-29 10:03

use Foldoc qw(text2html);

# Convert the body of the form, with all escapes restored, to
# an associative array mapping keys to values.  E.g. for a body:

# name=Den+Howe&email=dbh@doc&subject=Hot+toast&text=A%0Amultiline%0Amessage

# the array would contain

#  $form{name}    = "Den Howe"
#  $form{email}   = "dbh\@doc"
#  $form{subject} = "Hot toast"
#  $form{text}    = "A\nmultiline\nmessage"

$input = <>;			# Get input from POST method
# $input = $ENV{QUERY_STRING};	# Get input from GET method (not args)

print "Content-type: text/html\n\n";
print "<html><head>\n";

foreach (split(/&/, $input))
{
	($key, $_) = split(/=/);
	s/\+/ /g;				 # Restore + -> space
	s/%([\da-f]{1,2})/pack(C,hex($1))/eig; # Restore %xx
	s/\r\n/\n/g; s/\n?\r/\n/g;		 # Normalise EOL
	$form{$key} = $_;
};

$name    = $form{name};
$email   = $form{email};
$subject = $form{subject};
$url	 = $form{url};
$text    = $form{text};
$human	 = $form{is_human};

$name =~ s/\s*,\s*/ /g;

# Check e-mail address

unless ($email =~ /\S@\S/)
{
	print '<title>Invalid e-mail address</title>
</head>

<body>
Please go back and enter a valid e-mail address.<p>

Your e-mail address must have an \'@\' in the middle.<p>

Input was "', text2html($input), '"
</body>
</html>
';
	exit 0;
}

$email = "$name <$email>" if ($name =~ /\S/ && $email !~ /</);

# Check there's some text

unless ($text =~ /\S/)
{
	print '<title>Nothing to post</title>
</head>
<body>

No text given - ignored.<p>

Input was "', text2html($input), '"

</body>
</html>
';
    exit 0;
}

unless ($human)
{
	print '<title>Are you human?</title>

</head>
<body>

Please go back and tick the <i>Human</i> tick box.
</body>
</html>
';
	exit 0;
}

# Check for spam or other attacks
if ($email =~ /[\n\r]/
	|| $subject =~ /[\n\r]/
	|| $text =~ /^content-/mi
	|| $text =~ /xoomer/)
{
	print '<title>Illegal characters in input</title>
</head>
<body>

Illegal characters in input.  What are you up to?

</body>
</html>
';
	exit 0;
}

$ENV{REMOTE_HOST} ||= $ENV{REMOTE_ADDR};
unless ($ENV{REMOTE_HOST})
{
	print "<title>Unknown Remote Host</title>
</head>
<body>

Sorry, I can't determine your host name so I'm
afraid I'm rejecting your message as spam.

</body>
</html>
";
	exit 0;
}

# OK to send mail

# -oi => Don't terminate message at single dot
# -t  => To address in header
open MAILER, "| /usr/lib/sendmail -oi -t"
	or die "Can't send mail: $!";
print MAILER "To: Denis Howe <dbh\@doc.ic.ac.uk>
", $email =~ /\S/ && "From: $email\n",
	"Subject: FOLDOC feedback: $subject

Host: $ENV{REMOTE_HOST}
Browser: $ENV{HTTP_USER_AGENT}
", $url =~ /\S/ && "URL: $url\n", "
Human: ", $human ? "Yes" : "No", "
$text
" or die "Error writing mail: $!";
close MAILER or die "Error closing mail: $!";

print '<title>Feedback received</title></head>
<body>
<center>
<a href="index.html"><img src="foldoc.gif" title="Free On-line Dictionary of Computing" width="150" height="49" align="LEFT" border="0"></a>
<form action="index.cgi">
  <input name="query">
  <input type="submit" name="action" value="Search">
  <input type="submit" name="action" value="Home">
  <input type="submit" name="action" value="Contents">
  <input type="submit" name="action" value="Feedback">
  <input type="submit" name="action" value="Random">
</form>

<h1>Feedback received</h1>
</center>

Thank you for your message about <em>', text2html($subject), '</em> ',
  text2html($name), '.<p>

It has been sent to the editor.

</body>
</html>
';

# Local variables:
# compile-command: "echo name=Den+Howe | ./post.cgi"
# compile-command: "setenv REMOTE_HOST bozoland.com; echo \"name=Den+Howe&email=dbh@doc&subject=Hot+toast&text=A%0Amultiline%0Amessage\" | ./post.cgi"
# compile-command: "(echo To: dbh@doc.ic.ac.uk; echo; echo Test) | /usr/lib/sendmail -oi -t"
# compile-command: "perl -wc post.cgi"
# End:
