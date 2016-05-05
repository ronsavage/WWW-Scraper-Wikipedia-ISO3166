package WWW::Scraper::Wikipedia::ISO3166;

require v5.10.1;
use strict;
use warnings;

use File::ShareDir;
use File::Spec;

use Hash::FieldHash ':all';

fieldhash my %config_file  => 'config_file';
fieldhash my %data_file    => 'data_file';
fieldhash my %share_dir    => 'share_dir';
fieldhash my %sqlite_file  => 'sqlite_file';
fieldhash my %verbose      => 'verbose';

our $VERSION = '1.02';

# -----------------------------------------------

sub _init
{
	my($self, $arg)    = @_;
	$$arg{config_file} ||= '.htwww.scraper.wikipedia.iso3166.conf'; # Caller can set.
	$$arg{data_file}   = 'data/en.wikipedia.org.wiki.ISO_3166-2';
	$$arg{sqlite_file} ||= 'www.scraper.wikipedia.iso3166.sqlite';  # Caller can set.
	$$arg{verbose}     ||= 0; # Caller can set.
	$self              = from_hash($self, $arg);
	(my $package       = __PACKAGE__) =~ s/::/-/g;
	my($dir_name)      = $ENV{AUTHOR_TESTING} ? 'share' : File::ShareDir::dist_dir($package);

	$self -> config_file(File::Spec -> catfile($dir_name, $self -> config_file) );
	$self -> sqlite_file(File::Spec -> catfile($dir_name, $self -> sqlite_file) );

	return $self;

} # End of _init.

# -----------------------------------------------

sub log
{
	my($self, $level, $s) = @_;
	$level ||= 'debug';
	$s     ||= '';

	print "$level: $s. \n" if ($self -> verbose);

}	# End of log.

# -----------------------------------------------

sub new
{
	my($class, %arg) = @_;
	my($self)        = bless {}, $class;
	$self            = $self -> _init(\%arg);

	return $self;

}	# End of new.

# -----------------------------------------------

sub run
{
	my($self) = @_;

	# Return 0 for success and 1 for failure.

	return 0;

} # End of run.

# -----------------------------------------------

1;

=pod

=head1 NAME

WWW::Scraper::Wikipedia::ISO3166 - Gently scrape Wikipedia for ISO3166-2 data

=encoding utf-8

=head1 Synopsis

Wikipedia I<has been scraped>. You do not need to run the scripts which download pages from there.

Just use the SQLite database shipped with this module, as discussed next.

=head2 Methods which return hashrefs

	use WWW::Scraper::Wikipedia::ISO3166::Database;

	my($database)     = WWW::Scraper::Wikipedia::ISO3166::Database -> new;
	my($countries)    = $database -> read_countries_table;
	my($subcountries) = $database -> read_subcountries_table;
	...

Each key in %$countries and %$subcountries points to a hashref of all columns for the given key.

So, $$countries{13} points to this hashref:

	{
		id                => 13,
		code2             => 'AU',
		code3             => '',
		fc_name           => 'australia',
		hash_subcountries => 'Yes',
		name              => 'Australia',
		timestamp         => '2012-05-08 04:04:43',
	}

One element of %$subcountries is $$subcountries{4276}:

	{
		id         => 4276,
		country_id => 13,
		code       => 'AU-VIC',
		fc_name    => 'victoria',
		name       => 'Victoria',
		sequence   => 5,
		timestamp  => '2012-05-08 04:05:27',
	}

=head3 Warnings

# 1: These hashrefs use the table's primary key as the hashref's key. In the case of the I<countries>
table, the primary key is the country's id, and is used as subcountries.country_id. But, in the case of
the I<subcountries> table, the id does not have any meaning apart from being a db primary key.
See L</What is the database schema?> for details.

# 2: Do not assume subcountry names are unique within a country.

L<See 'Taichung' etc in Taiwan for example|http://en.wikipedia.org/wiki/ISO_3166-2:TW>.

=head2 Scripts which output to a file

All scripts respond to the -h option.

Some examples:

	shell>perl scripts/export.as.csv.pl -c countries.csv -s subcountries.csv
	shell>perl scripts/export.as.html.pl -w iso.3166-2.html

This file is on-line at: L<http://savage.net.au/Perl-modules/html/WWW/Scraper/Wikipedia/ISO3166/iso.3166-2.html>.

	shell>perl scripts/report.statistics.pl

	Output statistics:
	countries_in_db => 249.
	has_subcounties => 199.
	subcountries_in_db => 4593.
	subcountry_files_downloaded => 249.

