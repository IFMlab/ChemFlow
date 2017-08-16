#######################################################################
# Functions
#######################################################################

usage() {
echo -e "
Usage : LigFlow
                 -h|--help        : Show this help message and quit
                 -c|--cutoff      : Only the poses with a score below or equal to this cutoff will be extracted
                                    Default : 0
                -np|--nbposes     : Restrict preparation to the X best poses per ligand
                                    Default : 1
                 -d|--docking     : Path to the docking folder
                                    Default : $PWD/docking
                -at|--atomtype    : gaff, gaff2, amber, bcc, sybyl
                                    Default : None. Keep existing atom types
                -ch|--charge      : Gasteiger (gas), AM1-BCC (bcc) or RESP (resp).
                                    Default : None. Keep existing charges
                 -p|--purge       : Delete all previous ligands configuration
                 -a|--amber       : Prepare frcmod and lib files for amber
               -rst|--restart     : Restart from errors.csv
                 -r|--run         : local, parallel (not for RESP charges), mazinger
                -cn|--corenumber  : Number of cores for parallel, mazinger, and/or RESP charges.
                                    Default : 8
               -mem|--memory      : Memory allocated for computing RESP charges. Default : 8GB
               -max|--maxsub      : Maximum number of jobs to submit to mazinger.
                                    Default : None. 1 job per pose

Please use the ${RED}--purge${NC} option before running any new calculation.
To try recovering from errors with the --restart option, please re-enter the run mode, and if you are running locally, please re-enter the full parameters.
"
}

LigFlow_CLI() {
# Command line interface
while [[ $# -gt 0 ]]; do
key="$1"

case $key in
    -h|--help)
    usage
    exit
    ;;
    -c|--cutoff)
    cutoff="$2"
    shift # past argument
    ;;
    -np|--nbposes)
    nb_poses="$2"
    shift # past argument
    ;;
    -d|--docking)
    path="$2"
    shift # past argument
    ;;
    -at|--atomtype)
    atom_type="$2"
    shift # past argument
    ;;
    -ch|--charge)
    charge_method="$2"
    shift # past argument
    ;;   
    -mem|--memory)
    memory="$2"
    shift
    ;; 
    -cn|--corenumber)
    core_number="$2"
    shift
    ;; 
    -r|--run)
    run_mode="$2"
    shift
    ;;
    -p|--purge)
    purge="true"
    ;; 
    -a|--amber)
    amber_flag="true"
    ;; 
    -rst|--restart)
    restart_from_errors="true"
    ;;
    -max|--maxsub)
    max_submissions="$2"
    shift
    ;;
    # Hidden option, for dev
    -pp|--purgeonly)
    purge_only="true"
    ;;
    *)
    unknown="$1" # unknown option
    echo "Unknown flag \"$unknown\". Aborting."
    exit 1
    ;;
esac
shift # past argument or value
done

# Default values
if [ -z ${path} ];             then path=$PWD/docking  ; fi
if [ -z ${cutoff} ];           then cutoff=0           ; fi
if [ -z ${nb_poses} ];         then nb_poses=1         ; fi
if [ -z ${memory} ];           then memory="8GB"       ; fi
if [ -z ${core_number} ];      then core_number=8      ; fi
if [ -z ${run_mode} ];         then run_mode="local"   ; fi
}

write_pbs_header() { # Write the job
echo "#!/bin/bash
#PBS -V
#PBS -l  nodes=1:ppn=${core_number},walltime=24:00:00
#PBS -N  ligflow_${identifier}
#PBS -o  ${run_folder}/pbs_scripts/ligflow_${identifier}.o
#PBS -e  ${run_folder}/pbs_scripts/ligflow_${identifier}.e

source $CHEMFLOW_HOME/common/LigFlow_functions.bash
" > ${run_folder}/pbs_scripts/ligflow_${identifier}.pbs
}

