#!/bin/bash
##################################################################### 
#   ChemFlow  -   Computational Chemistry is great again            #
#####################################################################
#
# Diego E. B. Gomes(1,2,3) - dgomes@pq.cnpq.br
# Cedric Boysset (3,4) - cboysset@unice.fr
# Marco Cecchini (3) - cecchini@unistra.fr
#
# 1 - Instituto Nacional de Metrologia, Qualidade e Tecnologia - Brazil
# 2 - Coordenacao Aperfeicoamento de Pessoal de Ensino Superior - CAPES - Brazil.
# 3 - Universite de Strasbourg - France
# 4 - Universite de Nice - France
#
#===============================================================================
#
#          FILE:  test.bash
#
#         USAGE: ./test.bash
# 
#
#         BRIEF: Main routine for testing ChemFlow
#   DESCRIPTION: Prepare and run a docking, and rescoring calculation.
#    COMPLIANCY: The ChemFlow standard version 1.0
#
#     MANDATORY: none
#  MAIN OPTIONS: none
#  REQUIREMENTS:  [PLANTS], [VINA], [AMBER16+], [SLURM], PBS]
#          BUGS:  ---
#         NOTES:  ---
#        AUTHOR:  Diego E. B. Gomes, dgomes@pq.cnpq.br
#       COMPANY:  Universite de Strasbourg / CAPES
#       VERSION:  1.0
#       CREATED:  mercredi 4 juillet 2018, 13:36:53 (UTC+0200)
#      REVISION:  ---
#===============================================================================

DEBUG='no'


# ChemFlow common functions.
source ${CHEMFLOW_HOME}/src/ChemFlow_functions.bash

#
# Program ----------------------------------------------------------------------
#
echo "[ ChemFlow ] Initiating test"
ChemFlow_Checkfile_ERROR protein_ligand.tar.gz

# Extracts test data to run "input" folder
#tar xfz protein_ligand.tar.gz

# Go to input data folder.
cd protein_ligand

#
python $(which SmilesTo3D.py ) -i compounds.smi -o compounds.sdf --hydrogen
babel -isdf compounds.sdf -omol2 compounds.mol2

# Run DockFlow
DockFlow --project test -r receptor.mol2 -l compounds.mol2 --radius 12 --center 20.259 -2.752 18.203 <<EOF
y
y
EOF
