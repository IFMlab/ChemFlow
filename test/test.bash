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





#
# Functions --------------------------------------------------------------------
#
ChemFlow_Checkfile_ERROR() {
# Checks if file exists. If not, exit with error.
if [ ! -f "$1" ] ; then
  echo "[ Error ] File: ${1} not found"
  exit 1
fi
}


#
# Program ----------------------------------------------------------------------
#
echo "[ ChemFlow ] Initiating test"
ChemFlow_Checkfile_ERROR hostguest.tar.gz

# Extracts test data to run "input" folder
tar xfz hostguest.tar.gz

# Go to input data folder.
cd input

# Run DockFlow
DockFlow --project test -r CB7.mol2 -l AD0.mol2 --center 2.713 1.767 4.858 --radius 12




