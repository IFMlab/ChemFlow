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
source ${CHEMFLOW_HOME}/test/test_function.sh

clean_project(){
    cd ${CHEMFLOW_HOME}/test/
    rm -rf protein_ligand
}


# Vina =============================================================================================================
run_vina_no_continue(){
# Run DockFlow
DockFlow --project test --protocol vina1 -r receptor.mol2 -l compounds.mol2 --radius 10 --center 20.259 -2.752 18.203 -sf vina <<EOF
n
EOF
}

run_vina_overwrite_no_continue(){
# Run DockFlow
DockFlow --project test --protocol vina1 -r receptor.mol2 -l compounds.mol2 --radius 10 --center 20.259 -2.752 18.203 -sf vina --overwrite <<EOF
Y
n
EOF
}

run_vina_continue_no_rewrite_ligand(){
# Run DockFlow
DockFlow --project test --protocol vina1 -r receptor.mol2 -l compounds.mol2 --radius 10 --center 20.259 -2.752 18.203 -sf vina <<EOF
y
n
EOF
}

run_vina_continue_rewrite_ligand(){
# Run DockFlow
DockFlow --project test --protocol vina1 -r receptor.mol2 -l compounds.mol2 --radius 10 --center 20.259 -2.752 18.203 -sf vina <<EOF
y
y
EOF
}

postdock_vina_no_archive(){
DockFlow --project test --protocol vina1 -r receptor.mol2 -l compounds.mol2 --radius 10 --center 20.259 -2.752 18.203 -sf vina --postdock<<EOF
n
EOF
}

postdock_vina_archive_no_remove(){
DockFlow --project test --protocol vina1 -r receptor.mol2 -l compounds.mol2 --radius 10 --center 20.259 -2.752 18.203 -sf vina --postdock<<EOF
y
n
EOF
}

postdock_vina_archive_remove(){
DockFlow --project test --protocol vina1 -r receptor.mol2 -l compounds.mol2 --radius 10 --center 20.259 -2.752 18.203 -sf vina --postdock<<EOF
y
y
EOF
}

archive_vina_archive_no_remove(){
DockFlow --project test --protocol vina1 -r receptor.mol2 -l compounds.mol2 --radius 10 --center 20.259 -2.752 18.203 -sf vina --archive<<EOF
y
n
EOF
}

archive_vina_archive_remove(){
DockFlow --project test --protocol vina1 -r receptor.mol2 -l compounds.mol2 --radius 10 --center 20.259 -2.752 18.203 -sf vina --archive<<EOF
y
y
EOF
}

# Plants (default) =============================================================================================================
run_plants_no_continue(){
# Run DockFlow
DockFlow --project test --protocol vina1 -r receptor.mol2 -l compounds.mol2 --radius 10 --center 20.259 -2.752 18.203 <<EOF
n
EOF
}

run_plants_overwrite_no_continue(){
# Run DockFlow
DockFlow --project test --protocol vina1 -r receptor.mol2 -l compounds.mol2 --radius 10 --center 20.259 -2.752 18.203 --overwrite <<EOF
Y
n
EOF
}

run_plants_continue_no_rewrite_ligand(){
# Run DockFlow
DockFlow --project test --protocol vina1 -r receptor.mol2 -l compounds.mol2 --radius 10 --center 20.259 -2.752 18.203 <<EOF
y
n
EOF
}

run_plants_continue_rewrite_ligand(){
# Run DockFlow
DockFlow --project test --protocol vina1 -r receptor.mol2 -l compounds.mol2 --radius 10 --center 20.259 -2.752 18.203 <<EOF
y
y
EOF
}

postdock_plants_no_archive(){
DockFlow --project test --protocol vina1 -r receptor.mol2 -l compounds.mol2 --radius 10 --center 20.259 -2.752 18.203 --postdock<<EOF
n
EOF
}

postdock_plants_archive_no_remove(){
DockFlow --project test --protocol vina1 -r receptor.mol2 -l compounds.mol2 --radius 10 --center 20.259 -2.752 18.203 --postdock<<EOF
y
n
EOF
}

