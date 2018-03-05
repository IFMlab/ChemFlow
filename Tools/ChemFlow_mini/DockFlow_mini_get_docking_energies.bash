#!/bin/bash

# Input files
receptor="receptor.mol2"
ligand_folder="lig_mol2_split"

# Output folder
output_folder="results"

get_energy_PLANTS() {
for i in ${list} ; do
  awk '//'
done
}

list=$(cd ${output_folder} ; ls)
echo $list

