package WWW::Scraper::Wikipedia::ISO3166::Database::Export;

use open qw/:std :utf8/;
use parent 'WWW::Scraper::Wikipedia::ISO3166::Database';
use strict;
use warnings;

use Config::Tiny;

use Encode; # For encode().

use Hash::FieldHash ':all';

use Text::Xslate 'mark_raw';

use Unicode::Normalize; # For NFC().

fieldhash my %config          => 'config';
fieldhash my %country_file    => 'country_file';
fieldhash my %subcountry_file => 'subcountry_file';
fieldhash my %templater       => 'templater';
fieldhash my %web_page_file   => 'web_page_file';

our $VERSION = '1.01';

# -----------------------------------------------

sub as_csv
{
	my($self)      = @_;
	my($countries) = $self -> read_countries_table;

	my(@row);

	push @row,
	[
		qw/id code2 code3 fc_name has_subcountries name timestamp/
	];

	for my $id (sort{NFC($$countries{$a}{name}) cmp NFC($$countries{$b}{name})} keys %$countries)
	{
		push @row,
		[
			$id,
			$$countries{$id}{code2},
			$$countries{$id}{code3},
			$$countries{$id}{fc_name},
			$$countries{$id}{has_subcountries},
			$$countries{$id}{name},
			$$countries{$id}{timestamp},
		];
	}

	die "No country_file name specified\n" if (! $self -> country_file);

	open(OUT, '>', $self -> country_file) || die "Can't open file: " . $self -> country_file . "\n";

	for (@row)
	{
		print OUT '"', join('","', @$_), '"', "\n";
	}

	close OUT;

	die "Country and subcountry file names are the same\n" if ($self -> country_file eq $self -> subcountry_file);

	my($subcountries) = $self -> read_subcountries_table;
	@row              = ();

	push @row,
	[
		qw/id country_id code fc_name name sequence timestamp/
	];

	for my $id (sort{NFC($$subcountries{$a}{name}) cmp NFC($$subcountries{$b}{name})} keys %$subcountries)
	{
		push @row,
		[
			$id,
			$$subcountries{$id}{country_id},
			$$subcountries{$id}{code},
			$$subcountries{$id}{fc_name},
			$$subcountries{$id}{name},
			$$subcountries{$id}{sequence},
			$$subcountries{$id}{timestamp},
		];
	}

	die "No subcountry_file name specified\n" if (! $self -> subcountry_file);

	open(OUT, '>', $self -> subcountry_file) || die "Can't open file: " . $self -> subcountry_file . "\n";

	for (@row)
	{
		print OUT '"', join('","', @$_), '"', "\n";
	}

	close OUT;

}	# End of as_csv.

# ------------------------------------------------

sub as_html
{
	my($self)   = @_;
	my($config) = $self -> config;

	die "No web_page_file name specified\n" if (! $self -> web_page_file);

	open(OUT, '>', $self -> web_page_file) || die "Can't open file: " . $self -> web_page_file . "\n";
	binmode(OUT, ':utf8');

	print OUT $self -> templater -> render
		(
		 'iso3166.report.tx',
		 {
			 country_data => $self -> build_country_data,
			 default_css  => "$$config{_}{css_url}/default.css",
		 }
		);

	close OUT;

} # End of as_html.

# ------------------------------------------------

sub build_country_data
{
	my($self)         = @_;
	my($countries)    = $self -> read_countries_table;
	my($subcountries) = $self -> read_subcountries_table;

	my($country_id);
	my(%subcountries);

	for my $sub_id (keys %$subcountries)
	{
		$country_id                = $$subcountries{$sub_id}{country_id};
		$subcountries{$country_id} = [] if (! $subcountries{$country_id});

		push @{$subcountries{$country_id} },
		[
			$$subcountries{$sub_id}{sequence}, # Sort key, below.
			$$subcountries{$sub_id}{code},
			$$subcountries{$sub_id}{name},
		];
	}

	my(@tr);

	push @tr, [{td => '#'}, {td => 'Db key'}, {td => 'Code2'}, {td => 'Code3'}, {td => 'Name'}, {td => 'Subcountries'}];

	my($count) = 1;

	for my $id (sort{NFC($$countries{$a}{name}) cmp NFC($$countries{$b}{name})} keys %$countries)
	{
		push @tr,
		[
			{td => $count++},
			{td => $id},
			{td => mark_raw($$countries{$id}{code2})},
			{td => mark_raw($$countries{$id}{code3})},
			{td => mark_raw($$countries{$id}{name})},
			{td => $$countries{$id}{has_subcountries} },
		];

		next if (! $subcountries{$id});

		# Sort by sequence.

		for my $sub_id (sort{$$a[0] <=> $$b[0]} @{$subcountries{$id} })
		{
			push @tr,
			[
				{td => ''},
				{td => ''},
				{td => ''},
				{td => mark_raw($$sub_id[1])},
				{td => mark_raw($$sub_id[2])},
				{td => ''},
			];
		}
	}

	push @tr, [{td => '#'}, {td => 'Key'}, {td => 'Code2'}, {td => 'Code3'}, {td => 'Name'}, {td => 'Subcountries'}];

	return [@tr];

} # End of build_country_data.

