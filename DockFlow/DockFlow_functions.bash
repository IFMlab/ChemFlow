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

  # And write the plants config file there.
  cd ${run_folder}/docking/${lig}
  write_plants_config
done

echo -e "\rFinished preparing files... Running"
# Kill the spinner
{ kill $! && wait $!; } 2>/dev/null

}

# Equivalent to python : if item in list
list_include_item() {
  local list="$1"
  local item="$2"
  if [[ $list =~ (^|[[:space:]])"$item"($|[[:space:]]) ]] ; then
    # yes, list include item
    result=0
  else
    result=1
  fi
  return $result
}

print_vars() {
# Print all variables defined from the console
# declare -p will print all system variables
# awk '/declare --/ {print $3}' will extract all users variables names and values as well as some other undesired variables
# awk 'f;/^_.*$/{f=1}' will start printing the variables after it reads a variable starting with _
# grep -v "^_" will remove all remaining variables starting with _
# grep -v "_list" will remove every list of variables
# in the end we should only be left with variables defined within the workflow which we could need
declare -p | awk '/declare --/ {print $3}' | awk 'f;/^_.*$/{f=1}' | grep -Fv -e "^_" -e "_list" -e "bs_center"
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

# Progress Bar
length=$(echo ${lig_list} | wc -w)
progress_count=0

# Print a spinner on the screen while preparing the commands for parallel
if [ "${run_mode}" = "parallel" ]; then
  # Run a spinner in the background
  (while :; do for s in / - \\ \|; do printf "\rPreparing parallel $s";sleep .2; done; done) &
fi

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
    source ${CHEMFLOW_HOME}/ChemFlow.config; \
    source ${CHEMFLOW_HOME}/DockFlow/DockFlow_functions.bash; " >> ${run_folder}/docking/VS_${datetime}.parallel
    CFvars=$(print_vars | sed ':a;N;$!ba;s/\n/; /g'); echo -n "${CFvars}" >> ${run_folder}/docking/VS_${datetime}.parallel
    echo "; plants_cmd; \
    echo -n 0 >>${run_folder}/docking/.progress.dat" >> ${run_folder}/docking/VS_${datetime}.parallel
  
  # If running on mazinger
  elif [ "${run_mode}" = "mazinger" ] ; then 
    write_pbs
    jobid=$(qsub plants.pbs )
    echo "$jobid" >> ${run_folder}/docking/jobs_list_${datetime}.mazinger
    echo -ne "Running ${PURPLE}${lig}${NC} on ${BLUE}${jobid}${NC}              \r"
  fi
done

# Kill the spinner when the preparation of parallel is done, and run it !
if [ "${run_mode}" = "parallel" ]; then
  echo -e "\rFinished preparing parallel... Running"
  { kill $! && wait $!; } 2>/dev/null
  # Run the progress bar
  touch ${run_folder}/docking/.progress.dat
  (while :; do progress_count=$(cat ${run_folder}/docking/.progress.dat | wc -c); ProgressBar ${progress_count} ${length}; sleep 1; done) &
  # Run parallel
  ${parallel} -j ${core_number} < ${run_folder}/docking/VS_${datetime}.parallel > ${run_folder}/docking/parallel.job 2>&1
  # Kill the progress bar when parallel is done
  { printf '\n'; kill $! && wait $!; } 2>/dev/null
  rm -f ${run_folder}/docking/.progress.dat
  
# If running on mazinger, wait untill all jobs are finished
elif [ ${run_mode} = "mazinger" ]; then 
  mazinger_progress_bar ${run_folder}/docking/jobs_list_${datetime}.mazinger
fi
}

plants_cmd() {
# Run
${PLANTS} --mode screen config.plants > plants.job
# Reorganize files
reorganize_plants
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

# Other user-defined parameters
${plants_user_parameters}

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

source ${CHEMFLOW_HOME}/ChemFlow.config
source ${CHEMFLOW_HOME}/ScoreFlow/ScoreFlow_functions.bash

"> plants.pbs
print_vars >> plants.pbs
echo "
plants_cmd" >> plants.pbs
}


# Create a csv table with all energies--------------------------------
plants_score_csv() {
# List ranking.csv files
ranking_list=$(cd ${run_folder}/docking/; ls */docking/ranking.csv)

# Make a list of docking poses with the associated energy
echo "#POSE,FILE,PLANTS_SCORE" > ${run_folder}/docking/VS_scores.csv
for file in ${ranking_list}
do
  lig=$(echo $file | cut -d"/" -f1)
  echo -ne "Processing ${PURPLE}$lig${NC} to gather docking scores          \r"
  awk -F, -v lig=$lig '{print $1","lig","$2}' ${run_folder}/docking/$file >> ${run_folder}/docking/VS_scores.csv
done
echo ""
sort -o ${run_folder}/docking/VS_scores_sorted.csv -nk3 ${run_folder}/docking/VS_scores.csv -t","
echo -e "${GREEN}Sorted docking results successfully${NC}"
}

reorganize_plants() {
if [ -f docking/ranking.csv ]; then
  cd docking
  mv protein_bindingsite_fixed.mol2 ${run_folder}/docking/
  # the command tail -n +2 skip the first line (containing the header), and starts printing at the 2nd line of the file
  tail -n +2 features.csv >> ${run_folder}/docking/features.csv
  tail -n +2 ranking.csv  >> ${run_folder}/docking/ranking.csv
  cd ..
  mv docking/*.mol2 .
  rm -rf docking
else
  echo "${lig},no ranking.csv" >> ${run_folder}/docking/errors.csv
fi
}