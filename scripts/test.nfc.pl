#!/usr/bin/env perl

use feature 'say';
use open qw/:std :utf8/;
use strict;
use warnings;
use warnings qw/FATAL utf8/;

use WWW::Scraper::Wikipedia::ISO3166::Database;

# -----------------------------------------------

my($db)   = WWW::Scraper::Wikipedia::ISO3166::Database -> new;
my($data) = $db -> dbh -> selectall_arrayref("select * from countries where code2 = 'AX'", { Slice => {} });

for my $record (@$data)
{
	say join("\n", map{"$_ => $$record{$_}"} sort keys %$record);
}