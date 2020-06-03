#!/usr/bin/perl

# Test a web site

# Denis Howe 2016-01-14 - 2015-05-29 13:09

# cp Web.pm C:/Strawberry/perl/site/lib/Test

# *_url methods return an absolute URL
# of the form "scheme://hostname/".

package Test::Web;

use strict;
use warnings;
use LWP::UserAgent;
use Test::More;
use Data::Dumper;
use Net::DNS;
use JSON;

$ENV{PERL_LWP_SSL_VERIFY_HOSTNAME} = 0;
my $ua;

sub new
{
	my ($class, @binds) = @_;

	$ua = LWP::UserAgent->new(cookie_jar => {});
	$ua->max_redirect(0);				# Don't follow redirects

	# Call arg pairs (attribute, value) as obj->attribute(value)
	die "Odd binds for new $class" if (@binds % 2);
	my $o = bless {}, $class;
	no warnings;
	foreach (0..@binds/2-1)
	{
		my $method = $binds[2*$_];
		$o->$method($binds[2*$_+1]);
	}
	return $o;
}

# Get or set an attribute named by the autoloading method name

sub AUTOLOAD
{
	my ($o, @values) = @_;

	die "No AUTOLOAD for class $o" unless (ref $o);

	my ($attribute) = $Test::Web::AUTOLOAD =~ /.*::(.*)/; # After last ::

	if (@values)
	{
		# warn "$o set $attribute";
		# Catch some undefined method calls
		warn @values . " values passed to set $attribute"
			if (@values > 1);
		$o->set($attribute, @values);
	}

	# If the attribute is not defined and there's a matching
	# _default method, set the attribute to the value it returns

	$o->set_from_default($attribute)
		if (! defined $o->{$attribute});

	return $o->{$attribute};
}

# Trying to fetch undefined attribute.  Has _default method?

sub set_from_default
{
	my ($o, $attribute) = @_;

	my $dm = $attribute . "_default";
	unless ($o->can($dm)) { warn "$attribute undef"; return }
	$o->set($attribute, $o->call_safe($dm));
}

# Set $attribute to $value.  Call post set hook method.

sub set
{
	my ($o, $attribute, @values) = @_;

	$o->{$attribute} = $values[0];

	my $sm = $attribute . "_set";
	$o->$sm if ($o->can($sm));
}

# Return the result of calling $method with @args or
# undef if we're inside a call of that method already.

my %calling;							# Loop detect

sub call_safe
{
	my ($self, $method, @args) = @_;

	my $ret = $calling{$method}++ ? undef : $self->$method(@args);
	delete $calling{$method};

	return $ret;
}

# Unset all attributes to ensure _defaults will be called

sub clear
{
	my ($self) = @_;

	%$self = ();
}

sub END
{
	done_testing();
}

# Dummy test to show IP address, etc.

sub show_setup
{
	my ($self) = @_;

	my $u = $self->url;
	my $ip = $self->hosts_file_ip || "DNS";
	ok $u, "Using $ip for $u";

	local ($_) = $self->relative_url =~ /(.*?):/;
	ok $_, $self->apex_hostname . " relative URLs: $_" ;

	# ok 1, "geo ip available? " . ($self->geoip_available ? "y" : "n");

	my $a = $self->api_hostname;
	ok $a, "API hostname" . ($a ? ": $a" : "");
}

# ######################################################################### #

# URLs

# Get or set the root URL, e.g. https://www.foxybingo.com.
# No trailing /.

sub url
{
	my ($self, @values) = @_;

	if (@values)
	{
		local $_ = $values[0];
		die "Bad trailing slash on $_" if (m|/$|);
		$_ = "https://$_" unless (/^http/);
		$self->{url} = $_;
	}
	$self->{url} = $self->url_default
		unless ($self->{url});

	return $self->{url};
}

# Return the root URL sans trailing /
# E.g. https://www.foxybingo.com, http://foldoc.org

sub url_default
{
	my ($self) = @_;

	my $proto = $self->proto
		or die "No protocol for url";
	my $host = $self->hostname
		or die "No hostname for url";

	return "$proto://$host";
}

