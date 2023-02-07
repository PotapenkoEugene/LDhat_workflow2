#!/bin/bash

#load parallel if necessary

find . -type f -name '*.txt' | parallel gzip --best

exit
for i in $(find . -name "rates.txt") ; do gzip $i ; done
for i in $(find . -name "bounds.txt") ; do gzip $i ; done
for i in $(find . -name "type_table.txt") ; do gzip $i ; done
for i in $(find . -name "new_lk.txt") ; do gzip $i ; done
for i in $(find . -name "res.txt") ; do gzip $i ; done
