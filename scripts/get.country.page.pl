#!/usr/bin/env perl
#
# Name:
#	populate.countries.pl.

use strict;
use warnings;

use Getopt::Long;

use WWW::Scraper::Wikipedia::ISO3166::Database::Download;

use Pod::Usage;

# -----------------------------------------------

my($option_parser) = Getopt::Long::Parser -> new();

my(%option);

if ($option_parser -> getoptions
(
	\%option,
	'help',
	'verbose=s',
) )
{
	pod2usage(1) if ($option{'help'});

	exit WWW::Scraper::Wikipedia::ISO3166::Database::Download -> new(%option) -> get_country_page;
}
else
{
	pod2usage(2);
}

__END__

=pod

=head1 NAME

get.country.page.pl - Get http://en.wikipedia.org/wiki/ISO_3166-2.html

=head1 SYNOPSIS

populate.countries.pl [options]

	Options:
	-help
	-verbose $integer

All switches can be reduced to a single letter.

Exit value: 0.

Default input: http://en.wikipedia.org.wiki.ISO_3166-2.html.

Default output: data/en.wikipedia.org.wiki.ISO_3166-2.html.

=head1 OPTIONS

=over 4

=item -help

Print help and exit.

=item -verbose => $integer

Print more or less progress reports. Details (more-or-less):

	0: Print nothing.
	1: Warnings, or anything I'm working on.
	2: The country table and specials table.
	3: The kinds of subcountries encountered. See comments in code re 'verbose > 2'.

Default: 0.

=back

=cut
