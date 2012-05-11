package WWW::Scraper::Wikipedia::ISO3166::Database::Create;

use parent 'WWW::Scraper::Wikipedia::ISO3166::Database';
use strict;
use warnings;

use Hash::FieldHash ':all';

our $VERSION = '1.00';

# -----------------------------------------------

sub create_all_tables
{
	my($self) = @_;

	# Warning: The order is important.

	my($method);
	my($table_name);

	for $table_name (qw/
countries
subcountries
/)
	{
		$method = "create_${table_name}_table";

		$self -> $method;
	}

}	# End of create_all_tables.

# --------------------------------------------------

sub create_countries_table
{
	my($self)        = @_;
	my($table_name)  = 'countries';
	my($primary_key) = $self -> creator -> generate_primary_key_sql($table_name);
	my($engine)      = $self -> engine;
	my($time_option) = $self -> time_option;
	my($result)      = $self -> creator -> create_table(<<SQL);
create table $table_name
(
id $primary_key,
code2 char(2) not null,
code3 char(3) not null,
fc_name varchar(255) not null,
has_subcountries varchar(3) not null,
name varchar(255) not null,
timestamp timestamp $time_option not null default current_timestamp
) $engine
SQL
	$self -> report($table_name, 'created', $result);

}	# End of create_countries_table.

# --------------------------------------------------

sub create_subcountries_table
{
	my($self)        = @_;
	my($table_name)  = 'subcountries';
	my($primary_key) = $self -> creator -> generate_primary_key_sql($table_name);
	my($engine)      = $self -> engine;
	my($time_option) = $self -> time_option;
	my($result)      = $self -> creator -> create_table(<<SQL);
create table $table_name
(
id $primary_key,
country_id integer not null references countries(id),
code varchar(255) not null,
fc_name varchar(255) not null,
name varchar(255) not null,
sequence integer not null,
timestamp timestamp $time_option not null default current_timestamp
) $engine
SQL
	$self -> report($table_name, 'created', $result);

}	# End of create_subcountries_table.

# -----------------------------------------------

sub drop_all_tables
{
	my($self) = @_;

	my($table_name);

	for $table_name (qw/
subcountries
countries
/)
	{
		$self -> drop_table($table_name);
	}

}	# End of drop_all_tables.

# -----------------------------------------------

sub drop_table
{
	my($self, $table_name) = @_;

	$self -> creator -> drop_table($table_name);
	$self -> report($table_name, 'dropped', '');

} # End of drop_table.

# -----------------------------------------------

sub report
{
	my($self, $table_name, $message, $result) = @_;

	if ($result)
	{
		die "Table '$table_name' $result\n";
	}
	else
	{
		$self -> log(debug => "Table '$table_name' $message");
	}

} # End of report.

# -----------------------------------------------

1;
