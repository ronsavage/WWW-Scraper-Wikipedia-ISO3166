package WWW::Scraper::Wikipedia::ISO3166::Database;

use parent 'WWW::Scraper::Wikipedia::ISO3166';
use strict;
use warnings;

use DBD::SQLite;

use DBI;

use DBIx::Admin::CreateTable;

use File::Slurper 'read_dir';

use Moo;

use Types::Standard qw/Any HashRef Str/;

has attributes =>
(
	default  => sub{return {AutoCommit => 1, RaiseError => 1, sqlite_unicode => 1} },
	is       => 'rw',
	isa      => HashRef,
	required => 0,
);

has creator =>
(
	default  => sub{return ''},
	is       => 'rw',
	isa      => Any,
	required => 0,
);

has dbh =>
(
	default  => sub{return ''},
	is       => 'rw',
	isa      => Any,
	required => 0,
);

has dsn =>
(
	default  => sub{return ''},
	is       => 'rw',
	isa      => Str,
	required => 0,
);

has engine =>
(
	default  => sub{return ''},
	is       => 'rw',
	isa      => Str,
	required => 0,
);

has password =>
(
	default  => sub{return ''},
	is       => 'rw',
	isa      => Str,
	required => 0,
);

has time_option =>
(
	default  => sub{return ''},
	is       => 'rw',
	isa      => Str,
	required => 0,
);

has username =>
(
	default  => sub{return ''},
	is       => 'rw',
	isa      => Str,
	required => 0,
);

our $VERSION = '1.05';

# -----------------------------------------------

sub BUILD
{
	my($self) = @_;

	$self -> dsn('dbi:SQLite:dbname=' . $self -> sqlite_file);
	$self -> dbh(DBI -> connect($self -> dsn, $self -> username, $self -> password, $self -> attributes) ) || die $DBI::errstr;
	$self -> dbh -> do('PRAGMA foreign_keys = ON');

	$self -> creator
		(
		 DBIx::Admin::CreateTable -> new
		 (
		  dbh     => $self -> dbh,
		  verbose => 0,
		 )
		);

	$self -> engine
		(
		 $self -> creator -> db_vendor =~ /(?:Mysql)/i ? 'engine=innodb' : ''
		);

	$self -> time_option
		(
		 $self -> creator -> db_vendor =~ /(?:MySQL|Postgres)/i ? '(0) without time zone' : ''
		);

} # End of BUILD.

# -----------------------------------------------

sub find_subcountry_downloads
{
	my($self) = @_;
	my(@file) = read_dir('data');

	return [grep{length == 2} grep{s/^.+\.([A-Z]{2,2})\..+$/$1/; $_} @file];

} # End of find_subcountry_downloads.

# ----------------------------------------------

sub get_country_count
{
	my($self) = @_;

	return ($self -> dbh -> selectrow_array('select count(*) from countries') )[0];

} # End of get_country_count.

# -----------------------------------------------

sub get_statistics
{
	my($self)  = @_;
	my(%count) =
	(
		countries_in_db             => $self -> get_country_count,
		has_subcounties             => $#{$self -> who_has_subcountries} + 1,
		subcountries_in_db          => $self -> get_subcountry_count,
		subcountry_files_downloaded => scalar @{$self -> find_subcountry_downloads},
	);

	return {%count};

} # End of get_statistics.

# ----------------------------------------------

sub get_subcountry_count
{
	my($self) = @_;

	return ($self -> dbh -> selectrow_array('select count(*) from subcountries') )[0];

} # End of get_subcountry_count.

# ----------------------------------------------

sub read_countries_table
{
	my($self) = @_;
	my($sth)  = $self -> dbh -> prepare('select * from countries');

	$sth -> execute;
	$sth -> fetchall_hashref('id');

} # End of read_countries_table.

# ----------------------------------------------

sub read_subcountries_table
{
	my($self) = @_;
	my($sth)  = $self -> dbh -> prepare('select * from subcountries');

	$sth -> execute;
	$sth -> fetchall_hashref('id');

} # End of read_subcountries_table.

# -----------------------------------------------

