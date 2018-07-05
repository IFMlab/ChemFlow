#!/usr/bin/env bash
###############################################################################
## ChemFlow - Computational Chemistry is Great Again
##
## Complies with:
## The ChemFlow standard version 1.0
## 
## Routine:
## DockFlow_init
##
## Brief:
## Initializes DockFlow variables and reads input.
##
## Description: 
## Initializes all DockFlow variables, then reads user input from command line or 
## from a configuration file.
##
## Author:
## dgomes    - Diego Enry Barreto Gomes - dgomes@pq.cnpq.br
## cbouysset - Cedric Bouysset - cbouysset@unice.fr
## 
## Last Update: (date, by who and where ) 
## vendredi 25 mai 2018, 13:54:40 (UTC+0200) by dgomes @ Universite de Strasbourg.
##
###############################################################################


DockFlow_archive() {

PROJECT=$(echo ${PROJECT} | cut -d. -f1)

if [ -z ${RUNDIR} ] ; then 
  echo "RUNDIR = ${RUNDIR}"
  exit 0
fi

cd ${RUNDIR}

echo "[ DockFlow ] Archiving the docking folders into: 
${RUNDIR}/docked_folder.tar.gz 
"

tar cfz docked_folder.tar.gz */

if [ -f docked_folder.tar.gz ] ; then 
  echo "[ DockFlow ] Archiving complete"
  
  read -p "[ DockFlow ] Remove docking folders in ${RUNDIR} ? " opt
  case $opt in
  "y"|"yes"|"Yes"|"Y"|"YES")
    rm -rf ${RUNDIR}/*/ 
    echo "[ DockFlow ] Done removing docking folders."
  ;;
  esac
  
else
  echo "[ DockFlow ] Archiving failed"
fi
 
}

DockFlow_summary() {
echo "
DockFlow summary:
-------------------------------------------------------------------------------
[ General info ]
    HOST ${HOSTNAME}
    USER ${USER}
 PROJECT ${PROJECT}
PROTOCOL ${PROTOCOL}
 WORKDIR ${PWD} 

[ Docking setup ]
RECEPTOR Name: ${RECEPTOR_NAME}
RECEPTOR File: ${RECEPTOR_FILE}
  LIGAND ${LIGAND_FILE}
NLIGANDS ${NLIGANDS}
  NPOSES ${DOCK_POSES}
 PROGRAM ${DOCK_PROGRAM}
 SCORING ${SCORING_FUNCTION}
  CENTER ${DOCK_CENTER[@]}"
case ${DOCK_PROGRAM} in
 "VINA") echo "    SIZE ${DOCK_LENGHT[@]} (X,Y,Z)" ;;
      *) echo "  RADIUS ${DOCK_RADIUS}"
esac

echo "
[ Run options ]
JOB SCHEDULLER: ${JOB_SCHEDULLER}
    CORES/NODE: ${NCORES}
         NODES: ${NNODES}
         
     OVERWRITE: ${OVERWRITE}
"
read -p "
Continue [Y/N] ? : " opt

case $opt in 
"Y"|"YES"|"Yes"|"yes"|"y")  ;;
*)  echo "Exiting" ; exit 0 ;;
esac
}



DockFlow_write_plants_config() {
#===  FUNCTION  ================================================================
#          NAME: DockFlow_write_plants_config_input
#   DESCRIPTION: Writes the PLANTS input file for each ligand. 
#                Input/Output filenames are hardcoded to comply with standard.
#                
#    PARAMETERS: ${RUNDIR}
#                ${LIGAND}
#                ${SCORING_FUNCTION}
#                ${DOCK_CENTER}
#                ${DOCK_RADIUS}
#                ${DOCK_POSES}
#       RETURNS: -
#
#          TODO: Allow "extra PLANTS keywords from cmd line"
#===============================================================================

echo "
# input files
protein_file ../receptor.mol2
ligand_file  ligand.mol2

# output
output_dir PLANTS

# scoring function and search settings
scoring_function ${SCORING_FUNCTION}
search_speed speed1

# write mol2 files as a single (1) or multiple (0) mol2 files
write_multi_mol2 1

# binding site definition
bindingsite_center ${DOCK_CENTER[@]}
bindingsite_radius ${DOCK_RADIUS}

# cluster algorithm, save the best DOCK_POSES.
cluster_structures ${DOCK_POSES}
cluster_rmsd 2.0

# write 
write_ranking_links 0
write_protein_bindingsite 1
write_protein_conformations 0
####
" > ${RUNDIR}/${LIGAND}/dock_input.in
}


DockFlow_write_slurm() {
#===  FUNCTION  ================================================================
#          NAME: write_slurm
#   DESCRIPTION: Writes the SLURM script to for each ligand (or range of ligands).
#                Filenames and parameters are hardcoded.
#    PARAMETERS: 
#               ${list[@]}  -   Array with all ligand names
#               ${first}    -   First ligand in the array
#               ${$nlig}    -   Number of compounds to dock
#               ${NNODES}   -   Number of compute nodes to use
#               ${NCORES}   -   Number of cores/node
#               ${NTHREADS} -   Total threads (NNODES*NCORES)
#
#          NOTE: Must be run while at "${RUNDIR}
#       RETURNS: -
#===============================================================================
echo "#! /bin/bash
# 1 noeud 8 coeurs
#SBATCH -p public
#SBATCH --job-name=PLANTS_${first}
#SBATCH -N ${NNODES}
#SBATCH -n ${NTHREADS}
#SBATCH -t 0:30:00

#Write the full DockFlow_write_plants_config function here.
$(declare -f DockFlow_write_plants_config)

RUNDIR=${RUNDIR}
cd ${RUNDIR}

DOCK_PROGRAM=${DOCK_PROGRAM}
DOCK_CENTER=\"${DOCK_CENTER[@]}\"
DOCK_RADIUS=${DOCK_RADIUS}
DOCK_POSES=${DOCK_POSES}
SCORING_FUNCTION=${SCORING_FUNCTION}

if [ -f ${first}.parallel ] ; then rm -rf ${first}.parallel ; fi

for LIGAND in ${DOCK_LIST[@]:$first:$nlig} ; do

  DockFlow_write_plants_config

  echo \"cd ${RUNDIR}/\${LIGAND} ; PLANTS1.2_64bit --mode screen dock_input.in &> docking.log ; rm -rf PLANTS/{protein.log,descent_ligand_1.dat,protein_bindingsite_fixed.mol2}\" >> ${first}.xargs

done

cat ${first}.xargs | xargs -P${NCORES} -I '{}' bash -c '{}'

"> plants.slurm
}


DockFlow_write_pbs() {
#===  FUNCTION  ================================================================
#          NAME: write_pbs
#   DESCRIPTION: Writes the PBS script to for each ligand (or range of ligands).
#                Filenames and parameters are hardcoded.
#    PARAMETERS: 
#               ${list[@]}  -   Array with all ligand names
#               ${first}    -   First ligand in the array
#               ${$nlig}    -   Number of compounds to dock
#               ${NNODES}   -   Number of compute nodes to use
#               ${NCORES}   -   Number of cores/node
#               ${NTHREADS} -   Total threads (NNODES*NCORES)
#
#          NOTE: Must be run while at "${RUNDIR}
#       RETURNS: -
#===============================================================================
echo "#! /bin/bash
# 1 noeud 8 coeurs
#PBS -p public
#PBS -j PLANTS_${first}
#PBS -l nodes=${NNODES}:ppn=${NTHREADS}
#PBS -l walltime=0:30:00

#Write the full DockFlow_write_plants_config function here.
$(declare -f DockFlow_write_plants_config)

RUNDIR=${RUNDIR}
cd ${RUNDIR}

DOCK_PROGRAM=${DOCK_PROGRAM}
DOCK_CENTER=\"${DOCK_CENTER[@]}\"
DOCK_RADIUS=${DOCK_RADIUS}
DOCK_POSES=${DOCK_POSES}
SCORING_FUNCTION=${SCORING_FUNCTION}

if [ -f ${first}.parallel ] ; then rm -rf ${first}.parallel ; fi

for LIGAND in ${DOCK_LIST[@]:$first:$nlig} ; do

  DockFlow_write_plants_config

  echo \"cd ${RUNDIR}/\${LIGAND} ; PLANTS1.2_64bit --mode screen dock_input.in &> docking.log ; rm -rf PLANTS/{protein.log,descent_ligand_1.dat,protein_bindingsite_fixed.mol2}\" >> ${first}.xargs

done

cat ${first}.xargs | xargs -P${NCORES} -I '{}' bash -c '{}'

"> plants.pbs
}

DockFlow_PostDock_PlantsResults() {
    #===  FUNCTION  ================================================================
    #          NAME: DockFlow_PostDock_PlantsResults
    #   DESCRIPTION: Post processing DockFlow runs while using plants.
    #                Extract results and organize files to ChemFlow standard.
    #                Each project will have a single RANK.csv
    #
    #    PARAMETERS: ${PROJECT}
    #
    #          NOTE: Must be run while at "${RUNDIR}
    #       RETURNS: rank.csv, top.csv
    #
    #        Author: Diego E. B. Gomes
    #                Cedric Bouysset
    #
    #        UPDATE: mar. mai 29 14:49:50 CEST 2018
    #
    #          TODO: A summary of protocols would be interesting
    #===============================================================================

    PROJECT=$(echo ${PROJECT} | cut -d. -f1)

    # Start up going to the project folder.
    DOCKFLOW_FOLDER=${WORKDIR}/${PROJECT}.chemflow/DockFlow
    cd ${WORKDIR}/${PROJECT}.chemflow/DockFlow

    # Retrieve available protocols
    PROTOCOL_LIST=$(ls -d */ | cut -d/ -f1)

    # STUPID fix this DIEGO !
    PROTOCOL_LIST=${PROTOCOL}
    PROTOCOL_LIST=(${PROTOCOL_LIST})
    NPROTOCOLS=${#PROTOCOL_LIST}

    for PROTOCOL in ${PROTOCOL_LIST[@]}  ; do

      # Start up going to the project folder.
      cd ${WORKDIR}/${PROJECT}.chemflow/DockFlow/${PROTOCOL}

      RECEPTOR_LIST=$(ls -d */| cut -d/ -f1)
      RECEPTOR_LIST=(${RECEPTOR_LIST})
      echo "Receptors: ${RECEPTOR_LIST[@]}"


      for RECEPTOR in ${RECEPTOR_LIST[@]} ; do

        cd ${WORKDIR}/${PROJECT}.chemflow/DockFlow/${PROTOCOL}/${RECEPTOR}
        # Cleanup ------------------------------------------------
        if [ -f rank.csv ] ; then rm rank.csv ; fi
        if [ -f docked_ligands.mol2 ] ; then rm docked_ligands.mol2 ; fi

        LIGAND_LIST=$(ls -d */| cut -d/ -f1)
        LIGAND_LIST=(${LIGAND_LIST})
        #echo "Ligands: ${LIGAND_LIST[@]}"

        if [ -f  ${RECEPTOR}/docked_ligands.mol2 ] ; then
          rm -rf ${RECEPTOR}/docked_ligands.mol2
        fi

        echo "DOCK_PROGRAM PROTOCOL LIGAND POSE SCORE" > rank.csv

        # Organize to ChemFlow standard.
        for LIGAND in ${LIGAND_LIST[@]}; do

          # PLANTS -----------------------------------------------------------
          if [ -f ${LIGAND}/PLANTS/docked_ligands.mol2 ] ; then
            echo -ne "PostDock: ${PROTOCOL} - ${LIGAND}        \r"
            awk -v protocol=${PROTOCOL} -v target=${RECEPTOR_NAME} -v ligand=${LIGAND} -F, '!/LIGAND_ENTRY/ {print "PLANTS",protocol,target,ligand,$1,$2}' ${LIGAND}/PLANTS/ranking.csv >> rank.csv
            cat ${LIGAND}/PLANTS/docked_ligands.mol2 >> docked_ligands.mol2
          fi
        done
      done
    done

    #grep -v not rank.tmp > rank.csv

    echo "[ DockFlow ] Done with post-processing."
    # Archiving.
    read -p "[ DockFlow ] Archive the docking results (folders) in a TAR file? " opt
    case $opt in
    "y"|"yes"|"Yes"|"Y"|"YES")
      DockFlow_archive
    ;;
    esac
}

