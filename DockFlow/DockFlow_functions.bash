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

# check if input is a directory
if [ -d "${lig_input}" ]; then
  lig_folder="${lig_input}"
else
  # Show a spinner while creating folders and configuration files, run it in the background
  (while :; do for s in / - \\ \|; do printf "\rPreparing docking files $s";sleep .2; done; done) &

  # convert file to a single mol2 per molecule, all in one directory
  filename=$(basename "${lig_input}")
  extension="${filename##*.}"
  lig_path=$(echo "${lig_input}" | sed "s/.${extension}//g")
  if   [ "${extension}" = "mol2" ]; then
    # split to 1 file per ligand
    $CHEMFLOW_HOME/Tools/splitmol2.bash ${lig_input} ${lig_path}
  elif [ "${extension}" = "sdf" ]; then
    # convert to mol2
    babel -isdf ${lig_input} -omol2 ${lig_path}_temp.mol2 >> prepare_ligands.job 2>&1
    # if no names are present, babel will use "*****" as ligand name
    # --> replace with "ligand_1" and so on if necessary
    awk 'BEGIN {count=1} {if ($0 == "*****") {sub(/\*\*\*\*\*/, "ligand_" count);count+=1}};{print}' ${lig_path}_temp.mol2 > ${lig_path}.mol2
    # split to 1 file per ligand
    $CHEMFLOW_HOME/Tools/splitmol2.bash ${lig_path}.mol2 ${lig_path}
    rm -f ${lig_path}_temp.mol2
  elif [ "${extension}" = "smi" ]; then
    # convert to sdf
    python $CHEMFLOW_HOME/Tools/SmilesTo3D.py -i ${lig_input} -o ${lig_path}.sdf -nt $(nproc) >> prepare_ligands.job
    # split to 1 file per ligand
    babel -isdf ${lig_path}.sdf -omol2 ${lig_path}.mol2 >> prepare_ligands.job 2>&1
    $CHEMFLOW_HOME/Tools/splitmol2.bash ${lig_path}.mol2 ${lig_path}
  else
    echo -e "\n${RED}ERROR${NC} : ${lig_input} is not a .smi .mol2 or .sdf file"
    { kill $! && wait $!; } 2>/dev/null
    exit 1
  fi
  lig_folder="${lig_path}"
fi

# list all mol2 files in the ligand folder.
lig_list=$(cd ${lig_folder} ; \ls -v *.mol2 | sed s/.mol2//g)

if [ -z "${lig_list}" ]
then
  echo -e "\n${RED}ERROR${NC} : Could not find mol2 files in ${lig_folder}"
  { kill $! && wait $!; } 2>/dev/null
  exit 1
fi

# Receptor
filename=$(basename "${rec}")
extension="${filename##*.}"
rec=$(echo "${rec}" | sed "s/.${extension}//g")

# Create an output folder per ligand.
for lig in ${lig_list} ; do
  mkdir -p ${output_folder}/${lig}

  # And write the config file there.
  cd ${output_folder}/${lig}
  if [ "${docking_program}" = "plants" ]; then
    write_plants_config
  elif [ "${docking_program}" = "vina" ]; then
    write_vina_config
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
elif [ "${run_mode}" = "PBS" ]; then
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
  touch ${output_folder}/.progress.dat
  (while :; do progress_count=$(cat ${output_folder}/.progress.dat | wc -c); ProgressBar ${progress_count} ${length}; sleep 1; done) &
  # Run parallel
  ${parallel} -j ${core_number} < ${output_folder}/VS_${datetime}.parallel \
  > ${output_folder}/parallel.job 2>&1
  # Kill the progress bar when parallel is done
  { printf '\rProgress : [########################################] 100%%\n'; kill $! && wait $!; } 2>/dev/null
  rm -f ${output_folder}/.progress.dat

# If running on PBS, wait untill all jobs are finished
elif [ "${run_mode}" = "PBS" ]; then
  mazinger_progress_bar ${output_folder}/jobs_list_${datetime}.PBS
elif [ "${run_mode}" = "local" ]; then
  echo -ne "\rProgress : [########################################] 100%%\n"
fi
}

#######################################################################
# PLANTS
#######################################################################

