package WWW::Scraper::Wikipedia::ISO3166::Database::Import;

use parent 'WWW::Scraper::Wikipedia::ISO3166::Database';
use feature 'say';
use strict;
use utf8;
use warnings;
use warnings  qw(FATAL utf8);    # Fatalize encoding glitches.

use File::Slurper qw/read_dir read_text/;

use List::AllUtils 'first';
use List::Compare;

use Mojo::DOM;

use Moo;

use Types::Standard qw/HashRef Str/;

use Unicode::CaseFold; # For fc().

has code2 =>
(
	default  => sub{return ''},
	is       => 'rw',
	isa      => Str,
	required => 0,
);

our $VERSION = '2.00';

# ----------------------------------------------

sub cross_check_country_downloads
{
	my($self, $table) = @_;

	my($code2);
	my($country_file);
	my(%seen);

	for my $element (@$table)
	{
		$code2			= $$element{code2};
		$country_file	= "data/en.wikipedia.org.wiki.ISO_3166-2:$code2.html";
		$seen{$code2}	= 1;

		if (! -e "data/en.wikipedia.org.wiki.ISO_3166-2.$code2.html")
		{
			$self -> log(info => "File $country_file not yet downloaded");
		}
	}

	for my $file_name (read_dir('data') )
	{
		if ( ($file_name =~ /^en.wikipedia.org.wiki.ISO_3166-2\.(..)\.html$/) && ! $seen{$1})
		{
			$self -> log(warning => "Unknown country code '$1' in file name in data/");
		}
	}

} # End of cross_check_country_downloads.

# -----------------------------------------------

sub _parse_country_page_1
{
	my($self)		= @_;
	my($in_file)	= 'data/en.wikipedia.org.wiki.ISO_3166-1.html';
	my($dom)		= Mojo::DOM -> new(read_text($in_file) );

	my($td_count);

	for my $node ($dom -> at('table[class="wikitable sortable"]') -> descendant_nodes -> each)
	{
		# Select the heading's tr.

		if ($node -> matches('tr') )
		{
			$td_count = $node -> children -> size;

			last;
		}
	}

	my($codes)	= [];
	my($count)	= -1;

	my($content, $code);
	my($nodule);

	for my $node ($dom -> at('table[class="wikitable sortable"]') -> descendant_nodes -> each)
	{
		next if (! $node -> matches('td') );

		$count++;

		if ( ($count % $td_count) == 0)
		{
			for $nodule ($node -> descendant_nodes -> each)
			{
				if ($nodule -> matches('a') )
				{
					# Special cases:
					# o TW - Taiwan.

					if ($nodule -> content !~ /\[a\]/)
					{
						$content = $nodule -> content;
					}
				}
				elsif ($nodule -> at('span a') )
				{
					# Special cases:
					# o TW - Taiwan.

					if ($nodule -> content !~ /\[a\]/)
					{
						$content = $nodule -> content;
					}
				}
			}

			$code = {code2 => '', code3 => '', name => $content, number => 0};
		}
		elsif ( ($count % $td_count) == 1)
		{
			for $nodule ($node -> descendant_nodes -> each)
			{
				# This actually overwrites the 1st node's content with the 2nd's.

				$$code{code2} = $nodule -> content;
			}
		}
		elsif ( ($count % $td_count) == 2)
		{
			$$code{code3} = $node -> children -> first -> content;
		}
		elsif ( ($count % $td_count) == 3)
		{
			$$code{number} = $node -> children -> first -> content;

			push @$codes, $code;
		}
	}

	return $codes;

} # End of _parse_country_page_1.

# -----------------------------------------------

sub _parse_country_page_2
{
	my($self)					= @_;
	my($in_file)				= 'data/en.wikipedia.org.wiki.ISO_3166-2.html';
	my($dom)					= Mojo::DOM -> new(read_text($in_file) );
	my($has_subcountries_count)	= 0;
	my($names)					= [];
	my($count)					= -1;

	my($content, $code);
	my(@kids);
	my($size);
	my($td_count, @temp_1, @temp_2, $temp_3);

	for my $node ($dom -> at('table[class="wikitable sortable"]') -> descendant_nodes -> each)
	{
		# Select the heading's tr.

		if ($node -> matches('tr') )
		{
			$td_count = $node -> children -> size;

			last;
		}
	}

	for my $node ($dom -> at('table') -> descendant_nodes -> each)
	{
		next if (! $node -> matches('td') );

		$count++;

		if ( ($count % $td_count) == 0)
		{
			$content	= $node -> children -> first -> content;
			$code		= {code2 => $content, name => '', subcountries => []};
		}
		elsif ( ($count % $td_count) == 1)
		{
			$content = $node -> children -> first -> content;

			# Special cases:
			# o AX - Åland Islands.
			# o CI - Côte d'Ivoire.
			# o RE - Réunion.

			if ($content =~ /\s!$/)
			{
				@kids		= $node -> children -> each;
				@kids		= map{$_ -> content} @kids; # The next lines is a WTF.
				$content	= join('', map{$_ -> content} Mojo::DOM -> new($kids[1]) -> children -> each);
			}

			$$code{name} = $content;
		}
		elsif ( ($count % $td_count) == 2)
		{
			$content	= $node -> content;
			$size		= $node -> children -> size;

			if ($size > 0)
			{
				@temp_1 = @temp_2 = ();

				for my $item ($node -> children -> each)
				{
					$content = $item -> content;

					push @temp_1, $content if ($content);
				}

				for my $i (0 .. $#temp_1)
				{
					push @temp_2, split(/<br>\n/, $temp_1[$i]);
				}

				@temp_1 = ();

				for my $i (0 .. $#temp_2)
				{
					$temp_3	= Mojo::DOM -> new($temp_2[$i]);
					$size	= $temp_3 -> children -> size;

					if ($size == 0)
					{
						push @temp_1, $temp_3 -> content;
					}
					else
					{
						push @temp_1, $_ -> content for $temp_3 -> children -> each;
					}
				}

				$$code{subcountries} = [@temp_1];

				$has_subcountries_count++;
			}

			push @$names, $code;
		}
	}

	$self -> log(info => "1 of 2: $has_subcountries_count countries have subcountries");

	return $names;

} # End of _parse_country_page_2.

# -----------------------------------------------

sub populate_countries
{
	my($self)	= @_;
	my($codes)	= $self -> _parse_country_page_1;

	$self -> cross_check_country_downloads($codes);

	my($code2index)	= $self -> _save_countries($codes);
	my($names)		= $self -> _parse_country_page_2;

	$self -> _save_subcountry_types($code2index, $names);

	# Return 0 for success and 1 for failure.

	return 0;

} # End of populate_countries.

# -----------------------------------------------

sub populate_subcountry
{
	my($self)		= @_;
	my($code2)		= $self -> code2;
	my($in_file)	= "data/en.wikipedia.org.wiki.ISO_3166-2.$code2.html";

	$self -> log(info => "Start: $in_file");

	my($dom)	= Mojo::DOM -> new(read_text($in_file) );
	my($names)	= [];
	my($count)	= -1;

	my($td_count);

	for my $node ($dom -> at('table[class="wikitable sortable"]') -> descendant_nodes -> each)
	{
		# Select the heading's tr.

		if ($node -> matches('tr') )
		{
			$td_count = $node -> children -> size;

			last;
		}
	}

	my($content, $code);
	my($finished);
	my($kid, $kids, @kids);

	for my $node ($dom -> at('table[class="wikitable sortable"]') -> descendant_nodes -> each)
	{
		next if (! $node -> matches('td') );

		$count++;

		if ( ($count % $td_count) == 0)
		{
			# Special cases:
			# o CG - Congo.
			# o KH - Cambodia.
			# o MN - Mongolia.
			# o PY - Paraguay.

			if ($code2 =~ /(?:CG|KH|MN|PY)/)
			{
				$kids = $node -> children;

				if ($kids -> size == 1)
				{
					$content = $kids -> first -> content;
				}
				else
				{
					@kids		= $kids -> each;
					$kids		= $kids[1] -> children;
					$content	= $kids -> first -> content;
				}
			}
			else
			{
				$content = $node -> at('span') -> content;
			}

			$code		= {code => $content, name => ''};
			$finished	= 0;

		}
		elsif ( ($count % $td_count)  == 1)
		{
			# Special cases:
			# o CG - Congo.
			# o KH - Cambodia.
			# o TD - Chad.
			# o CY - Cyprus.
			# o DO - Dominican Republic.
			# o MR - Mauritania.
			# o MT - Malta.
			# o PY - Paraguay.

			next if ($code2 =~ /(?:KH|MT)/);

			$kids = $node -> children;

			if ($kids -> size == 0)
			{
				$content = $node -> content;
			}
			elsif ($code2 =~ /(?:CG|PY)/)
			{
				for $kid ($node -> descendant_nodes -> each)
				{
					$content = $kid -> content if ($kid -> matches('a') );
				}
			}
			elsif ($code2 eq 'TD')
			{
				if ($kids -> size == 0)
				{
					$content = $node -> content;
				}
				elsif ($kids -> size == 1)
				{
					next;
				}
				else
				{
					@kids		= $node -> children -> each;
					$content	= $kids[1] -> content;
				}
			}
			else
			{
				# Special cases:
				# o AD - Andorra.
				# o GT - Guatemala.
				# o PY - Paraguay.

				$kid = $node -> at('a img');

				if ($kid)
				{
					for $kid ($node -> children -> each)
					{
						next if ($kid -> children -> size > 0);

						$content = $kid -> content;
					}
				}
				else
				{
					$kid = $node -> at('a') || $node -> at('span a');

					if ($kid)
					{
						$content = $kid -> content;
					}
					else
					{
						$content = $node -> content;
					}
				}
			}

			$self -> log(debug => "code2: $code2. content: $content") if ($code2 eq 'TD');

			$$code{name}	= $content;
			$finished		= ( ($code2 =~ /(?:MR|NZ)/) && ($$code{name} eq '') ) ? 0 : 1;
		}
		elsif (! $finished && ($count % $td_count) == 2)
		{
			# Special cases:
			# o KH - Cambodia.
			# o MR - Mauritania.
			# o NZ - New Zealand.
			# o TD - Chad.
			# Some rows in the subcountry table have blanks in column 2,
			# so we have to get the value from column 3.

			if ($code2 eq 'MT')
			{
				$content	= $node -> content;
				$finished	= 1;
			}
			elsif ($code2 eq 'KH')
			{
				$content	= $node -> content;
				$finished	= 1;
			}
			elsif ( ($code2 =~ /(?:MR|NZ)/) && ($$code{name} eq '') )
			{
				$content	= $node -> at('a') -> content;
				$finished	= 1;
			}
			elsif ($code2 eq 'TD')
			{
				$content = $node -> at('a') -> content;
			}

			$$code{name} = $content if ($finished);
		}
		elsif (! $finished && ($count % $td_count) == 3)
		{
			# Special cases:
			# o CY - Cyprus.

			if ($code2 =~ /(?:CY)/)
			{
				$kid			= $node -> at('a');
				$$code{name}	= $kid -> content if ($kid);
				$finished		= 1;
			}
		}

		if ($finished)
		{
			$finished = 0;

			push @$names, $code;
		}
	}

	$self -> _save_subcountry($count, $names);

	# Return 0 for success and 1 for failure.

	return 0;

} # End of populate_subcountry.

# -----------------------------------------------

sub populate_subcountries
{
	my($self)  = @_;

	# Find which subcountries have been downloaded but not imported.
	# %downloaded will contain 2-letter codes.

	my(%downloaded);

	my($downloaded)           = $self -> find_subcountry_downloads;
	@downloaded{@$downloaded} = (1) x @$downloaded;
	my($countries)            = $self -> read_countries_table;
	my($subcountries)         = $self -> read_subcountries_table;

	my($country_id);
	my(%imported);

	for my $subcountry_id (keys %$subcountries)
	{
		$country_id                                 = $$subcountries{$subcountry_id}{country_id};
		$imported{$$countries{$country_id}{code2} } = 1;
	}

	# 2: Import if not already imported.

	$self -> dbh -> begin_work;

	my($code2);

	for $country_id (sort keys %$countries)
	{
		$code2 = $$countries{$country_id}{code2};

		next if ($imported{$code2});

		next if ($$countries{$country_id}{has_subcountries} eq 'No');

		$self -> code2($code2);
		$self -> populate_subcountry;
	}

	$self -> dbh -> commit;

	# Return 0 for success and 1 for failure.

	return 0;

} # End of populate_subcountries.

# ----------------------------------------------

sub _save_countries
{
	my($self, $table) = @_;

	$self -> dbh -> begin_work;
	$self -> dbh -> do('delete from countries');

	my($i)   = 0;
	my($sql) = 'insert into countries '
				. '(code2, code3, fc_name, has_subcountries, name, number) '
				. 'values (?, ?, ?, ?, ?, ?)';
	my($sth) = $self -> dbh -> prepare($sql) || die "Unable to prepare SQL: $sql\n";

	my(%code2index);

	for my $element (sort{$$a{name} cmp $$b{name} } @$table)
	{
		$i++;

		$code2index{$$element{code2} } = $i;

		$sth -> execute
		(
			$$element{code2},
			$$element{code3},
			fc $$element{name},
			'No', # The default for 'has_subcountries'. Updated later.
			$$element{name},
			$$element{number},
		);
	}

	$sth -> finish;
	$self -> dbh -> commit;

	$self -> log(info => "Saved $i countries to the database");

	return \%code2index;

} # End of _save_countries.

# ----------------------------------------------

sub _save_subcountry_types
{
	my($self, $code2index, $table) = @_;

	$self -> dbh -> begin_work;
	$self -> dbh -> do('delete from subcountry_types');

	my($has_subcountries_count)	= 0;
	my($i)						= 0;
	my($sql_1)					= 'insert into subcountry_types '
									. '(country_id, name, sequence) '
									. 'values (?, ?, ?)';
	my($sth_1)					= $self -> dbh -> prepare($sql_1) || die "Unable to prepare SQL: $sql_1\n";
	my($sql_2)					= 'update countries set has_subcountries = ? where id = ?';
	my($sth_2)					= $self -> dbh -> prepare($sql_2) || die "Unable to prepare SQL: $sql_2\n";

	my($country_id);
	my($subcountry, $sequence, %seen);

	for my $element (@$table)
	{
		next if (scalar @{$$element{subcountries} } == 0);

		$has_subcountries_count++;

		$sequence = 0;

		for $subcountry (@{$$element{subcountries} })
		{
			$i++;
			$sequence++;

			$country_id = $$code2index{$$element{code2} };

			$sth_1 -> execute
			(
				$country_id,
				$subcountry,
				$sequence
			);
		}

		# We can use $country_id because it has the same value every time thru the loop above.

		$sth_2 -> execute('Yes', $country_id);

		if ($seen{$country_id})
		{
			$self -> log(warning => "Seeing country_id $country_id for the 2nd time");
		}

		$seen{$country_id} = 1;
	}

	$sth_1 -> finish;
	$sth_2 -> finish;
	$self -> dbh -> commit;

	$self -> log(info => "Saved $i subcountry types to the database");
	$self -> log(info => "2 of 2: $has_subcountries_count countries have subcountries");

} # End of _save_subcountry_types.

# ----------------------------------------------

sub _save_subcountry
{
	my($self, $count, $table) = @_;
	my($code2)     = $self -> code2;
	my($countries) = $self -> read_countries_table;

	# Find which country has the code we're processing.

	my($country_id) = first {$$countries{$_}{code2} eq $code2} keys %$countries;

	die "Unknown country code: $code2\n" if (! $country_id);

	$self -> dbh -> do("delete from subcountries where country_id = $country_id");

	my($i)   = 0;
	my($sql) = 'insert into subcountries (country_id, code, fc_name, name, sequence) values (?, ?, ?, ?, ?)';
	my($sth) = $self -> dbh -> prepare($sql) || die "Unable to prepare SQL: $sql\n";

	for my $element (@$table)
	{
		$i++;

		$sth -> execute($country_id, $$element{code}, fc $$element{name}, $$element{name}, $i);
	}

	$sth -> finish;

	$self -> log(info => "$count: $code2 => '$$countries{$country_id}{name}' contains $i subcountries");

} # End of _save_subcountry.

# -----------------------------------------------

1;

=pod

=head1 NAME

WWW::Scraper::Wikipedia::ISO3166::Database::Import - Part of the interface to www.scraper.wikipedia.iso3166.sqlite

=head1 Synopsis

See L<WWW::Scraper::Wikipedia::ISO3166/Synopsis>.

=head1 Description

Documents the methods used to populate the SQLite database,
I<www.scraper.wikipedia.iso3166.sqlite>, which ships with this distro.

See L<WWW::Scraper::Wikipedia::ISO3166/Description> for a long description.

=head1 Distributions

This module is available as a Unix-style distro (*.tgz).

See http://savage.net.au/Perl-modules.html for details.

See http://savage.net.au/Perl-modules/html/installing-a-module.html for
help on unpacking and installing.

=head1 Constructor and initialization

new(...) returns an object of type C<WWW::Scraper::Wikipedia::ISO3166::Database::Import>.

This is the class's contructor.

Usage: C<< WWW::Scraper::Wikipedia::ISO3166::Database::Import -> new() >>.

This method takes a hash of options.

Call C<new()> as C<< new(option_1 => value_1, option_2 => value_2, ...) >>.

Available options (these are also methods):

=over 4

=item o code2 => $2_letter_code

Specifies the code2 of the country whose subcountry page is to be downloaded.

=back

=head1 Methods

This module is a sub-class of L<WWW::Scraper::Wikipedia::ISO3166::Database> and consequently
inherits its methods.

=head2 cross_check_country_downloads()

Report what country code files have not been downloaded, after parsing ISO_3166-1.html. This report
is at the 'debug' level.

Also, report if any files are found in the data/ dir whose code does not appear in ISO_3166-1.html.
This report is at the 'warning' level'.

=head2 code2($code)

Get or set the 2-letter country code of the country or subcountry being processed.

Also, I<code2> is an option to L</new()>.

=head2 new()

See L</Constructor and initialization>.

=head2 parse_country_page_1()

Parse the HTML page of country names from data/en.wikipedia.org.wiki.ISO-3166-1.html.

Returns an arrayref where each element is a hashref with these keys:

=over 4

=item o code2 => $string

=item o code3 => $string

=item o name => $string

=item o number => $string

=back

=head2 parse_country_page_2()

Parse the HTML page of 3-letter country codes, which has 3 tables side-by-side from
 from data/en.wikipedia.org.wiki.ISO-3166-2.html.

Return an arrayref where each element is a hashref with these keys:

=over 4

=item o code2 => $string

=item o name => $string

This is the name of the country, but it is not used.

=item o subcountries => $array_ref

This arrayref holds the N text fields from the 3rd column of the big table on that wiki page. E.g.:
For Uzbekistan the 3 elements of the arrayref are:

=over 4

=item o '1 city'

=item o '12 regions'

=item o '1 republic'

=back

And for United Kingdom, the elements will be:

=over 4

=item o '3 countries'

=item o '1 province

=item o '78 unitary authorities'

=item o '27 two-tier counties'

=item o '32 london boroughs'

=item o '1 city corporation'

=item o '36 metropolitan districts'

=item o '11 districts'

=item o '32 council areas'

All of which nicely encapsulates the complexity of human existence.

The details of these are on the page L<ISO_3166-2:UZ|https://en.wikipedia.org/wiki/ISO_3166-2:UZ>.

These strings are entries in the subcountry_types table. Fir details of the schema,
see L<WWW::Scraper::Wikipedia::ISO3166/What is the database schema?>.

Obviously, the arrayref is empty if the country has no subcoyntries.

=head2 parse_subcountry_page()

Parse the HTML page of a subcountry.

Warning. The 2-letter code of the subcountry must be set with $self -> code2('XX') before calling
this method.

=head2 populate_countries()

Populate the I<countries> table.

=head2 populate_subcountry()

Populate the I<subcountries> table, for 1 subcountry.

Warning. The 2-letter code of the subcountry must be set with $self -> code2('XX') before calling
this method.

=head2 populate_subcountries()

Populate the I<subcountries> table, for all subcountries.

=head2 process_subcountries($table)

Delete the I<detail> key of the arrayref of hashrefs for the subcountry.

=head2 save_countries($table)

Save the $table to the I<countries> table in the database.

=head2 save_subcountries($count, $table)

Save the I<subcountries> table, for the given subcountry, using the output of
L</process_subcountries($table)>.

$count is just used in the log for progress messages.

=head1 FAQ

For the database schema, etc, see L<WWW::Scraper::Wikipedia::ISO3166/FAQ>.

=head1 References

See L<WWW::Scraper::Wikipedia::ISO3166/References>.

=head1 Support

Email the author, or log a bug on RT:

L<https://rt.cpan.org/Public/Dist/Display.html?Name=WWW::Scraper::Wikipedia::ISO3166>.

=head1 Author

C<WWW::Scraper::Wikipedia::ISO3166> was written by Ron Savage I<E<lt>ron@savage.net.auE<gt>> in
2012.

Home page: L<http://savage.net.au/index.html>.

=head1 Copyright

Australian copyright (c) 2012 Ron Savage.

	All Programs of mine are 'OSI Certified Open Source Software';
	you can redistribute them and/or modify them under the terms of
	The Artistic License, a copy of which is available at:
	http://www.opensource.org/licenses/index.html


=cut
