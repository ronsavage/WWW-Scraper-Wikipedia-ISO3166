package WWW::Scraper::Wikipedia::ISO3166::Database::Download;

use parent 'WWW::Scraper::Wikipedia::ISO3166::Database';
use strict;
use warnings;

use Hash::FieldHash ':all';

use HTTP::Tiny;

fieldhash my %code2 => 'code2';
fieldhash my %url   => 'url';

our $VERSION = '1.00';

# -----------------------------------------------

sub get_country_page
{
	my($self)     = @_;
	my($response) = HTTP::Tiny -> new -> get($self -> url);

	if (! $$response{success})
	{
		$self -> log(error => 'Failed to get ' . $self -> url);
		$self -> log(error => "HTTP status: $$response{status} => $$response{reason}");

		if ($$response{status} == 599)
		{
			$self -> log(error => "Exception message: $$response{content}");
		}

		# Return 0 for success and 1 for failure.

		return 1;
	}

	my($out_file) = 'data/en.wikipedia.org.wiki.ISO_3166-2.html';

	open(OUT, '>', $out_file) || die "Can't open file: $out_file: $!\n";
	print OUT $$response{content};
	close OUT;

	$self -> log(info => "Downloaded $out_file");

	# Return 0 for success and 1 for failure.

	return 0;

} # End of get_country_page.

# -----------------------------------------------

sub get_subcountry_page
{
	my($self)  = @_;
	my($code2) = $self -> code2;

	$self -> url($self -> url . ":$code2");

	my($response) = HTTP::Tiny -> new -> get($self -> url);

	if (! $$response{success})
	{
		$self -> log(error => 'Failed to get ' . $self -> url);
		$self -> log(error => "HTTP status: $$response{status} => $$response{reason}");

		if ($$response{status} == 599)
		{
			$self -> log(error => "Exception message: $$response{content}");
		}

		# Return 0 for success and 1 for failure.

		return 1;
	}

	my($out_file) = "data/en.wikipedia.org.wiki.ISO_3166-2.$code2.html";

	open(OUT, '>', $out_file) || die "Can't open file: $out_file: $!\n";
	print OUT $$response{content};
	close OUT;

	$self -> log(info => "Downloaded $out_file");

	# Return 0 for success and 1 for failure.

	return 0;

} # End of get_subcountry_page.

# -----------------------------------------------

sub get_subcountry_pages
{
	my($self) = @_;

	# %downloaded will contain 2-letter codes.

	my(%downloaded);

	my($downloaded)           = $self -> find_downloads;
	@downloaded{@$downloaded} = (1) x @$downloaded;
	my($countries)            = $self -> read_countries_table;

	my(%countries);

	for my $id (keys %$countries)
	{
		if (! $downloaded{$$countries{$id}{code2}})
		{
			$self -> code2($$countries{$id}{code2});
			$self -> url('http://en.wikipedia.org/wiki/ISO_3166-2');
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
	$$arg{url}      ||= 'http://en.wikipedia.org/wiki/ISO_3166-2'; # Caller can set.
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
