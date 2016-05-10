#!/usr/bin/env perl

use strict;
use warnings;

use Capture::Tiny 'capture';

use Test::More;

use WWW::Scraper::Wikipedia::ISO3166::Database;

# ---------------------------------------------

my(@params);

push @params, '-Ilib', 'scripts/report.statistics.pl';
push @params, '-v', 1;

my($stdout, $stderr, $result)	= capture{system($^X, @params)};
my(@got)						= map{s/\s+$//; $_} split(/\n/, $stdout);
my(@expected)					= split(/\n/, <<EOS);
info: countries_in_db => 249.
info: has_subcounties => 199.
info: subcountries_in_db => 4593.
info: subcountry_files_downloaded => 249.
EOS

is_deeply(\@got, \@expected, 'report_statistics() returned the expected data');

done_testing;