DockFlow_PostDock_VinaResults() {
    #===  FUNCTION  ================================================================
    #          NAME: DockFlow_PostDock_VinaResults
    #   DESCRIPTION: Post processing DockFlow runs while using vina.
    #                Extract results and organize files to ChemFlow standard.
    #                Each project will have a single RANK.csv
    #
    #    PARAMETERS: ${PROJECT}
    #
    #          NOTE: Must be run while at "${RUNDIR}
    #       RETURNS: rank.csv, top.csv
    #
    #        Author: Diego E. B. Gomes
    #                Cedric Bouysset
    #
    #        UPDATE: mar. mai 29 14:49:50 CEST 2018
    #
    #          TODO: A summary of protocols would be interesting
    #===============================================================================
    exit 0;
#    PROJECT=$(echo ${PROJECT} | cut -d. -f1)
#
#    # Start up going to the project folder.
#    DOCKFLOW_FOLDER=${WORKDIR}/${PROJECT}.chemflow/DockFlow
#    cd ${WORKDIR}/${PROJECT}.chemflow/DockFlow
#
#    # Retrieve available protocols
#    PROTOCOL_LIST=$(ls -d */ | cut -d/ -f1)
#
#    # STUPID fix this DIEGO !
#    PROTOCOL_LIST=${PROTOCOL}
#    PROTOCOL_LIST=(${PROTOCOL_LIST})
#    NPROTOCOLS=${#PROTOCOL_LIST}
#
#    for PROTOCOL in ${PROTOCOL_LIST[@]}  ; do
#
#      # Start up going to the project folder.
#      cd ${WORKDIR}/${PROJECT}.chemflow/DockFlow/${PROTOCOL}
#
#      RECEPTOR_LIST=$(ls -d */| cut -d/ -f1)
#      RECEPTOR_LIST=(${RECEPTOR_LIST})
#      echo "Receptors: ${RECEPTOR_LIST[@]}"
#
#
#      for RECEPTOR in ${RECEPTOR_LIST[@]} ; do
#
#        cd ${WORKDIR}/${PROJECT}.chemflow/DockFlow/${PROTOCOL}/${RECEPTOR}
#        # Cleanup ------------------------------------------------
#        if [ -f rank.csv ] ; then rm rank.csv ; fi
#        if [ -f docked_ligands.mol2 ] ; then rm docked_ligands.mol2 ; fi
#
#        LIGAND_LIST=$(ls -d */| cut -d/ -f1)
#        LIGAND_LIST=(${LIGAND_LIST})
#        #echo "Ligands: ${LIGAND_LIST[@]}"
#
#        if [ -f  ${RECEPTOR}/docked_ligands.mol2 ] ; then
#          rm -rf ${RECEPTOR}/docked_ligands.mol2
#        fi
#
#        echo "DOCK_PROGRAM PROTOCOL LIGAND POSE SCORE" > rank.csv
#
#        # Organize to ChemFlow standard.
#        for LIGAND in ${LIGAND_LIST[@]}; do
#
#          # PLANTS -----------------------------------------------------------
#          if [ -f ${LIGAND}/PLANTS/docked_ligands.mol2 ] ; then
#            echo -ne "PostDock: ${PROTOCOL} - ${LIGAND}        \r"
#            awk -v protocol=${PROTOCOL} -v target=${RECEPTOR_NAME} -v ligand=${LIGAND} -F, '!/LIGAND_ENTRY/ {print "PLANTS",protocol,target,ligand,$1,$2}' ${LIGAND}/PLANTS/ranking.csv >> rank.csv
#            cat ${LIGAND}/PLANTS/docked_ligands.mol2 >> docked_ligands.mol2
#          fi
#        done
#      done
#    done
#
#    #grep -v not rank.tmp > rank.csv
#
#    echo "[ DockFlow ] Done with post-processing."
#    # Archiving.
#    read -p "[ DockFlow ] Archive the docking results (folders) in a TAR file? " opt
#    case $opt in
#    "y"|"yes"|"Yes"|"Y"|"YES")
#      DockFlow_archive
#    ;;
#    esac
}