# Return URL as an absolute URL with scheme and hostname

sub absolute
{
	my ($self, $url) = @_;

	die unless (defined $url);
	$url = $self->url . $url
		unless ($url =~ /^http/);

	return $url;
}

# Return the hostname part of the site URL, e.g. www.foxybingo.com

sub hostname_default
{
	my ($self) = @_;

	# Extract hostname from site URL
	if ($_ = $self->url)
	{
		m|//([^/:]+)| or die "Bad site $_";
		return $1;
	}
	die "No url for hostname";
}

# ######################################################################### #

# Test that fetching $url returns $code (default 200)

sub get_ok
{
	my ($self, $url, $test_name, $code) = @_;

	$url =~ s/""//;
	$test_name ||= "GET $url";
	$code ||= 200;
	my $r = $self->get($url);
	print STDERR "Response: ", Dumper($r) if ($self->{verbose});
	$self->response($r);

	is $r->code, $code, $test_name;

	return $self;
}

# Test that the last response returned a PNG image

sub is_png
{
	my ($self, $test_name) = @_;

	$self->contains("^\x89PNG\r\n", undef, $test_name);
}

# Test that the last response returned a JPEG image

sub is_jpeg
{
	my ($self, $test_name) = @_;

	$self->contains("^\xFF\xD8", undef, $test_name);
}

# Check that URL responds with a valid SSL certificate

sub ssl_valid
{
	my ($self, $url, $test_name) = @_;

	$ENV{PERL_LWP_SSL_VERIFY_HOSTNAME} = 1;
	get_url($self, $url, $test_name || "$url valid SSL");
	$ENV{PERL_LWP_SSL_VERIFY_HOSTNAME} = 0;
}


# Return the response from fetching $url from the site

sub get
{
	my ($self, $url) = @_;

	die unless (defined $url);
	$url = $self->absolute($url);
	my $resp;
	while (1)
	{
		print "Fetching $url\n";
		$resp = $ua->get($url);
		last;
		last if ($resp->is_success || $resp->is_redirect
				 || $resp->code eq "404");
		warn "Response ", Dumper $resp;
		sleep 1;
	}
	return $resp;
}

# A POST to $url should return $status and redirect to $to

sub post
{
	my ($self, $url, $status, $to, $test_name) = @_;

	die unless (defined $url);
	$url = $self->absolute($url);
	my $r = $ua->post($url);
	my $got_status = $r->code;

	is $got_status, $status, "$test_name $status";
	my $location = $r->header("Location");
	is $location, $to, "$test_name location";
}

# Check that the last response matches $pattern and the
# first match also matches $sub_pattern (if given).

sub contains
{
	my ($self, $pattern, $sub_pattern, $test_name) = @_;

	$test_name ||= $pattern;
	my $r = $self->response;

	return $self if ($r->code ne "200");

	local $_ = $r->content;
	# die "Content $_";
	my $match = /$pattern/ && ($1 || $0);
	if ($match)
	{
		pass $test_name;
		like $match, qr($sub_pattern), $test_name
			if ($sub_pattern);
	}
	else
	{
		fail "$test_name: no match for $pattern" . " in\n$_";
	}
	return $self;
}

sub redirects
{
	my ($self, $from, $to, $test_name, $status) = @_;

	die "No from for $test_name" unless (defined $from);
	die "No to for $test_name" unless (defined $to);
	$to = $self->absolute($to);
	$test_name ||= $from;
	$status ||= 301;

	my $r = $self->get($from);

	my $target = $r->header("Location");
	# print Dumper $r unless $target;
	$test_name .= " (from $from)"
		if (($target || "") ne $to);
	# like $target, qr(^$to), $test_name;
	is $target, $to, $test_name;

	my $rc = $r->code;
	$test_name .= " - " . $r->message
		if ($rc ne $status && $rc ne 200);
	is $rc, $status, "$test_name $status";
}

# DNS

# Is site visible on Internet?

sub is_public
{
	my ($self) = @_;

	return ! $self->hosts_file_ip;
}

# Return the web site IP address, either from the hosts file or DNS

