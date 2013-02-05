#!/usr/bin/env perl

use feature 'say';
use strict;
use utf8;
use warnings;
use warnings  qw(FATAL utf8);    # Fatalize encoding glitches.
use open      qw(:std :utf8);    # Undeclared streams in UTF-8.
use charnames qw(:full :short);  # Unneeded in v5.16.

use WWW::Scraper::Wikipedia::ISO3166::Database;

# -----------------------------------------------

my($db)   = WWW::Scraper::Wikipedia::ISO3166::Database -> new;
my($data) = $db -> dbh -> selectall_arrayref("select * from countries where code2 = 'AX'", { Slice => {} });

for my $record (@$data)
{
	say join("\n", map{"$_ => $$record{$_}"} sort keys %$record);
}
