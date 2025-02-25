use TAP::Harness;
use Test::More tests => 32;
use lib "../lib";
use Test::Web;		# ~/Projects/Perl/Test

# cpan install TAP::Harness

# Windows: run under cmd, not bash
# cd Projects\FOLDOC\foldoc & cls & prove

$ENV{RUN}++ or TAP::Harness->new->runtests(<*.t>);

my $t = Test::Web->new(url => "http://foldoc.org");

# Home

my $home = "https://foldoc.org";
$t->redirects('/', "$home/", "Redirect HTTP to HTTPS");

$t = Test::Web->new(url => $home);

$t->get_ok("/")->contains("<title>FOLDOC - Computing Dictionary</title>", "Home title");

# Dangling cross-reference

$t->get_ok("/precedence")
	->contains(h2 => "", "Dangling cross-ref");

# Contents

$t->get_ok("/contents/D.html")
	->contains('<a href="/DWIM">DWIM</a>', "contents/D entry label");

$t->get_ok("/contents/subject.html", "subject index")
	->contains(qq{<a href="/contents/job.html">}, "subject index link");

$t->get_ok("/contents/music.html", "music subject")
	->contains(h2 => "Entries for subject music")
	->contains("a[href=/mod]", "music mod link");

# Legacy Redirects

$t->redirects("/?query=foo&action=Search", "/foo", "Legacy redirect query=foo");

$t->redirects("/?query=%2F&action=Search", "/%2F", "Legacy redirect query=%2F");

$t->redirects("/?query=&action=Search", "/", "Legacy redirect query=''");

$t->redirects("/query?foo", "/foo", "/query?foo");

$t->redirects("//Fairchild", "/Fairchild", "Query starts with /");

$t->get_ok("//dev/null", "Term starts with /")
	->contains("<h2>/dev/null</h2>");

# Search

# Neighbouring entries

# Missing entries

# Entry with image

$t->get_ok("/exclusive%20or")
	->element_exists("img", "Entry with image");

# Plural query

$t->get_ok("/cpus", "Case, stem")
	->contains(qr/computer which controls/, "Plural query");

# Follow cross-ref

$t->get_ok("/Classic C")
	->contains("<h2>K&amp;R C</h2>", "Follow cross-ref");

# Word-search

$t->get_ok('/words.pl?r=[^aeiouy]{6}')
	->content_like(qr/crwths/);
