#!/bin/bash

cp /dev/null populate.countries.log

perl -Ilib scripts/drop.tables.pl >> populate.countries.log
perl -Ilib scripts/create.tables.pl >> populate.countries.log

echo Run populate.countries.pl >> populate.countries.log

time perl -Ilib scripts/populate.countries.pl -v 1 >> populate.countries.log

echo Run populate.subcountries.pl >> populate.countries.log

time perl -Ilib scripts/populate.subcountries.pl -v 1 >> populate.countries.log

echo Finished >> populate.countries.log
