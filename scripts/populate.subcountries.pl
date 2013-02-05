#!/usr/bin/env perl

use feature 'say';
use strict;
use utf8;
use warnings;
use warnings  qw(FATAL utf8);    # Fatalize encoding glitches.
use open      qw(:std :utf8);    # Undeclared streams in UTF-8.
use charnames qw(:full :short);  # Unneeded in v5.16.

use Getopt::Long;

use WWW::Scraper::Wikipedia::ISO3166::Database::Import;

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

	exit WWW::Scraper::Wikipedia::ISO3166::Database::Import -> new(%option) -> populate_subcountries;
}
else
{
	pod2usage(2);
}

__END__

=pod

=head1 NAME

populate.subcountries.pl - Parse en.wikipedia.org.wiki.ISO_3166-2.$code2.html for all missing $code2

=head1 SYNOPSIS

populate.subcountries.pl [options]

	Options:
	-help
	-verbose $integer

All switches can be reduced to a single letter.

Exit value: 0.

Default input: data/en.wikipedia.org.wiki.ISO_3166-2.$code2.html for all not-yet-imported $code2.

These is output by scripts/get.subcountry.page.pl.

Default output: share/www.scraper.wikipedia.iso3166.sqlite.

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
