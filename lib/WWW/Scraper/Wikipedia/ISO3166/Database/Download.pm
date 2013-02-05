package WWW::Scraper::Wikipedia::ISO3166::Database::Download;

use parent 'WWW::Scraper::Wikipedia::ISO3166::Database';
use feature 'say';
use strict;
use utf8;
use warnings;
use warnings  qw(FATAL utf8);    # Fatalize encoding glitches.
use open      qw(:std :utf8);    # Undeclared streams in UTF-8.
use charnames qw(:full :short);  # Unneeded in v5.16.

use Hash::FieldHash ':all';

use HTTP::Tiny;

fieldhash my %code2 => 'code2';
fieldhash my %url   => 'url';

our $VERSION = '1.01';

# -----------------------------------------------

sub get_1_page
{
	my($self, $url, $data_file) = @_;
	my($response) = HTTP::Tiny -> new -> get($url);

	if (! $$response{success})
	{
		$self -> log(error => "Failed to get $url");
		$self -> log(error => "HTTP status: $$response{status} => $$response{reason}");

		if ($$response{status} == 599)
		{
			$self -> log(error => "Exception message: $$response{content}");
		}

		# Return 0 for success and 1 for failure.

		return 1;
	}

	open(OUT, '>', $data_file) || die "Can't open file: $data_file: $!\n";
	print OUT $$response{content};
	close OUT;

	$self -> log(info => "Downloaded '$url' to '$data_file'");

	# Return 0 for success and 1 for failure.

	return 0;

} # End of get_1_page.

# -----------------------------------------------

sub get_country_pages
{
	my($self) = @_;

	# Firstly, get the page of 3 letter country codes.

	my($url)    = $self -> url;
	$url        =~ s/2$/1_alpha-3/;
	my($result) = $self -> get_1_page($url, $self -> data_file . '.3.html');

	# Secondly, get the page of country names.

	# Return 0 for success and 1 for failure.

	return $result || $self -> get_1_page($self -> url, $self -> data_file . '.html');

} # End of get_country_pages.

# -----------------------------------------------

sub get_fips_pages
{
	my($self)     = @_;
#	my(@url)      = (qw/A-C D-F G-I J-L M-O P-R S-U V-Z/);
	my(@url)      = (qw/A-C/);
	my($base_url) = 'https://en.wikipedia.org/wiki/List_of_FIPS_region_codes_';

	my($real_url, $result, $random);

	for my $url (@url)
	{
		$real_url = "$base_url($url)";
		$result   = $self -> get_1_page($url, "data/List_of_FIPS_region_codes_$url.html");

		for (;;)
		{
			last if ( ($random = int(rand(500) ) ) > 35);
		}

		say "Sleeping for $random seconds";

		sleep $random;
	}

	return $result;

} # End of get_fips_pages.

# -----------------------------------------------

sub get_statoids_pages
{
	my($self) = @_;
	my(@url)  = (qw/
la.html  lb.html lc.html  ldf.html lg.html lhj.html
lkl.html lm.html lno.html lpr.html ls.html ltu.html lvz.html
/);
	my($base_url) = 'http://statoids.com';

	my($real_url, $result, $random);

	for my $url (@url)
	{
		$real_url = "$base_url/$url";
		$result   += $self -> get_1_page($real_url, "statoids/statoids.$url");

		for (;;)
		{
			last if ( ($random = int(rand(500) ) ) > 35);
		}

		say "Sleeping for $random seconds";

		sleep $random;
	}

	return $result;

} # End of get_statoids_pages.

# -----------------------------------------------

sub get_subcountry_page
{
	my($self)  = @_;
	my($code2) = $self -> code2;
	my($url)   = $self -> url . ":$code2";

	# Return 0 for success and 1 for failure.

	return $self -> get_1_page($url, $self -> data_file . ".$code2.html");

} # End of get_subcountry_page.

# -----------------------------------------------

sub get_subcountry_pages
{
	my($self) = @_;

	# %downloaded will contain 2-letter codes.

	my(%downloaded);

	my($downloaded)           = $self -> find_subcountry_downloads;
	@downloaded{@$downloaded} = (1) x @$downloaded;
	my($countries)            = $self -> read_countries_table;

	my(%countries);

	for my $id (keys %$countries)
	{
		if (! $downloaded{$$countries{$id}{code2} })
		{
			$self -> code2($$countries{$id}{code2});
			$self -> get_subcountry_page;

			sleep 5;
		}
	}

	# Return 0 for success and 1 for failure.

	return 0;

} # End of get_subcountry_pages.