write_pbs() { # Write the job
echo "
#---------------------
" >> ${run_folder}/pbs_scripts/ligflow_${identifier}.pbs
print_vars >> ${run_folder}/pbs_scripts/ligflow_${identifier}.pbs
echo "
run_preparation
" >> ${run_folder}/pbs_scripts/ligflow_${identifier}.pbs
}

list_poses() {
# Make a list of poses and the folders containing them

# Run a spinner in the background
(while :; do for s in / - \\ \|; do printf "\rSelecting poses $s";sleep .2; done; done) &

# List folders
dock_list=$(cd ${path}; \ls -l | grep "^d" | awk '{print $9}')

# List of docking poses and folder
for dock_folder in ${dock_list}
do
  # List ligands in folder
  lig_list=$(cd ${path}/${dock_folder}; \ls *.mol2 | sed 's/.mol2//g' | cut -d_ -f1 | uniq)

  for lig in ${lig_list}
  do
    # Create input folder
    mkdir -p ${run_folder}/input_files/lig/${lig}/

    # awk -F, -v cutoff=${cutoff} -v lig="${lig}_" : set variables and delimiters for awk
    # '{if (($2 <= cutoff) : if the score is below or equal to the cutoff
    # && ($1 ~ lig)) : AND if the ligand name's matches lig
    # -> print the name of the pose
    # we can then restrict this selection to the number of poses desired by the user with sed "1,${nb_poses} (equivalent to head -${nb_poses})
    # s/^/${dock_folder},${lig},/gp : insert the docking folder and name of the ligand at the begining of each matched row
    # the result is appended to the pose list with a newline
    selected=$(awk -F, -v cutoff=${cutoff} -v lig="${lig}_" \
                          '{if (($2 <= cutoff) && ($1 ~ lig)) {print $1}}' ${path}/ranking_sorted.csv \
                          | sed -n "1,${nb_poses}s/^/${dock_folder},${lig},/gp" )
    poses_selected_list+=$(echo -e "\n${selected}")
  done
done

# Kill spinner
echo -e "\rFinished selecting docking poses..."
{ kill $! && wait $!; } 2>/dev/null

}