=head1 Description

C<WWW::Scraper::Wikipedia::ISO3166> is a pure Perl module.

It is used to download various ISO3166-related pages from Wikipedia, and to then import data
(scraped from those pages) into an SQLite database.

The pages have already been downloaded, so that phase only needs to be run when pages are updated.

Likewise, the data has been imported.

This means you would normally only ever use the database in read-only mode.

Its components are:

=over 4

=item o scripts/get.country.page.pl

1: Downloads the ISO3166-1_alpha-3 page from Wikipedia.

Input: L<http://en.wikipedia.org/wiki/ISO_3166-1_alpha-3>.

Output: data/en.wikipedia.org.wiki.ISO_3166-2.3.html.

2: Downloads the ISO3166-2 page from Wikipedia.

Input: L<http://en.wikipedia.org/wiki/ISO_3166-2>.

Output: data/en.wikipedia.org.wiki.ISO_3166-2.html.

=item o scripts/populate.countries.pl

Imports country data into an SQLite database.

inputs: data/en.wikipedia.org.wiki.ISO_3166-2.html, data/en.wikipedia.org.wiki.ISO_3166-2.3.html.

Output: share/www.scraper.wikipedia.iso3166.sqlite.

=item o scripts/get.subcountry.page.pl and scripts/get.subcountry.pages.pl

Downloads each countries' corresponding subcountries page.

Source: http://en.wikipedia.org/wiki/ISO_3166:$code2.html.

Output: data/en.wikipedia.org.wiki.ISO_3166-2.$code2.html.

=item o scripts/populate.subcountry.pl and scripts/populate.subcountries.pl

Imports subcountry data into the database.

Source: data/en.wikipedia.org.wiki.ISO_3166-2.$code2.html.

Output: share/www.scraper.wikipedia.iso3166.sqlite.

Note: When the distro is installed, this SQLite file is installed too.
See L</Where is the database?> for details.

=item o scripts/export.as.csv.pl -c c.csv -s s.csv

Exports the country and subcountry data as CSV.

Input: share/www.scraper.wikipedia.iso3166.sqlite.

Output: data/countries.csv and data/subcountries.csv.

=item o scripts/export.as.html -w c.html

Exports the country and subcountry data as HTML.

Input: share/www.scraper.wikipedia.iso3166.sqlite.

Output: data/iso.3166-2.html.

On-line: L<http://savage.net.au/Perl-modules/html/WWW/Scraper/Wikipedia/ISO3166/iso.3166-2.html>.

=item o scripts/get.statoids.pl

Downloads some pages from L<http://statoids.com> in case one day we need to convert from FIPS to ISO 3166-2.

See data/List_of_FIPS_region_codes_*.html.

=item o scripts/populate.fips.codes.pl

This reads the files output by scripts/get.statoids.pl and produces 2 reports, data/wikipedia.fips.codes.txt
and data/wikipedia.fips.mismatch.log. These are discussed in L</What FIPS data is included?>

=item o scripts/test.nfc.pl

See L</Why did you use C<Unicode::Normalize>'s NFC() for sorting?> for a discussion of this script.

=back

=head1 Constructor and initialization

new(...) returns an object of type C<WWW::Scraper::Wikipedia::ISO3166>.

This is the class's contructor.

Usage: C<< WWW::Scraper::Wikipedia::ISO3166 -> new() >>.

This method takes a hash of options.

Call C<new()> as C<< new(option_1 => value_1, option_2 => value_2, ...) >>.

Available options (these are also methods):

=over 4

=item o config_file => $file_name

The name of the file containing config info, such as I<css_url> and I<template_path>.
These are used by L<WWW::Scraper::Wikipedia::ISO3166::Database::Export/as_html()>.

The code prefixes this name with the directory returned by L<File::ShareDir/dist_dir()>.

Default: .htwww.scraper.wikipedia.iso3166.conf.

=item o sqlite_file => $file_name

The name of the SQLite database of country and subcountry data.

The code prefixes this name with the directory returned by L<File::ShareDir/dist_dir()>.

Default: www.scraper.wikipedia.iso3166.sqlite.

=item o verbose => $integer

Print more or less information.

Default: 0 (print nothing).

=back

=head1 Distributions

This module is available as a Unix-style distro (*.tgz).

Install WWW::Scraper::Wikipedia::ISO3166 as you would for any C<Perl> module:

Run:

	cpanm WWW::Scraper::Wikipedia::ISO3166

or run:

	sudo cpan WWW::Scraper::Wikipedia::ISO3166