DockFlow_PostDock() {
    #===  FUNCTION  ================================================================
    #          NAME: DockFlow_PostDock
    #   DESCRIPTION: Post processing DockFlow runs depending on the dock program used
    #
    #    PARAMETERS: ${DOCK_PROGRAM}
    #
    #        Author: Diego E. B. Gomes
    #                Dona de Francquen
    #
    #        UPDATE: thur. july 5 14:49:50 CEST 2018
    #
    #===============================================================================
    if [ "${DOCK_PROGRAM}" == "PLANTS" ] ; then
        DockFlow_PostDock_PlantsResults
    elif [ "${DOCK_PROGRAM}" == "VINA" ] ; then
        DockFlow_PostDock_VinaResults
    fi
}

DockFlow_write_HPC() {
#===  FUNCTION  ================================================================
#          NAME: DockFlow_write_HPC
#   DESCRIPTION: Adjusts and submits the calculation to HPC environment.
#                
#    PARAMETERS: ${RUNDIR}      - ${WORKDIR}/${PROJECT}.chemflow/DockFlow/${PROTOCOL}/${RECEPTOR_NAME}/
#                ${PROJECT}
#                ${RUNDIR}
#                ${LIGAND_LIST} - List of all ligands do dock.
#                ${NLIGANDS}    - Number of ligands.
#       RETURNS: -
#===============================================================================

echo "There are $NDOCK ligands to dock"
read -p "
How many do you want per PBS/SLURM job? : " nlig

read -p "
How many tasks per node ? : " NCORES

NTHREADS=$(echo "${NNODES} * ${NCORES}" | bc)

for (( first=0;${first}<${NDOCK} ; first=${first}+${nlig} )) ; do
  echo -ne "Docking $first         \r"
  jobname="${first}"
  
  if [ "${JOB_SCHEDULLER}" == "SLURM" ] ; then 
    DockFlow_write_slurm
    sbatch plants.slurm
  fi

  if [ "${JOB_SCHEDULLER}" == "PBS" ] ; then
    DockFlow_write_pbs
    qsub plants.pbs
  fi


done

}



DockFlow_Dock() {
#===  FUNCTION  ================================================================
#          NAME: DockFlow_Dock.
#   DESCRIPTION: Loop over ligand.lst and dock them to receptor.mol2
#                The organization if kind of weird because I (dgomes) introduced a "ligand.lst" file
#                to read but latter it's so much easier to use the LIGAND_LIST[@] array.
#                I'm not very confident BASH will confortably handle >1million of elemente in the array.
#                
#    PARAMETERS: ${WORKDIR}
#                ${PROJECT}
#                ${RUNDIR}
#                ${LIGAND}
#       RETURNS: ${DOCK_LIST} - List of ligands to dock.
#===============================================================================

# Always work here
cd ${RUNDIR}

# Some housekeeping
if [  -f todock.lst ] ; then 
  rm -rf todock.lst
fi

if [  -f docked.lst ] ; then 
  rm -rf docked.lst
fi

if [ -f  plants.xargs ] ; then
  rm -rf plants.xargs
fi

# Loop over ligands and prepare docking folders/checkpoint calculations
while read LIGAND ; do

  # Check again if rewrite ligands was asked
  case ${rewrite_ligands} in
  "y"|"yes"|"Yes"|"Y"|"YES")
    if [ ! -d   ${LIGAND} ] ; then 
      mkdir -p  ${LIGAND}    

      if [ ! -d ${LIGAND} ] ; then 
        echo "[ ERROR ] could not create ${RUNDIR}. Did you check your quotas ?"
        exit 0
      fi
    fi

    if [ ${DOCK_PROGRAM} == "PLANTS" ] ; then
        if [ ! -f ${LIGAND}/ligand.mol2 ]  || [ ${OVERWRITE} == 'yes' ] ; then
          cp ${WORKDIR}/${PROJECT}.chemflow/LigFlow/original/${LIGAND}.mol2 ${LIGAND}/ligand.mol2
        fi
    fi

    if [ ${DOCK_PROGRAM} == "VINA" ] ; then
         if [ ! -f  ${LIGAND}/ligand.pdbqt ] || [ ${OVERWRITE} == 'yes' ] ; then
            ${mgltools_folder}/bin/python ${mgltools_folder}/MGLToolsPckgs/AutoDockTools/Utilities24/prepare_ligand4.py \
            -l ${WORKDIR}/${PROJECT}.chemflow/LigFlow/original/${LIGAND}.mol2 \
            -o ${LIGAND}/ligand.pdbqt
         fi
    fi

    esac

  # [ Resume or Overwrite ]
  # Check if folder exists, then check if "bestranking.csv" exist, then if user wants to overwrite.

  if [ "${OVERWRITE}" == "yes" ] ; then
      if [ -d ${LIGAND}/${DOCK_PROGRAM} ] ; then
        rm -rf ${LIGAND}/${DOCK_PROGRAM}
      fi
  else
    # If the folder exists but there's no "bestranking.csv" its incomplete.
    if [ -d ${LIGAND}/${DOCK_PROGRAM} ] && [ ! -s ${LIGAND}/${DOCK_PROGRAM}/bestranking.csv ] ; then
      echo "[ NOTE ] ${RECEPTOR_NAME} and ${LIGAND} incomplete... redoing it !"
      rm -rf ${LIGAND}/PLANTS
    fi
  fi

  # Finally, if all goes well create the docking list.
  if [ ! -d ${LIGAND}/${DOCK_PROGRAM} ] ; then
    DOCK_LIST="${DOCK_LIST} $LIGAND"  # Still unused.
    echo -ne "Preparing: ${LIGAND} \r"
    echo "${LIGAND}" >> todock.lst
  else
    echo "${LIGAND}" >> docked.lst
  fi

done < ${WORKDIR}/${PROJECT}.chemflow/LigFlow/ligands.lst

# Make DOCK_LIST into an array.
DOCK_LIST=(${DOCK_LIST})
NDOCK=${#DOCK_LIST[@]}

echo "There are ${NLIGANDS} compounds and ${NDOCK} remaining to dock"

# Actually run the docking --------------------------------------------

## Local docking using PLANTS.
case ${DOCK_PROGRAM} in
    "PLANTS")
        case ${JOB_SCHEDULLER} in
            "None")
                for LIGAND in ${DOCK_LIST[@]} ; do  # Write XARGS file.
                    DockFlow_write_plants_config
                    echo "cd ${RUNDIR}/${LIGAND} ; echo [ Docking ] ${RECEPTOR_NAME} - ${LIGAND} ;  PLANTS1.2_64bit --mode screen dock_input.in &> PLANTS.log ; rm -rf PLANTS/{protein.log,descent_ligand_1.dat,protein_bindingsite_fixed.mol2}" >> plants.xargs
                done

                if [ ! -f plants.xargs ] ; then
                    echo "All ligands docked, nothing to do here" ; exit 0
                else
                    echo "[ DockFlow ] Running ${PROTOCOL} ${RECEPTOR_NAME} with ${NCORES} cores"
                    # Actually runs PLANTS
                    cd ${RUNDIR} ; cat plants.xargs | xargs -P${NCORES} -I '{}' bash -c '{}'
                fi
            ;;
            "SLURM"|"PBS")
                DockFlow_write_HPC
        esac
    ;;
    "VINA")
        for LIGAND in ${DOCK_LIST[@]} ; do
            echo "vina --receptor ${RUNDIR}/receptor.pdbqt --ligand ${RUNDIR}/${LIGAND}/ligand.pdbqt \
                --center_x ${DOCK_CENTER[0]} --center_y ${DOCK_CENTER[1]} --center_z ${DOCK_CENTER[2]} \
                --size_x ${DOCK_RADIUS} --size_y ${DOCK_RADIUS} --size_z ${DOCK_RADIUS} \
                --out ${LIGAND}/VINA/output.pdbqt --cpu 1 &>/dev/null " >> vina.xargs
        done
        # Actually runs VINA
        cd ${RUNDIR} ; cat vina.xargs | xargs -P${NCORES} -I '{}' bash -c '{}'
    ;;
