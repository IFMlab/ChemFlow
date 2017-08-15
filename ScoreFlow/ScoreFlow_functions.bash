#!/bin/bash


prepare_rescoring() {
# Check the ScoreFlow config file, make folders and write config files for rescoring

# Check if everything is ok with the input.
check_input

# Depending on what the user wants to do (ALL, BEST or PDB rescoring), take actions

# PDB rescoring mode
if [ "${mode}" = "PDB" ]; then
  # List complexes, create folder
  # and write plants config in each folder
  list_complexes
elif $(list_include_item "ALL BEST" "${mode}"); then
  list_docking
fi
}


list_complexes() {
# List complexes, make folders and write the config files
# list all pdb files in the complex folder.
com_list=$(cd ${pdb_folder} ; ls *.pdb | sed s/.pdb//g )

if [ -z "${com_list}" ]; then
  echo -e "${RED}ERROR${NC} : Could not find pdb files in ${pdb_folder}"
  exit 1
fi

# Create an output folder per complex.
for com in ${com_list} ; do
  mkdir -p ${run_folder}/rescoring/${scoring_function}/${com}

  # And write the plants config file there.
  cd ${run_folder}/rescoring/${scoring_function}/${com}

  # Separate the complex in protein, ligand(s) and water mol2 files
  cd ${pdb_folder} # otherwise spores will add the path to the ligand name inside the file, which causes some bugs with PLANTS
  ${spores_exec} --mode splitpdb ${com}.pdb > ${run_folder}/rescoring/${scoring_function}/${com}/spores.job 2>&1
 
  # Output is ${pdb_folder}, so we need to move it
  mv ${pdb_folder}/*.mol2 ${run_folder}/rescoring/${scoring_function}/${com}/
  
  # path to ligand and receptor
  lig=$(ls ${run_folder}/rescoring/${scoring_function}/${com}/ligand*.mol2 | sed s/.mol2//g)
  rec=$(ls ${run_folder}/rescoring/${scoring_function}/${com}/protein.mol2 | sed s/.mol2//g)
  if [ "${rescore_method}" = "mmpbsa" ]; then
    babel -imol2 ${rec}.mol2 -opdb babel_${rec}.pdb
    pdb4amber -i babel_${rec}.pdb -o ${rec}.pdb
    if [ ! -z "$(cat *_nonprot.pdb)" ]; then
       illegal_residues=$(awk '{print $4}' *_nonprot.pdb | uniq | sed ':a;N;$!ba;s/\n/ /g')
      echo -e "${RED}ERROR${NC} : Non-standard residue detected in your complex pdb file : ${illegal_residues}"
      echo "Exiting"
      exit 1
    fi
  fi

  # write the config file
  cd ${run_folder}/rescoring/${scoring_function}/${com}
  echo -ne "Configuring ${PURPLE}${com}${NC}    \r"
  if [ "${rescore_method}" = "plants" ]; then
    sphere_list=$(python ${CHEMFLOW_HOME}/common/bounding_sphere.py ${lig}.mol2)
    bs_center=$(echo "${sphere_list}" | cut -d";" -f1)
    bs_radius=$(echo "${sphere_list}" | cut -d";" -f2)
    write_plants_config
  elif [ "${rescore_method}" = "vina" ]; then
    write_vina_config
  fi
done

if [ "${rescore_method}" = "mmpbsa" ]; then
  cd ${run_folder}/rescoring/${scoring_function}/
  write_pbsa_config
  if [ "${pb_method}" = "MD" ]; then
    # write input files for MD
    write_quickMD_config
  fi
fi

echo "Rescoring configuration finished                                               "

if [ -z "${com_list}" ]; then
  echo -e "${RED}ERROR${NC} : Could not find pdb files in ${pdb_folder}"    
  exit 1
fi
}



list_docking() {
# List docking results, make folders and write config files
# Receptor
filename=$(basename "${rec}")
extension="${filename##*.}"
rec=$(echo "${rec}" | sed "s/.${extension}//g")

# list all docking folders
# For the ALL mode, this will correspond to folders named after the mol2 files used for docking
# For the BEST mode, this will correspond to folders named after the ligands
dock_list=$(cd ${folder} ; \ls -l | grep "^d" | awk '{print $9}')

# list all docking poses in the sub-folder
pose_list=""
for dock_folder in ${dock_list}; do
    poses_list=$(cd ${folder}/${dock_folder}/; \ls *conf*.mol2 2>/dev/null | sed s/.mol2//g )
  
  if [ ! -z "$poses_list" ]; then
    for pose in ${poses_list}
    do
      lig_name=$(echo ${pose} | cut -d_ -f1)
      pose_list+=" ${lig_name}/${pose}/${dock_folder}"
  
      # And write the plants config file there.
      mkdir -p ${run_folder}/rescoring/${scoring_function}/${lig_name}/${pose}
      cd ${run_folder}/rescoring/${scoring_function}/${lig_name}/${pose}
      lig="${folder}/${dock_folder}/${pose}"
      
      echo -ne "Configuring ${PURPLE}${pose}${NC} from ${PURPLE}${lig_name}${NC}   \r"
      if [ "${rescore_method}" = "plants" ]; then
        # Compute the binding-site center (average on coordinates) and radius
        sphere_list=$(python ${CHEMFLOW_HOME}/common/bounding_sphere.py ${lig}.mol2)
        bs_center=$(echo "${sphere_list}" | cut -d";" -f1)
        bs_radius=$(echo "${sphere_list}" | cut -d";" -f2)
        write_plants_config
      elif [ "${rescore_method}" = "vina" ]; then
        lig="${run_folder}/input_files/lig/${lig_name}/${pose}"
        write_vina_config
      fi
    done
  fi
done

if [ "${rescore_method}" = "mmpbsa" ]; then
  cd ${run_folder}/rescoring/${scoring_function}/
  write_pbsa_config
  if [ "${pb_method}" = "MD" ]; then
    # write input files for MD
    write_quickMD_config
  fi
fi

echo "Rescoring configuration finished                                               "

if [ -z "${pose_list}" ]
then
  echo -e "${RED}ERROR${NC} : Could not find mol2 docking poses in ${folder}'s sub-folders"    
  exit 1
fi
}


############################################################
# PLANTS
############################################################

# Write Plants Configuration file
write_plants_config() {
echo -e "
# scoring function and search settings
scoring_function ${scoring_function}

# input
protein_file ${rec}.mol2
ligand_file  ${lig}.mol2

# output
output_dir results

# Binding site definition
bindingsite_center ${bs_center}
bindingsite_radius ${bs_radius}

# write mol2 files as a single (0) or multiple (1) files
write_multi_mol2 0

# water molecule centered on a sphere of coord x y z and can move in radius r
${dock_water}

# Other user-defined parameters
${plants_user_parameters}

# write
write_ranking_links 0
write_protein_bindingsite 1
write_protein_conformations 0
####
">config.plants
}

write_plants_pbs_header() {
echo "#!/bin/bash
#PBS -N PLANTS_${identifier}
#PBS -l nodes=1:ppn=1,walltime=24:00:00.00
#PBS -o ${run_folder}/pbs_scripts/plants_${identifier}.o
#PBS -e ${run_folder}/pbs_scripts/plants_${identifier}.e

#-----user_section----------
module load plants/1.2

source ${CHEMFLOW_HOME}/ScoreFlow/ScoreFlow_functions.bash
"> ${run_folder}/pbs_scripts/plants_${identifier}.pbs
}

write_plants_pbs() {
echo "
#-----------------------------
cd ${run_folder}/rescoring/${scoring_function}/${common_folder}
">> ${run_folder}/pbs_scripts/plants_${identifier}.pbs
print_vars >> ${run_folder}/pbs_scripts/plants_${identifier}.pbs
echo "
plants_cmd
" >> ${run_folder}/pbs_scripts/plants_${identifier}.pbs
}


run_plants() {
# Run PLANTS

# Create features.csv and ranking.csv headers
echo "LIGAND_ENTRY,TOTAL_SCORE,SCORE_RB_PEN,SCORE_NORM_HEVATOMS,SCORE_NORM_CRT_HEVATOMS,SCORE_NORM_WEIGHT,SCORE_NORM_CRT_WEIGHT,\
SCORE_RB_PEN_NORM_CRT_HEVATOMS,SCORE_NORM_CONTACT,EVAL,TIME">${run_folder}/rescoring/${scoring_function}/ranking.csv
echo "LIGAND_ENTRY,TOTAL_SCORE,SCORE_RB_PEN,SCORE_NORM_HEVATOMS,SCORE_NORM_CRT_HEVATOMS,SCORE_NORM_WEIGHT,SCORE_NORM_CRT_WEIGHT,\
SCORE_RB_PEN_NORM_CRT_HEVATOMS,SCORE_NORM_CONTACT,PLPtotal,PLPparthbond,PLPpartsteric,PLPpartmetal,PLPpartrepulsive,PLPpartburpolar,\
LIG_NUM_CLASH,LIG_NUM_CONTACT,LIG_NUM_NO_CONTACT,CHEMpartmetal,CHEMparthbond,CHEMparthbondCHO,DON,ACC,UNUSED_DON,UNUSED_ACC,\
CHEMPLP_CLASH2,TRIPOS_TORS,ATOMS_OUTSIDE_BINDINGSITE">${run_folder}/rescoring/${scoring_function}/features.csv

# List to iterate
if [ "${mode}" = "PDB" ]; then
  common_list="${com_list}"
elif $(list_include_item "ALL BEST" "${mode}"); then
  common_list="${pose_list}"
fi

# Progress Bar
length=$(echo ${common_list} | wc -w)
progress_count=0

# Print a spinner on the screen while preparing the commands for parallel
if [ "${run_mode}" = "parallel" ]; then
  # Run a spinner in the background
  (while :; do for s in / - \\ \|; do printf "\rPreparing parallel $s";sleep .2; done; done) &
elif [ "${run_mode}" = "mazinger" ]; then
  # Initialize variable that counts the number of poses rescored per pbs script
  pbs_count=0
  # Get the ceiling value of the number of jobs to put per pbs script
  let max_jobs_pbs=(${length}+${max_submissions}-1)/${max_submissions}
  # create pbs_script folder
  mkdir -p ${run_folder}/pbs_scripts/
fi

# Iterate over the docking poses
for item in ${common_list}
do
  # Extract names
  if [ "${mode}" = "PDB" ]; then
    common_folder="${item}"
    lig_name="${common_folder}"
    pose_name="${common_folder}"
    dock_folder="${common_folder}"
  elif $(list_include_item "ALL BEST" "${mode}"); then
    common_folder=$(echo "${item}"    | cut -d"/" -f"1,2")
    lig_name=$(echo "$common_folder"  | cut -d"/" -f1)
    pose_name=$(echo "$common_folder" | cut -d"/" -f2)
    dock_folder=$(echo "${item}"      | cut -d"/" -f3)
  fi

  # Go to the rescoring folder
  cd ${run_folder}/rescoring/${scoring_function}/${common_folder}
  
  # Run
  if [ "${run_mode}" = "local" ]    ; then
    # Progress
    (ProgressBar ${progress_count} ${length}) &
    # Run
    plants_cmd
    # update progress bar
    let progress_count+=1
    # Kill the progress bar when plants is done
    { kill $! && wait $!; } 2>/dev/null

  elif [ "${run_mode}" = "parallel" ] ; then
    echo -n "cd ${run_folder}/rescoring/${scoring_function}/${common_folder}; \
    source ${CHEMFLOW_HOME}/ScoreFlow/ScoreFlow_functions.bash; " >> ${run_folder}/rescoring/${scoring_function}/rescore_${datetime}.parallel
    CFvars=$(print_vars | sed ':a;N;$!ba;s/\n/; /g'); echo -n "${CFvars}" >> ${run_folder}/rescoring/${scoring_function}/rescore_${datetime}.parallel
    echo "; plants_cmd; \
    echo -n 0 >>${run_folder}/rescoring/${scoring_function}/.progress.dat" >> ${run_folder}/rescoring/${scoring_function}/rescore_${datetime}.parallel

  elif [ "${run_mode}" = "mazinger" ]; then
    if [ -z "${max_submissions}" ]; then
      identifier=${pose_name}
      write_plants_pbs
      jobid=$(qsub ${run_folder}/pbs_scripts/plants_${identifier}.pbs)
      echo "$jobid" >> ${run_folder}/rescoring/${scoring_function}/jobs_list_${datetime}.mazinger
      echo -ne "Running ${PURPLE}${pose_name}${NC} on ${BLUE}${jobid}${NC}              \r"
    else
      let progress_count+=1
      mazinger_current=$(mazinger_submitter ${pbs_count} ${max_jobs_pbs} ${progress_count} ${length} ${run_folder}/pbs_scripts/plants write_plants_pbs)
      pbs_count=$( echo "${mazinger_current}" | cut -d, -f1)
      identifier=$(echo "${mazinger_current}" | cut -d, -f2)
      test_jobid=$(echo "${mazinger_current}" | cut -d, -f3)
      if [ ! -z "${test_jobid}" ]; then 
        jobid=${test_jobid}
        echo "$jobid" >> ${run_folder}/rescoring/${scoring_function}/jobs_list_${datetime}.mazinger
        echo -ne "Running ${PURPLE}PBS script #${identifier}${NC} on ${BLUE}${jobid}${NC}              \r"
      fi
    fi
  fi
done
  
# Kill the spinner when the preparation of parallel is done, and run it !
if [ "${run_mode}" = "parallel" ]; then
  echo -e "\rFinished preparing parallel... Running"
  { kill $! && wait $!; } 2>/dev/null
  # Run the progress bar
  touch ${run_folder}/rescoring/${scoring_function}/.progress.dat
  (while :; do progress_count=$(cat ${run_folder}/rescoring/${scoring_function}/.progress.dat | wc -c); ProgressBar ${progress_count} ${length}; sleep 1; done) &
  # Run parallel
  ${parallel} -j ${core_number} < ${run_folder}/rescoring/${scoring_function}/rescore_${datetime}.parallel \
  > ${run_folder}/rescoring/${scoring_function}/parallel.job 2>&1
  # Kill the progress bar when parallel is done
  { printf '\n'; kill $! && wait $!; } 2>/dev/null
  rm -f ${run_folder}/rescoring/${scoring_function}/.progress.dat

# If running on mazinger, wait untill all jobs are finished
elif [ "${run_mode}" = "mazinger" ]; then
  mazinger_progress_bar ${run_folder}/rescoring/${scoring_function}/jobs_list_${datetime}.mazinger
  echo ""
fi
}

plants_cmd() {
# Run
${plants} --mode rescore config.plants > plants.job 2>&1
# reorganize results
reorganize_plants
}

reorganize_plants() {
if [ -d results ]; then
  cd results
  mv protein_bindingsite_fixed.mol2 ${run_folder}/rescoring/${scoring_function}/
  # the command tail -n +2 skip the first line (containing the header), and starts printing at the 2nd line of the file
  # PLANTS appends _entry_XXX_conf_XX to the rescored poses in the csv tables, so we use sed 's/\(^.*_entry.*_conf.*\)_entry.*_conf_[[:digit:]]*\(,.*$\)/\1\2/g'
  # to remove this string from the names
  tail -n +2 features.csv | sed 's/\(^.*_entry.*_conf.*\)_entry.*_conf_[[:digit:]]*\(,.*$\)/\1\2/g'>> ${run_folder}/rescoring/${scoring_function}/features.csv
  tail -n +2 ranking.csv  | sed 's/\(^.*_entry.*_conf.*\)_entry.*_conf_[[:digit:]]*\(,.*$\)/\1\2/g'>> ${run_folder}/rescoring/${scoring_function}/ranking.csv
  cd ${run_folder}/rescoring/${scoring_function}/
  rm -rf ${common_folder}
else
  echo "${pose_name},${dock_folder}" >> ${run_folder}/rescoring/${scoring_function}/errors.csv
fi
}


################################################
# VINA
################################################

write_vina_config() {
echo "# input
receptor = ${rec}.pdbqt
ligand   = ${lig}.pdbqt
">config.vina
}

write_vina_pbs_header() {
echo "#!/bin/bash
#PBS -N VINA_${identifier}
#PBS -l nodes=1:ppn=1,walltime=24:00:00.00
#PBS -o ${run_folder}/pbs_scripts/vina_${identifier}.o
#PBS -e ${run_folder}/pbs_scripts/vina_${identifier}.e

#-----user_section--------
module load vina

source ${CHEMFLOW_HOME}/ScoreFlow/ScoreFlow_functions.bash
" > ${run_folder}/pbs_scripts/vina_${identifier}.pbs
}

write_vina_pbs() {
echo "
#----------------------
cd ${run_folder}/rescoring/${scoring_function}/${common_folder}
">> ${run_folder}/pbs_scripts/vina_${identifier}.pbs
print_vars >> ${run_folder}/pbs_scripts/vina_${identifier}.pbs
echo "
vina_cmd
" >> ${run_folder}/pbs_scripts/vina_${identifier}.pbs
}

vina_cmd() {
# PDB mode
if [ "${mode}" = "PDB" ]; then
  # Prepare receptor
  ${adt_u24}/prepare_receptor4.py -r ${rec}.mol2 > convert2pdbqt.job
  # Prepare ligand
  ${adt_u24}/prepare_ligand4.py -l ${lig}.mol2 >> convert2pdbqt.job
# Mode BEST or ALL
elif $(list_include_item "ALL BEST" "${mode}"); then
  # Convert pose to pdbqt if it doesn't exist
  if [ ! -f ${run_folder}/input_files/lig/${lig_name}/${pose_name}.pdbqt ]; then
    mkdir -p ${run_folder}/input_files/lig/${lig_name}
    ${adt_u24}/prepare_ligand4.py -l ${folder}/${dock_folder}/${pose_name}.mol2 >> convert2pdbqt.job
    mv ${pose_name}.pdbqt ${run_folder}/input_files/lig/${lig_name}
  fi
fi

# Run
${vina_exec} --score_only --config config.vina --log output.log > vina.job
# Reorganize files and output master csv table
reorganize_vina
}


run_vina() {
# Headers for the concatenated score file
echo "Ligand,Affinity,gauss_1,gauss_2,repulsion,hydrophobic,Hydrogen" > ${run_folder}/rescoring/${scoring_function}/ranking.csv

# List to iterate
if [ "${mode}" = "PDB" ]; then
  common_list="${com_list}"
elif $(list_include_item "ALL BEST" "${mode}"); then
  common_list="${pose_list}"
fi

# Progress Bar
length=$(echo ${common_list} | wc -w)
progress_count=0

# Print a spinner on the screen while preparing the commands for parallel
if [ "${run_mode}" = "parallel" ]; then
  # Run a spinner in the background
  (while :; do for s in / - \\ \|; do printf "\rPreparing parallel $s";sleep .2; done; done) &
elif [ "${run_mode}" = "mazinger" ]; then
  # Initialize variable that counts the number of poses rescored per pbs script
  pbs_count=0
  # Get the ceiling value of the number of jobs to put per pbs script
  let max_jobs_pbs=(${length}+${max_submissions}-1)/${max_submissions}
  # create pbs_script folder
  mkdir -p ${run_folder}/pbs_scripts/
fi

# Convert receptor if it's not already done
if $(list_include_item "ALL BEST" "${mode}") && [ ! -f ${rec}.pdbqt ]; then 
  cd $(dirname ${rec}.${extension})
  ${adt_u24}/prepare_receptor4.py -r ${rec}.${extension} > convert2pdbqt.job
fi

# Iterate over the docking poses
for item in ${common_list}
do
  # Extract names
  if [ "${mode}" = "PDB" ]; then
    common_folder="${item}"
    lig_name="${common_folder}"
    pose_name="${common_folder}"
    dock_folder="${common_folder}"
  elif $(list_include_item "ALL BEST" "${mode}"); then
    common_folder=$(echo "${item}"    | cut -d"/" -f"1,2")
    lig_name=$(echo "$common_folder"  | cut -d"/" -f1)
    pose_name=$(echo "$common_folder" | cut -d"/" -f2)
    dock_folder=$(echo "${item}"      | cut -d"/" -f3)
  fi

  # Go to the rescoring folder
  cd ${run_folder}/rescoring/${scoring_function}/${common_folder}

  # List ligands for complex mode
  if [ "${mode}" = "PDB" ]; then
    lig=$(ls ligand*.mol2 | sed s/.mol2//g)
    rec=$(ls protein.mol2 | sed s/.mol2//g)
  fi

  # Run
  if [ "${run_mode}" = "local" ]    ; then
    # Progress
    (ProgressBar ${progress_count} ${length}) &
    # Run
    vina_cmd
    # update progress bar
    let progress_count+=1
    # Kill the progress bar when plants is done
    { kill $! && wait $!; } 2>/dev/null

  elif [ "${run_mode}" = "parallel" ] ; then
    echo -n "cd ${run_folder}/rescoring/${scoring_function}/${common_folder}; \
    source ${CHEMFLOW_HOME}/ScoreFlow/ScoreFlow_functions.bash; " >> ${run_folder}/rescoring/${scoring_function}/rescore_${datetime}.parallel
    CFvars=$(print_vars | sed ':a;N;$!ba;s/\n/; /g'); echo -n "${CFvars}" >> ${run_folder}/rescoring/${scoring_function}/rescore_${datetime}.parallel
    echo "; vina_cmd; \
    echo -n 0 >>${run_folder}/rescoring/${scoring_function}/.progress.dat" >> ${run_folder}/rescoring/${scoring_function}/rescore_${datetime}.parallel

  elif [ "${run_mode}" = "mazinger" ]; then
    if [ -z "${max_submissions}" ]; then
      identifier=${pose_name}
      write_vina_pbs
      jobid=$(qsub ${run_folder}/pbs_scripts/vina_${identifier}.pbs)
      echo "$jobid" >> ${run_folder}/rescoring/${scoring_function}/jobs_list_${datetime}.mazinger
      echo -ne "Running ${PURPLE}${pose_name}${NC} on ${BLUE}${jobid}${NC}              \r"
    else
      let progress_count+=1
      mazinger_current=$(mazinger_submitter ${pbs_count} ${max_jobs_pbs} ${progress_count} ${length} ${run_folder}/pbs_scripts/vina write_vina_pbs)
      pbs_count=$( echo "${mazinger_current}" | cut -d, -f1)
      identifier=$(echo "${mazinger_current}" | cut -d, -f2)
      test_jobid=$(echo "${mazinger_current}" | cut -d, -f3)
      if [ ! -z "${test_jobid}" ]; then 
        jobid=${test_jobid}
        echo "$jobid" >> ${run_folder}/rescoring/${scoring_function}/jobs_list_${datetime}.mazinger
        echo -ne "Running ${PURPLE}PBS script #${identifier}${NC} on ${BLUE}${jobid}${NC}              \r"
      fi
    fi
  fi
done

# Kill the spinner when the preparation of parallel is done, and run it !
if [ "${run_mode}" = "parallel" ]; then
  echo -e "\rFinished preparing parallel... Running"
  { kill $! && wait $!; } 2>/dev/null
  # Run the progress bar
  touch ${run_folder}/rescoring/${scoring_function}/.progress.dat
  (while :; do progress_count=$(cat ${run_folder}/rescoring/${scoring_function}/.progress.dat | wc -c); ProgressBar ${progress_count} ${length}; sleep 1; done) &
  # Run parallel
  ${parallel} -j ${core_number} < ${run_folder}/rescoring/${scoring_function}/rescore_${datetime}.parallel \
  > ${run_folder}/rescoring/${scoring_function}/parallel.job 2>&1
  # Kill the progress bar when parallel is done
  { printf '\n'; kill $! && wait $!; } 2>/dev/null
  rm -f ${run_folder}/rescoring/${scoring_function}/.progress.dat

# If running on mazinger, wait untill all jobs are finished
elif [ "${run_mode}" = "mazinger" ]; then
  mazinger_progress_bar ${run_folder}/rescoring/${scoring_function}/jobs_list_${datetime}.mazinger
  echo ""
fi
}

reorganize_vina() {
# First output the results as a csv table, inside the ligand/pose/complex folder
# Then concatenate this csv table in the master ranking file.
# Remark : Don't output directly in the ranking file, because we first need to print all the values on one line
# without returning to a new line. Using parallel or mazinger, this will result in overwriting results of
# different poses on the same line.
if [ -f output.log ]; then
  # Parse and print values on one line, in csv format
  echo -n "${pose_name}" >> energy.csv
  for item in 'Affinity' 'gauss 1' 'gauss 2' 'repulsion' 'hydrophobic' 'Hydrogen'
  do
    val=$(awk -F: -v var="${item}" '$0 ~ var {print $2}' output.log | cut -d" " -f2)
    echo -n ",${val}" >> energy.csv
  done
  echo "" >> energy.csv
  # Concatenate to ranking
  cat energy.csv >> ${run_folder}/rescoring/${scoring_function}/ranking.csv
  # remove the old files
  cd ${run_folder}/rescoring/${scoring_function}/
  rm -rf ${common_folder}
else
  echo "${pose_name},${dock_folder}" >> ${run_folder}/rescoring/${scoring_function}/errors.csv
fi
}


#################################################
# MMPBSA
#################################################
tleap_receptor() {
# Run tleap for the receptor

echo "source leaprc.protein.ff14SB
source leaprc.gaff
set default pbradii ${radii}

rec = loadpdb ${rec}.pdb
saveamberparm rec ${rec}.prmtop ${rec}.rst7
savepdb rec ${rec}_amber.pdb
quit">tleap_rec.cmd

tleap -f tleap_rec.cmd &>tleap_rec.job
}

write_tleap_without_water() {
# Write tleap configuration file, no water
echo "source leaprc.protein.ff14SB
source leaprc.gaff

set default pbradii ${radii}

loadamberparams ${lig}.frcmod
loadOff ${lig}.lib
saveamberparm MOL ${run_folder}/input_files/lig/${lig_name}/${pose_name}.prmtop ${run_folder}/input_files/lig/${lig_name}/${pose_name}.rst7
savepdb MOL ${run_folder}/input_files/lig/${lig_name}/${pose_name}.pdb

rec = loadpdb ${rec}_amber.pdb
saveamberparm rec ${rec}.prmtop ${rec}.rst7

com = combine {rec, MOL}
saveamberparm com ${run_folder}/input_files/com/${lig_name}/${pose_name}.prmtop ${run_folder}/input_files/com/${lig_name}/${pose_name}.rst7
savepdb com ${run_folder}/input_files/com/${lig_name}/${pose_name}.pdb
quit">tleap.cmd
}

write_tleap_with_water() {
# Write tleap configuration file, with water

echo "source leaprc.protein.ff14SB
source leaprc.gaff
source leaprc.water.tip3p

set default pbradii ${radii}

loadamberparams ${lig}.frcmod
loadOff ${lig}.lib
saveamberparm MOL ${run_folder}/input_files/lig/${lig_name}/${pose_name}.prmtop ${run_folder}/input_files/lig/${lig_name}/${pose_name}.rst7
savepdb MOL ${run_folder}/input_files/lig/${lig_name}/${pose_name}.pdb

rec = loadpdb ${rec}_amber.pdb

wat = loadmol2 ${water}

com = combine {rec, wat, MOL}
saveamberparm com ${run_folder}/input_files/com/${lig_name}/${pose_name}.prmtop ${run_folder}/input_files/com/${lig_name}/${pose_name}.rst7
savepdb com ${run_folder}/input_files/com/${lig_name}/${pose_name}.pdb
quit">tleap.cmd
}

run_tleap() {
# If the complex topology doesn't exist, run tleap
if [ ! -f ${run_folder}/input_files/com/${lig_name}/${pose_name}.prmtop ]; then
  mkdir -p ${run_folder}/input_files/com/${lig_name}
  mkdir -p ${run_folder}/input_files/lig/${lig_name}
  # Run tleap to prepare topology and coordinates
  if [ -z "${water}" ]; then
    write_tleap_without_water
  else
    write_tleap_with_water
  fi
  # Run tleap
  tleap -f tleap.cmd &>tleap.job
fi
}

write_pbsa_config() {
# Write MMPBSA/MMGBSA config files

if [ "${scoring_function}" = "GB8" ] ; then
echo "GBSA using GB8
&general
verbose=2, keep_files=0,
/
&gb
igb=8, saltcon=0.150,
/
"> GB8.in

elif [ "${scoring_function}" = "GB5" ] ; then
echo "GBSA using GB5
&general
verbose=2, keep_files=0,
/
&gb
igb=5, saltcon=0.150,
/
"> GB5.in

elif [ "${scoring_function}" == "PB3" ] ; then

# old config
echo "PBSA using PB3
&cntrl
ntx=1, imin=1, igb=10, inp=1,
/
&pb
epsout=80.0, epsin=1.0, space=0.5, bcopt=6, dprob=1.4,
cutnb=0, eneopt=2,
accept=0.001, sprob=1.6, radiopt=0, fillratio=4,
maxitn=1000, arcres=0.0625,
cavity_surften=0.005, cavity_offset=0.86
/
">/dev/null

echo "PBSA using PB3
&general
verbose=2, keep_files=0,
/
&pb
inp=1,                     
radiopt=0,                
istrng=0.15,              
cavity_surften=0.00542,   
cavity_offset=0.92,        
/
"> PB3.in
fi
}

write_quickMD_config() {
echo "Complex: initial minimization prior to MD GB model
 &cntrl
  imin   = 1,
  maxcyc = 500,
  ncyc   = 250,
  ntb    = 0,
  igb    = ${gb_model},
  cut    = 999
 /">min.in


echo "Complex MD Generalized Born, infinite cut off
 &cntrl
  imin = 0, ntb = 0,
  igb = ${gb_model}, ntpr = 1000, ntwx = 1000,
  ntt = 3, gamma_ln = 1.0,
  tempi = 300.0, temp0 = 300.0
  nstlim = ${md_time}000, dt = 0.001,
  cut = 999
 /
">prod.in
}

write_mmpbsa_pbs_header() {
# Write PBS script for MMPBSA
echo "#!/bin/bash
#PBS -N MMPBSA_${identifier}
#PBS -l nodes=1:ppn=1,walltime=24:00:00.00
#PBS -o ${run_folder}/pbs_scripts/mmpbsa_${identifier}.o
#PBS -e ${run_folder}/pbs_scripts/mmpbsa_${identifier}.e

source ${amber}
source ${CHEMFLOW_HOME}/ScoreFlow/ScoreFlow_functions.bash
" > ${run_folder}/pbs_scripts/mmpbsa_${identifier}.pbs
}

write_mmpbsa_pbs() {
# Write PBS script for MMPBSA
echo "
#----------------------
cd ${run_folder}/rescoring/${scoring_function}/${common_folder}
">> ${run_folder}/pbs_scripts/mmpbsa_${identifier}.pbs
print_vars >> ${run_folder}/pbs_scripts/mmpbsa_${identifier}.pbs
echo "
# Make trajectory and topology of the complex from the pdb file
run_tleap
# Create files
mmpbsa_${pb_method}_cmd
# Run calculation
mmpbsa_calculation
# Reorganize files
reorganize_mmpbsa
" >> ${run_folder}/pbs_scripts/mmpbsa_${identifier}.pbs
}

mmpbsa_1F_cmd() {
# Preparation of files prior to 1F MMPBSA

# Run a quick minimization if asked by user
if [ ! -z "${min_steps}" ]; then
  # If the complex_before_min.rst7 file doesn't exist, run the minimization
  if [ ! -f ${run_folder}/input_files/com/${lig_name}/${pose_name}_1F_min.rst7 ]; then
    if [ "${min_type}" = "backbone" ]; then
      minab_mask=":${min_mask}:CA|:${min_mask}:N|:${min_mask}:C|:${min_mask}:O"
    else
      minab_mask="${min_mask}"
    fi
    # Minimize
    minab ${run_folder}/input_files/com/${lig_name}/${pose_name}.pdb \
          ${run_folder}/input_files/com/${lig_name}/${pose_name}.prmtop \
          ${run_folder}/input_files/com/${lig_name}/${pose_name}_1F_min.pdb \
          ${implicit_model} ${min_steps} \'${minab_mask}\' ${min_energy} &> minab.job
    # Write trajectory from minimized pdb
    cpptraj -p ${run_folder}/input_files/com/${lig_name}/${pose_name}.prmtop \
            -y ${run_folder}/input_files/com/${lig_name}/${pose_name}_1F_min.pdb \
            -x ${run_folder}/input_files/com/${lig_name}/${pose_name}_1F_min.rst7 &> cpptraj.job
  fi
  mmpbsa_rst7="${run_folder}/input_files/com/${lig_name}/${pose_name}_1F_min.rst7"
else
  mmpbsa_rst7="${run_folder}/input_files/com/${lig_name}/${pose_name}.rst7"
fi
}

mmpbsa_MD_cmd() {
# Preparation of files for a quick implicit solvent MD prior to MMPBSA

# Run Minimization
if [ ! -f ${run_folder}/input_files/com/${lig_name}/${pose_name}_MD_min.rst7 ]; then
pmemd.cuda  -O -i ${run_folder}/rescoring/${scoring_function}/min.in \
            -c ${run_folder}/input_files/com/${lig_name}/${pose_name}.rst7 \
            -p ${run_folder}/input_files/com/${lig_name}/${pose_name}.prmtop \
            -o min.mdout -e min.mden -v min.mdvel \
            -r ${run_folder}/input_files/com/${lig_name}/${pose_name}_MD_min.rst7 \
            -x ${run_folder}/input_files/com/${lig_name}/${pose_name}_MD_min.mdcrd \
            -ref ${run_folder}/input_files/com/${lig_name}/${pose_name}.rst7 &> MD_min.job
  if [ ! -f min.mdout ]; then
    echo "${pose_name},${dock_folder},implicit solvent MD minimization" >> ${run_folder}/rescoring/${scoring_function}/errors.csv
  fi
fi
# Run MD
if [ ! -f ${run_folder}/input_files/com/${lig_name}/${pose_name}_MD_prod.rst7 ]; then
pmemd.cuda  -O -i ${run_folder}/rescoring/${scoring_function}/prod.in \
            -c ${run_folder}/input_files/com/${lig_name}/${pose_name}_MD_min.rst7 \
            -p ${run_folder}/input_files/com/${lig_name}/${pose_name}.prmtop \
            -o prod.mdout -e prod.mden -v prod.mdvel \
            -r ${run_folder}/input_files/com/${lig_name}/${pose_name}_MD_prod.rst7 \
            -x ${run_folder}/input_files/com/${lig_name}/${pose_name}_MD_prod.mdcrd \
            -ref ${run_folder}/input_files/com/${lig_name}/${pose_name}_MD_min.rst7 &> MD_prod.job
  if [ ! -f prod.mdout ]; then
    # if no output file was found
    echo "${pose_name},${dock_folder},implicit solvent MD production" >> ${run_folder}/rescoring/${scoring_function}/errors.csv
  fi
fi

mmpbsa_rst7="${run_folder}/input_files/com/${lig_name}/${pose_name}_MD_prod.rst7"
}

mmpbsa_calculation() {
# Run the calculation
if [ "${scoring_function}" = "PB3" ] ; then
  ante-MMPBSA.py  -p ${run_folder}/input_files/com/${lig_name}/${pose_name}.prmtop \
                  -c com.top -r rec.top -l lig.top -s \'${strip_mask}\' -n ${lig_mask} &> ante_mmpbsa.job
else
  ante-MMPBSA.py  -p ${run_folder}/input_files/com/${lig_name}/${pose_name}.prmtop \
                  -c com.top -r rec.top -l lig.top -s \'${strip_mask}\' -n ${lig_mask} --radii=${radii} &> ante_mmpbsa.job
fi
MMPBSA.py -O -i ${run_folder}/rescoring/${scoring_function}/${scoring_function}.in \
          -o MM${scoring_function::2}SA.dat -eo MM${scoring_function::2}SA.csv -cp com.top -rp rec.top -lp lig.top \
          -y ${mmpbsa_rst7} &> mmpbsa.job
# Check if output was created
if [ ! -f MM${scoring_function::2}SA.csv ]; then
  echo "${pose_name},${dock_folder},mmpbsa results" >> ${run_folder}/rescoring/${scoring_function}/errors.csv
fi
}

reorganize_mmpbsa() {
# if the PB_method was 1F, output minimization results
if [ "${pb_method}" = "1F" ]; then
  # if the minimization was done
  if [ ! -z "$(grep "ff:" minab.job)" ]; then
    # Exemple :
    #       iter    Total       bad      vdW     elect   nonpolar   genBorn      frms
    # ff:     0 1578877638.37  11225.12 1578897661.82 -20085.46      0.00 -11163.11  2.26e+08
    # ff:    10 431224018.15  11225.56 431244076.20 -20120.38      0.00 -11163.23  4.93e+07
    # ff:    20 3604773.52  11303.20 3624879.97 -20246.27      0.44 -11163.83  1.37e+05

    # Match lines begining with "ff:" : /^ff:/
    # Replace groups of spaces with a comma : s/\s\+/,/g
    # Replace "ff:" with the name of the ligand and print : s/^ff:/${pose_name}/gp
    sed -n "/^ff:/s/\s\+/,/g;s/^ff:/${pose_name}/gp" minab.job >> ${run_folder}/rescoring/${scoring_function}/1F_min.csv
  fi

# if the PB_method was MD, output min and prod results
elif [ "${pb_method}" = "MD" ]; then
  if [ -f min.mdout ]; then
    # Exemple of min.mdout :
    #   NSTEP       ENERGY          RMS            GMAX         NAME    NUMBER
    #      1      -7.2130E+02     4.2787E+01     4.0475E+02     H20       185
    #
    # BOND    =       94.3081  ANGLE   =      191.4991  DIHED      =      162.5874
    # VDWAALS =       58.5641  EEL     =     1651.2674  EGB        =     -153.7386
    # 1-4 VDW =       22.9043  1-4 EEL =    -2748.6909  RESTRAINT  =        0.0000
    #
    #
    #   NSTEP       ENERGY          RMS            GMAX         NAME    NUMBER
    #...

    # Get lines that are between "4. RESULTS" and "FINAL RESULTS" in the mdout file to obtain only the values shown above
    lines=$(awk '/4.  RESULTS/{f=1;next};/FINAL RESULTS/{f=0}f' min.mdout)
    # Get values following the "NSTEP" line, and output them in csv format
    # awk '/NSTEP/{f=1;next};/^\s*$/{f=0} : start reading after the line containing NSTEP, and stop at the first empty line
    # Thus we only get the values following the "NSTEP" flag
    # f{gsub (/\s+/, ",", $0); print}' : for the lines marked by the flag, replace groups of spaces (\s\+) with a comma (",") on all the line ($0)
    # in order to obtain a csv formatted file
    values1=$(echo "${lines}" | awk '/NSTEP/{f=1;next};/^\s*$/{f=0}f{gsub (/\s+/, ",", $0); print}')
    # Get energy decomposition
    # sed -n '/BOND/,/1-4 VDW/ : For the lines between "BOND" and "1-4 VDW" (inclusive)
    # s/^.*=\s\+\([.0-9-]\+\).*=\s\+\([.0-9-]\+\).*=\s\+\([.0-9-]\+\)$/ : search for a regular expression : chars = space float, repeated 3 times
    # /\1,\2,\3/gp' : return only the values between parenthesis, and separated by commas
    # This will return 3 lines with 3 values each separated by commas, but for a csv format we want 1 line per NSTEP
    # | sed -n '$!N;s/\n/,/;$!N;s/\n/,/p' : join line1 and line2, replace \n with a comma, then join line1+line2 and line3, replace \n with a comma
    # so that "1 2\n3 4\n5 6\n" becomes "1 2 3 4 5 6\n"
    values2=$(echo "${lines}" | sed -n '/BOND/,/1-4 VDW/s/^.*=\s\+\([.0-9-]\+\).*=\s\+\([.0-9-]\+\).*=\s\+\([.0-9-]\+\)$/\1,\2,\3/gp' \
              | sed -n '$!N;s/\n/,/;$!N;s/\n/,/p')
    # Concatenate both gathered values on the same rows
    lines=$(paste -d"," <(echo "${values1}") <(echo "${values2}"))
    # Make the final csv table by appending the docking pose name
    echo "${lines}" | sed -n "s/^/${pose_name}/gp" >> ${run_folder}/rescoring/${scoring_function}/MD_min.csv
  fi

    if [ -f prod.mdout ]; then
    # Exemple :
    # NSTEP =        0   TIME(PS) =       0.000  TEMP(K) =   306.02  PRESS =     0.0
    # Etot   =      -895.1130  EKtot   =       176.0523  EPtot      =     -1071.1653
    # BOND   =         3.8889  ANGLE   =       149.0011  DIHED      =       120.7584
    # 1-4 NB =        19.5578  1-4 EEL =     -2766.3216  VDWAALS    =       -94.1882
    # EELEC  =      1671.7489  EGB     =      -175.6107  RESTRAINT  =         0.0000
    # ------------------------------------------------------------------------------
    #
    #
    # NSTEP =     1000   TIME(PS) =       1.000  TEMP(K) =   235.78  PRESS =     0.0
    #...

    # Get lines between "4. RESULTS" and "A V E R A G E S" to obtain the values shown above
    lines=$(awk '/4.  RESULTS/{f=1;next};/A V E R A G E S/{f=0}f' prod.mdout)
    # Get energy decomposition
    # sed -n '/NSTEP/,/RESTRAINT/ : For the lines between NSTEP and RESTRAINT (inclusive)
    # s/^.*=\s\+\([.0-9-]\+\).*=\s\+\([.0-9-]\+\).*=\s\+\([.0-9-]\+\)$/\1,\2,\3/gp' : return only the values
    # Notice that the first line contains 4 values, but with this regular expression, we are only asking for 3
    # As a result, the most left-side value (NSTEP), will be ignored. This is acceptable since we have a value that can get us back
    # to NSTEP if needed : the TIME(PS). NSTEP = 1000*TIME(PS) since we chose a dt of 0.001
    # | sed -n '$!N;s/\n/,/;$!N;s/\n/,/;$!N;s/\n/,/;$!N;s/\n/,/p' : output the 5 lines separated by \n as 1 line separated by commas
    values=$( echo "${lines}" | sed -n '/NSTEP/,/RESTRAINT/s/^.*=\s\+\([.0-9-]\+\).*=\s\+\([.0-9-]\+\).*=\s\+\([.0-9-]\+\)$/\1,\2,\3/gp'  \
              | sed -n '$!N;s/\n/,/;$!N;s/\n/,/;$!N;s/\n/,/;$!N;s/\n/,/p')
    # # Make the final csv table by appending the docking pose name
    echo "${values}" | sed -n "s/^/${pose_name},/gp" >> ${run_folder}/rescoring/${scoring_function}/MD_prod.csv
  fi
fi

# if the MM-PB/GB-SA output file exists
if [ -f MM${scoring_function::2}SA.csv ]; then
  # Get the values for all structures
  for structure in Ligand Receptor Complex DELTA
  do
    # We want to retrieve the values in the MM-PB/GB-SA csv file to output a computer-readable csv file
    # We identify the line corresponding to our structure with var="${structure} Energy Terms" '$0 ~ var'
    # At this point, we set the flag to true starting 2 lines after the match : {flag=1;getline;getline}
    # We then search for the last values for our structure, identified by an empty line : /^\s*$/
    # When we match this empty line, the flag is set to false for the remaining lines : {flag=0}
    # And we print the lines for which the flag was set to true : flag
    # This will output all values corresponding to the $structure in csv format
    # Then, with sed, we insert the docking pose name, and the structure, at the beginning of the file
    awk -v var="${structure} Energy Terms" '$0 ~ var {flag=1;getline;getline}/^\s*$/{flag=0}flag' MM${scoring_function::2}SA.csv \
    | sed -n "s/^/${pose_name},${structure},/gp" >> energy.csv
  done
# Concatenate to ranking
cat energy.csv >> ${run_folder}/rescoring/${scoring_function}/ranking.csv

# Delete all output files related to the docking pose, since we managed to gather the results
cd ${run_folder}/rescoring/${scoring_function}/
rm -rf ${common_folder}

fi
}


run_mmpbsa() {
# Run MMPBSA or MMGBSA

# Headers for the concatenated score file
# If the 2 first letters of scoring function (PB3, GB5...) are PB
if [ "${scoring_function::2}" = "PB" ]; then
  echo "Ligand,Structure,Frame #,BOND,ANGLE,DIHED,UB,IMP,CMAP,VDWAALS,EEL,1-4 VDW,1-4 EEL,EPB,ENPOLAR,EDISPER,G gas,G solv,TOTAL" \
  > ${run_folder}/rescoring/${scoring_function}/ranking.csv
# If it's GB
elif [ "${scoring_function::2}" = "GB" ]; then
  echo "Ligand,Structure,Frame #,BOND,ANGLE,DIHED,UB,IMP,CMAP,VDWAALS,EEL,1-4 VDW,1-4 EEL,EGB,ESURF,G gas,G solv,TOTAL" \
  > ${run_folder}/rescoring/${scoring_function}/ranking.csv
fi
# Time series for minimization and production
if [ "${pb_method}" = "1F" ]; then
  echo "Ligand,iter,Total,bad,vdW,elect,nonpolar,genBorn,frms" \
  > ${run_folder}/rescoring/${scoring_function}/1F_min.csv
elif [ "${pb_method}" = "MD" ]; then
  echo "Ligand,NSTEP,ENERGY,RMS,GMAX,NAME,NUMBER,BOND,ANGLE,DIHED,VDWAALS,EEL,EGB,1-4 VDW,1-4 EEL,RESTRAINT" \
  > ${run_folder}/rescoring/${scoring_function}/MD_min.csv
  echo "Ligand,TIME(PS),TEMP(K),PRESS,Etot,EKtot,EPtot,BOND,ANGLE,DIHED,1-4 NB,1-4 EEL,VDWAALS,EELEC,EGB,RESTRAINT" \
  > ${run_folder}/rescoring/${scoring_function}/MD_prod.csv
fi

# List to iterate
if [ "${mode}" = "PDB" ]; then
  common_list="${com_list}"
elif $(list_include_item "ALL BEST" "${mode}"); then
  common_list="${pose_list}"
fi

# Progress Bar
length=$(echo ${common_list} | wc -w)
progress_count=0

# Print a spinner on the screen while preparing the commands for parallel
if [ "${run_mode}" = "parallel" ]; then
  # Run a spinner in the background
  (while :; do for s in / - \\ \|; do printf "\rPreparing parallel $s";sleep .2; done; done) &
elif [ "${run_mode}" = "mazinger" ]; then
  # Initialize variable that counts the number of poses rescored per pbs script
  pbs_count=0
  # Get the ceiling value of the number of jobs to put per pbs script
  let max_jobs_pbs=(${length}+${max_submissions}-1)/${max_submissions}
  # create pbs_script folder
  mkdir -p ${run_folder}/pbs_scripts/
fi

# Prepare topology and trajectory for the receptor
if [ ! -f ${rec}.prmtop ]; then tleap_receptor; fi

# Iterate over the docking poses
for item in ${common_list}
do
  # Extract names
  if [ "${mode}" = "PDB" ]; then
    common_folder="${item}"
    lig_name="${common_folder}"
    pose_name="${common_folder}"
    dock_folder="${common_folder}"
  elif $(list_include_item "ALL BEST" "${mode}"); then
    common_folder=$(echo "${item}"    | cut -d"/" -f"1,2")
    lig_name=$(echo "$common_folder"  | cut -d"/" -f1)
    pose_name=$(echo "$common_folder" | cut -d"/" -f2)
    dock_folder=$(echo "${item}"      | cut -d"/" -f3)
  fi

  # Go to the rescoring folder
  cd ${run_folder}/rescoring/${scoring_function}/${common_folder}

  # List ligands for complex mode
  if [ "${mode}" = "PDB" ]; then
    lig=$(ls ligand*.mol2 | sed s/.mol2//g)
    rec=$(ls protein.mol2 | sed s/.mol2//g)
  elif $(list_include_item "ALL BEST" "${mode}"); then
    lig="${folder}/${dock_folder}/${pose_name}"
  fi

  # Run
  if [ "${run_mode}" = "local" ]    ; then
    # Progress
    (ProgressBar ${progress_count} ${length}) &

    # Make trajectory and topology of the complex from the pdb file
    run_tleap
    # Create files
    mmpbsa_${pb_method}_cmd
    # Run calculation
    mmpbsa_calculation
    # Reorganize files
    reorganize_mmpbsa

    # update progress bar
    let progress_count+=1
    # Kill the progress bar when plants is done
    { kill $! && wait $!; } 2>/dev/null

  elif [ "${run_mode}" = "parallel" ] ; then
    echo -n "cd ${run_folder}/rescoring/${scoring_function}/${common_folder}; \
    source ${CHEMFLOW_HOME}/ScoreFlow/ScoreFlow_functions.bash; " >> ${run_folder}/rescoring/${scoring_function}/rescore_${datetime}.parallel
    CFvars=$(print_vars | sed ':a;N;$!ba;s/\n/; /g'); echo -n "${CFvars}" >> ${run_folder}/rescoring/${scoring_function}/rescore_${datetime}.parallel
    echo "; run_tleap; mmpbsa_${pb_method}_cmd; mmpbsa_calculation; reorganize_mmpbsa; \
    echo -n 0 >>${run_folder}/rescoring/${scoring_function}/.progress.dat" >> ${run_folder}/rescoring/${scoring_function}/rescore_${datetime}.parallel

  elif [ "${run_mode}" = "mazinger" ]; then

    if [ -z "${max_submissions}" ]; then
      identifier=${pose_name}
      write_mmpbsa_pbs
      jobid=$(qsub ${run_folder}/pbs_scripts/mmpbsa_${identifier}.pbs)
      echo "$jobid" >> ${run_folder}/rescoring/${scoring_function}/jobs_list_${datetime}.mazinger
      echo -ne "Running ${PURPLE}${pose_name}${NC} on ${BLUE}${jobid}${NC}              \r"
    else
      let progress_count+=1
      mazinger_current=$(mazinger_submitter ${pbs_count} ${max_jobs_pbs} ${progress_count} ${length} ${run_folder}/pbs_scripts/mmpbsa write_mmpbsa_pbs)
      pbs_count=$( echo "${mazinger_current}" | cut -d, -f1)
      identifier=$(echo "${mazinger_current}" | cut -d, -f2)
      test_jobid=$(echo "${mazinger_current}" | cut -d, -f3)
      if [ ! -z "${test_jobid}" ]; then 
        jobid=${test_jobid}
        echo "$jobid" >> ${run_folder}/rescoring/${scoring_function}/jobs_list_${datetime}.mazinger
        echo -ne "Running ${PURPLE}PBS script #${identifier}${NC} on ${BLUE}${jobid}${NC}              \r"
      fi
    fi
  fi
done

# Kill the spinner when the preparation of parallel is done, and run it !
if [ "${run_mode}" = "parallel" ]; then
  echo -e "\rFinished preparing parallel... Running"
  { kill $! && wait $!; } 2>/dev/null
  # Run the progress bar
  touch ${run_folder}/rescoring/${scoring_function}/.progress.dat
  (while :; do progress_count=$(cat ${run_folder}/rescoring/${scoring_function}/.progress.dat | wc -c); ProgressBar ${progress_count} ${length}; sleep 1; done) &
  # Run parallel
  ${parallel} -j ${core_number} < ${run_folder}/rescoring/${scoring_function}/rescore_${datetime}.parallel \
  > ${run_folder}/rescoring/${scoring_function}/parallel.job 2>&1
  # Kill the progress bar when parallel is done
  { printf '\n'; kill $! && wait $!; } 2>/dev/null
  rm -f ${run_folder}/rescoring/${scoring_function}/.progress.dat

# If running on mazinger, wait untill all jobs are finished
elif [ "${run_mode}" = "mazinger" ]; then
  mazinger_progress_bar ${run_folder}/rescoring/${scoring_function}/jobs_list_${datetime}.mazinger
  echo ""
fi
}