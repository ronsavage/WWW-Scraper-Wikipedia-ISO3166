#!/bin/bash

perl -Ilib scripts/drop.tables.pl
perl -Ilib scripts/create.tables.pl

echo Run populate.countries.pl

time perl -Ilib scripts/populate.countries.pl -maxlevel debug

echo Run populate.subcountries.pl

time perl -Ilib scripts/populate.subcountries.pl -maxlevel debug

echo Run export.as.html.pl

time perl -Ilib scripts/export.as.html.pl -w data/iso.3166-2.html

cp data/iso.3166-2.html $DR/

echo Copied data/iso.3166-2.html to doc root
echo Finished
