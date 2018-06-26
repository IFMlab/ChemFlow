#!/bin/bash
##################################################################### 
#   ChemFlow  -   Making Computational Chemistry is great again     #
#####################################################################
#
# Diego E. B. Gomes(1,2,3) - dgomes@pq.cnpq.br
# Cedric Boysset (3) - cboysset@unistra.fr
# Marco Cecchini (3) - cecchini@unistra.fr
#
# 1 - Instituto Nacional de Metrologia, Qualidade e Tecnologia - Brazil
# 2 - Coordenacao Aperfeicoamento de Pessoal de Ensino Superior - CAPES - Brazil.
# 3 - Universite de Strasbourg - France
#
#===============================================================================
#
#          FILE:  DockFlowVS.bash
#
#         USAGE:  ./DockFlowVS.bash
#
#   DESCRIPTION: Run Virtual Screening using the SLURM scheduller.
#
#       OPTIONS:  ---
#  REQUIREMENTS:  VINA, SLURM
#          BUGS:  ---
#         NOTES:  ---
#        AUTHOR:  Diego E. B. Gomes, dgomes@pq.cnpq.br
#       COMPANY:  Universite de Strasbourg / CAPES
#       VERSION:  1.0
#       CREATED:  Mon Nov 17 14:41:38 CEST 2017
#      REVISION:  ---
#===============================================================================


# User configuration ################################################

# Input files
receptor="receptor.pdbqt"
ligand_folder="../all_leads/"

# Number of ligands per PBS job
nlig=5000

# Technical details #################################################

# Autodock Vina Executable
vina_exec=$HOME/software/autodock_vina_1_1_2_linux_x86/bin/vina


#####################################################################
# Do not change anything unless you know what you're doing          #
#####################################################################


welcome() {
echo "\
##################################################### 
# ChemFlow - Computational Chemistry is great again #
#####################################################
"
}

write_slurm() {
#===  FUNCTION  ================================================================
#          NAME: write_slurm
#   DESCRIPTION: Writes the SLURM script to for each ligand.
#                so far it is very specific for Myosin. 
#                Filenames and parameters are hardcoded.
#    PARAMETERS: $ligand_folder;  $LIGAND ; GB5.in 
#       RETURNS: -
#===============================================================================
echo "#! /bin/bash
# 1 noeud 8 coeurs
#SBATCH -p public
#SBATCH --job-name=pose3_${first}
#SBATCH -N 1
#SBATCH -n 16
#SBATCH -t 6:00:00

cd \$SLURM_SUBMIT_DIR

if [ -f ${first}.parallel ] ; then rm -rf ${first}.parallel ; fi
for i in ${list[@]:$first:$nlig} ; do
  echo \"${vina_exec} --cpu 1 --ligand ${ligand_folder}/\${i}.pdbqt --receptor receptor.pdbqt --config config.txt --out results/\${i}.pdbqt --log results/\${i}.log >results/\${i}.out\" >> ${first}.parallel
done

cat ${first}.parallel | xargs -P16 -I '{}' bash -c '{}'
"> vina.slurm
}

# The actual program ################################################

# Create vina output folder
mkdir -p results 

# Count the number of ligands.
list=$(cd ${ligand_folder} ; ls *.pdbqt | cut -d. -f1 )
list=($list)
list_max=${#list[@]}

echo "There are $list_max ligands to dock"
read -p "How many do you want per PBS job? : " nlig


for (( first=0;$first<$list_max; first=$first+$nlig )) ; do
  echo -ne "Docking $first         \r"
  jobname="${first}"
  write_slurm
  sbatch vina.slurm
done

echo -ne "\n"


