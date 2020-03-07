#!/usr/bin/perl

use strict;
use warnings;

my ($string, $delay) = split /\&/, $ENV{QUERY_STRING};
$string =~ s/%20/ /g;
print "Content-type: text/javascript\n\n";
sleep $delay;
print qq{
log('$string ($delay)');
};

# Local variables:
# compile-command: "http://foldoc.org/pub/js/slow.cgi?Body"
# End:
