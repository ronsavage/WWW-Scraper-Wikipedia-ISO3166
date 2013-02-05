package WWW::Scraper::Wikipedia::ISO3166::Database::Import;

use parent 'WWW::Scraper::Wikipedia::ISO3166::Database';
use feature 'say';
use strict;
use utf8;
use warnings;
use warnings  qw(FATAL utf8);    # Fatalize encoding glitches.
use open      qw(:std :utf8);    # Undeclared streams in UTF-8.
use charnames qw(:full :short);  # Unneeded in v5.16.

use Encode; # For decode().

use Hash::FieldHash ':all';

use HTML::TreeBuilder;

use List::AllUtils 'first';

use Unicode::CaseFold; # For fc().

fieldhash my %code2 => 'code2';

our $VERSION = '1.01';

# ----------------------------------------------

sub get_content
{
	my($self, $element) = @_;
	my($content) =
		ref $element && ref $element eq 'HTML::Element'
		? join(', ', grep{/./} map{$self -> get_content($_)} $element -> content_array_ref)
		: ref $element eq 'ARRAY'
			? join(', ', grep{/./} map{$self -> get_content($_)} @$element)
			: $element;

	return $self -> trim($content);

} # End of get_content.

# ----------------------------------------------

sub get_table
{
	my($self, $node, $column_type, $country_code) = @_;
	my($column_count) = $#$column_type + 1;
	my(@td)           = $node -> look_down(_tag => 'td');
	my($i)            = - 1;

	my($a);
	my($detail, @detail);
	my($index);
	my($modulus);
	my($name);
	my(@result);
	my($tag, $tr);

	for my $td (@td)
	{
		$i++;

		$modulus = $i % $column_count;
		$tag     = $$column_type[$modulus];

		if ($modulus == 0)
		{
			$a         = $td -> look_down(_tag => $tag);
			$tr        = {};
			$$tr{code} = $self -> get_content($a);
		}
		elsif ($modulus == 1)
		{
			if ($tag eq 'a')
			{
				$a         = $td -> look_down(_tag => $tag);
				$$tr{name} = $self -> get_content($a);
			}
			else # '-'.
			{
				$$tr{name} = $self -> get_content($td);

				# Special code for:
				# o ET => Ethiopia.
				# o KM => Comoros.
				# o LB => Lebanon is handled under ($modulus == 2).
				# o TD => Chad.

				if ($country_code)
				{
					my(@field);

					if ($country_code eq 'KM')
					{
						@field     = split(/\s\(/, $$tr{name});
						$$tr{name} = $field[0];
					}
					elsif ($country_code =~ /(?:ET|TD)/)
					{
						@field     = split(/\s!/, $$tr{name});
						$$tr{name} = $#field == 1 ? $field[1] : $field[0];
					}
				}
			}
		}
		elsif ($modulus == 2)
		{
			if ($tag eq 'a')
			{
				$a      = $td -> content_array_ref;
				$detail = $a ? $self -> get_content($a) : '-';
				@detail = split(/, /, $detail);
				$index  = - 1;

				# Special code for FR => France (IIRC). The country page says:
				# 5 overseas regions/departments.
				# WTF: first_index from List::AllUtils does not always work.
				#$index = first_index{$_ eq '/'} @detail;

				for my $i (0 .. $#detail)
				{
					if ($detail[$i] eq '/')
					{
						$index = $i;

						last;
					}
				}

				if ($index > 0)
				{
					$detail =
						join(', ', @detail[0 .. $index - 2])
						. ", $detail[$index - 1]/$detail[$index + 1], "
						. join(', ', @detail[$index + 2 .. $#detail]);
				}
			}
			else # '-'.
			{
				$detail = $self -> get_content($td);
			}

			if ($country_code && ($country_code eq 'LB') )
			{
				$$tr{name} = $detail;
			}
			else
			{
				$$tr{detail} = $detail if ($detail);
			}
		}
		elsif ($modulus == 3)
		{
			if ($tag eq 'a')
			{
				$a           = $td -> look_down(_tag => $tag);
				$$tr{detail} .= ', ' . $self -> get_content($a);
			}
		}

		# Clean up scraped data.

		if ($modulus == ($column_count - 1) )
		{
			$$tr{detail} =~ s/^,\s// if ($$tr{detail});
			$$tr{name}   =~ s/^,\s//;

			push @result, $tr;
		}
	}

	return [@result];

} # End of get_table.

# -----------------------------------------------

sub _init
{
	my($self, $arg) = @_;

	return $self -> SUPER::_init($arg);

} # End of _init.

# -----------------------------------------------

sub parse_country_code_page
{
	my($self)    = @_;
	my($in_file) = 'data/en.wikipedia.org.wiki.ISO_3166-2.3.html';

	my($root)   = HTML::TreeBuilder -> new();
	my($result) = $root -> parse_file($in_file) || die "Can't parse file: $in_file\n";
	my(@node)   = $root -> look_down(_tag => 'table');
	my($codes)  =
	[
		@{$self -> get_table($node[2], [qw/tt a/])},
		@{$self -> get_table($node[3], [qw/tt a/])},
		@{$self -> get_table($node[4], [qw/tt a/])},
	];

	$root -> delete;

	return $codes;

} # End of parse_country_code_page.

# -----------------------------------------------

sub parse_country_page
{
	my($self)    = @_;
	my($in_file) = 'data/en.wikipedia.org.wiki.ISO_3166-2.html';

	my($root)     = HTML::TreeBuilder -> new();
	my($result)   = $root -> parse_file($in_file) || die "Can't parse file: $in_file\n";
	my(@node)     = $root -> look_down(_tag => 'table');
	my($names)    = $self -> get_table($node[1], [qw/a a a/]);
	#my($specials) = $self -> get_table($node[2], [qw/a a a/]);

	$root -> delete;

	return $names;

} # End of parse_country_page.

# -----------------------------------------------

sub parse_fips_page
{
	my($self, $suffix) = @_;
	my($in_file)       = "data/List_of_FIPS_region_codes_$suffix.html";
	my($root)          = HTML::TreeBuilder -> new();
	my($result)        = $root -> parse_file($in_file) || die "Can't parse file: $in_file\n";
	my(@country)       = $root -> look_down(_tag => 'span', class => qr/mw-headline/, id => qr/[A-Z]{2,2}:/);
	my(@ul)            = $root -> look_down(_tag => 'ul');
	my($count)         = 0;

	# Discard 1st ul.

	shift @ul;

	my($country);
	my($li);
	my(@name);
	my($text);

	for my $ul (@ul)
	{
		$count++;

		$country               = (shift @country) -> as_text;
		substr($country, 0, 4) = '';

		push @name, $country;

		for my $li ($ul -> look_down(_tag => 'li') )
		{
			$text = $li -> as_text;
			$text =~ s/(.+),\s+$country/$1/;

			push @name, $text;
		}

		# Ignore remaining uls.

		last if ($#country < 0);
	}

	$root -> delete;

	return [@name];

} # End of parse_fips_page.

# ----------------------------------------------

sub parse_subcountry_page
{
	my($self)  = @_;
	my($code2) = $self -> code2;

	# column_type is the HTML type of the column's data.
	# Each field is assumed to be inside a <td>...</td> pair.
	# o a => <a ...>Real data</a>
	# o tt => <tt>Real data</tt>
	# o - => Real data
	# Due to the way the code steps thru the <td>s, the number of elements
	# in the column_type arrayref must exactly match the number of <td>s.
	#
	# table_number (1 .. N) indicates which table on the page is processed.
	# It does /not/ refer to the total number of tables on the page.

	my(%code) =
	(
		AD =>
		{
			column_type  => [qw/tt a/],
			table_number => 2,
		},
		AE =>
		{
			column_type  => [qw/tt a/],
			table_number => 2,
		},
		AF =>
		{
			column_type  => [qw/tt a/],
			table_number => 2,
		},
		AG =>
		{
			column_type  => [qw/tt a -/],
			table_number => 2,
		},
		AL =>
		{
			column_type  => [qw/tt a/],
			table_number => 2,
		},
		AM =>
		{
			column_type  => [qw/tt a -/],
			table_number => 1,
		},
		AO =>
		{
			column_type  => [qw/tt a/],
			table_number => 2,
		},
		AR =>
		{
			column_type  => [qw/tt a -/],
			table_number => 2,
		},
		AT =>
		{
			column_type  => [qw/tt a/],
			table_number => 1,
		},
		AU =>
		{
			column_type  => [qw/tt a -/],
			table_number => 2,
		},
		AW =>
		{
		},
		AX =>
		{
		},
		AZ =>
		{
			column_type  => [qw/tt a - -/],
			table_number => 3,
		},
		BA =>
		{
			column_type  => [qw/tt a - - a/],
			table_number => 3,
		},
		BB =>
		{
			column_type  => [qw/tt a/],
			table_number => 2,
		},
		BD =>
		{
			column_type  => [qw/tt a a/],
			table_number => 3,
		},
		BE =>
		{
			column_type  => [qw/tt a a/],
			table_number => 3,
		},
		BF =>
		{
			column_type  => [qw/tt a a/],
			table_number => 3,
		},
		BG =>
		{
			column_type  => [qw/tt a/],
			table_number => 2,
		},
		BH =>
		{
			column_type  => [qw/tt a/],
			table_number => 2,
		},
		BI =>
		{
			column_type  => [qw/tt a/],
			table_number => 2,
		},
		BJ =>
		{
			column_type  => [qw/tt a/],
			table_number => 2,
		},
		BN =>
		{
			column_type  => [qw/tt a/],
			table_number => 1,
		},
		BO =>
		{
			column_type  => [qw/tt a/],
			table_number => 2,
		},
		BQ =>
		{
			column_type  => [qw/tt a a/],
			table_number => 2,
		},
		BR =>
		{
			column_type  => [qw/tt a -/],
			table_number => 1,
		},
		BS =>
		{
			column_type  => [qw/tt a/],
			table_number => 2,
		},
		BT =>
		{
			column_type  => [qw/tt a/],
			table_number => 1,
		},
		BW =>
		{
			column_type  => [qw/tt a/],
			table_number => 2,
		},
		BY =>
		{
			column_type  => [qw/tt a - - - -/],
			table_number => 2,
		},
		BZ =>
		{
			column_type  => [qw/tt a/],
			table_number => 1,
		},
		CA =>
		{
			column_type  => [qw/tt a - -/],
			table_number => 2,
		},
		CD =>
		{
			column_type  => [qw/tt a -/],
			table_number => 2,
		},
		CF =>
		{
			column_type  => [qw/tt a - -/],
			table_number => 2,
		},
		CG =>
		{
			column_type  => [qw/tt a -/],
			table_number => 1,
		},
		CH =>
		{
			column_type  => [qw/tt a/],
			table_number => 2,
		},
		CI =>
		{
			column_type  => [qw/tt a/],
			table_number => 2,
		},
		CL =>
		{
			column_type  => [qw/tt a/],
			table_number => 2,
		},
		CM =>
		{
			column_type  => [qw/tt a -/],
			table_number => 1,
		},
		CN =>
		{
			column_type  => [qw/tt a -/],
			table_number => 2,
		},
		CO =>
		{
			column_type  => [qw/tt a -/],
			table_number => 2,
		},
		CR =>
		{
			column_type  => [qw/tt a/],
			table_number => 1,
		},
		CU =>
		{
			column_type  => [qw/tt a -/],
			table_number => 1,
		},
		CV =>
		{
			column_type  => [qw/tt a a/],
			table_number => 3,
		},
		CY =>
		{
			column_type  => [qw/tt a -/],
			table_number => 1,
		},
		CZ =>
		{
			column_type  => [qw/tt a a/],
			table_number => 3,
		},
		DE =>
		{
			column_type  => [qw/tt a/],
			table_number => 1,
		},
		DJ =>
		{
			column_type  => [qw/tt a - -/],
			table_number => 2,
		},
		DK =>
		{
			column_type  => [qw/tt a/],
			table_number => 2,
		},
		DM =>
		{
			column_type  => [qw/tt a/],
			table_number => 2,
		},
		DO =>
		{
			column_type  => [qw/tt a -/],
			table_number => 2,
		},
		DZ =>
		{
			column_type  => [qw/tt a/],
			table_number => 1,
		},
		EC =>
		{
			column_type  => [qw/tt a/],
			table_number => 2,
		},
		EE =>
		{
			column_type  => [qw/tt a/],
			table_number => 1,
		},
		EG =>
		{
			column_type  => [qw/tt a/],
			table_number => 2,
		},
		ER =>
		{
			column_type  => [qw/tt a -/],
			table_number => 2,
		},
		ES =>
		{
			column_type  => [qw/tt a a/],
			table_number => 3,
		},
		ET =>
		{
			column_type  => [qw/tt - a -/],
			table_number => 2,
		},
		FI =>
		{
			column_type  => [qw/tt a - -/],
			table_number => 2,
		},
		FJ =>
		{
			column_type  => [qw/tt a -/],
			table_number => 1,
		},
		FK =>
		{
		},
		FM =>
		{
			column_type  => [qw/tt a/],
			table_number => 1,
		},
		FR =>
		{
			column_type  => [qw/tt a a/],
			table_number => 4,
		},
		GA =>
		{
			column_type  => [qw/tt a/],
			table_number => 1,
		},
		GB =>
		{
			column_type  => [qw/tt a - a/],
			table_number => 4,
		},
		GD =>
		{
			column_type  => [qw/tt a -/],
			table_number => 2,
		},
		GE =>
		{
			column_type  => [qw/tt a -/],
			table_number => 2,
		},
		GH =>
		{
			column_type  => [qw/tt a/],
			table_number => 1,
		},
		GI =>
		{
		},
		GL =>
		{
			column_type  => [qw/tt a/],
			table_number => 2,
		},
		GM =>
		{
			column_type  => [qw/tt a -/],
			table_number => 1,
		},
		GN =>
		{
			column_type  => [qw/tt a a/],
			table_number => 3,
		},
		GQ =>
		{
			column_type  => [qw/tt a - - a/],
			table_number => 3,
		},
		GR =>
		{
			column_type  => [qw/tt a - a/],
			table_number => 3,
		},
		GS =>
		{
		},
		GT =>
		{
			column_type  => [qw/tt a/],
			table_number => 2,
		},
		GU =>
		{
		},
		GW =>
		{
			column_type  => [qw/tt a - -/],
			table_number => 3,
		},
		GY =>
		{
			column_type  => [qw/tt a/],
			table_number => 1,
		},
		HN =>
		{
			column_type  => [qw/tt a/],
			table_number => 2,
		},
		HR =>
		{
			column_type  => [qw/tt a -/],
			table_number => 2,
		},
		HT =>
		{
			column_type  => [qw/tt a -/],
			table_number => 2,
		},
		HU =>
		{
			column_type  => [qw/tt a -/],
			table_number => 2,
		},
		ID =>
		{
			column_type  => [qw/tt a - a/],
			table_number => 3,
		},
		IE =>
		{
			column_type  => [qw/tt a - a/],
			table_number => 3,
		},
		IL =>
		{
			column_type  => [qw/tt a -/],
			table_number => 1,
		},
		IN =>
		{
			column_type  => [qw/tt a -/],
			table_number => 2,
		},
		IQ =>
		{
			column_type  => [qw/tt a/],
			table_number => 1,
		},
		IR =>
		{
			column_type  => [qw/tt a/],
			table_number => 2,
		},
		IS =>
		{
			column_type  => [qw/tt a/],
			table_number => 1,
		},
		IT =>
		{
			column_type  => [qw/tt a a/],
			table_number => 3,
		},
		JO =>
		{
			column_type  => [qw/tt a/],
			table_number => 2,
		},
		JM =>
		{
			column_type  => [qw/tt a/],
			table_number => 2,
		},
		JP =>
		{
			column_type  => [qw/tt a/],
			table_number => 1,
		},
		KE =>
		{
			column_type  => [qw/tt a -/],
			table_number => 2,
		},
		KG =>
		{
			column_type  => [qw/tt a - - -/],
			table_number => 2,
		},
		KH =>
		{
			column_type  => [qw/tt a -/],
			table_number => 2,
		},
		KI =>
		{
			column_type  => [qw/tt a/],
			table_number => 1,
		},
		KM =>
		{
			column_type  => [qw/tt - a -/],
			table_number => 2,
		},
		KN =>
		{
			column_type  => [qw/tt a - a/],
			table_number => 3,
		},
		KP =>
		{
			column_type  => [qw/tt a - -/],
			table_number => 2,
		},
		KR =>
		{
			column_type  => [qw/tt a -/],
			table_number => 2,
		},
		KW =>
		{
			column_type  => [qw/tt a/],
			table_number => 2,
		},
		KZ =>
		{
			column_type  => [qw/tt a - - -/],
			table_number => 2,
		},
		LA =>
		{
			column_type  => [qw/tt a -/],
			table_number => 2,
		},
		LB =>
		{
			column_type  => [qw/tt - -/],
			table_number => 2,
		},
		LC =>
		{
			column_type  => [qw/tt a/],
			table_number => 2,
		},
		LI =>
		{
			column_type  => [qw/tt a/],
			table_number => 2,
		},
		LK =>
		{
			column_type  => [qw/tt a - a/],
			table_number => 3,
		},
		LR =>
		{
			column_type  => [qw/tt a/],
			table_number => 2,
		},
		LS =>
		{
			column_type  => [qw/tt a/],
			table_number => 2,
		},
		LT =>
		{
			column_type  => [qw/tt a/],
			table_number => 1,
		},
		LU =>
		{
			column_type  => [qw/tt a/],
			table_number => 1,
		},
		LV =>
		{
			column_type  => [qw/tt a -/],
			table_number => 2,
		},
		LY =>
		{
			column_type  => [qw/tt a/],
			table_number => 2,
		},
		MA =>
		{
			column_type  => [qw/tt a - a/],
			table_number => 3,
		},
		MC =>
		{
			column_type  => [qw/tt a/],
			table_number => 2,
		},
		MD =>
		{
			column_type  => [qw/tt a -/],
			table_number => 2,
		},
		ME =>
		{
			column_type  => [qw/tt a/],
			table_number => 2,
		},
		MG =>
		{
			column_type  => [qw/tt a/],
			table_number => 1,
		},
		MH =>
		{
			column_type  => [qw/tt a a/],
			table_number => 3,
		},
		MK =>
		{
			column_type  => [qw/tt a -/],
			table_number => 2,
		},
		ML =>
		{
			column_type  => [qw/tt a -/],
			table_number => 1,
		},
		MM =>
		{
			column_type  => [qw/tt a -/],
			table_number => 2,
		},
		MN =>
		{
			column_type  => [qw/tt a -/],
			table_number => 1,
		},
		MR =>
		{
			column_type  => [qw/tt a -/],
			table_number => 1,
		},
		MT =>
		{
			column_type  => [qw/tt a/],
			table_number => 2,
		},
		MU =>
		{
			column_type  => [qw/tt a -/],
			table_number => 2,
		},
		MV =>
		{
			column_type  => [qw/tt a - -/],
			table_number => 3,
		},
		MW =>
		{
			column_type  => [qw/tt a a/],
			table_number => 3,
		},
		MX =>
		{
			column_type  => [qw/tt a -/],
			table_number => 1,
		},
		MY =>
		{
			column_type  => [qw/tt a -/],
			table_number => 2,
		},
		MZ =>
		{
			column_type  => [qw/tt a -/],
			table_number => 1,
		},
		NA =>
		{
			column_type  => [qw/tt a/],
			table_number => 1,
		},
		NC =>
		{
		},
		NE =>
		{
			column_type  => [qw/tt a -/],
			table_number => 2,
		},
		NF =>
		{
		},
		NG =>
		{
			column_type  => [qw/tt a -/],
			table_number => 2,
		},
		NI =>
		{
			column_type  => [qw/tt a -/],
			table_number => 2,
		},
		NL =>
		{
			column_type  => [qw/tt a/],
			table_number => 2,
		},
		NO =>
		{
			column_type  => [qw/tt a -/],
			table_number => 2,
		},
		NP =>
		{
			column_type  => [qw/tt a -/],
			table_number => 3,
		},
		NR =>
		{
			column_type  => [qw/tt a/],
			table_number => 2,
		},
		NZ =>
		{
			column_type  => [qw/tt a span - a/],
			table_number => 3,
		},
		OM =>
		{
			column_type  => [qw/tt a -/],
			table_number => 2,
		},
		PA =>
		{
			column_type  => [qw/tt a -/],
			table_number => 2,
		},
		PE =>
		{
			column_type  => [qw/tt a - - -/],
			table_number => 2,
		},
		PG =>
		{
			column_type  => [qw/tt a -/],
			table_number => 2,
		},
		PH =>
		{
			column_type  => [qw/tt a a/],
			table_number => 3,
		},
		PK =>
		{
			column_type  => [qw/tt a - -/],
			table_number => 2,
		},
		PL =>
		{
			column_type  => [qw/tt a/],
			table_number => 2,
		},
		PM =>
		{
		},
		PN =>
		{
		},
		PR =>
		{
		},
		PS =>
		{
			column_type  => [qw/tt a - -/],
			table_number => 2,
		},
		PT =>
		{
			column_type  => [qw/tt a -/],
			table_number => 1,
		},
		PW =>
		{
			column_type  => [qw/tt a/],
			table_number => 2,
		},
		PY =>
		{
			column_type  => [qw/tt a -/],
			table_number => 1,
		},
		QA =>
		{
			column_type  => [qw/tt a/],
			table_number => 2,
		},
		RO =>
		{
			column_type  => [qw/tt a -/],
			table_number => 2,
		},
		RS =>
		{
			column_type  => [qw/tt a - a/],
			table_number => 3,
		},
		RU =>
		{
			column_type  => [qw/tt a - -/],
			table_number => 2,
		},
		RW =>
		{
			column_type  => [qw/tt a -/],
			table_number => 2,
		},
		SA =>
		{
			column_type  => [qw/tt a/],
			table_number => 2,
		},
		SB =>
		{
			column_type  => [qw/tt a -/],
			table_number => 2,
		},
		SC =>
		{
			column_type  => [qw/tt a - -/],
			table_number => 2,
		},
		SD =>
		{
			column_type  => [qw/tt a -/],
			table_number => 2,
		},
		SE =>
		{
			column_type  => [qw/tt a -/],
			table_number => 2,
		},
		SG =>
		{
			column_type  => [qw/tt a/],
			table_number => 3,
		},
		SH =>
		{
			column_type  => [qw/tt a/],
			table_number => 2,
		},
		SI =>
		{
			column_type  => [qw/tt a/],
			table_number => 2,
		},
		SK =>
		{
			column_type  => [qw/tt a/],
			table_number => 1,
		},
		SL =>
		{
			column_type  => [qw/tt a -/],
			table_number => 1,
		},
		SM =>
		{
			column_type  => [qw/tt a/],
			table_number => 2,
		},
		SN =>
		{
			column_type  => [qw/tt a/],
			table_number => 2,
		},
		SO =>
		{
			column_type  => [qw/tt a/],
			table_number => 1,
		},
		SR =>
		{
			column_type  => [qw/tt a/],
			table_number => 1,
		},
		SS =>
		{
			column_type  => [qw/tt a/],
			table_number => 2,
		},
		ST =>
		{
			column_type  => [qw/tt a/],
			table_number => 1,
		},
		SV =>
		{
			column_type  => [qw/tt a/],
			table_number => 1,
		},
		SX =>
		{
		},
		SY =>
		{
			column_type  => [qw/tt a/],
			table_number => 1,
		},
		SZ =>
		{
			column_type  => [qw/tt a/],
			table_number => 1,
		},
		TD =>
		{
			column_type  => [qw/tt - a/],
			table_number => 2,
		},
		TF =>
		{
		},
		TG =>
		{
			column_type  => [qw/tt a/],
			table_number => 1,
		},
		TH =>
		{
			column_type  => [qw/tt a -/],
			table_number => 2,
		},
		TJ =>
		{
			column_type  => [qw/tt a -/],
			table_number => 2,
		},
		TL =>
		{
			column_type  => [qw/tt a -/],
			table_number => 2,
		},
		TM =>
		{
			column_type  => [qw/tt a -/],
			table_number => 2,
		},
		TN =>
		{
			column_type  => [qw/tt a/],
			table_number => 2,
		},
		TO =>
		{
			column_type  => [qw/tt a/],
			table_number => 2,
		},
		TR =>
		{
			column_type  => [qw/tt a/],
			table_number => 2,
		},
		TT =>
		{
			column_type  => [qw/tt a -/],
			table_number => 1,
		},
		TV =>
		{
			column_type  => [qw/tt a -/],
			table_number => 2,
		},
		TW =>
		{
			column_type  => [qw/tt - - a/],
			table_number => 2,
		},
		TZ =>
		{
			column_type  => [qw/tt - a/],
			table_number => 2,
		},
		UA =>
		{
			column_type  => [qw/tt a -/],
			table_number => 1,
		},
		UG =>
		{
			column_type  => [qw/tt a a/],
			table_number => 3,
		},
		UM =>
		{
			column_type  => [qw/tt a -/],
			table_number => 1,
		},
		US =>
		{
			column_type  => [qw/tt a -/],
			table_number => 2,
		},
		UY =>
		{
			column_type  => [qw/code a/],
			table_number => 1,
		},
		UZ =>
		{
			column_type  => [qw/tt a -/],
			table_number => 2,
		},
		VC =>
		{
			column_type  => [qw/tt a/],
			table_number => 2,
		},
		VE =>
		{
			column_type  => [qw/tt a -/],
			table_number => 2,
		},
		VI =>
		{
		},
		VN =>
		{
			column_type  => [qw/tt a -/],
			table_number => 2,
		},
		VU =>
		{
			column_type  => [qw/tt a/],
			table_number => 1,
		},
		WS =>
		{
			column_type  => [qw/tt a/],
			table_number => 1,
		},
		YE =>
		{
			column_type  => [qw/tt a -/],
			table_number => 2,
		},
		ZA =>
		{
			column_type  => [qw/tt a - - - - -/],
			table_number => 2,
		},
		ZM =>
		{
			column_type  => [qw/tt a/],
			table_number => 1,
		},
		ZW =>
		{
			column_type  => [qw/tt a/],
			table_number => 1,
		},
	);

	die "Unknown country code: $code2\n" if (! $code{$code2});

	if (! exists $code{$code2}{table_number})
	{
		$self -> log(warning => "Country with code $code2 has no subcountries");

		return undef;
	}

	my($in_file) = "data/en.wikipedia.org.wiki.ISO_3166-2.$code2.html";
	my($root)    = HTML::TreeBuilder -> new();
	my($result)  = $root -> parse_file($in_file) || die "Can't parse file: $in_file\n";
	my(@node)    = $root -> look_down(_tag => 'table');
	my($names)   = $self -> get_table
		(
			$node[$code{$code2}{table_number} - 1],
			$code{$code2}{column_type},
			$code2 =~ /(ET|KM|LB|TD)/ ? $1 : undef
		);

	$root -> delete;

	return $names;

} # End of parse_subcountry_page.

# -----------------------------------------------

sub populate_countries
{
	my($self)  = @_;
	my($codes) = $self -> parse_country_code_page;
	my($names) = $self -> parse_country_page;
	$names     = $self -> process_countries($names);

	# Reformat @$codes{code => x, name => x} as %codes{$name} = $code.

	my(%codes);

	for my $i (0 .. $#$codes)
	{
		$codes{$$codes[$i]{name} } = $$codes[$i]{code};
	}

	$self -> save_countries(\%codes, $names);

	# TODO: Have to return $specials from parse_country_page().
	#$self -> process_table($specials);

	# Return 0 for success and 1 for failure.

	return 0;

} # End of populate_countries.

# ----------------------------------------------

sub populate_fips_codes
{
	my($self) = @_;
	my($name) = $self -> process_fips_codes;

	say $_ for @$name;

} # End of populate_fips_codes.

# -----------------------------------------------

sub populate_subcountry
{
	my($self, $count) = @_;
	$count            ||= 1; # If called from scripts/populate.subcountry.pl.
	my($names)        = $self -> parse_subcountry_page;

	if ($names)
	{
		$names = $self -> process_subcountry($names);

		$self -> save_subcountry($count, $names);
	}

	# Return 0 for success and 1 for failure.

	return 0;

} # End of populate_subcountry.

# -----------------------------------------------

sub populate_subcountries
{
	my($self)  = @_;

	# 1: Find which subcountries have been downloaded but not imported.
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

	my($count) = 0;

	my($code2);

	for $country_id (keys %$countries)
	{
		$count++;

		$code2 = $$countries{$country_id}{code2};

		next if ($imported{$code2});

		next if ($$countries{$country_id}{has_subcountries} eq 'No');

		$self -> code2($code2);
		$self -> populate_subcountry($count);
	}

	# Return 0 for success and 1 for failure.

	return 0;

} # End of populate_subcountries.

# ----------------------------------------------

sub process_countries
{
	my($self, $table) = @_;

	my(%kind);
	my(@result);

	for my $element (@$table)
	{
		my(@item);

		for my $item (split(/,\s*/, $$element{detail} || '') )
		{
			if ($item =~ /^(\d+)\s+(.+)$/)
			{
				$kind{$2} = 1;

				push @item, {$2 => $1};
			}
			else
			{
				# Skip ':' and (fancy) '-' == 0xe2.

				if ( (ord(substr($item, 0, 1) ) != 0xe2) && ($item ne ':') )
				{
					$kind{subdivision} = 1;

					push @item, {subdivision => $item};
				}
			}
		}

		# Concatenate multiple entries called 'subdivision'.
		# Currently, this is for GB => United Kingdom only.

		my($first);
		my($last);

		for my $i (1 .. $#item)
		{
			if (exists($item[$i - 1]{subdivision}) && exists($item[$i]{subdivision}) )
			{
				$first = $i - 1 if (! defined $first);
				$last  = $i;
			}
		}

		if ($first)
		{
			my($item);
			my(@text);

			for my $i ($first .. $last)
			{
				$item = $item[$i];

				push @text, $$item{subdivision};
			}

			splice(@item, $first, $last, {subdivision => join(', ', @text)});
		}

		if ($#item >= 0)
		{
			$$element{detail} = [@item];
		}
		else
		{
			delete $$element{detail};
		}

		push @result, $element;
	}

	# This is for determining whether or not we
	# ignore junk such as the ':' and (fancy) '-' == 0xe2 above.

	if ($self -> verbose > 2)
	{
		$self -> log(debug => "Kind: $_") for sort keys %kind;
	}

	return [@result];

} # End of process_countries.

# ----------------------------------------------

sub process_fips_codes
{
	my($self)   = @_;
	my(@suffix) = (qw/A-C D-F G-I J-L M-O P-R S-U V-Z/);

	my(@result);

	for my $suffix (@suffix)
	{
		push @result, @{$self -> parse_fips_page($suffix)};
	}

	return [@result];

} # End of process_fips_codes.

# ----------------------------------------------

sub process_subcountry
{
	my($self, $table) = @_;

	# Zap unwanted data in the hashref. Subcountries don't have 'detail',
	# but the code for countries and subcountries created this key.

	my(@result);

	for my $element (@$table)
	{
		delete $$element{detail};

		push @result, $element;
	}

	return [@result];

} # End of process_subcountry.

# ----------------------------------------------

sub save_countries
{
	my($self, $code3, $table) = @_;

	$self -> dbh -> do('delete from countries');

	my($i)   = 0;
	my($sql) = 'insert into countries (code2, code3, fc_name, has_subcountries, name) values (?, ?, ?, ?, ?)';
	my($sth) = $self -> dbh -> prepare($sql) || die "Unable to prepare SQL: $sql\n";

	for my $element (@$table)
	{
		$i++;

		$sth -> execute($$element{code}, $$code3{$$element{name} } || '', fc decode('utf8', $$element{name}), defined($$element{detail}) ? 'Yes' : 'No', decode('utf8', $$element{name}) );
	}

	$sth -> finish;

	$self -> log(info => "Saved $i countries to the database");

} # End of save_countries.

# ----------------------------------------------

sub save_subcountry
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

	my($decode);

	for my $element (@$table)
	{
		$i++;

		$decode = decode('utf8', $$element{name});

		$sth -> execute($country_id, $$element{code}, fc $decode, $decode, $i);
	}

	$sth -> finish;

	$self -> log(info => "$count: $code2 => '$$countries{$country_id}{name}' contains $i subcountries");

} # End of save_subcountry.

# ----------------------------------------------

sub trim
{
	my($self, $s) = @_;
	$s ||= '';
	$s =~ s/^\s+//;
	$s =~ s/\s+$//;

	return $s;

} # End of trim.

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

This module is a sub-class of L<WWW::Scraper::Wikipedia::ISO3166::Database> and consequently inherits its methods.

=head2 code2($code)

Get or set the 2-letter country code of the country or subcountry being processed.

Also, I<code2> is an option to L</new()>.

=head2 get_content($element)

Extract, recursively if necessary, the content of the HTML element, as returned from L<HTML::TreeBuilder>'s
look_down() method.

=head2 get_table($node, $column_type, $country_code)

Get the country or subcountry details from the HTML table ($node), as returned from L<HTML::TreeBuilder>'s
look_down() method.

Use the arrayref $column_type of HTML attributes ('a', 'tt', '-', i.e. none) to determine exactly how to extract
the data from the enclosing 'td'.

Use $country_code to handle some special cases, specifically:

=over 4

=item o ET => Ethopia

=item o KM => Comoros

=item o LB => Lebanon

=item o TD => Chad

=back

Returns an arrayref of hashrefs, where the (key => value) pair of each hashref are:

=over 4

=item o code => $string

The country or subcountry code.

=item o detail => $arrayref

An indicator as to whether or not the country has subcountries.

=item o name => $string

The name of the country or subcountry.

=back

=head2 new()

See L</Constructor and initialization>.

=head2 parse_country_code_page()

Parse the HTML page of 3-letter country codes, which has 3 tables side-by-side.

Return an arrayref of 3-letter codes.

Special cases are documented in L<WWW::Scraper::Wikipedia::ISO3166/What is the database schema?>.

=head2 parse_country_page()

Parse the HTML page of country names.

Returns the result of calling L</get_table($node, $column_type, $country_code)>.

=head2 parse_subcountry_page()

Parse the HTML page of a subcountry.

Warning. The 2-letter code of the subcountry must be set with $self -> code2('XX') before calling this
method.

Returns the result of calling L</get_table($node, $column_type, $country_code)>.

=head2 populate_countries()

Populate the I<countries> table.

=head2 populate_subcountry($count)

Populate the I<subcountries> table, for 1 subcountry.

Warning. The 2-letter code of the subcountry must be set with $self -> code2('XX') before calling this
method.

=head2 populate_subcountries()

Populate the I<subcountries> table, for all subcountries.

=head2 process_countries($table)

Clean up the I<detail> key of the arrayref of hashrefs for the countries.

=head2 process_subcountries($table)

Delete the I<detail> key of the arrayref of hashrefs for the subcountry.

=head2 save_countries($code3, $table)

Save the I<countries> table, by combining the output of L<parse_country_code_page()> with the output of
L</process_countries($table)>.

=head2 save_subcountries($count, $table)

Save the I<subcountries> table, for the given subcountry, using the output of L</process_subcountries($table)>.

$count is just used in the log for progress messages.

=head2 trim($s)

Remove leading and trailing spaces from $s, and return it.

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
