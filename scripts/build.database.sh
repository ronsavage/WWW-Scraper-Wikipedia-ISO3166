#!/bin/bash

cp /dev/null populate.countries.log

perl -Ilib scripts/drop.tables.pl >> populate.countries.log
perl -Ilib scripts/create.tables.pl >> populate.countries.log

echo Run populate.countries.pl >> populate.countries.log

time perl -Ilib scripts/populate.countries.pl -maxlevel debug >> populate.countries.log

#echo Run populate.subcountries.pl >> populate.countries.log

#time perl -Ilib scripts/populate.subcountries.pl -maxlevel debug >> populate.countries.log

perl -Ilib scripts/export.as.html.pl

cp iso.3166-2.html $DR/

echo Finished, and copied iso.3166-2.html to doc root >> populate.countries.log
