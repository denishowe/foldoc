#!/usr/bin/perl

# Tweet a string to twitter

# Denis Howe 2013-05-10 - 2014-02-16 21:27

# http://qscripts.blogspot.co.uk/2010/05/post-to-twitter-from-perl-using-single.html

use strict;
use warnings;
use Net::Twitter::Lite::WithAPIv1_1;
use Net::OAuth; # Required by above

my $nt = Net::Twitter::Lite::WithAPIv1_1->new(
	consumer_key        => "8B4vlh7sZlsVYGFit43xAg",
	consumer_secret     => "f6YOiXCoyaFLREnICZ97SFcCqb7v4YaP0xaugYEIyU",
	access_token        => "1416528271-Kl0is5vu8zALgM2lNI696bBv7U1sbHYGfjoQyhu",
	access_token_secret => "Raf3oAtreR8Mb6Vh2LVvgKi8wTvsyffeabcqVX0Hu5U",
	ssl					=> 1,
	legacy_lists_api	=> 0,
);

sub tweet
{
	my $result = eval { $nt->update("@_") };

	return $@ || $result;
}

if ($0 =~ /Twitter.pm$/)
{ use Data::Dumper; print Dumper tweet("Denis testing from FOLDOC") };

1;

# ############################################################################ #
