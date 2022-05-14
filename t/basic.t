use TAP::Harness;
use Test::More tests => 22;
use lib "../lib";
use Test::Web; # C:/Strawberry/perl/site/lib

# cpan install TAP::Harness
# cd foldoc && prove

$ENV{RUN}++ or TAP::Harness->new->runtests(<*.t>);

my $origin =  "http://foldoc.org";
my $t = Test::Web->new(url => $origin);

# Home

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

# Search

$t->get_ok("/?query=foo&action=Search", "legacy query param", 301)
	->header_is(Location => $t->absolute("/foo"), "Query param redirect");

# Test: http://foldoc.org//Fairchild
$t->get_ok("//Fairchild", "Query starts with /");

# Test: http://foldoc.org/%2fdev%2fnull

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

# Redirects

# Neighbouring entries
# Missing entries