or unpack the distro, and then run:

	perl Makefile.PL
	make (or dmake)
	make test
	make install

See L<http://savage.net.au/Perl-modules.html> for details.

See L<http://savage.net.au/Perl-modules/html/installing-a-module.html> for
help on unpacking and installing.

=head1 Methods

=head2 config_file($file_name)

Get or set the name of the config file.

The code prefixes this name with the directory returned by L<File::ShareDir/dist_dir()>.

Also, I<config_file> is an option to L</new()>.

=head2 log($level => $s)

Print $s at log level $level, if ($self -> verbose);

Since $self -> verbose defaults to 0, nothing is printed by default.

=head2 new()

See L</Constructor and initialization>.

=head2 sqlite_file($file_name)

Get or set the name of the database file.

The code prefixes this name with the directory returned by L<File::ShareDir/dist_dir()>.

Also, I<sqlite_file> is an option to L</new()>.

=head2 verbose($integer)

Get or set the verbosity level.

Also, I<verbose> is an option to L</new()>.

=head1 FAQ

=head2 Design faults in ISO3166

Where ISO3166 uses Country Name, I would have used Long Name and Short Name.

Then we'd have:

	Long Name:  Bolivia, Plurinational State of
	Short Name: Bolivia

This distro uses the value directly from Wikipedia, which is what I have called 'Long Name', for
all country and subcountry names.

=head2 Where is the database?

It is shipped in share/www.scraper.wikipedia.iso3166.sqlite.

It is installed into the distro's shared dir, as returned by L<File::ShareDir/dist_dir()>.
On my machine that's:

/home/ron/perl5/perlbrew/perls/perl-5.14.2/lib/site_perl/5.14.2/auto/share/dist/WWW-Scraper-Wikipedia-ISO3166/www.scraper.wikipedia.iso3166.sqlite.

=head2 What is the database schema?

A single SQLite file holds 2 tables, I<countries> and I<subcountries>:

	countries           subcountries
	---------           ------------
	id                  id
	code2               country_id
	code3               code
	fc_name             fc_name
	has_subcountries    name
	name                sequence
	timestamp           timestamp

I<code3> has a couple of special cases. 2 countries have no value for code3:
Libyan Arab Jamahiriya and Sint Maarten.
3-letter codes which almost match: LBY => Libya and MAF => Saint Martin (French part).

I<subcountries.country_id> points to I<countries.id>.

I<fc_name> is output from calling fc(decode('utf8', $name) ).

For decode(), see L<Encode/THE PERL ENCODING API>.

For fc(), see L<Unicode::CaseFold/fc($str)>.

$name is from a Wikipedia page.

I<has_subcountries> is 'Yes' or 'No'.

I<name> is output from calling decode('utf8', $name).

I<sequence> is a number (1 .. N) indicating the order in which subcountry names appear in the list
on that subcountry's Wikipedia page.

See the source code of L<WWW::Scraper::Wikipedia::ISO3166::Database::Create> for details of the SQL
used to create the tables.

=head2 What do I do if I find a mistake in the data?

What data? What mistake? How do you know it's wrong?

Also, you must decide what exactly you were expecting the data to be.

If the problem is the ISO data, report it to them.

If the problem is the Wikipedia data, get agreement from everyone concerned and update Wikipedia.

If the problem is the output from my code, try to identify the bug in the code and report it via the
usual mechanism. See L</Support>.

If the problem is with your computer's display of the data, consider (in alphabetical order):

=over 4

=item o CSV

Does the file display correctly in 'Emacs'? On the screen using 'less'?

scripts/export.as.csv.pl uses: use open ':utf8';

Is that not working?

=item o DBD::SQLite

Did you set the sqlite_unicode attribute? Use something like:

	my($dsn)        = 'dbi:SQLite:dbname=www.scraper.wikipedia.iso3166.sqlite'; # Sample only.
	my($attributes) = {AutoCommit => 1, RaiseError => 1, sqlite_unicode => 1};
	my($dbh)        = DBI -> connect($dsn, '', '', $attributes);

The SQLite file ships in the share/ directory of the distro, and must be found by File::ShareDir
at run time.

Did you set the foreign_keys pragma (if needed)? Use:

	$dbh -> do('PRAGMA foreign_keys = ON');

=item o HTML

The template htdocs/assets/templates/www/scraper/wikipedia/iso3166/iso3166.report.tx which ships with
this distro contains this line:

	<meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />

Is that not working?

=item o Locale

