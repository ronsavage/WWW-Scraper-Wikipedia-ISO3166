package WWW::Scraper::Wikipedia::ISO3166::Database::Export;

use open qw/:std :utf8/;
use parent 'WWW::Scraper::Wikipedia::ISO3166::Database';
use strict;
use warnings;

use Config::Tiny;

use Hash::FieldHash ':all';

use Text::Xslate 'mark_raw';

use Unicode::Normalize; # For NFC().

fieldhash my %config          => 'config';
fieldhash my %country_file    => 'country_file';
fieldhash my %subcountry_file => 'subcountry_file';
fieldhash my %templater       => 'templater';
fieldhash my %web_page_file   => 'web_page_file';

our $VERSION = '1.02';

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
	#binmode(OUT, ':utf8');

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

	push @tr, [{td => '#'}, {td => 'Code2'}, {td => 'Code3'}, {td => 'Name'}, {td => 'Subcountries'}];

	my($count) = 1;

	for my $id (sort{NFC($$countries{$a}{name}) cmp NFC($$countries{$b}{name})} keys %$countries)
	{
		push @tr,
		[
			{td => $count++},
			{td => $$countries{$id}{code2} },
			{td => $$countries{$id}{code3} },
			{td => $$countries{$id}{name}},
			{td => $$countries{$id}{has_subcountries} },
		];

		next if (! $subcountries{$id});

		# Sort by sequence.

		for my $sub_id (sort{$$a[0] <=> $$b[0]} @{$subcountries{$id} })
		{
			push @tr,
			[
				{td => ''},
				{td => $$sub_id[1]},
				{td => ''},
				{td => $$sub_id[2]},
				{td => ''},
			];
		}
	}

	push @tr, [{td => '#'}, {td => 'Code2'}, {td => 'Code3'}, {td => 'Name'}, {td => 'Subcountries'}];

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
	$$arg{verbose}         ||= 0;  # Caller can set.
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
