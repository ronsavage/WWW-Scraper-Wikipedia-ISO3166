#!/usr/bin/env perl

use strict;
use warnings;

use Getopt::Long;

use WWW::Scraper::Wikipedia::ISO3166::Database;

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

	exit WWW::Scraper::Wikipedia::ISO3166::Database -> new(%option) -> report_Australian_statistics;
}
else
{
	pod2usage(2);
}

__END__

=pod

=head1 NAME

report.statistics.pl - Report some stats about the SQLite database

=head1 SYNOPSIS

report.statistics.pl [options]

	Options:
	-help
	-verbose $integer

All switches can be reduced to a single letter.

Exit value: 0.

Default input: share/www.scraper.wikipedia.iso3166.sqlite.

Default output: Screen.

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