Here's my setup:

	shell>locale
	LANG=en_AU.utf8
	LANGUAGE=
	LC_CTYPE="en_AU.utf8"
	LC_NUMERIC="en_AU.utf8"
	LC_TIME="en_AU.utf8"
	LC_COLLATE="en_AU.utf8"
	LC_MONETARY="en_AU.utf8"
	LC_MESSAGES="en_AU.utf8"
	LC_PAPER="en_AU.utf8"
	LC_NAME="en_AU.utf8"
	LC_ADDRESS="en_AU.utf8"
	LC_TELEPHONE="en_AU.utf8"
	LC_MEASUREMENT="en_AU.utf8"
	LC_IDENTIFICATION="en_AU.utf8"
	LC_ALL=

=item o OS

Unicode is a moving target. Perhaps your OS's installed version of unicode fies needs updating.

=item o SQLite

Both Oracle and SQLite.org ship a program called sqlite3. They are not compatible.
Which one are you using? I use the one from the SQLite.org.

AFAICT, sqlite3 does not have command line options, or options while running, to set unicode or pragmas.

=back

=head2 Why did you use L<Unicode::Normalize>'s NFC() for sorting?

This question implies why not use NFD() instead.

Run scripts/test.nfc.pl, and the output is:

	code2 => AX
	code3 => ALA
	fc_name => åland islands
	has_subcountries => No
	id => 15
	name => Åland Islands
	timestamp => 2012-05-13 23:37:20

And this (Åland Islands) is what Wikipedia displays. So, NFC() it is.

See L<http://www.perl.com/pub/2012/04>, and specifically prescription # 1.

See also section 1.2 Normalization Forms in L<http://www.unicode.org/reports/tr15/>.

See also L<http://www.unicode.org/faq/normalization.html>.

=head2 What is $ENV{AUTHOR_TESTING} used for?

When this env var is 1, scripts output to share/*.sqlite within the distro's dir. That's how I populate the
database tables. After installation, the database is elsewhere, and read-only, so you don't want the scripts
writing to that copy anyway.

At run-time, L<File::ShareDir> is used to find the installed version of *.sqlite.

=head2 What FIPS data is included?

Firstly, scripts/get.fips.pages.pl downloads some Wikipedia data, into data/List_of_FIPS_region_codes_*.html.

Secondly, the latter files are parsed by scripts/populate.fips.codes.pl and the 2 reports are in
data/wikipedia.fips.codes.txt, and data/wikipedia.fips.mismatch.log.

This data is I<not> written into the SQLite database yet, but it's available in case it's included
one day.

=head1 Wikipedia's Terms of Use

See L<http://wikimediafoundation.org/wiki/Terms_of_use>.

Also, since I'm distributing copies of Wikipedia-sourced material, reformatted but not changed by editing,
I hereby give notice that their material is released under CC-BY-SA.
See L<http://creativecommons.org/licenses/by-sa/3.0/> for that licence.

=head1 References

In no particular order:

L<http://en.wikipedia.org/wiki/ISO_3166-2>.

L<http://en.wikipedia.org/wiki/ISO_3166-1_alpha-3>.

L<http://savage.net.au/Perl-modules/html/WWW/Scraper/Wikipedia/ISO3166/iso.3166-2.html>.

L<http://www.statoids.com/>.

L<http://unicode.org/Public/cldr/latest/core.zip>.

This is complex set of XML files concerning currency, postal, etc, formats and other details for various countries
and/or languages.

For Debian etc users: /usr/share/xml/iso-codes/iso_3166_2.xml, as installed from the iso-codes package, with:

	sudo apt-get install iso-codes

L<http://geonames.org>.

L<http://www.geonames.de/index.html>.

L<http://www.perl.com/pub/2012/04>.

Check the Monthly Archives at Perl.com, starting in April 2012, for a series of Unicode-specific articles by
Tom Christiansen.

L<http://www.unicode.org/reports/tr15/>.

L<http://www.unicode.org/faq/normalization.html>.

=head1 Support

Email the author, or log a bug on RT:

L<https://rt.cpan.org/Public/Dist/Display.html?Name=WWW::Scraper::Wikipedia::ISO3166>.

=head1 Author

C<WWW::Scraper::Wikipedia::ISO3166> was written by Ron Savage I<E<lt>ron@savage.net.auE<gt>> in 2012.

Home page: L<http://savage.net.au/index.html>.

=head1 Copyright

Australian copyright (c) 2012 Ron Savage.

	All Programs of mine are 'OSI Certified Open Source Software';
	you can redistribute them and/or modify them under the terms of
	The Artistic License, a copy of which is available at:
	http://www.opensource.org/licenses/index.html


=cut
