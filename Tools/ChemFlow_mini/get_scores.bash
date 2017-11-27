#!/bin/bash
if [ -f scores.csv ] ; then rm -rf scores.csv ; fi
for i in $(cd results ; ls *.out | cut -d. -f1 ) ; do
  #echo -ne "Getting score for ${i} \r"
  awk -v i=${i} '/0.000      0.000/ {print i","$2}' results/${i}.out  >> scores.csv
done