prepare_poses() {
# Creates a new directory with poses prepared to the user's preference.
# The folder created has the same organization that the docking folder :
# folders named as the mol2 files used for docking.
# Each folder contains the prepared mol2 docking poses.

# counts the number of docking poses extracted
progress_count=0
length=$(echo "${poses_selected_list}" | wc -l)

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

# for each selected poses               
for item in ${poses_selected_list}
do
  # Variable names
  dock_folder=$(echo "${item}" | cut -d, -f1)
  lig=$(        echo "${item}" | cut -d, -f2)
  pose=$(       echo "${item}" | cut -d, -f3)

  # Remove old preparation of ligand before running
  if [ "${purge}" = "true" ]; then
    purge_ligands
  fi

  # If the user only wants to extract the poses
  if [ -z "${atom_type}" ] && [ -z "${charge_method}" ]; then
    # Progress in background
    (ProgressBar ${progress_count} ${length}) &
    # Create a symbolic link to the selected pose
    ln -s ${path}/${dock_folder}/${pose}.mol2 ${run_folder}/input_files/lig/${lig}/${pose}.mol2
    # Count number of poses prepared
    let progress_count+=1
    # Kill the progress bar when done
    { kill $! && wait $!; } 2>/dev/null

  # If the user wants to change the current atom types or charges
  else
    # Run
    if [ "${run_mode}" = "local" ]    ; then
      # Progress in background
      (ProgressBar ${progress_count} ${length}) &
      # Run
      run_preparation
      # update progress bar
      let progress_count+=1
      # Kill the progress bar when done
      { kill $! && wait $!; } 2>/dev/null
  
    elif [ "${run_mode}" = "parallel" ] ; then
      echo -n "source $CHEMFLOW_HOME/common/LigFlow_functions.bash; " >> ${run_folder}/LigFlow_${datetime}.parallel
      CFvars=$(print_vars | sed ':a;N;$!ba;s/\n/; /g'); echo -n "${CFvars}" >> ${run_folder}/LigFlow_${datetime}.parallel
      echo "; run_preparation; \
      echo -n 0 >> ${run_folder}/.progress.dat" >> ${run_folder}/LigFlow_${datetime}.parallel
  
    elif [ "${run_mode}" = "mazinger" ]; then
      if [ -z "${max_submissions}" ]; then
        identifier=${pose}
        write_pbs
        jobid=$(qsub ${run_folder}/pbs_scripts/ligflow_${identifier}.pbs)
        echo "$jobid" >> ${run_folder}/jobs_list_${datetime}.mazinger
        echo -ne "Running ${PURPLE}${pose}${NC} on ${BLUE}${jobid}${NC}              \r"
      else
        let progress_count+=1
        mazinger_current=$(mazinger_submitter ${pbs_count} ${max_jobs_pbs} ${progress_count} ${length} ${run_folder}/pbs_scripts/ligflow write_pbs)
        pbs_count=$( echo "${mazinger_current}" | cut -d, -f1)
        identifier=$(echo "${mazinger_current}" | cut -d, -f2)
        test_jobid=$(echo "${mazinger_current}" | cut -d, -f3)
        if [ ! -z "${test_jobid}" ]; then 
          jobid=${test_jobid}
          echo "$jobid" >> ${run_folder}/jobs_list_${datetime}.mazinger
          echo -ne "Running ${PURPLE}PBS script #${identifier}${NC} on ${BLUE}${jobid}${NC}              \r"
        fi
      fi
    fi
  fi
done

# Kill the spinner when the preparation of parallel is done, and run it !
if [ "${run_mode}" = "parallel" ]; then
  echo -e "\rFinished preparing parallel... Running"
  { kill $! && wait $!; } 2>/dev/null
  # Run the progress bar
  touch ${run_folder}/.progress.dat
  (while :; do progress_count=$(cat ${run_folder}/.progress.dat | wc -c); ProgressBar ${progress_count} ${length}; sleep 1; done) &
  # Run parallel
  ${parallel} -j ${core_number} < ${run_folder}/LigFlow_${datetime}.parallel \
  > ${run_folder}/LigFlow_${datetime}.parallel.job 2>&1
  # Kill the progress bar when parallel is done
  { printf '\n'; kill $! && wait $!; } 2>/dev/null
  rm -f ${run_folder}/.progress.dat

elif [ "${run_mode}" = "local" ]; then
  echo ""

# If running on mazinger, wait untill all jobs are finished
elif [ "${run_mode}" = "mazinger" ] ; then
  if [ ! "${purge_only}" = "true" ]; then 
    mazinger_progress_bar ${run_folder}/jobs_list_${datetime}.mazinger
  fi
  
fi
}

run_preparation() {
# Run ligand parametrization for a given force field and charge method
source ${amber}

# prepare each pose into a separate subfolder, to avoid overwriting intermediate files
mkdir -p ${run_folder}/input_files/${pose}
cd ${run_folder}/input_files/${pose}

if [ ! -f ${run_folder}/input_files/lig/${lig}/${pose}.mol2 ]; then
  # Get the number of atoms in compound
  # sed -n '/@<TRIPOS>MOLECULE/,+2 : return lines from @<TRIPOS>MOLECULE to 2 lines after
  # {} : run the following command for this selection
  # 3s///p : search and replace, on line 3, for something, and print 
  # s/\([0-9]\+\).*/\1/p : search for a number followed by other characters, return only the number
  nb_atoms=$(sed -n '/@<TRIPOS>MOLECULE/,+2{3s/\([0-9]\+\).*/\1/p}' ${path}/${dock_folder}/${pose}.mol2)
  
  if [ ${nb_atoms} -le 100 ]; then
    if [ "${charge_method}" = "resp" ]; then
      # MOL2 to Gaussian (GAFF atom types)
      antechamber \
        -i ${path}/${dock_folder}/${pose}.mol2               -fi mol2 \
        -o ${run_folder}/input_files/lig/${lig}/${pose}.gau  -fo gcrt \
        -gv 1 -ge lig.gesp -gm "%mem=${memory}" -gn "%nproc=${core_number}" \
        -s 2 -eq 2 -rn MOL -pf y \
        -at ${atom_type} > ${run_folder}/input_files/lig/${lig}/${pose}.antechamber_gauss.job
      
      # Run Gaussian to optimize structure and generate electrostatic potential grid
      g09 ${run_folder}/input_files/lig/${lig}/${pose}.gau > ${run_folder}/input_files/lig/${lig}/${pose}.gaussian.job
      
      # Read Gaussian output and write new optimized ligand with RESP charges
      antechamber \
        -i lig.log -fi gout \
        -o ${run_folder}/input_files/lig/${lig}/${pose}.mol2 -fo mol2 \
        -c ${charge_method} -s 2 -rn MOL -pf y \
        -at ${atom_type} > ${run_folder}/input_files/lig/${lig}/${pose}.antechamber.job

    else
      antechamber \
        -i ${path}/${dock_folder}/${pose}.mol2               -fi mol2 \
        -o ${run_folder}/input_files/lig/${lig}/${pose}.mol2 -fo mol2 \
        -s 2 -rn MOL -pf y \
        -at ${atom_type} -c ${charge_method} > ${run_folder}/input_files/lig/${lig}/${pose}.antechamber.job
    fi

  else
    # For large compounds, convergency is harder to reach
    # antechamber recommands to put between 10 and 30 after the -pl flag for these compounds
    # The calculation will thus take longer to run.
    if [ "${charge_method}" = "resp" ]; then
      # MOL2 to Gaussian (GAFF atom types)
      antechamber \
        -i ${path}/${dock_folder}/${pose}.mol2               -fi mol2 \
        -o ${run_folder}/input_files/lig/${lig}/${pose}.gau  -fo gcrt \
        -gv 1 -ge lig.gesp -gm "%mem=${memory}" -gn "%nproc=${core_number}" \
        -s 2 -eq 2 -rn MOL -pf y \
        -at ${atom_type} > ${run_folder}/input_files/lig/${lig}/${pose}.antechamber_gauss.job
      
      # Run Gaussian to optimize structure and generate electrostatic potential grid
      g09 ${run_folder}/input_files/lig/${lig}/${pose}.gau > ${run_folder}/input_files/lig/${lig}/${pose}.gaussian.job
      
      # Read Gaussian output and write new optimized ligand with RESP charges
      antechamber \
        -i lig.log -fi gout \
        -o ${run_folder}/input_files/lig/${lig}/${pose}.mol2 -fo mol2 \
        -c ${charge_method} -s 2 -rn MOL -pf y \
        -at ${atom_type} > ${run_folder}/input_files/lig/${lig}/${pose}.antechamber.job
    else
      antechamber \
        -i ${path}/${dock_folder}/${pose}.mol2               -fi mol2 \
        -o ${run_folder}/input_files/lig/${lig}/${pose}.mol2 -fo mol2 \
        -s 2 -rn MOL -pf y -pl 30 \
        -at ${atom_type} -c ${charge_method} > ${run_folder}/input_files/lig/${lig}/${pose}.antechamber.job
    fi
  fi
  if [ -f ${run_folder}/input_files/lig/${lig}/${pose}.mol2 ]; then
    rm -f ${run_folder}/input_files/lig/${lig}/${pose}.*.job
    rm -f ${run_folder}/sqm.*
  else
    echo "${dock_folder},${pose},antechamber" >> ${run_folder}/errors.csv
  fi
fi

if [ "${amber_flag}" = "true" ]; then
  if [ ! -f ${run_folder}/input_files/lig/${lig}/${pose}.frcmod ]; then
    if [ -f ${run_folder}/input_files/lig/${lig}/${pose}.mol2 ]; then
      # Remove useless output files
      rm -f ${run_folder}/input_files/lig/${lig}/${pose}.antechamber_gauss.job \
            ${run_folder}/input_files/lig/${lig}/${pose}.gaussian.job \
            ${run_folder}/input_files/lig/${lig}/${pose}.antechamber.job \
            lig.log lig.gesp
  
      # Create frcmod
      parmchk2 -i ${run_folder}/input_files/lig/${lig}/${pose}.mol2 -f mol2 \
               -o ${run_folder}/input_files/lig/${lig}/${pose}.frcmod
    fi
  fi
  
  if [ ! -f ${run_folder}/input_files/lig/${lig}/${pose}.lib ]; then
    if [ -f ${run_folder}/input_files/lig/${lig}/${pose}.frcmod ]; then
      # Create lib
      echo "source leaprc.gaff
      loadAmberParams ${run_folder}/input_files/lig/${lig}/${pose}.frcmod
      MOL = loadMol2  ${run_folder}/input_files/lig/${lig}/${pose}.mol2
      saveOff MOL     ${run_folder}/input_files/lig/${lig}/${pose}.lib
      quit
      " > tleap_lig.in
      tleap -f tleap_lig.in > tleap.job
    else
      echo "${dock_folder},${pose},parmchk2" >> ${run_folder}/errors.csv
    fi
    
    if [ -f  ${run_folder}/input_files/lig/${lig}/${pose}.lib ]; then
      rm -f tleap_lig.in leap.log tleap.job
    else
      echo "${dock_folder},${pose},tleap" >> ${run_folder}/errors.csv
    fi
  fi
fi

# remove temporary folder for preparation
rm -rf ${run_folder}/input_files/${pose}
}

