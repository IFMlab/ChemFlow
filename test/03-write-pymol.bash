#!/bin/bash
PDB_LIST=$(awk '!/2tpi/ {print $1}' trypsin_greenidge.lst )
PDB_LIST=($PDB_LIST)

echo "
from pymol import cmd
PDB_LIST=\"${PDB_LIST[@]}\".split()
for PDB in PDB_LIST : cmd.load(f'{PDB}/{PDB}.pdb')

# Align to 1bju (no reason for 1bju)
cmd.alignto('1bju')
"
