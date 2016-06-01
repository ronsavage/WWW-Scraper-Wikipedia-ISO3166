#!/bin/bash

perl -Ilib scripts/drop.tables.pl
perl -Ilib scripts/create.tables.pl

echo Run populate.countries.pl

perl -Ilib scripts/populate.countries.pl -maxlevel debug

echo Run populate.subcountries.pl

perl -Ilib scripts/populate.subcountries.pl -maxlevel debug

echo Run export.as.html.pl

perl -Ilib scripts/export.as.html.pl -w data/iso.3166-2.html

cp data/iso.3166-2.html $DR/

echo Copied data/iso.3166-2.html to doc root

echo Run export.as.csv.pl

perl -Ilib scripts/export.as.csv.pl \
	-country_file			data/countries.csv \
	-subcountry_file		data/subcountries.csv \
	-subcountry_type_file	data/subcountry.types.csv

echo Finished
