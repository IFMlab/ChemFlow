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
#          FILE:  DockFlow_mini_PLANTS.bash
#
#         USAGE:  ./DockFlow_mini_PLANTS.bash
#
#   DESCRIPTION: Run Virtual Screening using the SLURM schedulle
#                and PLANTS as docking engine.
#
#       OPTIONS:  ---
#  REQUIREMENTS:  PLANTS, SLURM
#          BUGS:  ---
#         NOTES:  ---
#        AUTHOR:  Diego E. B. Gomes, dgomes@pq.cnpq.br
#       COMPANY:  Universite de Strasbourg / CAPES
#       VERSION:  1.0
#       CREATED:  Tue Jan 23 18:25:02 CET 2018 
#      REVISION:  ---
#===============================================================================


# User configuration ################################################

# Input files
receptor="receptor.mol2"
ligand_folder="lig_mol2_babel"

# Output folder
output_folder="DockFlow"

# Number of ligands per PBS job
nlig=500

# Technical details #################################################

# PLANTS Executable
plants_exec=$HOME/software/plants/PLANTS1.2_64bit


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

write_plants() {
echo "
# scoring function and search settings
scoring_function chemplp
search_speed speed1

# input
protein_file ${receptor}
ligand_file  ${ligand_folder}/${lig}.mol2

# output
output_dir ${output_folder}/${lig}/

# write mol2 files as a single (0) or multiple (1) files
write_multi_mol2 0

# binding site definition
bindingsite_center 5.40 0.35 -6.50
bindingsite_radius 15

# cluster algorithm
cluster_structures 10
cluster_rmsd 2.0

# write 
write_ranking_links 0
write_protein_bindingsite 0
write_protein_conformations 0
####
" > /scratch/job.${SLURM_JOB_ID}/${lig}.plants
}

write_slurm() {
#===  FUNCTION  ================================================================
#          NAME: write_slurm
#   DESCRIPTION: Writes the SLURM script to for each ligand.
#                so far it is very specific for Myosin. 
#                Filenames and parameters are hardcoded.
#    PARAMETERS: $ligand_folder;  $LIGAND ;  
#       RETURNS: -
#===============================================================================
echo "#! /bin/bash
# 1 noeud 8 coeurs
#SBATCH -p publicgpu
##SBATCH -p pri2013-short
##SBATCH -A qosisisifm
##SBATCH --sockets-per-node=2
##SBATCH --cores-per-socket=8
#SBATCH --job-name=PLANTS_${first}
#SBATCH -N 1
#SBATCH -n 24
#SBATCH -t 0:30:00

cd \$SLURM_SUBMIT_DIR

# Input files
receptor=${receptor}
ligand_folder=${ligand_folder}

# Output folder
output_folder=${output_folder}

#Write plants function
$(declare -f write_plants)

if [ -f ${first}.parallel ] ; then rm -rf ${first}.parallel ; fi
for lig in ${list[@]:$first:$nlig} ; do
  write_plants
  echo \"${plants_exec} --mode screen /scratch/job.\${SLURM_JOB_ID}/\${lig}.plants >/dev/null\" >> ${first}.parallel
done

cat ${first}.parallel | xargs -P16 -I '{}' bash -c '{}'
"> plants.slurm
}

# The actual program ################################################

# Create plants output folder
mkdir -p ${output_folder}

# Count the number of ligands.
list=$(cd ${ligand_folder} ; ls *.mol2 | cut -d. -f1 )
list=($list)
list_max=${#list[@]}

echo "There are $list_max ligands to dock"
read -p "How many do you want per PBS job? : " nlig


for (( first=0;$first<$list_max; first=$first+$nlig )) ; do
  echo -ne "Docking $first         \r"
  jobname="${first}"
  write_slurm
  sbatch plants.slurm
done

echo -ne "\n"


