use TAP::Harness;
use Test::More tests => 8;
use lib "../lib";
use Test::Web;

# cpan install TAP::Harness
# cd foldoc && prove

$ENV{RUN}++ or TAP::Harness->new->runtests(<*.t>);

my $t = Test::Web->new(url => "http://foldoc.org");

# Home

$t->get_ok("/")
	->contains(title => "FOLDOC - Computing Dictionary", "Home title");

# Dangling cross-reference

$t->get_ok("/precedence")
	->contains(h2 => "", "Dangling cross-ref");

# Contents

$t->get_ok("/contents/D.html")
	->contains("a[href=/DWIM]" => "DWIM", "D entry label");

$t->get_ok("/contents/subject.html", "subject index")
	->content_like(qr/entries by subject/i)
	->contains("a[href=/contents/job.html]" => "job", "subject index link");

$t->get_ok("/contents/music.html", "music subject")
	->contains(h2 => "Entries for subject music")
	->contains("a[href=/mod]" => "mod", "music mod link");

# Search

$t->get_ok("/?query=foo&action=Search")
	->status_is(302, "Query 302")
	->header_is(Location => "/foo", "Query target");

# Entry with image

$t->get_ok("/exclusive%20or")
	->element_exists("img[src][title]", "Entry with image");

# Plural query

$t->get_ok("/cpus", "Case, stem")
	->text_like(p => qr/part of a computer/, "Plural query");

# Follow cross-ref

$t->get_ok("/Classic C")
	->contains(h2 => "K&R C", "Follow cross-ref");

# Word-search

$t->get_ok('/word-search?query=%5Equ..ms%24')
	->content_like(qr/qualms/);

done_testing();

# Redirects
# Neighbouring entries
# life
# Missing entries
# Other search engines