# -----------------------------------------------

sub _init
{
	my($self, $arg) = @_;
	$$arg{code2}    ||= 'AU'; # Caller can set.
	$$arg{url}      = 'http://en.wikipedia.org/wiki/ISO_3166-2';
	$self           = $self -> SUPER::_init($arg);

	return $self;

} # End of _init.

# -----------------------------------------------

sub new
{
	my($class, %arg) = @_;
	my($self)        = bless {}, $class;
	$self            = $self -> _init(\%arg);

	return $self;

}	# End of new.

# -----------------------------------------------

1;

=pod

=head1 NAME

WWW::Scraper::Wikipedia::ISO3166::Database::Download - Download various pages from Wikipedia

=head1 Synopsis

See L<WWW::Scraper::Wikipedia::ISO3166/Synopsis>.

=head1 Description

Downloads these pages:

Input: L<http://en.wikipedia.org/wiki/ISO_3166-1_alpha-3>.

Output: data/en.wikipedia.org.wiki.ISO_3166-2.3.html.

Input: L<http://en.wikipedia.org/wiki/ISO_3166-2>.

Output: data/en.wikipedia.org.wiki.ISO_3166-2.html.

Downloads each countries' corresponding subcountries page.

Source: http://en.wikipedia.org/wiki/ISO_3166:$code2.html.

Output: data/en.wikipedia.org.wiki.ISO_3166-2.$code2.html.

See scripts/get.country.pages.pl, scripts/get.subcountry.page.pl and scripts/get.subcountries.pages.pl.

Note: These pages have been downloaded, and are shipped with the distro.

=head1 Constructor and initialization

new(...) returns an object of type C<WWW::Scraper::Wikipedia::ISO3166::Database::Download>.

This is the class's contructor.

Usage: C<< WWW::Scraper::Wikipedia::ISO3166::Database::Download -> new() >>.

This method takes a hash of options.

Call C<new()> as C<< new(option_1 => value_1, option_2 => value_2, ...) >>.

Available options (these are also methods):

=over 4

=item o code2 => $2_letter_code

Specifies the code2 of the country whose subcountry page is to be downloaded.

=back

=head1 Distributions

This module is available as a Unix-style distro (*.tgz).

See http://savage.net.au/Perl-modules.html for details.

See http://savage.net.au/Perl-modules/html/installing-a-module.html for
help on unpacking and installing.

=head1 Methods

This module is a sub-class of L<WWW::Scraper::Wikipedia::ISO3166::Database> and consequently inherits its methods.

=head2 code2($code)

Get or set the 2-letter country code of the country or subcountry being processed.

See L</get_subcountry_page()>.

Also, I<code2> is an option to L</new()>.

=head2 get_1_page($url, $data_file)

Download $url and save it in $data_file. $data_file normally takes the form 'data/*.html'.

=head2 get_country_pages()

Download the 2 country pages:

L<http://en.wikipedia.org/wiki/ISO_3166-1_alpha-3>.

L<http://en.wikipedia.org/wiki/ISO_3166-2>.

See L<WWW::Scraper::Wikipedia::ISO3166/Description>.

=head2 get_subcountry_page()

Download 1 subcountry page, e.g. http://en.wikipedia.org/wiki/ISO_3166:$code2.html.

Warning. The 2-letter code of the subcountry must be set with $self -> code2('XX') before calling this
method.

See L<WWW::Scraper::Wikipedia::ISO3166/Description>.

=head2 get_subcountry_pages()

Download all subcountry pages which have not been downloaded.

See L<WWW::Scraper::Wikipedia::ISO3166/Description>.

=head2 new()

See L</Constructor and initialization>.

=head1 FAQ

For the database schema, etc, see L<WWW::Scraper::Wikipedia::ISO3166/FAQ>.

=head1 References

See L<WWW::Scraper::Wikipedia::ISO3166/References>.

=head1 Support

Email the author, or log a bug on RT:

L<https://rt.cpan.org/Public/Dist/Display.html?Name=WWW::Scraper::Wikipedia::ISO3166>.

=head1 Author

C<WWW::Scraper::Wikipedia::ISO3166> was written by Ron Savage I<E<lt>ron@savage.net.auE<gt>> in 2012.

Home page: L<http://savage.net.au/index.html>.

=head1 Copyright

Australian copyright (c) 2012 Ron Savage.

	All Programs of mine are 'OSI Certified Open Source Software';
	you can redistribute them and/or modify them under the terms of
	The Artistic License, a copy of which is available at:
	http://www.opensource.org/licenses/index.html


=cut
