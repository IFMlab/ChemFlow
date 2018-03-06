#!/bin/bash
#
# ChemFlow 2018 - Computational Chemistry is Great Again.
#
# @Brief
# This script is intended to be used with IChem to compute the Structural
# Interaction Fingerprint (SIFP) for virtual screening (VS) poses, using IChem.
# VS must be performed with Autodock Vina (so far)
# 
# IChem licence must be obtained from:
#  http://bioinfo-pharma.u-strasbg.fr/labwebsite/download.html
#
# @author 
# Diego Enry Barreto Gomes, dgomes@pq.cnpq.br
# Priscila da Silva Figueiredo Celestino Gomes, pdasilva@unistra.fr
#
# @version 0.1 
# @mardi 6 mars 2018, 10:29:05 (UTC+0100)
#
# Copyright (c) 2018 Diego Gomes, Cedric Bouysset & Marco Cecchini
# 
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#  
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#  
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#
# -------------------------------------------------------------------
#
#
# INPUT FILES -----------------------------------------------------------------
#        receptor: Reference Receptor (format: TRIPOS MOL2).
#          ligand: Reference Ligand   (format: TRIPOS MOL2).
#     ligand_name: Reference ligand NAME in the .mol2 file.
# compound_prefix: Prefix for the compounds in the .pdbqt file (ex. ZINC)
#       rank_file: File containing the RANKING of compounds  (format: CSV).
#     max_results: Maximum number of results to extract
#     vina_result: Path to the folder where Vina results are (format: PDBQT).
#
#
# How to use ------------------------------------------------------------------
# Step 1 - Change what's necessary in the configuration below
# Step 2 - Run this script
# Step 3 - Smile
#


# Configuration ---------------------------------------------------------------
       receptor="receptor.mol2"     # Receptor file
         ligand="sam.mol2"          # Reference ligand
    ligand_name="SAM"               # Ligand name
compound_prefix="ZINC"              # Compound prefix
      rank_file="rank.csv"          # Ranking file
   vina_results="../results/"       # Folder with VS results
    max_results="100000"            # Number of results to IChem
    output_file="ifp.dat"           # Outout file
          nproc="8"                 # Number of processors to use.


# ------------------------------------// --------------------------------------





# WARNING! - ATTENTION ! - ACHTUNG ! ATENCAO! - ATENCION ! UWAGA!
#
# Do not change anything below unless you know what you're doing.
# Ne modifiez rien ci-dessous, sauf si vous savez ce que vous faites.
# Ändern Sie nichts unter, wenn Sie nicht wissen, was Sie tun.
# Nao modifique nada abaixo, salvo se voce sabe o que faz.
# No cambie nada abajo a menos que sepa lo que está haciendo.
# Nie zmieniaj ponizszego kodu, jezeli nie jestes pewien co robisz.
# 
# WARNING! - ATTENTION ! - ACHTUNG ! ATENCAO! - ATENCION! UWAGA!



# Functions -------------------------------------------------------------------
# Run Babel and IChem
run_IChem() {
babel -ipdbqt ${vina_results}/${mol}.pdbqt -omol2 /dev/shm/tmp.mol2 --addoutindex &>/dev/null
IChem --extended IFP /dev/shm/${receptor} /dev/shm/${mol}.mol2 /dev/shm/${ligand} | grep "${ligand_name}.*${compound_prefix}" >> /dev/shm/ifp.dat
}

run_IChem_parallel() {
babel -ipdbqt ${vina_results}/${mol}.pdbqt -omol2 /dev/shm/${mol}.mol2 --addoutindex &>/dev/null 
IChem --extended IFP /dev/shm/${receptor} /dev/shm/${mol}.mol2 /dev/shm/${ligand} | grep "${ligand_name}.*${compound_prefix}" >> /dev/shm/ifp.dat
rm /dev/shm/${mol}.mol2
}


# PROGRAM ---------------------------------------------------------------------
# Copy frequently used files to RAM
cp ${receptor}  /dev/shm/
cp ${ligand}    /dev/shm/
rm -rf /dev/shm/ifp.dat

# change the Input Field Separator to ","
IFS=","


if [ -f ${output_file} ] ; then 
  rm ${output_file} 
fi

i=0
while [ ${i} -lt ${max_results} ] ; do
  let i++
  ((j=j%nproc)); ((j++==0)) && wait
  read mol energy
#  run_IChem &> /dev/null
  run_IChem_parallel &> /dev/null &
done <rank.csv
wait

# Copy stuff the temporary output file to final location..
cp /dev/shm/ifp.dat ${output_file}


# Endnotes --------------------------------------------------------------------
# got the tip to paralelize the loop from here:
# https://unix.stackexchange.com/questions/103920/parallelize-a-bash-for-loop
