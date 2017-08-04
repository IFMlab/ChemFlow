#!/bin/bash


prepare_rescoring() {
# Check the ScoreFlow config file, make folders and write config files for rescoring

# Create a time stamp, in order to backup rescoring output directories if they already exists
datetime=$(date "+%Y%m%d%H%M%S")

# Check if everything is ok with the input.
check_input

# Depending on what the user wants to do (VS, BEST or PDB rescoring), take actions

# PDB rescoring mode
if [ "${mode}" = "PDB" ]; then
  # List complexes, create folder
  # and write plants config in each folder
  list_complexes
elif $(list_include_item "VS BEST" "${mode}"); then
  list_docking
fi
}


list_complexes() {
# List complexes, make folders and write the config files
# list all pdb files in the complex folder.
com_list=$(cd ${PDB_folder} ; ls *.pdb | sed s/.pdb//g )

if [ -z "${com_list}" ]; then
  echo -e "${RED}ERROR${NC} : Could not find pdb files in ${PDB_folder}"
  exit 1
fi

# Create an output folder per complex.
for com in ${com_list} ; do
  mkdir -p ${run_folder}/output/${scoring_function}_rescoring/${com}

  # And write the plants config file there.
  cd ${run_folder}/output/${scoring_function}_rescoring/${com}

  # Separate the complex in protein, ligand(s) and water mol2 files
  cd ${PDB_folder} # otherwise spores will add the path to the ligand name inside the file, which causes some bugs with PLANTS
  ${SPORES} --mode splitpdb ${com}.pdb > ${run_folder}/output/${scoring_function}_rescoring/${com}/spores.job 2>&1
 
  # Output is $PDB_folder, so we need to move it
  mv ${PDB_folder}/*.mol2 ${run_folder}/output/${scoring_function}_rescoring/${com}/
  
  # path to ligand and receptor
  lig=$(ls ${run_folder}/output/${scoring_function}_rescoring/${com}/ligand*.mol2 | sed s/.mol2//g)
  rec=$(ls ${run_folder}/output/${scoring_function}_rescoring/${com}/protein.mol2 | sed s/.mol2//g)
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
  cd ${run_folder}/output/${scoring_function}_rescoring/${com}
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
  cd ${run_folder}/output/${scoring_function}_rescoring/
  write_pbsa_config
fi

echo "Rescoring configuration finished                                               "

if [ -z "${com_list}" ]; then
  echo -e "${RED}ERROR${NC} : Could not find pdb files in ${PDB_folder}"    
  exit 1
fi
}



list_docking() {
# List docking results, make folders and write config files
# Receptor
filename=$(basename "${rec}")
extension="${filename##*.}"
if   [ "${extension}" = "pdb" ]  ; then rec=$(echo "${rec}" | sed s/.pdb//g)
elif [ "${extension}" = "mol2" ] ; then rec=$(echo "${rec}" | sed s/.mol2//g)
fi

# list all docking folders
if [ "${mode}" = "VS" ]; then
 dock_list=$(cd ${VS_folder} ; \ls -l | grep "^d" | awk '{print $9}')
elif [ "${mode}" = "BEST" ]; then
  dock_list=$(cd ${BEST_folder} ; \ls -l | grep "^d" | awk '{print $9}')
fi

# list all docking poses in the VS_folder
pose_list=""
for dock_folder in ${dock_list}; do
  if [ "${mode}" = "VS" ]; then
    poses_list=$(cd ${VS_folder}/${dock_folder}/docking/; \ls *conf*.mol2 | sed s/.mol2//g )
  elif [ "${mode}" = "BEST" ]; then
    poses_list=$(cd ${BEST_folder}/${dock_folder}/docking/; \ls *.mol2 | sed s/.mol2//g )
  fi
  
  for pose in ${poses_list}
  do
    lig_name=$(echo ${pose} | cut -d_ -f1)
    pose_list+=" ${lig_name}/${pose}/${dock_folder}"

    # And write the plants config file there.
    mkdir -p ${run_folder}/output/${scoring_function}_rescoring/${lig_name}/${pose}
    cd ${run_folder}/output/${scoring_function}_rescoring/${lig_name}/${pose}
    if [ "${mode}" = "VS" ]; then
      lig="${VS_folder}/${dock_folder}/docking/${pose}"
    elif [ "${mode}" = "BEST" ]; then
      lig="${BEST_folder}/${dock_folder}/docking/${pose}"
    fi
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
done

if [ "${rescore_method}" = "mmpbsa" ]; then
  cd ${run_folder}/output/${scoring_function}_rescoring/
  write_pbsa_config
fi

echo "Rescoring configuration finished                                               "

if [ -z "${pose_list}" ]
then
  if [ "${mode}" = "VS" ]; then
    echo -e "${RED}ERROR${NC} : Could not find mol2 docking poses in ${VS_folder}"    
  elif [ "${mode}" = "BEST" ]; then
    echo -e "${RED}ERROR${NC} : Could not find mol2 docking poses in ${BEST_folder}"
  fi
  exit 1
fi
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


write_plants_pbs() {
echo "#!/bin/bash
#PBS -N PLANTS_${pose_name}
#PBS -l nodes=1:ppn=1,walltime=24:00:00.00
#PBS -o ${run_folder}/output/${scoring_function}_rescoring/${common_folder}/${pose_name}.o
#PBS -e ${run_folder}/output/${scoring_function}_rescoring/${common_folder}/${pose_name}.e

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


run_plants() {
# Run PLANTS

# Create features.csv and ranking.csv headers
echo "LIGAND_ENTRY,TOTAL_SCORE,SCORE_RB_PEN,SCORE_NORM_HEVATOMS,SCORE_NORM_CRT_HEVATOMS,SCORE_NORM_WEIGHT,SCORE_NORM_CRT_WEIGHT,\
SCORE_RB_PEN_NORM_CRT_HEVATOMS,SCORE_NORM_CONTACT,EVAL,TIME">${run_folder}/output/${scoring_function}_rescoring/ranking.csv
echo "LIGAND_ENTRY,TOTAL_SCORE,SCORE_RB_PEN,SCORE_NORM_HEVATOMS,SCORE_NORM_CRT_HEVATOMS,SCORE_NORM_WEIGHT,SCORE_NORM_CRT_WEIGHT,\
SCORE_RB_PEN_NORM_CRT_HEVATOMS,SCORE_NORM_CONTACT,PLPtotal,PLPparthbond,PLPpartsteric,PLPpartmetal,PLPpartrepulsive,PLPpartburpolar,\
LIG_NUM_CLASH,LIG_NUM_CONTACT,LIG_NUM_NO_CONTACT,CHEMpartmetal,CHEMparthbond,CHEMparthbondCHO,DON,ACC,UNUSED_DON,UNUSED_ACC,\
CHEMPLP_CLASH2,TRIPOS_TORS,ATOMS_OUTSIDE_BINDINGSITE">${run_folder}/output/${scoring_function}_rescoring/features.csv

# List to iterate
if [ "${mode}" = "PDB" ]; then
  common_list="${com_list}"
elif $(list_include_item "VS BEST" "${mode}"); then
  common_list="${pose_list}"
fi

# Progress Bar
length=$(echo ${common_list} | wc -w)
progress_count=0

# Print a spinner on the screen while preparing the commands for parallel
if [ "${run_mode}" = "parallel" ]; then
  # Run a spinner in the background
  (while :; do for s in / - \\ \|; do printf "\rPreparing parallel $s";sleep .2; done; done) &
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
  elif $(list_include_item "VS BEST" "${mode}"); then
    common_folder=$(echo "${item}"    | cut -d"/" -f"1,2")
    lig_name=$(echo "$common_folder"  | cut -d"/" -f1)
    pose_name=$(echo "$common_folder" | cut -d"/" -f2)
    dock_folder=$(echo "${item}"      | cut -d"/" -f3)
  fi

  # Go to the rescoring folder
  cd ${run_folder}/output/${scoring_function}_rescoring/${common_folder}
  
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
    echo -n "cd ${run_folder}/output/${scoring_function}_rescoring/${common_folder}; \
    source ${CHEMFLOW_HOME}/ChemFlow.config; \
    source ${CHEMFLOW_HOME}/ScoreFlow/ScoreFlow_functions.bash; " >> ${run_folder}/output/${scoring_function}_rescoring/rescore_${datetime}.parallel
    CFvars=$(print_vars | sed ':a;N;$!ba;s/\n/; /g'); echo -n "${CFvars}" >> ${run_folder}/output/${scoring_function}_rescoring/rescore_${datetime}.parallel
    echo "; plants_cmd; \
    echo -n 0 >>${run_folder}/output/${scoring_function}_rescoring/.progress.dat" >> ${run_folder}/output/${scoring_function}_rescoring/rescore_${datetime}.parallel

  elif [ "${run_mode}" = "mazinger" ]; then
    write_plants_pbs
    jobid=$(qsub plants.pbs)
    echo "$jobid" >> ${run_folder}/output/${scoring_function}_rescoring/jobs_list_${datetime}.mazinger
    echo -ne "Running ${PURPLE}${pose_name}${NC} on ${BLUE}${jobid}${NC}              \r"
  fi
done
  
# Kill the spinner when the preparation of parallel is done, and run it !
if [ "${run_mode}" = "parallel" ]; then
  echo -e "\rFinished preparing parallel... Running"
  { kill $! && wait $!; } 2>/dev/null
  # Run the progress bar
  touch ${run_folder}/output/${scoring_function}_rescoring/.progress.dat
  (while :; do progress_count=$(cat ${run_folder}/output/${scoring_function}_rescoring/.progress.dat | wc -c); ProgressBar ${progress_count} ${length}; sleep 1; done) &
  # Run parallel
  ${parallel} -j ${core_number} < ${run_folder}/output/${scoring_function}_rescoring/rescore_${datetime}.parallel \
  > ${run_folder}/output/${scoring_function}_rescoring/parallel.job 2>&1
  # Kill the progress bar when parallel is done
  { printf '\n'; kill $! && wait $!; } 2>/dev/null
  rm -f ${run_folder}/output/${scoring_function}_rescoring/.progress.dat
fi
}

plants_cmd() {
# Run
${PLANTS} --mode rescore config.plants > plants.job 2>&1
# reorganize results
reorganize_plants
}

reorganize_plants() {
if [ -d results ]; then
  cd results
  mv protein_bindingsite_fixed.mol2 ${run_folder}/output/${scoring_function}_rescoring/
  # the command tail -n +2 skip the first line (containing the header), and starts printing at the 2nd line of the file
  # PLANTS appends _entry_XXX_conf_XX to the rescored poses in the csv tables, so we use sed 's/\(^.*_entry.*_conf.*\)_entry.*_conf_[[:digit:]]*\(,.*$\)/\1\2/g'
  # to remove this string from the names
  tail -n +2 features.csv | sed 's/\(^.*_entry.*_conf.*\)_entry.*_conf_[[:digit:]]*\(,.*$\)/\1\2/g'>> ${run_folder}/output/${scoring_function}_rescoring/features.csv
  tail -n +2 ranking.csv  | sed 's/\(^.*_entry.*_conf.*\)_entry.*_conf_[[:digit:]]*\(,.*$\)/\1\2/g'>> ${run_folder}/output/${scoring_function}_rescoring/ranking.csv
  cd ${run_folder}/output/${scoring_function}_rescoring/
  rm -rf ${common_folder}
  echo "${common_folder}" >> folders.txt
else
  echo "${pose_name},${dock_folder}" >> ${run_folder}/output/${scoring_function}_rescoring/errors.csv
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

write_vina_pbs() {
echo "#!/bin/bash
#PBS -N PLANTS_${pose_name}
#PBS -l nodes=1:ppn=1,walltime=24:00:00.00
#PBS -o ${run_folder}/output/${scoring_function}_rescoring/${common_folder}/${pose_name}.o
#PBS -e ${run_folder}/output/${scoring_function}_rescoring/${common_folder}/${pose_name}.e

#-----user_section-----------------------------------------------
module load vina

cd \$PBS_O_WORKDIR

source ${CHEMFLOW_HOME}/ChemFlow.config
source ${CHEMFLOW_HOME}/ScoreFlow/ScoreFlow_functions.bash

"> vina.pbs
print_vars >> vina.pbs
echo "
vina_cmd" >> vina.pbs
}

vina_cmd() {
# PDB mode
if [ "${mode}" = "PDB" ]; then
  # Prepare receptor
  ${ADT}/prepare_receptor4.py -r ${rec}.mol2 > convert2pdbqt.job
  # Prepare ligand
  ${ADT}/prepare_ligand4.py -l ${lig}.mol2 >> convert2pdbqt.job
# Mode BEST or VS
elif $(list_include_item "VS BEST" "${mode}"); then
  # Convert pose to pdbqt if it doesn't exist
  if [ ! -f ${run_folder}/input_files/lig/${lig_name}/${pose_name}.pdbqt ]; then
    mkdir -p ${run_folder}/input_files/lig/${lig_name}
    ${ADT}/prepare_ligand4.py -l ${folder}/${dock_folder}/docking/${pose_name}.mol2 >> convert2pdbqt.job
    mv ${pose_name}.pdbqt ${run_folder}/input_files/lig/${lig_name}
  fi
fi

# Run
${VINA} --score_only --config config.vina --log output.log > vina.job
# Reorganize files and output master csv table
reorganize_vina
}


run_vina() {
# Headers for the concatenated score file
echo "Ligand,Affinity,gauss_1,gauss_2,repulsion,hydrophobic,Hydrogen" > ${run_folder}/output/${scoring_function}_rescoring/ranking.csv

# List to iterate
if [ "${mode}" = "PDB" ]; then
  common_list="${com_list}"
elif $(list_include_item "VS BEST" "${mode}"); then
  common_list="${pose_list}"
fi

# Progress Bar
length=$(echo ${common_list} | wc -w)
progress_count=0

# Print a spinner on the screen while preparing the commands for parallel
if [ "${run_mode}" = "parallel" ]; then
  # Run a spinner in the background
  (while :; do for s in / - \\ \|; do printf "\rPreparing parallel $s";sleep .2; done; done) &
fi

# Convert receptor if it's not already done
if $(list_include_item "VS BEST" "${mode}") && [ ! -f ${rec}.pdbqt ]; then 
  cd $(dirname ${rec}.${extension})
  ${ADT}/prepare_receptor4.py -r ${rec}.${extension} > convert2pdbqt.job
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
  elif $(list_include_item "VS BEST" "${mode}"); then
    common_folder=$(echo "${item}"    | cut -d"/" -f"1,2")
    lig_name=$(echo "$common_folder"  | cut -d"/" -f1)
    pose_name=$(echo "$common_folder" | cut -d"/" -f2)
    dock_folder=$(echo "${item}"      | cut -d"/" -f3)
  fi

  # Go to the rescoring folder
  cd ${run_folder}/output/${scoring_function}_rescoring/${common_folder}

  # List ligands for complex mode
  if [ "${mode}" = "PDB" ]; then
    lig=$(ls ligand*.mol2 | sed s/.mol2//g)
    rec=$(ls protein.mol2 | sed s/.mol2//g)
  elif $(list_include_item "VS BEST" "${mode}"); then
    # Set folders, for pdbqt conversion
    if [ ${mode} = "VS" ]; then 
      folder="${VS_folder}"
    elif [ ${mode} = "BEST" ]; then 
      folder="${BEST_folder}"
    fi
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
    echo -n "cd ${run_folder}/output/${scoring_function}_rescoring/${common_folder}; \
    source ${CHEMFLOW_HOME}/ChemFlow.config; \
    source ${CHEMFLOW_HOME}/ScoreFlow/ScoreFlow_functions.bash; " >> ${run_folder}/output/${scoring_function}_rescoring/rescore_${datetime}.parallel
    CFvars=$(print_vars | sed ':a;N;$!ba;s/\n/; /g'); echo -n "${CFvars}" >> ${run_folder}/output/${scoring_function}_rescoring/rescore_${datetime}.parallel
    echo "; vina_cmd; \
    echo -n 0 >>${run_folder}/output/${scoring_function}_rescoring/.progress.dat" >> ${run_folder}/output/${scoring_function}_rescoring/rescore_${datetime}.parallel

  elif [ "${run_mode}" = "mazinger" ]; then
    write_vina_pbs
    jobid=$(qsub plants.pbs)
    echo "$jobid" >> ${run_folder}/output/${scoring_function}_rescoring/jobs_list_${datetime}.mazinger
    echo -ne "Running ${PURPLE}${pose_name}${NC} on ${BLUE}${jobid}${NC}              \r"
  fi
done

# Kill the spinner when the preparation of parallel is done, and run it !
if [ "${run_mode}" = "parallel" ]; then
  echo -e "\rFinished preparing parallel... Running"
  { kill $! && wait $!; } 2>/dev/null
  # Run the progress bar
  touch ${run_folder}/output/${scoring_function}_rescoring/.progress.dat
  (while :; do progress_count=$(cat ${run_folder}/output/${scoring_function}_rescoring/.progress.dat | wc -c); ProgressBar ${progress_count} ${length}; sleep 1; done) &
  # Run parallel
  ${parallel} -j ${core_number} < ${run_folder}/output/${scoring_function}_rescoring/rescore_${datetime}.parallel \
  > ${run_folder}/output/${scoring_function}_rescoring/parallel.job 2>&1
  # Kill the progress bar when parallel is done
  { printf '\n'; kill $! && wait $!; } 2>/dev/null
  rm -f ${run_folder}/output/${scoring_function}_rescoring/.progress.dat
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
  cat energy.csv >> ${run_folder}/output/${scoring_function}_rescoring/ranking.csv
  # remove the old files
  cd ${run_folder}/output/${scoring_function}_rescoring/
  rm -rf ${common_folder}
else
  echo "${pose_name},${dock_folder}" >> ${run_folder}/output/${scoring_function}_rescoring/errors.csv
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
# Run tleap

tleap -f tleap.cmd &>tleap.job
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

write_pbsa_pbs() {
# Write PBS script for MMPBSA

echo "#!/bin/bash
#PBS -N ${pose_name}
#PBS -l nodes=1:ppn=1,walltime=24:00:00.00
#PBS -o ${run_folder}/output/${scoring_function}_rescoring/${common_folder}/${pose_name}.o
#PBS -e ${run_folder}/output/${scoring_function}_rescoring/${common_folder}/${pose_name}.e

source ${amber} 

cd \$PBS_O_WORKDIR

source ${CHEMFLOW_HOME}/ChemFlow.config
source ${CHEMFLOW_HOME}/ScoreFlow/ScoreFlow_functions.bash

"> mmpbsa.pbs
print_vars >> mmpbsa.pbs
echo "
mmpbsa_cmd" >> mmpbsa.pbs
}


mmpbsa_cmd() {
# Preparation of files for MMPBSA, and running

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
  run_tleap
fi

# Run a quick minimization if asked by user
if [ ! -z "${min_steps}" ]; then
  # If the complex_before_min.rst7 file doesn't exist, run the minimization
  if [ ! -f ${run_folder}/input_files/com/${lig_name}/${pose_name}_no_min.rst7 ]; then
    mv ${run_folder}/input_files/com/${lig_name}/${pose_name}.pdb ${run_folder}/input_files/com/${lig_name}/${pose_name}_no_min.pdb
    mv ${run_folder}/input_files/com/${lig_name}/${pose_name}.rst7 ${run_folder}/input_files/com/${lig_name}/${pose_name}_no_min.rst7
    if [ "${min_type}" = "backbone" ]; then
      minab_mask=":${min_mask}:CA|:${min_mask}:N|:${min_mask}:C|:${min_mask}:O"
    else
      minab_mask="${min_mask}"
    fi
    # Minimize
    minab ${run_folder}/input_files/com/${lig_name}/${pose_name}_no_min.pdb \
    ${run_folder}/input_files/com/${lig_name}/${pose_name}.prmtop \
    ${run_folder}/input_files/com/${lig_name}/${pose_name}.pdb ${implicit_model} ${min_steps} \'${minab_mask}\' ${min_energy} > minab.job
    # Write trajectory from minimized pdb
    cpptraj -p ${run_folder}/input_files/com/${lig_name}/${pose_name}.prmtop \
    -y ${run_folder}/input_files/com/${lig_name}/${pose_name}.pdb \
    -x ${run_folder}/input_files/com/${lig_name}/${pose_name}.rst7
  fi
fi

# Calculation
if [ "${scoring_function}" = "PB3" ] ; then
  ante-MMPBSA.py -p ${run_folder}/input_files/com/${lig_name}/${pose_name}.prmtop \
  -c com.top -r rec.top -l lig.top -s \'${strip_mask}\' -n ${lig_mask}
  MMPBSA.py -O -i ${run_folder}/output/${scoring_function}_rescoring/${scoring_function}.in \
  -o MM${scoring_function::2}SA.dat -eo MM${scoring_function::2}SA.csv -cp com.top -rp rec.top -lp lig.top \
  -y ${run_folder}/input_files/com/${lig_name}/${pose_name}.rst7
else
  ante-MMPBSA.py -p ${run_folder}/input_files/com/${lig_name}/${pose_name}.prmtop \
  -c com.top -r rec.top -l lig.top -s \'${strip_mask}\' -n ${lig_mask} --radii=${radii}
  MMPBSA.py -O -i ${run_folder}/output/${scoring_function}_rescoring/${scoring_function}.in \
  -o MM${scoring_function::2}SA.dat -eo MM${scoring_function::2}SA.csv -cp com.top -rp rec.top -lp lig.top \
  -y ${run_folder}/input_files/com/${lig_name}/${pose_name}.rst7
fi

# Reorganize files and output master csv table
reorganize_mmpbsa
}

reorganize_mmpbsa() {
# if the output file exist
if [ -f MM${scoring_function::2}SA.csv ]; then
  # Get the values for all structures
  for structure in Ligand Receptor Complex DELTA
  do
    # We want to retrieve only the values in the MM-PB/GB-SA csv file
    # We identify the line corresponding to our structure with var="${structure} Energy Terms" '$0 ~ var'
    # At this point, we set the flag to true starting 2 lines after the match : {flag=1;getline;getline}
    # We then search for the last values for our structure, identified by an empty line : /^\s*$/
    # When we match this empty line, the flag is set to false for the remaining lines : {flag=0}
    # And we print the lines for which the flag was set to true : flag
    values=$(awk -v var="${structure} Energy Terms" '$0 ~ var {flag=1;getline;getline}/^\s*$/{flag=0}flag' MM${scoring_function::2}SA.csv)
    echo "${pose_name},${structure},${values}" >> energy.csv
  done
# Concatenate to ranking
cat energy.csv >> ${run_folder}/output/${scoring_function}_rescoring/ranking.csv
# remove the old files
cd ${run_folder}/output/${scoring_function}_rescoring/
rm -rf ${common_folder}

# if no output file was found
else
  echo "${pose_name},${dock_folder}" >> ${run_folder}/output/${scoring_function}_rescoring/errors.csv
fi
}


run_mmpbsa() {
# Run MMPBSA or MMGBSA

# Headers for the concatenated score file
# If the 2 first letters are PB
if [ "${scoring_function::2}" = "PB" ]; then
  echo "Ligand,Structure,Frame #,BOND,ANGLE,DIHED,UB,IMP,CMAP,VDWAALS,EEL,1-4 VDW,1-4 EEL,EPB,ENPOLAR,EDISPER,G gas,G solv,TOTAL" \
  > ${run_folder}/output/${scoring_function}_rescoring/ranking.csv
elif [ "${scoring_function::2}" = "GB" ]; then
  echo "Ligand,Structure,Frame #,BOND,ANGLE,DIHED,UB,IMP,CMAP,VDWAALS,EEL,1-4 VDW,1-4 EEL,EGB,ESURF,G gas,G solv,TOTAL" \
  > ${run_folder}/output/${scoring_function}_rescoring/ranking.csv
fi

# List to iterate
if [ "${mode}" = "PDB" ]; then
  common_list="${com_list}"
elif $(list_include_item "VS BEST" "${mode}"); then
  common_list="${pose_list}"
fi

# Progress Bar
length=$(echo ${common_list} | wc -w)
progress_count=0

# Print a spinner on the screen while preparing the commands for parallel
if [ "${run_mode}" = "parallel" ]; then
  # Run a spinner in the background
  (while :; do for s in / - \\ \|; do printf "\rPreparing parallel $s";sleep .2; done; done) &
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
  elif $(list_include_item "VS BEST" "${mode}"); then
    common_folder=$(echo "${item}"    | cut -d"/" -f"1,2")
    lig_name=$(echo "$common_folder"  | cut -d"/" -f1)
    pose_name=$(echo "$common_folder" | cut -d"/" -f2)
    dock_folder=$(echo "${item}"      | cut -d"/" -f3)
  fi

  # Go to the rescoring folder
  cd ${run_folder}/output/${scoring_function}_rescoring/${common_folder}

  # List ligands for complex mode
  if [ "${mode}" = "PDB" ]; then
    lig=$(ls ligand*.mol2 | sed s/.mol2//g)
    rec=$(ls protein.mol2 | sed s/.mol2//g)
  elif $(list_include_item "VS BEST" "${mode}"); then
    # Set folders, for amber files preparation
    if [ ${mode} = "VS" ]; then 
      folder="${VS_folder}"
    elif [ ${mode} = "BEST" ]; then 
      folder="${BEST_folder}"
    fi
    lig="${folder}/${dock_folder}/docking/${pose_name}"
  fi

  # Run
  if [ "${run_mode}" = "local" ]    ; then
    # Progress
    (ProgressBar ${progress_count} ${length}) &
    # Run
    mmpbsa_cmd
    # update progress bar
    let progress_count+=1
    # Kill the progress bar when plants is done
    { kill $! && wait $!; } 2>/dev/null

  elif [ "${run_mode}" = "parallel" ] ; then
    echo -n "cd ${run_folder}/output/${scoring_function}_rescoring/${common_folder}; \
    source ${CHEMFLOW_HOME}/ChemFlow.config; \
    source ${CHEMFLOW_HOME}/ScoreFlow/ScoreFlow_functions.bash; " >> ${run_folder}/output/${scoring_function}_rescoring/rescore_${datetime}.parallel
    CFvars=$(print_vars | sed ':a;N;$!ba;s/\n/; /g'); echo -n "${CFvars}" >> ${run_folder}/output/${scoring_function}_rescoring/rescore_${datetime}.parallel
    echo "; mmpbsa_cmd; \
    echo -n 0 >>${run_folder}/output/${scoring_function}_rescoring/.progress.dat" >> ${run_folder}/output/${scoring_function}_rescoring/rescore_${datetime}.parallel

  elif [ "${run_mode}" = "mazinger" ]; then
    write_mmpbsa_pbs
    jobid=$(qsub plants.pbs)
    echo "$jobid" >> ${run_folder}/output/${scoring_function}_rescoring/jobs_list_${datetime}.mazinger
    echo -ne "Running ${PURPLE}${pose_name}${NC} on ${BLUE}${jobid}${NC}              \r"
  fi
done

# Kill the spinner when the preparation of parallel is done, and run it !
if [ "${run_mode}" = "parallel" ]; then
  echo -e "\rFinished preparing parallel... Running"
  { kill $! && wait $!; } 2>/dev/null
  # Run the progress bar
  touch ${run_folder}/output/${scoring_function}_rescoring/.progress.dat
  (while :; do progress_count=$(cat ${run_folder}/output/${scoring_function}_rescoring/.progress.dat | wc -c); ProgressBar ${progress_count} ${length}; sleep 1; done) &
  # Run parallel
  ${parallel} -j ${core_number} < ${run_folder}/output/${scoring_function}_rescoring/rescore_${datetime}.parallel \
  > ${run_folder}/output/${scoring_function}_rescoring/parallel.job 2>&1
  # Kill the progress bar when parallel is done
  { printf '\n'; kill $! && wait $!; } 2>/dev/null
  rm -f ${run_folder}/output/${scoring_function}_rescoring/.progress.dat
fi
}