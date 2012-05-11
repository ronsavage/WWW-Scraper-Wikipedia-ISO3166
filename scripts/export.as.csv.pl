#!/usr/bin/env perl
#
# Name:
#	export.as.csv.pl.

use open qw/:std :utf8/;
use strict;
use warnings;
use warnings qw/FATAL utf8/;

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
	'subcountry_file=s',
	'verbose=s',
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
	-subcountry_file $aFileName
	-verbose $integer

All switches can be reduced to a single letter.

Exit value: 0.

Default input: share/www.scraper.wikipedia.iso3166.sqlite.

Default output: Screen.

=head1 OPTIONS

=over 4

=item o -country_file $aFileName

A CSV file name, to which country data will be written.

Default: country.csv

=item o -subcountry_file $aFileName

A CSV file name, to which subcountry data will be written.

Default: subcountry.csv

=item o -help

Print help and exit.

=item o -verbose $integer

Print more or less progress reports. Details (more-or-less):

	0: Print nothing.
	1: Warnings, or anything I'm working on.
	2: The country table and specials table.
	3: The kinds of subcountries encountered. See comments in code re 'verbose > 2'.

Default: 0.

=back

=cut
