#!/bin/bash

# Extract TRYPSIN from PDBBind
grep  "P00760" INDEX_general_PL_name.2020 > trypsin_pdbbind2020.lst

# Extract TRYPSIN found on greenidge
grep -wFf greenidge.lst trypsin_pdbbind2020.lst > trypsin_greenidge.lst

# Create pymol script
list=$(awk '{print $1}' trypsin_greenidge.lst )
line='list=['
for pdb in $list ; do
  line="${line}\"${pdb}\","
done
line="${line}]"