sub ip_address_default
{
	my ($self) = @_;

	local $_ = $self->hosts_file_ip || $self->dns_ip
		or die "No IP address for ", $self->hostname;

	return $_;
}

# Return the IP address given for $url's hostname
# domain in the hosts file or false if not found.

sub hosts_file_ip_default
{
	my ($self) = @_;

	return $self->hosts_file_ip_for($self->hostname);
}

# Return the IP address in the hosts file for $hostname or false

sub hosts_file_ip_for
{
	my ($self, $hostname) = @_;

	local $_ = $self->hosts_file_contents;

	my ($ip) = /([0-9.]+).*\s$hostname\b/
		or return;

	return $ip;
}

# Return the contents of the hosts file with comments removed

sub hosts_file_contents_default
{
	my ($self) = @_;

	my $f = "c:/Windows/System32/drivers/etc/hosts";
	open my $H, "<", $f or die "Can't read $f: $!";
	local $/;
	local $_ = <$H>;
	close $H;
	s/#.*//g;

	return $_;
}

# Check that the hostname part of $EMAIL_ADDRESS has MX records

sub email_address
{
	my ($self, $ad) = @_;

	my ($mailbox, $host) = split /@/, $ad, 2;
	ok $self->dns_mx($host), "$host MX";
}

# Return $hostname without its first component.
# Return false if it has less than two components.

sub parent_domain
{
	my ($self, $hostname) = @_;

	return $hostname =~ s/^[^.]+\.// && $hostname;
}

sub is_tld
{
	my ($self, $hostname) = @_;

	return grep $hostname eq $_, $self->tlds;
}

sub tlds
{
	return qw(com co.uk org);
}

# Return the hostname's NS names from DNS.  If it has none of
# its own, try its parent domain and so on until we reach a TLD.

sub dns_ns
{
	my ($self) = @_;

	my $h = $self->hostname;
	while (1)
	{
		my @r = $self->dns_rr($h, "NS");
		if (@r)
		{
			@r = sort map $_->nsdname, @r;
			# print "NS rr $h: ", Dumper \@r;

			return @r;
		}
		$h = $self->parent_domain($h);
		return if (!$h || $self->is_tld($h));
	}
}

# Return the IP address for $hostname.  If there's
# a CNAME, return that in preference to IP.

sub dns_ip
{
	my ($self, $hostname) = @_;

	$hostname ||= $self->hostname;

	# Hostname looks like an IP address
	return $hostname if ($hostname =~ /^\d/);

	my @rr = $self->dns_rr($hostname);
	my @cname = grep $_->type eq "CNAME", @rr;
	my @ip = grep $_->type eq "A", @rr;
	# Sort returns undefined in scalar context
	my @r = sort( @cname ? map "CNAME " . $_->cname, @cname
				 		 : map $_->address, @ip );
	unless (@r == 1)
	{
		$self->dns_error("Multiple results for dns_ip($hostname)");
		return;
	}
	return $r[0];
}

# Return the CNAME for $hostname (default www), if any

sub dns_cname
{
	my ($self, $hostname) = @_;

	return map $_->cname, $self->dns_rr($hostname || $self->hostname, "CNAME");
}

# Return the mail servers for $hostname (default apex)

sub dns_mx
{
	my ($self, $hostname) = @_;

	return map $_->exchange, $self->dns_rr($hostname, "MX");
}

# Return DNS records for $hostname (default
# apex), optonally limited to $type (e.g. "NS").

sub dns_rr
{
	my ($self, $hostname, $type) = @_;

	$hostname ||= $self->apex_hostname;
    my $res = Net::DNS::Resolver->new; # (debug => 1);
	my $reply = $res->query($hostname, $type);
	unless ($reply)
	{
		$self->dns_error("DNS fail $hostname" . ($type ? " type" : "")
						 . ": " . $res->errorstring);
		return;
	}
	my @rr = $reply->answer;
	# print "dns_rr $hostname ", $type ? "$type " : "", Dumper(\@rr), "\n";
	# Ignore additional info records not owned by $hostname
	@rr = grep $_->name eq $hostname, @rr;

	return @rr;
}

1;
