#!/bin/bash

PDB_LIST="1D3D 1D3P 1D3Q 1D3T 1DWB 1DWC 1DWD"

if [ -d PDB ] ; then mkdir PDB ; fi 

cd PDB/

for PDB in ${PDB_LIST} ; do 
    $HOME/software/schrodinger2018-1/utilities/getpdb ${PDB}
done