sub report_statistics
{
	my($self)  = @_;
	my($count) = $self -> get_statistics;

	$self -> log(info => $_) for map{"$_ => $$count{$_}"} sort keys %$count;

} # End of report_statistics.

# ----------------------------------------------

sub who_has_subcountries
{
	my($self) = @_;
	my($countries) = $self -> read_countries_table;

	my(@has);

	for my $id (keys %$countries)
	{
		push @has, $id if ($$countries{$id}{has_subcountries} eq 'Yes');
	}

	return [@has];

} # End of who_has_subcountries.

# -----------------------------------------------

1;

=pod

=head1 NAME

WWW::Scraper::Wikipedia::ISO3166::Database - The interface to www.scraper.wikipedia.iso3166.sqlite

=head1 Synopsis

See L<WWW::Scraper::Wikipedia::ISO3166/Synopsis> for a long synopsis.

=head1 Description

Documents the methods end-users need to access the SQLite database,
I<www.scraper.wikipedia.iso3166.sqlite>, which ships with this distro.

See L<WWW::Scraper::Wikipedia::ISO3166/Description> for a long description.

See scripts/export.as.csv.pl, scripts/export.as.html.pl and scripts/report.statistics.pl.

=head1 Distributions

This module is available as a Unix-style distro (*.tgz).

See http://savage.net.au/Perl-modules.html for details.

See http://savage.net.au/Perl-modules/html/installing-a-module.html for
help on unpacking and installing.

=head1 Constructor and initialization

new(...) returns an object of type C<WWW::Scraper::Wikipedia::ISO3166::Database>.

This is the class's contructor.

Usage: C<< WWW::Scraper::Wikipedia::ISO3166::Database -> new() >>.

This method takes a hash of options.

Call C<new()> as C<< new(option_1 => value_1, option_2 => value_2, ...) >>.

Available options:

=over 4

=item o attributes => $hash_ref

This is the hashref of attributes passed to L<DBI>'s I<connect()> method.

Default: {AutoCommit => 1, RaiseError => 1, sqlite_unicode => 1}

=back

=head1 Methods

This module is a sub-class of L<WWW::Scraper::Wikipedia::ISO3166> and consequently inherits its methods.

=head2 attributes($hashref)

Get or set the hashref of attributes passes to L<DBI>'s I<connect()> method.

Also, I<attributes> is an option to L</new()>.

=head2 find_subcountry_downloads()

Returns an arrayref of 2-letter codes of countries whose subcountry page has been downloaded to
data/*$code2.html.

=head2 get_country_count()

Returns the result of: 'select count(*) from countries'.

=head2 get_statistics()

Returns a hashref of database statistics:

	{
	countries_in_db             => 249,
	has_subcounties             => 199,
	subcountries_in_db          => 4593,
	subcountry_files_downloaded => 249,
	}

Called by L</report_statistics()>.

=head2 get_subcountry_count()

Returns the result of: 'select count(*) from subcountries'.

=head2 new()

See L</Constructor and initialization>.

=head2 read_countries_table()

Returns a hashref of hashrefs for this SQL: 'select * from countries'.

The key of the hashref is the primary key (integer) of the I<countries> table.

This is discussed further in L<WWW::Scraper::Wikipedia::ISO3166/Methods which return hashrefs>.

=head2 read_subcountries_table()

Returns a hashref of hashrefs for this SQL: 'select * from subcountries'.

The key of the hashref is the primary key (integer) of the I<subcountries> table.

This is discussed further in L<WWW::Scraper::Wikipedia::ISO3166/Methods which return hashrefs>.

=head2 report_statistics()

Logs various database statistics at the I<info> level.

Calls L</get_statistics()>.

This is the output from scripts/report.statistics.pl -v 1:

	info: countries_in_db => 249.
	info: has_subcounties => 199.
	info: subcountries_in_db => 4593.
	info: subcountry_files_downloaded => 249.

=head2 verbose($integer)

Get or set the verbosity level.

Also, I<verbose> is an option to L</new()>.

=head2 who_has_subcountries()

Returns an arrayref of primary keys (integers) in the I<countries> table, of those countries who have
subcountry entries in the I<subcountries> table.

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