esac
}


DockFlow_organize() {
# [ Stage 1 ] - Prepare receptor.
## Create folders within PROJECT.chemflow.
## Copy receptor to its own folder.

# [ Stage 2 ] - Prepare ligand
## Read all ligand names from the header of a .MOL2 file.
## Split each ligand to it's own ".MOL2" file.
## 2C) Create "ligand.lst" with the list of ligands do dock. (still unused)


# [ Phase 1 ] - Prepare receptor  --------------------------------------

if [  ! -d ${RUNDIR} ] ; then
  mkdir -p ${RUNDIR}
fi

# [ Stage 2 ] Prepare receptor and ligand(s) - SplitMOL2 ----------------------------

# Receptor
if [ ${DOCK_PROGRAM} == 'PLANTS' ] && [ ! -f ${RUNDIR}/receptor.mol2 ] ; then
  cp ${RECEPTOR_FILE} ${RUNDIR}/receptor.mol2
fi

if [ ${DOCK_PROGRAM} == 'VINA' ] && [ ! -f  ${RUNDIR}/receptor.pdbqt ] ; then
    ${mgltools_folder}/bin/python \
    /storage/rgimatev/bin/MGLTools-1.5.6/mgltools_x86_64Linux2_1.5.6//MGLToolsPckgs/AutoDockTools/Utilities24/prepare_receptor4.py \
    -r ${RECEPTOR_FILE} \
    -o ${RUNDIR}/receptor.pdbqt
fi

# Ligands

read -p "Rewrite ligands [Y/N] ? : " rewrite_ligands

case ${rewrite_ligands} in
"y"|"yes"|"Yes"|"Y"|"YES")
    if [  -d ${PROJECT}.chemflow/LigFlow/original/ ] ; then 
      rm -rf ${PROJECT}.chemflow/LigFlow/original/
    fi

    if [  ! -d ${PROJECT}.chemflow/LigFlow/original/ ] ; then 
      mkdir -p ${PROJECT}.chemflow/LigFlow/original/
    fi

    if [ -f  ${PROJECT}.chemflow/LigFlow/ligands.lst ] ; then 
      rm -rf ${PROJECT}.chemflow/LigFlow/ligands.lst
    fi

    for i in ${LIGAND_LIST[@]} ; do
      echo ${i} >> ${PROJECT}.chemflow/LigFlow/ligands.lst
    done

    n=-1
    while read line ; do
      if [ "${line}" == '@<TRIPOS>MOLECULE' ]; then
        let n=$n+1
      fi
      echo -e "${line}" >> ${PROJECT}.chemflow/LigFlow/original/${LIGAND_LIST[$n]}.mol2
    done < ${LIGAND_FILE}