postdock_plants_archive_remove(){
DockFlow --project test --protocol vina1 -r receptor.mol2 -l compounds.mol2 --radius 10 --center 20.259 -2.752 18.203 --postdock<<EOF
y
y
EOF
}

archive_plants_archive_no_remove(){
DockFlow --project test --protocol vina1 -r receptor.mol2 -l compounds.mol2 --radius 10 --center 20.259 -2.752 18.203 --archive<<EOF
y
n
EOF
}

archive_plants_archive_remove(){
DockFlow --project test --protocol vina1 -r receptor.mol2 -l compounds.mol2 --radius 10 --center 20.259 -2.752 18.203 --archive<<EOF
y
y
EOF
}


# Test DockFlow input --------------------------------------------------------------------------------------------------
test_dockflow_plants_without_arg(){
TEST="test_dockflow_plants_without_arg"
output=`DockFlow`
output=`echo ${output}`
expected="[ ERROR ] DockFlow called without arguments. For help, type: DockFlow -h"
assertOutputIsExpected
}

test_dockflow_vina_without_arg(){
TEST="test_dockflow_vina_without_arg"
output=`DockFlow`
output=`echo ${output}`
expected="[ ERROR ] DockFlow called without arguments. For help, type: DockFlow -h"
assertOutputIsExpected
}

test_dockflow_plants_without_project(){
TEST="test_dockflow_plants_without_project"
output=`DockFlow --protocol vina1 -r receptor.mol2 -l compounds.mol2`
output=`echo ${output}`
expected="[ ChemFlow ] Checking input files... [ ERROR ] No PROJECT name (-p myproject) For help, type: DockFlow -h"
assertOutputIsExpected
}

test_dockflow_vina_without_project(){
TEST="test_dockflow_vina_without_project"
output=`DockFlow --protocol vina1 -r receptor.mol2 -l compounds.mol2 -sf vina`
output=`echo ${output}`
expected="[ ChemFlow ] Checking input files... [ ERROR ] No PROJECT name (-p myproject) For help, type: DockFlow -h"
assertOutputIsExpected
}

test_dockflow_plants_without_receptor_file(){
TEST="test_dockflow_plants_without_receptor_file"
output=`DockFlow -p test --protocol vina1 -l compounds.mol2`
output=`echo ${output}`
expected="[ ChemFlow ] Checking input files... [ ERROR ] No RECEPTOR file name (-r receptor_file.mol2) For help, type: DockFlow -h"
assertOutputIsExpected
}

test_dockflow_vina_without_receptor_file(){
TEST="test_dockflow_vina_without_receptor_file"
output=`DockFlow -p test --protocol vina1 -l compounds.mol2 -sf vina`
output=`echo ${output}`
expected="[ ChemFlow ] Checking input files... [ ERROR ] No RECEPTOR file name (-r receptor_file.mol2) For help, type: DockFlow -h"
assertOutputIsExpected
}

test_dockflow_plants_without_ligand_file(){
TEST="test_dockflow_plants_without_ligand_file"
output=`DockFlow -p test --protocol vina1 -r receptor.mol2`
output=`echo ${output}`
expected="[ ChemFlow ] Checking input files... [ ERROR ] No LIGAND filename (-l ligand_file.mol2) For help, type: DockFlow -h"
assertOutputIsExpected
}

test_dockflow_vina_without_ligand_file(){
TEST="test_dockflow_vina_without_ligand_file"
output=`DockFlow -p test --protocol vina1 -r receptor.mol2 -sf vina`
output=`echo ${output}`
expected="[ ChemFlow ] Checking input files... [ ERROR ] No LIGAND filename (-l ligand_file.mol2) For help, type: DockFlow -h"
assertOutputIsExpected
}

test_dockflow_plants_without_center(){
TEST="test_dockflow_plants_without_center"
output=`DockFlow --project test --protocol vina1 -r receptor.mol2 -l compounds.mol2`
output=`echo ${output}`
expected="[ ChemFlow ] Checking input files... [ ERROR ] No DOCKING CENTER defined (--center x y z) For help, type: DockFlow -h"
assertOutputIsExpected
}

