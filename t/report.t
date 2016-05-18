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
info: has_subcounties => 200.
info: subcountries_in_db => 3503.
info: subcountry_files_downloaded => 249.
EOS

is_deeply(\@got, \@expected, 'report_statistics() returned the expected data');

@params = ();

push @params, '-Ilib', 'scripts/report.Australian.statistics.pl';
push @params, '-v', 1;

($stdout, $stderr, $result)	= capture{system($^X, @params)};
(@got)						= map{s/\s+$//; $_} split(/\n/, $stdout);
(@expected)					= split(/\n/, <<EOS);
info: 1: New South Wales.
info: 2: Queensland.
info: 3: South Australia.
info: 4: Tasmania.
info: 5: Victoria.
info: 6: Western Australia.
info: 7: Australian Capital Territory.
info: 8: Northern Territory.
EOS

is_deeply(\@got, \@expected, 'report_Australian_statistics() returned the expected data');

done_testing;
