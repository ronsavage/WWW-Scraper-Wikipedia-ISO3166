#!/usr/bin/env perl

use feature 'say';
use strict;
use utf8;
use warnings;
use warnings  qw(FATAL utf8);    # Fatalize encoding glitches.
use open      qw(:std :utf8);    # Undeclared streams in UTF-8.
use charnames qw(:full :short);  # Unneeded in v5.16.

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

	exit WWW::Scraper::Wikipedia::ISO3166::Database::Download -> new(%option) -> get_statoids_pages;
}
else
{
	pod2usage(2);
}

__END__

=pod

=head1 NAME

get.statoids.pages.pl - Get all country pages from http://statoids.com/.

=head1 SYNOPSIS

get.statoids.pages.pl [options]

	Options:
	-help
	-verbose $integer

All switches can be reduced to a single letter.

Exit value: 0.

1: Input: http://statoids.com/

Output: data/statoids.(la, ...).html

=head1 OPTIONS

=over 4

=item -help

Print help and exit.

=item -verbose => $Boolean

Print more or less progress reports.

Default: 0.

=back

=cut
