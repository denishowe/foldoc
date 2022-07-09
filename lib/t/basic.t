use Mojo::Base -strict;

use Test::More;
use Test::Mojo;

my $t = Test::Mojo->new('Foldoc');

# Home

# Dangling cross-reference

$t->get_ok("/precedence")
	->text_is(h2 => "", "Dangling cross-ref");

$t->get_ok("/")
	->text_is(title => "FOLDOC - Computing Dictionary", "Home title");

# Contents

$t->get_ok("/contents/D.html")
	->text_is("a[href=/DWIM]" => "DWIM", "D entry label");

$t->get_ok("/contents/subject.html", "subject index")
	->content_like(qr/entries by subject/i)
	->text_is("a[href=/contents/job.html]" => "job", "subject index link");

$t->get_ok("/contents/music.html", "music subject")
	->text_is(h2 => "Entries for subject music")
	->text_is("a[href=/mod]" => "mod", "music mod link");

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
	->text_is(h2 => "K&R C", "Follow cross-ref");

# Word-search

$t->get_ok('/word-search?query=%5Equ..ms%24')
	->content_like(qr/qualms/);

done_testing();

# Redirects
# Neighbouring entries
# life
# Missing entries
# Other search engines

# Local variables:
# compile-command: "cd .. & run-tests"
# End:
