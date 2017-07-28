#!/bin/bash

#######################################################################
##################### Script for pose extraction ######################
#######################################################################
# Finds defined docking poses for defined ligands in the VS folder from DockFlow
# Compatible with PLANTS

#######################################################################
# Functions
#######################################################################

usage() {
echo -e "
Usage : $0 cutoff pose path
        ${RED}cutoff${NC} : Only the poses with a score below this cutoff will be extracted
        ${RED}pose${NC}   : Restrict extraction to the X best poses per ligand
        ${RED}path${NC}   : Set path to the work directory, containing the lig,rec, and output directories
"
}

# Color output
RED="\e[0;31m"
BLUE="\e[0;34m"
GREEN="\e[0;32m"
PURPLE="\e[0;35m"
NC="\033[0m"

extract() {
# List ligands
lig_list=$(cd ${path}/output/VS; ls -l | grep "^d" | awk '{print $9}')
# List ranking.csv files
ranking_list=$(cd $path/output/VS/; ls */docking/ranking.csv)

mkdir -p ${path}/output/lig_selection
rm -rf ${path}/output/lig_selection/VS_scores.csv

# Make a list of docking poses with the associated energy
for file in ${ranking_list}
do
  lig=$(echo $file | cut -d"/" -f1)
  echo -ne "Sorting ${PURPLE}$lig${NC}           \r"
  # If the user didn't specify, any number of poses, take all of them
  if [ -z "$pose" ]; then
    awk -F, -v cutoff=$cutoff -v lig=$lig '{if ($2<=cutoff) {print $1","lig","$2}}' $path/output/VS/$file >> ${path}/output/lig_selection/VS_scores.csv
  # Else, take only the best X ones
  else
    awk -F, -v cutoff=$cutoff -v lig=$lig '{if ($2<=cutoff) {print $1","lig","$2}}' $path/output/VS/$file > ${path}/output/lig_selection/temporary_scores.csv
    # list available ligands
    ligand_list=$(grep "_conf_01" $path/output/VS/$file | cut -d"," -f1 | sed s/_conf_01//g)
    for ligand in $ligand_list; do
      grep "$ligand" ${path}/output/lig_selection/temporary_scores.csv | head -${pose} >> ${path}/output/lig_selection/VS_scores.csv
    done
  fi
done
echo -e "${GREEN}Sorted selection of ligands successfully${NC}"
rm -rf ${path}/output/lig_selection/temporary_scores.csv
sort -o ${path}/output/lig_selection/VS_scores_sorted.csv -nk3 ${path}/output/lig_selection/VS_scores.csv -t","

# For the listed ligands, copy the docking poses to a separate folder
nb_poses=0
while IFS='' read -r line || [[ -n "$line" ]]; do
  ligand=$(echo $line | cut -d, -f2)
  pose=$(echo $line | cut -d, -f1)
  
  binding_mode=""
  search=$(ls $path/output/VS/${ligand}/docking/${pose}.mol2 2>/dev/null)
  if [ ! -z "${search}" ]; then
    binding_mode=${search}
    echo -ne "Copying ${PURPLE}${pose}${NC}                  \r"
    mkdir -p ${path}/output/lig_selection/$ligand/docking
    cp ${binding_mode} ${path}/output/lig_selection/$ligand/docking/${pose}.mol2
    nb_poses=$(expr $nb_poses + 1)
  else
    echo -e "\nERROR : could not find ${RED}${pose}${NC}"
  fi
done < ${path}/output/lig_selection/VS_scores_sorted.csv
echo -e "Extracted ${PURPLE}${nb_poses}${NC} docking poses.                                                                       
Thank you for using ChemFlow Tools"
}

#################
# Main
#################

if [ "$#" -eq 3 ]; then
  path="$3"
  pose="$2"
  cutoff=$1
  extract
else
  usage
  exit 1
fi
