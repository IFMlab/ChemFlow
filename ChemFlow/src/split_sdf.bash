#!/bin/bashi
OLDIFS=${IFS}
IFS='%'

n=0
while read line ; do
  if [ ${n} == 0 ] ; then
    name=${line}
    n=1
    echo ${line} > ${name}.sdf
  else
    echo ${line} >> ${name}.sdf
  fi

  if [ "${line}" == '$$$$' ] ; then 
    n=0
  fi
done <compounds.sdf

IFS=${OLDIFS}