;;
"n"|"no"|"No"|"N"|"NO") ;;
*)
  echo ${opt} "[ ERROR ] Choose only Y or N" ; exit 0
;;
esac
}

DockFlow_unset() {
# User variables
unset PROJECT  	   # Name for the current project, ChemFlow folders go after it
unset PROTOCOL     # Name for the current protocol. 

# ChemFlow internals
unset WORKFLOW     # Which ChemFlow protocol to use: DockFlow, ScoreFlow ...
##unset METHOD       # Internal of each workflow ( PLANTS, VINA, gbsa...)
##                   # Method will define which software to use.

# User input files ------------------------------------------------------------
unset RECEPTOR_FILE
unset RECEPTOR_NAME
#unset RECEPTOR     # Filename (no extension) for the receptor file. 
                   # This can be equivalent to MOL_ID. 
                   # DockFlow requires a .MOL2.

unset LIGAND_FILE  # Filename .MOL2 for the ligand file. 
                   # An unique .mol2, properly prepared would do the job.

# Docking Variables
unset DOCK_PROGRAM # Program used for docking.
unset DOCK_CENTER  # Binding pocket center (X, Y and Z). 
unset DOCK_LENGHT  # Length of the X, Y and Z axis.
unset DOCK_RADIUS  # Radius from the Docking Center.

unset RUNDIR       # Folder where the calculations will actually run. 
                   # RUNDIR=$WORKDIR/$PROJECT/$WORKFLOW/$PROTOCOL

unset POSTDOCK     # Either just post-process dockings
unset ARCHIVE      # Either just post-process dockings
}

DockFlow_set_defaults() {

# General options
  WORKDIR=${PWD}
  PROTOCOL="default"
  WORKFLOW="DockFlow"

# Docking options
  DOCK_PROGRAM="PLANTS"
  DOCK_LENGHT="15 15 15"
  DOCK_RADIUS="15"
  DOCK_POSES="10"
  SCORING_FUNCTION="chemplp"
  
# Run options
JOB_SCHEDULLER="None"
        NCORES=$(nproc --all)
        if [ -z ${NCORES} ] ; then NCORES=4 ; fi
        NNODES="1"
        RESUME="No"
        OVERWRITE="No"    # Don't overwrite stuff. 
     
}


DockFlow_help() {
echo "Example usage: 
DockFlow -r receptor.mol2 -l ligand.mol2 -p myproject [-protocol 1] [-n 8] [-sf chemplp]   

[Options]
 -h/--help           : Show this help message and quit
 -hh/--fullhelp      : Detailed help
 -f/--file           : DockFlow configuration file
 -r/--receptor       : Receptor's mol2 file.
 -l/--ligand         : Ligands .mol2 input file.
 -p/--project        : ChemFlow project
 --postdock          : Process DockFlow output in a ChemFlow project.

"
exit 0
}

DockFlow_help_full(){
echo "
DockFlow is a bash script designed to work with PLANTS or Vina.  

It can perform an automatic VS based on information given by the user :
ligands, receptor, binding site info, and extra options.

DockFlow requires a configuration file named DockFlow.config, if absent, one will be created. 
A template can be found in: ${CHEMFLOW_HOME}/config_files/DockFlow.config

If you already have an existing config file and wish to rerun DockFlow
only modifying some options, see the help below.


Usage:
DockFlow -r receptor.mol2 -l ligand.mol2 -p myproject [-protocol 1] [-n 8] [-sf chemplp] [--radius 15] 

[Help]
 -h/--help           : Show this help message and quit
 -hh/--fullhelp      : Detailed help

[ Required ]
 -f/--file           : DockFlow configuration file
 -r/--receptor       : Receptor NAME
 -rf/--receptor-file : Receptor MOL2 file
 -l/--ligand         : Ligands  MOL2 file
 -p/--project        : ChemFlow project
 
[ Post Processing ] 
 --postdock          : Process DockFlow output in a ChemFlow project.
 --archive           : Compress the docking folder
 --report            : [not implemented]
 --clean             : [not implemented] Clean up DockFlow output for a fresh start.
 
[ Optional ]
 --protocol          : Name for this specific protocol [default]
 -n/--number         : Number of poses to generate, per ligand [10]
 -sf/--function      : vina, chemplp, plp, plp95  [chemplp]

[ Parallel execution ] 
 -nc/--cores         : Number of cores per node
 -w/--workload       : Workload manager, PBS or SLURM
 -nn/--nodes         : Number of nodes to use (ony for PBS or SLURM)

[ Additional ] 
 --overwrite          : Overwrite results

[ Options for docking program ] 
_________________________________________________________________________________
[ PLANTS ]
 --speed             : Search speed for Plants. 1, 2 or 4 [1]
 --ants              : Number of ants     [20]
 --evap_rate         : Evaporation rate of pheromones [0.15]
 --iteration_scaling : Iteration scaling factor [1.0]
 --center            : xyz coordinates of the center of the binding site, separated by a space
 --radius            : Radius of the spheric binding site
 --water             : Path to a structural water molecule
 --water_xyzr        : xyz coordinates and radius of the water sphere, separated by a space

_________________________________________________________________________________
[ Vina ]
 --center            : xyz coordinates of the center of the grid, separated by a space
 --size              : Size of the grid along the x, y and z axis, separated by a space
 --exhaustiveness    : Exhaustiveness of the global search [8]
 --energy_range      : Max energy difference (kcal/mol) between the best and worst poses displayed [3.00]
_________________________________________________________________________________
"
exit 0
}

