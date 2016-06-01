#!/usr/bin/env perl

use strict;
use warnings;
use warnings  qw(FATAL utf8);    # Fatalize encoding glitches.
use open      qw(:std :utf8);    # Undeclared streams in UTF-8.

use Getopt::Long;

use WWW::Scraper::Wikipedia::ISO3166::Database::Export;

use Pod::Usage;

# -----------------------------------------------

my($option_parser) = Getopt::Long::Parser -> new();

my(%option);

if ($option_parser -> getoptions
(
	\%option,
	'help',
	'country_file=s',
	'maxlevel=s',
	'subcountry_file=s',
	'subcountry_type_file=s',
) )
{
	pod2usage(1) if ($option{'help'});

	exit WWW::Scraper::Wikipedia::ISO3166::Database::Export -> new(%option) -> as_csv;
}
else
{
	pod2usage(2);
}

__END__

=pod

=head1 NAME

export.as.csv.pl - Export the SQLite database as CSV

=head1 SYNOPSIS

export.as.html.pl [options]

	Options:
	-help
	-country_file $aFileName
	-maxlevel $integer
	-subcountry_file $aFileName
	-subcountry_type_file $aFileName

All switches can be reduced to a single letter.

Exit value: 0.

Default input: share/www.scraper.wikipedia.iso3166.sqlite.

Default output: Screen.

=head1 OPTIONS

=over 4

=item o -country_file $aFileName

A CSV file name, to which country data will be written.

Default: countries.csv

=item o -help

Print help and exit.

=item -maxlevel => $string

Typical values: 'debug'.

Default: 'notice'.

=item o -subcountry_file $aFileName

A CSV file name, to which subcountry data will be written.

Default: subcountries.csv

=item o -subcountry_type_file $aFileName

A CSV file name, to which subcountry type data will be written.

Default: subcountry.types.csv

=back

=cut
