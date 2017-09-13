#!/bin/bash
# 
# ChemFlow - Prepare Vina Docking and virtual screening.
#
# Diego E. B. Gomes(1,2,3) - dgomes@pq.cnpq.br
# 1 - Instituto Nacional de Metrologia, Qualidade e Tecnologia - Brazil
# 2 - Universite de Strasbourg - France
# 3 - Coordenacao Aperfeicoamento de Pessoal de Ensino Superior - CAPES - Brazil.
#
# 

# User configuration ################################################

# Input files
receptor="3jaf-a.pdb"
ligand_folder="lig_split"


# Technical details #################################################

# Autodock Vina Executable
vina_exec=/home/dgomes/software/autodock_vina_1_1_2_linux_x86/bin//vina

# Path to MGLTools' Utilities 24
export PATH=${PATH}:/home/dgomes/MGLTools-1.5.6/MGLToolsPckgs/AutoDockTools/Utilities24/

# Alias to pythosh
alias pythonsh='/home/dgomes/MGLTools-1.5.6/bin/pythonsh'







######################################################################
# Do no change anything bellow unless you know what you're doing.    #
######################################################################

welcome() {
echo "
ChemFlow 2017 - Autodock Vina Docking Module
#
# Author(s)
# Diego E. B. Gomes(1,2,3) - dgomes@pq.cnpq.br
# 1 - Instituto Nacional de Metrologia, Qualidade e Tecnologia - Brazil 
# 2 - Universite de Strasbourg - France
# 3 - Coordenacao Aperfeicoamento de Pessoal de Ensino Superior - CAPES - Brazil.
#
"
}


checklist() {
# Check either required programs and paths can be found
echo "Checklist"
}


prepare_receptor() {
echo "Preparing ${receptor} as RECEPTOR"
echo "# ChemFlow 2017 - Autodock Vina Prepare module.

Running 
prepare_receptor4.py -r ${receptor} -o receptor.pdbqt" > DockFlow_prepare_vina.job
prepare_receptor4.py -r ${receptor} -o receptor.pdbqt &>> DockFlow_prepare_vina.job
echo ""
}


list_ligands() {
 lig_list=$(ls -v ${ligand_folder} )
}


prepare_ligand() {
# Create output folder
mkdir lig_vina/

for i in $lig_list ; do

  lig=$(basename -s .mol2 $i)
 
  echo -ne "Preparing $lig    \r"
  echo "
  prepare_ligand4.py -l lig_split/${lig}.mol2 -o lig_vina/${lig}.pdbqt" >> DockFlow_prepare_vina.job

  prepare_ligand4.py -l lig_split/${lig}.mol2 -o lig_vina/${lig}.pdbqt &>> DockFlow_prepare_vina.job

done
echo ""

}

error() {
# error codes
echo "error"
}



# The actual program ################################################
welcome
checklist
prepare_receptor
list_ligands
prepare_ligand


