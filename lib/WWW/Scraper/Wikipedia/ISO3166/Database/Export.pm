package WWW::Scraper::Wikipedia::ISO3166::Database::Export;

use parent 'WWW::Scraper::Wikipedia::ISO3166::Database';
use strict;
use warnings;

use Config::Tiny;

use File::ShareDir;
use File::Spec;

use Moo;

use Sort::Naturally; # For nsort.

use Text::Xslate 'mark_raw';

use Types::Standard qw/Any HashRef Str/;

use Unicode::Normalize; # For NFC().

has config =>
(
	default  => sub{return {} },
	is       => 'rw',
	isa      => Any,
	required => 0,
);

has config_file =>
(
	default  => sub{return '.htwww.scraper.wikipedia.iso3166.conf'},
	is       => 'rw',
	isa      => Str,
	required => 0,
);

has country_file =>
(
	default  => sub{return 'countries.csv'},
	is       => 'rw',
	isa      => Str,
	required => 0,
);

has subcountry_file =>
(
	default  => sub{return 'subcountries.csv'},
	is       => 'rw',
	isa      => Str,
	required => 0,
);

has subcountry_info_file =>
(
	default  => sub{return 'subcountry_info.csv'},
	is       => 'rw',
	isa      => Str,
	required => 0,
);

has templater =>
(
	default  => sub{return ''},
	is       => 'rw',
	isa      => Any,
	required => 0,
);

has web_page_file =>
(
	default  => sub{return 'iso.3166-2.html'},
	is       => 'rw',
	isa      => Str,
	required => 0,
);

our $VERSION = '2.00';

# -----------------------------------------------

sub BUILD
{
	my($self) = @_;

	$self -> config(Config::Tiny -> read($self -> config_file ) );

	if (Config::Tiny -> errstr)
	{
		die Config::Tiny -> errstr;
	}

	$self -> config(${$self -> config}{_});
	$self -> templater
	(
		Text::Xslate -> new
		(
		 input_layer => '',
		 path        => ${$self -> config}{template_path},
		)
	);

} # End of BUILD.

# -----------------------------------------------

sub as_csv
{
	my($self) = @_;

	die "No country_file name specified\n"							if (! $self -> country_file);
	die "No subcountry_info_file name specified\n"					if (! $self -> subcountry_info_file);
	die "No subcountry_file name specified\n"						if (! $self -> subcountry_file);
	die "Country and subcountry type file names are the same\n"		if ($self -> country_file eq $self -> subcountry_info_file);
	die "Country and subcountry file names are the same\n"			if ($self -> country_file eq $self -> subcountry_file);
	die "Subcountry and subcountry type file names are the same\n"	if ($self -> subcountry_file eq $self -> subcountry_info_file);

	# 1: Countries.

	my($countries) = $self -> read_countries_table;

	my(@row);

	push @row,
	[
		qw/id code2 code3 fc_name has_subcountries name number timestamp/
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
			$$countries{$id}{number},
			$$countries{$id}{timestamp},
		];
	}

	open(my $fh, '>:encoding(UTF-8)', $self -> country_file) || die "Can't open file: " . $self -> country_file . "\n";

	for (@row)
	{
		print $fh '"', join('","', @$_), '"', "\n";
	}

	close $fh;

	# 2: Subcountry types.

	my($subcountry_info)	= $self -> read_subcountry_info_table;
	@row              		= ();

	push @row,
	[
		qw/id country_id name sequence timestamp/
	];

	for my $id (nsort(keys %$subcountry_info) )
	{
		push @row,
		[
			$id,
			$$subcountry_info{$id}{country_id},
			$$subcountry_info{$id}{name},
			$$subcountry_info{$id}{sequence},
			$$subcountry_info{$id}{timestamp},
		];
	}

	open($fh, '>:encoding(UTF-8)', $self -> subcountry_info_file) || die "Can't open file: " . $self -> subcountry_info_file . "\n";

	for (@row)
	{
		print $fh '"', join('","', @$_), '"', "\n";
	}

	close $fh;

	# 3: Subcountries.

	my($subcountries)	= $self -> read_subcountries_table;
	@row				= ();

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

	open($fh, '>:encoding(UTF-8)', $self -> subcountry_file) || die "Can't open file: " . $self -> subcountry_file . "\n";

	for (@row)
	{
		print $fh '"', join('","', @$_), '"', "\n";
	}

	close $fh;

}	# End of as_csv.

# ------------------------------------------------

sub as_html
{
	my($self)   = @_;
	my($config) = $self -> config;

	die "No web_page_file name specified\n" if (! $self -> web_page_file);

	open(my $fh, '>', $self -> web_page_file) || die "Can't open file: " . $self -> web_page_file . "\n";
	binmode($fh, ':utf8');

	print $fh $self -> templater -> render
		(
			'iso3166.report.tx',
			{
				country_data => $self -> _build_country_data,
				default_css  => "$$config{css_url}/default.css",
				version      => $VERSION,
			}
		);

	close $fh;

} # End of as_html.

# ------------------------------------------------

sub _build_country_data
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

	push @tr, [{td => '#'}, {td => 'Db key'}, {td => 'Code2'}, {td => 'Code3'}, {td => 'Number'}, {td => 'Name'}, {td => 'Subcountries'}];

	my($count) = 1;

	for my $id (sort{NFC($$countries{$a}{name}) cmp NFC($$countries{$b}{name})} keys %$countries)
	{
		push @tr,
		[
			{td => $count++},
			{td => $id},
			{td => mark_raw($$countries{$id}{code2})},
			{td => mark_raw($$countries{$id}{code3})},
			{td => mark_raw($$countries{$id}{number})},
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
				{td => ''},
				{td => mark_raw($$sub_id[1])},
				{td => mark_raw($$sub_id[2])},
				{td => ''},
			];
		}
	}

	# Duplicate the heading at the bottom.

	push @tr, $tr[0];

	return [@tr];

} # End of _ build_country_data.

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

=item o data/subcountry_info.csv

This data comes from the 3rd column of the country table at
L<https://en.wikipedia.org/wiki/ISO_3166-2>.

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

=item o subcountry_info_file => $a_csv_file_name

Specify the name of the CSV file to which subcountry types data is exported.

Default: 'subcountry.types.csv'.

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

=head2 country_file($file_name)

Get or set the name of the CSV file to which country data is exported.

C<country_file> is an option to L</new()>.

=head2 new()

See L</Constructor and initialization>.

=head2 subcountry_file($file_name)

Get or set the name of the CSV file to which subcountry data is exported.

C<subcountry_file> is an option to L</new()>.

=head2 subcountry_info_file($file_name)

Get or set the name of the CSV file to which subcountry type data is exported.

C<subcountry_info_file> is an option to L</new()>.

=head2 web_page_file($file_name)

Get or set the name of the HTML file to which country and subcountry data is exported.

C<web_page_file> is an option to L</new()>.

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
