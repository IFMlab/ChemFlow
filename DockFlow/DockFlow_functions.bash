# Execute plants
prepare_plants() {

# Instead of absolute path,
# set "dir" to run folder.
dir=$PWD

# Create a time stamp, in order to backup PLANTS output if it already exists
datetime=$(date "+%Y%m%d%H%M%S")

# Check if everything is ok with the input.
check_input

# List ligands, create folder
# and write plants config in each folder
list_ligands

}


run_plants() {
for lig in ${lig_list} ; do
  cd ${dir}/output/VS/${lig}
  
  if [ "${run_mode}" = "local" ]    ; then
    ${PLANTS} --mode screen config.plants > plants.job
    echo -ne "Running ${PURPLE}${lig}${NC}             \r"
  fi

  if [ "${run_mode}" = "mazinger" ] ; then 
    write_pbs
    jobid=$(qsub plants.pbs )
    echo "$jobid" >> jobs_list_${datetime}.mazinger
    echo -ne "Running ${PURPLE}${lig}${NC} on ${BLUE}${jobid}${NC}              \r"
  fi
  
  if [ "${run_mode}" = "parallel" ] ; then
    echo "cd ${dir}/output/VS/${lig} ; ${PLANTS} --mode screen config.plants > plants.job" >>${dir}/output/VS/VS_${datetime}.parallel
    echo -ne "Running ${PURPLE}${lig}${NC}             \r"
  fi
done
echo ""

if [ "${run_mode}" = "parallel" ] ; then
  echo "Running parallel"
  ${parallel} -j ${core_number} < ${dir}/output/VS/VS_${datetime}.parallel > ${dir}/output/VS/parallel.job 2>&1
fi
}




# List ligands ------------------------------------------------------
list_ligands() {

# list all mol2 files in the ligand folder.
list=$(cd ${lig_folder} ; ls -v -1 *.mol2)
lig_list=$(echo $list | sed s/.mol2//g )

if [ -z "$list" ]
then
  echo -e "${RED}ERROR${NC} : Could not find mol2 files in ${lig_folder}"
  exit 1
fi

# Create an output folder per ligand.
for lig in $lig_list ; do
  echo -ne "Creating ${PURPLE}${lig}${NC}        \r"
  mkdir -p ${dir}/output/VS/${lig}

# And write the plants config file there.
  cd ${dir}/output/VS/${lig}
  write_plants_config
done
echo "Finished writing configuration files.                                          "

# echo ${lig_list[@]}

}



# Write Plants Configuration file -----------------------------------
write_plants_config() {
echo "
# scoring function and search settings
scoring_function chemplp
search_speed speed1

# input
protein_file ${rec}
ligand_file  ${lig_folder}/${lig}.mol2

# output
output_dir docking

# write mol2 files as a single (0) or multiple (1) files
write_multi_mol2 0

# binding site definition
bindingsite_center ${bs_center}
bindingsite_radius ${bs_radius}

# water molecule centered on a sphere of coord x y z and can move in radius r
${dock_water}

# cluster algorithm
cluster_structures ${poses_number}
cluster_rmsd 2.0

# write 
write_ranking_links 0
write_protein_bindingsite 1
write_protein_conformations 0
####
">config.plants
}


# Write PBS script --------------------------------------------------
write_pbs() {
echo "#!/bin/bash
#PBS -N VS_${lig}
#PBS -l nodes=1:ppn=1,walltime=24:00:00.00
#PBS -o ${lig}.o
#PBS -e ${lig}.e

#-----user_section-----------------------------------------------
module load plants/1.2

cd \$PBS_O_WORKDIR

#----Runing the VS---------
plants --mode screen config.plants
"> plants.pbs
}


# Create a csv table with all energies--------------------------------
plants_score_csv() {
# List ranking.csv files
ranking_list=$(cd $dir/output/VS/; ls */docking/ranking.csv)

# Make a list of docking poses with the associated energy
echo "#POSE,FILE,PLANTS_SCORE" > ${dir}/output/VS/VS_scores.csv
for file in ${ranking_list}
do
  lig=$(echo $file | cut -d"/" -f1)
  echo -ne "Processing ${PURPLE}$lig${NC} to gather docking scores          \r"
  awk -F, -v lig=$lig '{print $1","lig","$2}' $dir/output/VS/$file >> ${dir}/output/VS/VS_scores.csv
done
echo ""
sort -o ${dir}/output/VS/VS_scores_sorted.csv -nk3 ${dir}/output/VS/VS_scores.csv -t","
echo -e "${GREEN}Sorted docking results successfully${NC}"
}
