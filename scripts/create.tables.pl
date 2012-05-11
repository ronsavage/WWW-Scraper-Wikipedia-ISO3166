#!/usr/bin/env perl

use strict;
use warnings;

use WWW::Scraper::Wikipedia::ISO3166::Database::Create;

# ----------------------------

WWW::Scraper::Wikipedia::ISO3166::Database::Create -> new(verbose => 2) -> create_all_tables;