DockFlow_CLI() {

if [ "$1" == "" ] ; then
  echo -ne "\n[ ERROR ] DockFlow called without arguments\n\n"
  DockFlow_help
fi

while [[ $# -gt 0 ]]; do
key="$1"

case ${key} in
    --resume) 
      echo -ne "\nResume not implemented"
      exit 0
    ;;
    -h|--help)
      DockFlow_help
      exit 0
      shift # past argument
    ;;
    -hh|--full-help)
      DockFlow_help_full
      exit 0
      shift
    ;;
    -f|--file)
      CONFIG_FILE="$2"
      shift # past argument
    ;;
    -r|--receptor)
      RECEPTOR_FILE="$2"
      RECEPTOR_NAME="$(basename -s .mol2 ${RECEPTOR_FILE})"
      shift # past argument
    ;;
    -l|--ligand)
      LIGAND_FILE="$2"
      shift # past argument
    ;;
    -p|--project)
      PROJECT="$2"
      shift
    ;;
    --protocol)
      PROTOCOL="$2"
      shift
    ;;
    -sf|--scoring_function)
      SCORING_FUNCTION="$2"
      shift
    ;;
    --center)
      DOCK_CENTER="$2 $3 $4"
      DOCK_CENTER=($DOCK_CENTER) # Transform into array
      shift 3 # past argument
    ;;
    --radius)
      DOCK_RADIUS="$2"
      shift # past argument
    ;;
    --size)
      DOCK_LENGTH="$2 $3 $4"
      DOCK_LENGHT=($DOCK_LENGHT) # Transform into array
      shift 3
    ;;
    -n|--number)
      DOCK_POSES="$2"
      shift # past argument
    ;;
    --run)
      run_mode="$2"
      shift # past argument
    ;;
    -nc|--cores) # Number of Cores [1] (or cores/node)
      NCORES="$2" # Same as above.
      shift # past argument
    ;;
# HPC options ----------------------------------------------------------
    -nn|--nodes) # Number of NODES [1]
      NNODES="$2" # Same as above.
      shift # past argument
    ;;
    -w|--workload) # Workload manager, [SLURM] or PBS
      JOB_SCHEDULLER="$2"
      shift # past argument
    ;;
## PLANTS arguments ----------------------------------------------------
    --speed)
      speed="$2"
      shift
    ;;
    --ants)
      ants="$2"
      shift
    ;;
    --evap_rate)
      evap_rate="$2"
      shift
    ;;
    --water)
      water="$2"
      shift # past argument
    ;;
    --water_xyzr)
      water_xyzr="$2 $3 $4 $5"
      shift 4 # past argument
    ;;
 ### VINA arguments
    --iteration_scaling)
      iteration_scaling="$2"
      shift
    ;;
    --exhaustiveness)
      exhaustiveness="$2"
      shift
    ;;
    --energy_range)
      energy_range="$2"
      shift
    ;;
## Final arguments
    --overwrite)
      OVERWRITE="yes"
    ;;
## ADVANCED USER INPUT
#    --advanced)
#      USER_INPUT="$2"
#      shift
    --postdock)
      POSTDOCK="yes"
    ;;
    --archive)
      ARCHIVE='yes' 
    ;;
    *)
      unknown="$1"        # unknown option
      echo "Unknown flag \"$unknown\""
    ;;
esac
shift # past argument or value
done
}
