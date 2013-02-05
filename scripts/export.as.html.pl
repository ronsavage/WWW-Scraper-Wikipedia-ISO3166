#!/usr/bin/env perl
#
# Name:
#	export.as.html.pl.

use feature 'say';
use strict;
use utf8;
use warnings;
use warnings  qw(FATAL utf8);    # Fatalize encoding glitches.
use open      qw(:std :utf8);    # Undeclared streams in UTF-8.
use charnames qw(:full :short);  # Unneeded in v5.16.

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
	'verbose=s',
	'web_page_file=s',
) )
{
	pod2usage(1) if ($option{'help'});

	exit WWW::Scraper::Wikipedia::ISO3166::Database::Export -> new(%option) -> as_html;
}
else
{
	pod2usage(2);
}

__END__

=pod

=head1 NAME

export.as.html.pl - Export the SQLite database as HTML

=head1 SYNOPSIS

export.as.html.pl [options]

	Options:
	-help
	-verbose $integer
	-web_page_file $aFileName

All switches can be reduced to a single letter.

Exit value: 0.

Default input: share/www.scraper.wikipedia.iso3166.sqlite.

Default output: Screen.

=head1 OPTIONS

=over 4

=item o -help

Print help and exit.

=item o -verbose $integer

Print more or less progress reports. Details (more-or-less):

	0: Print nothing.
	1: Warnings, or anything I'm working on.
	2: The country table and specials table.
	3: The kinds of subcountries encountered. See comments in code re 'verbose > 2'.

Default: 0.

=item o -web_page_file $aFileName

A HTML file name, to which country and subcountry data is to be output.

Default: iso.3166-2.html

=back

=cut