test_dockflow_vina_without_center(){
TEST="test_dockflow_vina_without_center"
output=`DockFlow --project test --protocol vina1 -r receptor.mol2 -l compounds.mol2 -sf vina`
output=`echo ${output}`
expected="[ ChemFlow ] Checking input files... [ ERROR ] No DOCKING CENTER defined (--center x y z) For help, type: DockFlow -h"
assertOutputIsExpected
}

test_dockflow_postdock_empty_plants(){
TEST="test_dockflow_plants_without_center"
output=`DockFlow --project test --protocol vina1 -r receptor.mol2 -l compounds.mol2 --postdock`
output=`echo ${output}`
expected="[ ChemFlow ] Checking input files... [ ERROR ] Plants result for ligand CHEMBL195725 does not exists. [ ERROR ] Plants result for ligand CHEMBL477992 does not exists. [ DockFlow ] Error during post-processing, see error above."
assertOutputIsExpected
}

test_dockflow_postdock_empty_vina(){
TEST="test_dockflow_vina_without_center"
output=`DockFlow --project test --protocol vina1 -r receptor.mol2 -l compounds.mol2 -sf vina --postdock`
output=`echo ${output}`
expected="[ ChemFlow ] Checking input files... [ ERROR ] No DOCKING CENTER defined (--center x y z) For help, type: DockFlow -h"
assertOutputIsExpected
}





# Test the flow ---------------------------------------------------------------------------------------------
test_DockFlow_vina_produces_output_pdbqt(){
TEST="test_DockFlow_vina_produces_output_pdbqt"

# run vina
run_vina_continue_no_rewrite_ligand

# files that were supposed to be created
FILES="test.chemflow/DockFlow/vina1/receptor/CHEMBL195725/VINA/output.pdbqt test.chemflow/DockFlow/vina1/receptor/CHEMBL477992/VINA/output.pdbqt"
for FILE in ${FILES} ; do
    msg="The file ${FILE} has not been created."
    assertFileExits
done
}

test_PostDock_vina_produces_rank_docked_ligands(){
TEST="test_PostDock_results_from_vina"

# run postdock vina
postdock_vina_no_archive

FILES="test.chemflow/DockFlow/vina1/receptor/rank.csv test.chemflow/DockFlow/vina1/receptor/docked_ligands.mol2"
for FILE in ${FILES} ; do
    msg="The file ${FILE} has not been created."
    assertFileExits
done
}

#test_vina2(){
## Run DockFlow
#DockFlow --project test --protocol vina2 -r receptor.mol2 -l compounds.mol2 --radius 15 --center 20.259 -2.752 18.203 -sf vina <<EOF
#y
#y
#EOF
#}
#
#
#test_plants1(){
## Run DockFlow
#DockFlow --project test --protocol plants1 -r receptor.mol2 -l compounds.mol2 --radius 10 --center 20.259 -2.752 18.203 <<EOF
#y
#y
#EOF
#}
#
#
#test_plants2(){
## Run DockFlow
#DockFlow --project test --protocol plants2 -r receptor.mol2 -l compounds.mol2 --radius 15 --center 20.259 -2.752 18.203 <<EOF
#y
#y
#EOF
#}

initialize_test() {
echo "[ ChemFlow ] Initiating test"
cd ${CHEMFLOW_HOME}/test/
#ChemFlow_checkfile_ERROR protein_ligand.tar.gz

## Extracts test data to run "input" folder
#tar xfz protein_ligand.tar.gz

# Go to input data folder.
cd protein_ligand

## prepare input files
#python $(which SmilesTo3D.py ) -i compounds.smi -o compounds.sdf --hydrogen
#babel -isdf compounds.sdf -omol2 compounds.mol2
}


# Program ----------------------------------------------------------------------
initialize_test

# Tests on inputs
test_dockflow_plants_without_arg
test_dockflow_vina_without_arg

test_dockflow_plants_without_project
test_dockflow_vina_without_project

test_dockflow_plants_without_receptor_file
test_dockflow_vina_without_receptor_file

test_dockflow_plants_without_ligand_file
test_dockflow_vina_without_ligand_file

test_dockflow_vina_without_center
test_dockflow_plants_without_center

#test_DockFlow_vina_produces_output_pdbqt
#test_PostDock_vina_produces_rank_docked_ligands



echo "[ ChemFlow ] All tests passed. Yeah ! :D"