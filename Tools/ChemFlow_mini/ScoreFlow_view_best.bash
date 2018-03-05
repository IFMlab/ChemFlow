#!/bin/bash

read -p "How many top results to open in PyMol? " ntop

# View top results in pymol.
IFS=,
list=""
j=0
while [ $j -le ${ntop} ] ; do 
  read ligand energy
  list="${list} ${ligand}"
  let j++
done < MMGBSA_implicit_rank.csv 

cmd=""
if [ -f pymol.selected.py ] ; then rm -rf pymol.selected.py ; fi

IFS=" "
for i in ${list[@]} ; do
  echo "cmd.load( 'ScoreFlow/MMGBSA_implicit/${i}/complex.pdb' ,'${i}')" >> pymol.selected.py
done