run_plants() {

# Create features.csv and ranking.csv headers
echo "LIGAND_ENTRY,TOTAL_SCORE,SCORE_RB_PEN,SCORE_NORM_HEVATOMS,SCORE_NORM_CRT_HEVATOMS,SCORE_NORM_WEIGHT,SCORE_NORM_CRT_WEIGHT,\
SCORE_RB_PEN_NORM_CRT_HEVATOMS,SCORE_NORM_CONTACT,EVAL,TIME">${output_folder}/ranking.csv
echo "LIGAND_ENTRY,TOTAL_SCORE,SCORE_RB_PEN,SCORE_NORM_HEVATOMS,SCORE_NORM_CRT_HEVATOMS,SCORE_NORM_WEIGHT,SCORE_NORM_CRT_WEIGHT,\
SCORE_RB_PEN_NORM_CRT_HEVATOMS,SCORE_NORM_CONTACT,PLPtotal,PLPparthbond,PLPpartsteric,PLPpartmetal,PLPpartrepulsive,PLPpartburpolar,\
LIG_NUM_CLASH,LIG_NUM_CONTACT,LIG_NUM_NO_CONTACT,CHEMpartmetal,CHEMparthbond,CHEMparthbondCHO,DON,ACC,UNUSED_DON,UNUSED_ACC,\
CHEMPLP_CLASH2,TRIPOS_TORS,ATOMS_OUTSIDE_BINDINGSITE">${output_folder}/features.csv

# Initialization procedure, common to all scoring functions
begin_run

# Iterate through each ligand file
for lig in ${lig_list} ; do
  cd ${output_folder}/${lig}

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
    echo -n "cd ${output_folder}/${lig}; \
    source ${CHEMFLOW_HOME}/DockFlow/DockFlow_functions.bash; " >> ${output_folder}/VS_${datetime}.parallel
    CFvars=$(print_vars | sed ':a;N;$!ba;s/\n/; /g'); echo -n "${CFvars}" >> ${output_folder}/VS_${datetime}.parallel
    echo "; plants_cmd; \
    echo -n 0 >>${output_folder}/.progress.dat" >> ${output_folder}/VS_${datetime}.parallel

  # If running on PBS
  elif [ "${run_mode}" = "PBS" ] ; then
    write_plants_pbs
    jobid=$(qsub ${run_folder}/pbs_scripts/plants_${lig}.pbs)
    echo "$jobid" >> ${output_folder}/jobs_list_${datetime}.PBS
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
search_speed speed${search_speed}
aco_ants ${ants}
aco_evap ${evap_rate}
aco_sigma ${iteration_scaling}

# input
protein_file ${rec}.mol2
ligand_file  ${lig_folder}/${lig}.mol2

# output
output_dir docking

# write mol2 files as a single (0) or multiple (1) files
write_multi_mol2 1

# binding site definition
bindingsite_center ${bs_center}
bindingsite_radius ${bs_radius}

# water molecule centered on a sphere of coord x y z and can move in radius r
${dock_water}
${dock_water2}

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
${load_plants_PBS}

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
  mkdir -p ${output_folder}/ranking
  mkdir -p ${output_folder}/features

  # Move the protein bindingsite residues file
  mv docking/protein_bindingsite_fixed.mol2 ${output_folder}/
  # the command tail -n +2 skip the first line (containing the header), and starts printing at the 2nd line of the file
  tail -n +2 docking/features.csv >> ${output_folder}/features/${lig}.csv
  tail -n +2 docking/ranking.csv  >> ${output_folder}/ranking/${lig}.csv

  # Move docking poses
  mv docking/*.mol2 .
  rm -rf docking
else
  echo "${lig},no ranking.csv" >> ${output_folder}/errors.csv
fi
}

#######################################################################
# VINA
#######################################################################

run_vina() {

# Headers for the concatenated score file
echo "LIGAND_ENTRY,AFFINITY,RMSD_lb,RMSD_ub" > ${output_folder}/ranking.csv

# Initialization procedure, common to all scoring functions
begin_run

if [ ! -f ${rec}.pdbqt ]; then
  cd $(dirname ${rec}.mol2)
  ${mgltools_folder}/bin/python ${mgltools_folder}/MGLToolsPckgs/AutoDockTools/Utilities24/prepare_receptor4.py -r ${rec}.mol2 > convert2pdbqt.job
fi

# Iterate through each ligand file
for lig in ${lig_list} ; do
  cd ${output_folder}/${lig}

  # If running locally
  if [ "${run_mode}" = "local" ]    ; then
    # Progress
    (ProgressBar ${progress_count} ${length}) &
    # Run
    vina_cmd
    # update progress bar
    let progress_count+=1
    # Kill the progress bar when plants is done
    { kill $! && wait $!; } 2>/dev/null

  # If running locally with parallel
  elif [ "${run_mode}" = "parallel" ] ; then
    echo -n "cd ${output_folder}/${lig}; \
    source ${CHEMFLOW_HOME}/DockFlow/DockFlow_functions.bash; " >> ${output_folder}/VS_${datetime}.parallel
    CFvars=$(print_vars | sed ':a;N;$!ba;s/\n/; /g'); echo -n "${CFvars}" >> ${output_folder}/VS_${datetime}.parallel
    echo "; vina_cmd; \
    echo -n 0 >>${output_folder}/.progress.dat" >> ${output_folder}/VS_${datetime}.parallel

  # If running on PBS
  elif [ "${run_mode}" = "PBS" ] ; then
    write_vina_pbs
    jobid=$(qsub ${run_folder}/pbs_scripts/vina_${lig}.pbs)
    echo "$jobid" >> ${output_folder}/jobs_list_${datetime}.PBS
    echo -ne "Running ${PURPLE}${lig}${NC} on ${BLUE}${jobid}${NC}              \r"
  fi
done

# End procedure, common to all scoring functions
end_run
}

vina_cmd() {
# Prepare ligand
${mgltools_folder}/bin/python ${mgltools_folder}/MGLToolsPckgs/AutoDockTools/Utilities24/prepare_ligand4.py -l ${lig_folder}/${lig}.mol2 >> convert2pdbqt.job
# Run
${vina_exec} --config config.vina --log output.log > vina.job 2>&1
# Reorganize files
reorganize_vina
}

# Write Plants Configuration file -----------------------------------
write_vina_config() {
echo "
# input
receptor = ${rec}.pdbqt
ligand   = ${output_folder}/${lig}/${lig}.pdbqt

# binding site definition
center_x = ${bs_center[0]}
center_y = ${bs_center[1]}
center_z = ${bs_center[2]}
size_x   = ${bs_size[0]}
size_y   = ${bs_size[1]}
size_z   = ${bs_size[2]}

# parameters
cpu = 1
exhaustiveness = ${exhaustiveness}
energy_range   = ${energy_range}
num_modes      = ${poses_number}
">config.vina
}

# Write PBS script --------------------------------------------------
write_vina_pbs() {
echo "#!/bin/bash
#PBS -N docking_${lig}
#PBS -l nodes=1:ppn=1,walltime=24:00:00.00
#PBS -o ${lig}.o
#PBS -e ${lig}.e

#-----user_section-----------------------------------------------
${load_vina_PBS}

cd \$PBS_O_WORKDIR

source ${CHEMFLOW_HOME}/DockFlow/DockFlow_functions.bash

"> ${run_folder}/pbs_scripts/vina_${lig}.pbs
print_vars >> ${run_folder}/pbs_scripts/vina_${lig}.pbs
echo "
vina_cmd" >> ${run_folder}/pbs_scripts/vina_${lig}.pbs
}

reorganize_vina() {
# First output the results as a csv table, inside the ligand/pose/complex folder
# Then concatenate this csv table in the master ranking file.
# Remark : Don't output directly in the ranking file, because we first need to print all the values on one line
# without returning to a new line. Using parallel or PBS, this will result in overwriting results of
# different poses on the same line.
if [ -f output.log ]; then
  mkdir -p ${output_folder}/ranking
  awk -v lig=${lig} '/-----/{f=1;next};/Writing output ... done./{f=0}f{print lig"_"$1","$2","$3","$4}' output.log >> ${output_folder}/ranking/${lig}.csv

else
  echo "${lig},no ranking.csv" >> ${output_folder}/errors.csv
fi
}

#########################
# Other docking software
#########################

# insert the programs name :
# * in the list_ligands function here
# * in DockFlow under the "Run docking" comment
# * in DockFlow_interface under the "Scoring function" comment in check_input function
# then copy and paste what was done for plants, and modify accordingly.
# Don't forget to add the scoring function :
# * in usage function in DockFlow_interface
