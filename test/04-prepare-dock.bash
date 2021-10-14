#!/bin/bash
eval "$(conda shell.bash hook)"
conda activate chemflow

# Config
basedir=$PWD
export PATH='/home/dgomes/ADFRsuite-1.0/bin/':$PATH

PDB_LIST=$(awk '!/2tpi/ {print $1}' trypsin_greenidge.lst )

for PDB in ${PDB_LIST} ; do

  cd ${basedir}/${PDB}/

  prepare_receptor -r ${PDB}.pdb -o receptor.pdbqt

  ~/software/schrodinger2021-3/utilities/structconvert ${PDB}.sdf ligand.mol2

  prepare_ligand -l ligand.mol2 -o ligand.pdbqt 

done

