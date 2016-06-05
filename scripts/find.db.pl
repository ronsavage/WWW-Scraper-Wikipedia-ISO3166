#!/usr/bin/env perl

use strict;
use warnings;

use File::ShareDir;

# -----------------

my($app_name)	= 'WWW-Scraper-Wikipedia-ISO3166';
my($db_name)	= shift || 'share/www.scraper.wikipedia.iso3166.sqlite';
$db_name		.= '.sqlite' if ($db_name && ($db_name !~ /\.sqlite$/) );
my($path)		= File::ShareDir::dist_file($app_name, $db_name);

print "Using: File::ShareDir::dist_file('$app_name', '$db_name'): \n";
print "Found: $path\n";