purge_ligands() {
rm -f ${run_folder}/input_files/lig/${lig}/${pose}.{mol2,gau,frcmod,lib}
}

only_purge_ligands() {
# for each selected poses               
rm -f ${run_folder}/input_files/lig/*/*.{mol2,gau,frcmod,lib}
}

error_restart() {
# if errors were detected, rerun

if [ -f ${run_folder}/errors.csv ]; then
  # Copy the old error file, as it will be overwritten
  mv ${run_folder}/errors.csv ${run_folder}/old_errors.csv

  # Loop
  for line in $(cat old_errors.csv)
  do 
    # Variables
    dock_folder=$(echo ${line} | cut -d, -f1)
    pose=$(       echo ${line} | cut -d, -f2)
    lig=$(        echo ${pose} | cut -d_ -f1)

    # Run
    if [ "${run_mode}" = "local" ]; then
      echo -ne "Restarting ${pose}             \r"
      run_preparation

    elif [ "${run_mode}" = "parallel" ]; then
      # Run command for parallel
      command=$(grep ${pose} LigFlow_*.parallel)
      echo "${command}" >> ${run_folder}/LigFlow.restart.parallel

    elif [ "${run_mode}" = "mazinger" ]; then
      jobid=$(qsub pbs_scripts/${pose}.pbs)
      echo "$jobid" >> ${run_folder}/jobs_list_${datetime}.mazinger
      echo -ne "Running ${PURPLE}${pose}${NC} on ${BLUE}${jobid}${NC}              \r"

    fi
  done
fi

# Parallel
if [ "${run_mode}" = "parallel" ]; then
  # Run the progress bar
  touch ${run_folder}/.progress.dat
  (while :; do progress_count=$(cat ${run_folder}/.progress.dat | wc -c); ProgressBar ${progress_count} ${length}; sleep 1; done) &
  # Run parallel
  ${parallel} -j ${core_number} < ${run_folder}/LigFlow.restart.parallel \
  > ${run_folder}/LigFlow.restart.parallel.job 2>&1
  # Kill the progress bar when parallel is done
  { printf '\n'; kill $! && wait $!; } 2>/dev/null
  rm -f ${run_folder}/.progress.dat
fi

# Check errors
if [ -f ${run_folder}/errors.csv ]; then
  errorcount=$(cat ${run_folder}/errors.csv | wc -l)
  echo -e "${RED}ERRORS detected${NC} : ${errorcount}"
  echo "See errors.csv for more info"
else
  rm -f LigFlow_*.parallel.job LigFlow_*.parallel
  rm -f ${run_folder}/old_errors.csv
fi
}