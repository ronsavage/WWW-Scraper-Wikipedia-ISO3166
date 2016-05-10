#!/usr/bin/env perl

use inc::Module::Install;

# -----------------------

name 'WWW-Scraper-Wikipedia-ISO3166';

license 'perl';

all_from 'lib/WWW/Scraper/Wikipedia/ISO3166.pm';

install_share;

license 'perl';

resources
repository => 'https://github.com/ronsavage/WWW-Scraper-Wikipedia-ISO3166.git';

requires 'Capture::Tiny'			=> 0.36;
requires 'charnames'                => 0;
requires 'Config::Tiny'             => 2.14;
requires 'DBD::SQLite'              => 1.35;
requires 'DBI'                      => 1.620;
requires 'DBIx::Admin::CreateTable' => 2.07;
requires 'Encode'                   => 2.44;
requires 'feature'                  => 0,
requires 'File::ShareDir'           => 1.03;
requires 'File::Slurper'            => 0.008;
requires 'File::Spec'               => 3.33;
requires 'Getopt::Long'             => 2.38;
requires 'HTML::TreeBuilder'        => 4.2;
requires 'HTTP::Tiny'               => 0.056;
requires 'List::AllUtils'           => 0.03;
requires 'List::Compare'            => 0.37;
requires 'Moo'						=> 2.001001;
requires 'open'                     => 1.08;
requires 'parent'                   => 0.225;
requires 'Pod::Usage'               => 1.51;
requires 'strict'                   => 1.04;
requires 'Text::Xslate'             => 1.5008;
requires 'Types::Standard'			=> 1.000005;
requires 'Unicode::CaseFold'        => 0.02;
requires 'Unicode::Normalize'       => 1.14;
requires 'utf8'                     => 0;
requires 'warnings'                 => 1.12;

test_requires 'Test::More'			=> '0.98';
#test_requires 'Pod::Simple'		=> '3.28'; # Make it optional. See t/pod.t
#test_requires 'Test::Pod'			=> '1.48'; # Make it optional. See t/pod.t

WriteAll;
