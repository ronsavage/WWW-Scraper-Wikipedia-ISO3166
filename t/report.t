#!/usr/bin/env perl

use Capture::Tiny 'capture';

use Test2::Bundle::Extended; # Turns on strict and warnings.

use WWW::Scraper::Wikipedia::ISO3166::Database;

# ---------------------------------------------

my(@params);

push @params, '-Ilib', 'scripts/report.statistics.pl';
push @params, '-max', 'info';

my($stdout, $stderr, $result)	= capture{system($^X, @params)};
my(@got)						= map{s/\s+$//; $_} split(/\n/, $stdout);
my(@expected)					= split(/\n/, <<EOS);
countries_in_db => 249
has_subcounties => 200
subcountries_in_db => 3507
subcountry_files_downloaded => 249
subcountry_types_in_db => 352
EOS

is(\@got, \@expected, 'report_statistics() returned the expected data');

@params = ();

push @params, '-Ilib', 'scripts/report.Australian.statistics.pl';
push @params, '-max', 'info';

($stdout, $stderr, $result)	= capture{system($^X, @params)};
(@got)						= map{s/\s+$//; $_} split(/\n/, $stdout);
(@expected)					= split(/\n/, <<EOS);
1: New South Wales
2: Queensland
3: South Australia
4: Tasmania
5: Victoria
6: Western Australia
7: Australian Capital Territory
8: Northern Territory
EOS

is(\@got, \@expected, 'report_Australian_statistics() returned the expected data');

done_testing;