# -----------------------------------------------

sub _init
{
	my($self, $arg)        = @_;
	$$arg{config}          = '';
	$$arg{country_file}    ||= 'countries.csv';    # Caller can set.
	$$arg{subcountry_file} ||= 'subcountries.csv'; # Caller can set.
	$$arg{templater}       = '';
	$$arg{web_page_file }  ||= 'iso.3166-2.html'; # Caller can set.
	$self                  = $self -> SUPER::_init($arg);

	$self -> config(Config::Tiny -> read($self -> config_file) );
	$self -> templater
	(
		Text::Xslate -> new
		(
		 input_layer => '',
		 path        => ${$self -> config}{_}{template_path},
		)
	);

	return $self;

} # End of _init.

# -----------------------------------------------

sub new
{
	my($class, %arg) = @_;
	my($self)        = bless {}, $class;
	$self            = $self -> _init(\%arg);

	return $self;

}	# End of new.

# ------------------------------------------------

1;

=pod

=head1 NAME

WWW::Scraper::Wikipedia::ISO3166::Database::Export - Export www.scraper.wikipedia.iso3166.sqlite as CSV and HTML

=head1 Synopsis

See L<WWW::Scraper::Wikipedia::ISO3166/Synopsis>.

=head1 Description

Documents the methods end-users need to export the SQLite database,
I<www.scraper.wikipedia.iso3166.sqlite>, which ships with this distro, as either CSV or HTML.

See scripts/export.as.csv.pl and scripts/export.as.html.pl.

The input to these scripts is shipped as share/www.scraper.wikipedia.iso3166.sqlite.

The output of these scripts is shipped as:

=over 4

=item o data/countries.csv

=item o data/iso.3166-2.html

This file is on-line at: L<http://savage.net.au/Perl-modules/html/WWW/Scraper/Wikipedia/ISO3166/iso.3166-2.html>.

=item o data/subcountries.csv

=back

=head1 Distributions

This module is available as a Unix-style distro (*.tgz).

See http://savage.net.au/Perl-modules.html for details.

See http://savage.net.au/Perl-modules/html/installing-a-module.html for
help on unpacking and installing.

=head1 Constructor and initialization

new(...) returns an object of type C<WWW::Scraper::Wikipedia::ISO3166::Database::Export>.

This is the class's contructor.

Usage: C<< WWW::Scraper::Wikipedia::ISO3166::Database::Export -> new() >>.

This method takes a hash of options.

Call C<new()> as C<< new(option_1 => value_1, option_2 => value_2, ...) >>.

Available options (these are also methods):

=over 4

=item o country_file => $a_csv_file_name

Specify the name of the CSV file to which country data is exported.

Default: 'countries.csv'.

=item o subcountry_file => $a_csv_file_name

Specify the name of the CSV file to which subcountry data is exported.

Default: 'subcountries.csv'.

=item o web_page_file => $a_html_file_name

Specify the name of the HTML file to which country and subcountry data is exported.

See htdocs/assets/templates/www/scraper/wikipedia/iso3166/iso3166.report.tx for the web page template used.

*.tx files are processed with L<Text::Xslate>.

Default: 'iso.3166-2.html'.

=back

=head1 Methods

This module is a sub-class of L<WWW::Scraper::Wikipedia::ISO3166::Database> and consequently inherits its methods.

=head2 as_csv()

Export the SQLite database to 2 CSV files.

=head2 as_html()

Export the SQLite database to 1 HTML file.

=head2 build_country_data()

Builds part of a HTML table, and returns an arrayref of arrayrefs of hashrefs suitable for L<Text::Xslate>.

=head2 country_file($file_name)

Get or set the name of the CSV file to which country data is exported.

Also, I<country_file> is an option to L</new()>.

=head2 new()

See L</Constructor and initialization>.

=head2 subcountry_file($file_name)

Get or set the name of the CSV file to which subcountry data is exported.

Also, I<subcountry_file> is an option to L</new()>.

=head2 web_page_file($file_name)

Get or set the name of the HTML file to which country and subcountry data is exported.

Also, I<web_page_file> is an option to L</new()>.

=head1 FAQ

For the database schema, etc, see L<WWW::Scraper::Wikipedia::ISO3166/FAQ>.

=head1 References

See L<WWW::Scraper::Wikipedia::ISO3166/References>.

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
