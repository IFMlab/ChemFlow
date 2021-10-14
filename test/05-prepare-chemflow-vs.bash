#!/bin/bash

# Config
basedir=$PWD

PDB_LIST=$(awk '!/2tpi/ {print $1}' trypsin_greenidge.lst )

for PDB in ${PDB_LIST} ; do
  cat ${PDB}/ligand.mol2
done > trypsin_ligands.mol2

for PDB in ${PDB_LIST} ; do
  cat ${PDB}/${PDB}.sdf
done > trypsin_ligands.sdf

