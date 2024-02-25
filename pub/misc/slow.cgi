#!/usr/bin/perl

use strict;
use warnings;

my ($string, $delay) = split /\&/, ($ENV{QUERY_STRING} || '&');
$string =~ s/%20/ /g;
print "Content-type: text/javascript\n\n";
sleep ($delay || 1);
print $string;
