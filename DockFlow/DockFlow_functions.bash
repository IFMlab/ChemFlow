###############################################
# Functions common to all scoring functions
###############################################

# Execute plants
prepare_docking() {

# Check if everything is ok with the input.
check_input

# List ligands, create folder
# and write plants config in each folder
list_ligands
}

# List ligands
list_ligands() {

# list all mol2 files in the ligand folder.
lig_list=$(cd ${lig_folder} ; \ls -v *.mol2 | sed s/.mol2//g)

if [ -z "${lig_list}" ]
then
  echo -e "${RED}ERROR${NC} : Could not find mol2 files in ${lig_folder}"
  exit 1
fi

# Show a spinner while creating folders and configuration files, run it in the background
(while :; do for s in / - \\ \|; do printf "\rPreparing parallel $s";sleep .2; done; done) &

# Create an output folder per ligand.
for lig in ${lig_list} ; do
  mkdir -p ${run_folder}/docking/${lig}

  # And write the config file there.
  cd ${run_folder}/docking/${lig}
  if [ "${docking_program}" = "plants" ]; then
    write_plants_config
  # insert other docking programs here
  fi
done

echo -e "\rFinished preparing files... Running"
# Kill the spinner
{ kill $! && wait $!; } 2>/dev/null

}


begin_run() {
# function containing the basic commands that are common at the begining of the run_* functions

# Progress Bar
length=$(echo ${lig_list} | wc -w)
progress_count=0

# Print a spinner on the screen while preparing the commands for parallel
if [ "${run_mode}" = "parallel" ]; then
  # Run a spinner in the background
  (while :; do for s in / - \\ \|; do printf "\rPreparing parallel $s";sleep .2; done; done) &
elif [ "${run_mode}" = "mazinger" ]; then
  # create pbs_script folder
  mkdir -p ${run_folder}/pbs_scripts/
fi
}

end_run() {
# function containing the basic commands that are common at the end of the run_* functions

# Kill the spinner when the preparation of parallel is done, and run it !
if [ "${run_mode}" = "parallel" ]; then
  echo -e "\rFinished preparing parallel... Running"
  { kill $! && wait $!; } 2>/dev/null
  # Run the progress bar
  touch ${run_folder}/docking/.progress.dat
  (while :; do progress_count=$(cat ${run_folder}/docking/.progress.dat | wc -c); ProgressBar ${progress_count} ${length}; sleep 1; done) &
  # Run parallel
  ${parallel} -j ${core_number} < ${run_folder}/docking/VS_${datetime}.parallel \
  > ${run_folder}/docking/parallel.job 2>&1
  # Kill the progress bar when parallel is done
  { printf '\rProgress : [########################################] 100%\n'; kill $! && wait $!; } 2>/dev/null
  rm -f ${run_folder}/docking/.progress.dat

# If running on mazinger, wait untill all jobs are finished
elif [ "${run_mode}" = "mazinger" ]; then
  mazinger_progress_bar ${run_folder}/docking/jobs_list_${datetime}.mazinger
elif [ "${run_mode}" = "local" ]; then
  echo -ne "\rProgress : [########################################] 100%\n"
fi
}

#######################################################################
# PLANTS
#######################################################################

run_plants() {

# Create features.csv and ranking.csv headers
echo "LIGAND_ENTRY,TOTAL_SCORE,SCORE_RB_PEN,SCORE_NORM_HEVATOMS,SCORE_NORM_CRT_HEVATOMS,SCORE_NORM_WEIGHT,SCORE_NORM_CRT_WEIGHT,\
SCORE_RB_PEN_NORM_CRT_HEVATOMS,SCORE_NORM_CONTACT,EVAL,TIME">${run_folder}/docking/ranking.csv
echo "LIGAND_ENTRY,TOTAL_SCORE,SCORE_RB_PEN,SCORE_NORM_HEVATOMS,SCORE_NORM_CRT_HEVATOMS,SCORE_NORM_WEIGHT,SCORE_NORM_CRT_WEIGHT,\
SCORE_RB_PEN_NORM_CRT_HEVATOMS,SCORE_NORM_CONTACT,PLPtotal,PLPparthbond,PLPpartsteric,PLPpartmetal,PLPpartrepulsive,PLPpartburpolar,\
LIG_NUM_CLASH,LIG_NUM_CONTACT,LIG_NUM_NO_CONTACT,CHEMpartmetal,CHEMparthbond,CHEMparthbondCHO,DON,ACC,UNUSED_DON,UNUSED_ACC,\
CHEMPLP_CLASH2,TRIPOS_TORS,ATOMS_OUTSIDE_BINDINGSITE">${run_folder}/docking/features.csv

# Initialization procedure, common to all scoring functions
begin_run

# Iterate through each ligand file
for lig in ${lig_list} ; do
  cd ${run_folder}/docking/${lig}
  
  # If running locally
  if [ "${run_mode}" = "local" ]    ; then
    # Progress
    (ProgressBar ${progress_count} ${length}) &
    # Run
    plants_cmd
    # update progress bar
    let progress_count+=1
    # Kill the progress bar when plants is done
    { kill $! && wait $!; } 2>/dev/null

  # If running locally with parallel
  elif [ "${run_mode}" = "parallel" ] ; then
    echo -n "cd ${run_folder}/docking/${lig}; \
    source ${CHEMFLOW_HOME}/DockFlow/DockFlow_functions.bash; " >> ${run_folder}/docking/VS_${datetime}.parallel
    CFvars=$(print_vars | sed ':a;N;$!ba;s/\n/; /g'); echo -n "${CFvars}" >> ${run_folder}/docking/VS_${datetime}.parallel
    echo "; plants_cmd; \
    echo -n 0 >>${run_folder}/docking/.progress.dat" >> ${run_folder}/docking/VS_${datetime}.parallel
  
  # If running on mazinger
  elif [ "${run_mode}" = "mazinger" ] ; then 
    write_pbs
    jobid=$(qsub ${run_folder}/pbs_scripts/plants_${lig}.pbs)
    echo "$jobid" >> ${run_folder}/docking/jobs_list_${datetime}.mazinger
    echo -ne "Running ${PURPLE}${lig}${NC} on ${BLUE}${jobid}${NC}              \r"
  fi
done

# End procedure, common to all scoring functions
end_run
}

plants_cmd() {
# Run
${plants_exec} --mode screen config.plants > plants.job 2>&1
# Reorganize files
reorganize_plants
}

# Write Plants Configuration file -----------------------------------
write_plants_config() {
echo "
# scoring function and search settings
scoring_function ${scoring_function}
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

# Other user-defined parameters
${PLANTS_user_parameters}

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
write_plants_pbs() {
echo "#!/bin/bash
#PBS -N docking_${lig}
#PBS -l nodes=1:ppn=1,walltime=24:00:00.00
#PBS -o ${lig}.o
#PBS -e ${lig}.e

#-----user_section-----------------------------------------------
module load plants/1.2

cd \$PBS_O_WORKDIR

source ${CHEMFLOW_HOME}/DockFlow/DockFlow_functions.bash

"> ${run_folder}/pbs_scripts/plants_${lig}.pbs
print_vars >> ${run_folder}/pbs_scripts/plants_${lig}.pbs
echo "
plants_cmd" >> ${run_folder}/pbs_scripts/plants_${lig}.pbs
}


reorganize_plants() {
# Append the scores to a unique csv file, and reorganize files
if [ -f docking/ranking.csv ]; then
  # create folders for concatenating the results
  mkdir -p ${run_folder}/docking/ranking
  mkdir -p ${run_folder}/docking/features

  # Move the protein bindingsite residues file
  mv docking/protein_bindingsite_fixed.mol2 ${run_folder}/docking/
  # the command tail -n +2 skip the first line (containing the header), and starts printing at the 2nd line of the file
  tail -n +2 docking/features.csv >> ${run_folder}/docking/features/${lig}.csv
  tail -n +2 docking/ranking.csv  >> ${run_folder}/docking/ranking/${lig}.csv
  
  # Move docking poses
  mv docking/*.mol2 .
  rm -rf docking
else
  echo "${lig},no ranking.csv" >> ${run_folder}/docking/errors.csv
fi
}

#########################
# Other docking software
#########################

# insert the programs name :
# * in the list_docking function here
# * in DockFlow under the "Run docking" comment
# * in DockFlow_interface under the "Scoring function" comment in check_input function
# then copy and paste what was done for plants, and modify accordingly.
# Don't forget to add the scoring function :
# * in usage function in DockFlow_interface
# * in ConfigFlow