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


DockFlow_summary() {
#===  FUNCTION  ================================================================
#          NAME: DockFlow_summary
#   DESCRIPTION: Summarize all docking information
#
#    PARAMETERS: ${HOSTNAME}
#                ${USER}
#                ${PROJECT}
#                ${PROTOCOL}
#                ${PWD}
#                ${RECEPTOR_NAME}
#                ${RECEPTOR_FILE}
#                ${LIGAND_FILE}
#                ${NLIGANDS}
#                ${DOCK_POSES}
#                ${DOCK_PROGRAM}
#                ${SCORING_FUNCTION}
#                ${DOCK_CENTER}
#                ${DOCK_LENGHT}
#                ${DOCK_RADIUS}
#                ${JOB_SCHEDULLER}
#                ${NCORES}
#                ${NNODES}
#                ${OVERWRITE}
#       RETURNS: -
#
#===============================================================================

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


DockFlow_prepare_receptor() {
#===  FUNCTION  ================================================================
#          NAME: DockFlow_prepare_receptor
#   DESCRIPTION: Prepare the receptor for the docking:
#                Copy the receptor file into the rundir folder as receptor.mol2
#                 - PLANTS uses the mol2 file,
#                 - VINA uses a pdbqt file. It is converted using AutoDockTools
#                   and saved into the rundir folder as receptor.pdbqt
#
#    PARAMETERS: ${DOCK_PROGRAM}
#                ${RUNDIR}
#                ${RECEPTOR_FILE}
#                ${mgltools_folder} (should be in the path)
#
#        Author: Dona de Francquen
#
#        UPDATE: fri. july 6 14:49:50 CEST 2018
#
#===============================================================================
cp ${WORKDIR}/${RECEPTOR_FILE} ${RUNDIR}/receptor.mol2


if [ ${DOCK_PROGRAM} == 'VINA' ] && [ ! -f  ${RUNDIR}/receptor.pdbqt ] ; then
    ${mgltools_folder}/bin/python \
    ${mgltools_folder}/MGLToolsPckgs/AutoDockTools/Utilities24/prepare_receptor4.py \
    -r ${RUNDIR}/receptor.mol2 \
    -o ${RUNDIR}/receptor.pdbqt
fi
}


DockFlow_rewrite_origin_ligands() {
# Original
rm -rf ${WORKDIR}/${PROJECT}.chemflow/LigFlow/original/
mkdir -p ${WORKDIR}/${PROJECT}.chemflow/LigFlow/original/

OLDIFS=$IFS
IFS='%'
n=-1
while read line ; do
    if [ "${line}" == '@<TRIPOS>MOLECULE' ]; then
        let n=$n+1
    fi
    echo -e "${line}" >> ${WORKDIR}/${PROJECT}.chemflow/LigFlow/original/${LIGAND_LIST[$n]}.mol2
done < ${WORKDIR}/${LIGAND_FILE}
IFS=${OLDIFS}


#
# QUICK AND DIRTY FIX BY DIEGO - PLEASE FIX THIS FOR THE LOVE OF GOD
#
for LIGAND in ${LIGAND_LIST[@]} ; do
    cd ${WORKDIR}/${PROJECT}.chemflow/LigFlow/original/
    antechamber -i ${LIGAND}.mol2 -o tmp.mol2 -fi mol2 -fo mol2 -at sybyl &>/dev/null
    mv tmp.mol2 ${LIGAND}.mol2
done
#
#
#
}


DockFlow_prepare_ligands() {
#===  FUNCTION  ================================================================
#          NAME: DockFlow_rewrite_ligands
#   DESCRIPTION: User interface for the rewrite ligands option.
#                 - Read all ligand names from the header of a .MOL2 file.
#                 - Split each ligand to it's own ".MOL2" file.
#               #  - Create "ligand.lst" with the list of ligands do dock.
#
#    PARAMETERS: ${PROJECT}
#                ${LIGAND_LIST}
#                ${RUNDIR}
#                ${DOCK_PROGRAM}
#                ${WORKDIR}
#                ${OVERWRITE}
#
#        Author: Dona de Francquen
#
#        UPDATE: fri. july 6 14:49:50 CEST 2018
#
#===============================================================================
cd ${RUNDIR}

# Create ligand folder into the project
for LIGAND in ${LIGAND_LIST[@]} ; do
    if [ ! -d  ${LIGAND} ] ; then
        mkdir -p  ${LIGAND}
        if [ ! -d ${LIGAND} ] ; then
            echo "[ ERROR ] could not create ${LIGAND} directory in ${RUNDIR}. Did you check your quotas ?"
            exit 0
        fi
    fi
    case ${DOCK_PROGRAM} in
    "PLANTS")
        if [ ! -f ${LIGAND}/ligand.mol2 ]  || [ ${rewrite_ligands} == 'yes' ] ; then
            cp ${WORKDIR}/${PROJECT}.chemflow/LigFlow/original/${LIGAND}.mol2 ${LIGAND}/ligand.mol2
        fi
    ;;
    "VINA")
        if [ ! -f  ${LIGAND}/ligand.pdbqt ] || [ ${rewrite_ligands} == 'yes' ] ; then
            ${mgltools_folder}/bin/python ${mgltools_folder}/MGLToolsPckgs/AutoDockTools/Utilities24/prepare_ligand4.py \
            -l ${WORKDIR}/${PROJECT}.chemflow/LigFlow/original/${LIGAND}.mol2 \
            -o ${LIGAND}/ligand.pdbqt
        fi
    ;;
    esac
done
#        if [ -f  ${PROJECT}.chemflow/LigFlow/ligands.lst ] ; then
#            rm -rf ${PROJECT}.chemflow/LigFlow/ligands.lst
#        fi

#        for i in ${LIGAND_LIST[@]} ; do
#            echo ${i} >> ${PROJECT}.chemflow/LigFlow/ligands.lst
#        done

#
}


DockFlow_prepare_input() {
#===  FUNCTION  ================================================================
#          NAME: DockFlow_prepare_input
#   DESCRIPTION: Prepare input for the docking.
#                1. Creates the RUNDIR folder
#                2. Copy the receptor to its own folder
#                3. Copy the ligands into their own folder
#
#    PARAMETERS: ${RUNDIR}
#
#        Author: Dona de Francquen
#
#       RETURNS: -
#
#          TODO: Allow "extra PLANTS keywords from cmd line"
#===============================================================================
# 1. Folder
if [  ! -d ${RUNDIR} ] ; then
  mkdir -p ${RUNDIR}
fi

# Always work here
cd ${RUNDIR}

# 2. Receptor
DockFlow_prepare_receptor

# 3. Ligands
if [ -d ${WORKDIR}/${PROJECT}.chemflow/LigFlow/original/ ] && [ -d ${RUNDIR}/${LIGAND_LIST} ]; then
    read -p "Rewrite ligands [Y/N] ? : " rewrite_ligands
else
    rewrite_ligands="yes"
fi

case ${rewrite_ligands} in
"y"|"yes"|"Yes"|"Y"|"YES")
    DockFlow_rewrite_origin_ligands
    DockFlow_prepare_ligands
;;
"n"|"no"|"No"|"N"|"NO")
    DockFlow_prepare_ligands
;;
*)
    echo ${opt} "[ ERROR ] Choose only Y or N" ; exit 0
;;
esac
}


DockFlow_write_plants_config() {
#===  FUNCTION  ================================================================
#          NAME: DockFlow_write_plants_config_input
#   DESCRIPTION: Write the dock input for plants (configuration file)
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


DockFlow_write_plants_slurm() {
#===  FUNCTION  ================================================================
#          NAME: DockFlow_write_plants_slurm
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
#SBATCH --job-name=DockFlow_${first}
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

if [ -f ${first}.xargs ] ; then rm -rf ${first}.xargs ; fi

for LIGAND in ${DOCK_LIST[@]:$first:$nlig} ; do

    DockFlow_write_plants_config

    echo \"cd ${RUNDIR}/\${LIGAND} ; PLANTS1.2_64bit --mode screen dock_input.in &> docking.log ; rm -rf PLANTS/{protein.log,descent_ligand_1.dat,protein_bindingsite_fixed.mol2}\" >> ${first}.xargs

done

cat ${first}.xargs | xargs -P${NCORES} -I '{}' bash -c '{}'

"> DockFlow.slurm
}



DockFlow_write_vina_slurm() {
#===  FUNCTION  ================================================================
#          NAME: write_vina slurm
#   DESCRIPTION: Writes the SLURM script to for each ligand (or range of ligands). for VINA
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
#SBATCH --job-name=DockFlow_${first}
#SBATCH -N ${NNODES}
#SBATCH -n ${NTHREADS}
#SBATCH -t 0:30:00

if [ -f ${first}.xargs ] ; then rm -rf ${first}.xargs ; fi

for LIGAND in ${DOCK_LIST[@]:$first:$nlig} ; do
  # Vina command.
    echo "vina --receptor ${RUNDIR}/receptor.pdbqt --ligand ${RUNDIR}/\${LIGAND}/ligand.pdbqt \
        --center_x ${DOCK_CENTER[0]} --center_y ${DOCK_CENTER[1]} --center_z ${DOCK_CENTER[2]} \
        --size_x ${DOCK_RADIUS} --size_y ${DOCK_RADIUS} --size_z ${DOCK_RADIUS} \
        --out ${RUNDIR}/\${LIGAND}/VINA/output.pdbqt --cpu 1 &>/dev/null " >> vina.xargs
done

cat ${first}.xargs | xargs -P${NCORES} -I '{}' bash -c '{}'

"> DockFlow.slurm
}


DockFlow_write_plants_pbs() {
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
#PBS -j DockFlow_${first}
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

if [ -f ${first}.xargs ] ; then rm -rf ${first}.xargs ; fi
for LIGAND in ${DOCK_LIST[@]:$first:$nlig} ; do

  DockFlow_write_plants_config

  echo \"cd ${RUNDIR}/\${LIGAND} ; PLANTS1.2_64bit --mode screen dock_input.in &> docking.log ; rm -rf PLANTS/{protein.log,descent_ligand_1.dat,protein_bindingsite_fixed.mol2}\" >> ${first}.xargs

done

cat ${first}.xargs | xargs -P${NCORES} -I '{}' bash -c '{}'

"> DockFlow.pbs
}


DockFlow_write_vina_pbs() {
#===  FUNCTION  ================================================================
#          NAME: write_vina_pbs
#   DESCRIPTION: Writes the PBS script to for each ligand (or range of ligands). for VINA
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
#PBS -j DockFlow_${first}
#PBS -l nodes=${NNODES}:ppn=${NTHREADS}
#PBS -l walltime=0:30:00


if [ -f ${first}.xargs ] ; then rm -rf ${first}.xargs ; fi

for LIGAND in ${DOCK_LIST[@]:$first:$nlig} ; do
  # Vina command.
    echo "vina --receptor ${RUNDIR}/receptor.pdbqt --ligand ${RUNDIR}/\${LIGAND}/ligand.pdbqt \
        --center_x ${DOCK_CENTER[0]} --center_y ${DOCK_CENTER[1]} --center_z ${DOCK_CENTER[2]} \
        --size_x ${DOCK_RADIUS} --size_y ${DOCK_RADIUS} --size_z ${DOCK_RADIUS} \
        --out ${RUNDIR}/\${LIGAND}/VINA/output.pdbqt --cpu 1 &>/dev/null " >> vina.xargs
done

cat ${first}.xargs | xargs -P${NCORES} -I '{}' bash -c '{}'

"> DockFlow.pbs
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
    if [ "${DOCK_PROGRAM}" == "PLANTS" ] ; then
        DockFlow_write_plants_slurm
    elif [ "${DOCK_PROGRAM}" == "VINA" ] ; then
        DockFlow_write_vina_slurm
    fi
    sbatch DockFlow.slurm

  fi

  if [ "${JOB_SCHEDULLER}" == "PBS" ] ; then
    if [ "${DOCK_PROGRAM}" == "PLANTS" ] ; then
        DockFlow_write_plants_pbs
    elif [ "${DOCK_PROGRAM}" == "VINA" ] ; then
        DockFlow_write_vina_pbs
    fi
    qsub DockFlow.pbs
  fi

done
}


DockFlow_dock() {
#===  FUNCTION  ================================================================
#          NAME: DockFlow_Dock.
#   DESCRIPTION: Loop over ligand.lst and dock them to receptor.mol2
#                The organization if kind of weird because I (dgomes) introduced a "ligand.lst" file
#                to read but latter it's so much easier to use the LIGAND_LIST[@] array.
#                I'm not very confident BASH will confortably handle > 1 million of elemente in the array.
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

if [ -f  vina.xargs ] ; then
  rm -rf vina.xargs
fi

# Creation of the docking list, checkpoint calculations.
DOCK_LIST=""
case ${DOCK_PROGRAM} in
"PLANTS")
    # If the folder exists but there's no "bestranking.csv" its incomplete.
    FILE="bestranking.csv"
;;
"VINA")
    # If the folder exists but there's no "output.pdbqt" its incomplete.
    FILE="output.pdbqt"
;;
esac
for LIGAND in ${LIGAND_LIST[@]} ; do
    if [ "${OVERWRITE}" == "no" ] ; then # Useless to process this loop if we overwrite anyway.
        if [ -d ${LIGAND}/${DOCK_PROGRAM} ] && [ ! -f ${LIGAND}/${DOCK_PROGRAM}/${FILE} ] ; then
            echo "[ NOTE ] ${RECEPTOR_NAME} and ${LIGAND} incomplete... redoing it !"
            rm -rf ${LIGAND}/${DOCK_PROGRAM}
        fi
    else
        rm -rf ${LIGAND}/${DOCK_PROGRAM}
    fi

    if [ ! -d ${LIGAND}/${DOCK_PROGRAM} ] || [ ${OVERWRITE} == "yes" ] ; then
        DOCK_LIST="${DOCK_LIST} $LIGAND"  # Still unused.
        echo -ne "Preparing: ${LIGAND} \r"
        echo "${LIGAND}" >> todock.lst
    else
        echo "${LIGAND}" >> docked.lst
    fi
done

# Make DOCK_LIST into an array.
DOCK_LIST=(${DOCK_LIST})
NDOCK=${#DOCK_LIST[@]}

echo "There are ${NLIGANDS} compounds and ${NDOCK} remaining to dock"

# Actually run the docking --------------------------------------------
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
    case ${JOB_SCHEDULLER} in
            "None")
                for LIGAND in ${DOCK_LIST[@]} ; do
                    # Create the output VINA folder if it doesn't exist.
                    if [  ! -d ${RUNDIR}/${LIGAND}/VINA/ ] ; then
                        mkdir -p ${RUNDIR}/${LIGAND}/VINA/
                    fi
                    echo [ Docking ] ${RECEPTOR_NAME} - ${LIGAND}
                    # Vina command.
                    echo "vina --receptor ${RUNDIR}/receptor.pdbqt --ligand ${RUNDIR}/${LIGAND}/ligand.pdbqt \
                        --center_x ${DOCK_CENTER[0]} --center_y ${DOCK_CENTER[1]} --center_z ${DOCK_CENTER[2]} \
                        --size_x ${DOCK_RADIUS} --size_y ${DOCK_RADIUS} --size_z ${DOCK_RADIUS} \
                        --out ${RUNDIR}/${LIGAND}/VINA/output.pdbqt  --log ${RUNDIR}/${LIGAND}/VINA/output.log  ${VINA_EXTRA} &>/dev/null " >> vina.xargs
                done

                if [ ! -f vina.xargs ] ; then
                    echo "All ligands docked, nothing to do here" ; exit 0
                else
                    # Actually runs VINA
                    cd ${RUNDIR} ; cat vina.xargs | xargs -P${NCORES} -I '{}' bash -c '{}'
                fi
             ;;
            "SLURM"|"PBS")
                DockFlow_write_HPC
        esac
        ;;
esac
}


DockFlow_archive() {
#===  FUNCTION  ================================================================
#          NAME: DockFlow_archive
#   DESCRIPTION: Archives the docking folders
#
#    PARAMETERS: ${PROJECT}
#                ${RUNDIR}
#
#       RETURNS: docked_folder.tar.gz
#
#===============================================================================
PROJECT=$(echo ${PROJECT} | cut -d. -f1)

if [ -d ${WORKDIR}/${PROJECT}.chemflow/DockFlow ] ; then
    # Start up going to the project folder.
    cd ${WORKDIR}/${PROJECT}.chemflow/DockFlow

    # Retrieve available protocols
    if [ ! -z ${ARCHIVE_ALL} ] || [ ! -z ${POSTDOCK_ALL} ] ; then
        PROTOCOL_LIST=($(ls -d */ | cut -d/ -f1))
    else
        PROTOCOL_LIST=${PROTOCOL}
    fi

    #echo "Protocols: ${PROTOCOL_LIST[@]}"

    for PROTOCOL in ${PROTOCOL_LIST[@]}  ; do

        if [ -d  ${WORKDIR}/${PROJECT}.chemflow/DockFlow/${PROTOCOL} ] ; then
            # Go to the protocol folder.
            cd ${WORKDIR}/${PROJECT}.chemflow/DockFlow/${PROTOCOL}
            # Retrieve available receptors
            if [ ! -z ${ARCHIVE_ALL} ] || [ ! -z ${POSTDOCK_ALL} ] ; then
                RECEPTOR_LIST=($(ls -d */| cut -d/ -f1))
            else
                RECEPTOR_LIST=${RECEPTOR_NAME}
            fi
        #    echo "Receptors: ${RECEPTOR_LIST[@]}"

            for RECEPTOR in ${RECEPTOR_LIST[@]} ; do
                if [ -d ${WORKDIR}/${PROJECT}.chemflow/DockFlow/${PROTOCOL}/${RECEPTOR} ] ; then
                    #  Go to the receptor folder.
                    cd ${WORKDIR}/${PROJECT}.chemflow/DockFlow/${PROTOCOL}/${RECEPTOR}

                    if [ -d */ ] ; then
                        # Cleanup
                        if [ -f docked_folder.tar.gz ] ; then rm docked_folder.tar.gz ; fi

                        echo "[ DockFlow ] Archiving the ${PROTOCOL}/${RECEPTOR} docking folders into: ${PROTOCOL}/${RECEPTOR}/docked_folder.tar.gz"
                        tar cfz docked_folder.tar.gz */

                        # Check if the archive is there
                        if [ -f docked_folder.tar.gz ] ; then
                            echo "[ DockFlow ] Archiving complete."
                        else
                            ERROR_MESSAGE="Archiving failed."
                            ChemFlow_error ;
                        fi
                    else
                        ERROR_MESSAGE="Nothing to archive."
                        ChemFlow_error ;
                    fi
                else
                    ERROR_MESSAGE="Error in the receptor name. The directory ${WORKDIR}/${PROJECT}.chemflow/DockFlow/${PROTOCOL}/${RECEPTOR} does not exist." ;
                    ChemFlow_error ;
                fi
            done
        else
            ERROR_MESSAGE="Error in the protocol name or there is no DockFlow results. The directory ${WORKDIR}/${PROJECT}.chemflow/DockFlow/${PROTOCOL} does not exist." ;
            ChemFlow_error ;
        fi
    done
else
    ERROR_MESSAGE="Error in the project name. The directory ${WORKDIR}/${PROJECT}.chemflow/ does not exist." ;
    ChemFlow_error ;
fi

# Remove docking folders
if [ ! -z ${ARCHIVE_ALL} ] || [ ! -z ${POSTDOCK_ALL} ] ; then
    read -p "[ DockFlow ] Remove all docking folders ? " opt
else
    read -p "[ DockFlow ] Remove docking folders for ${PROTOCOL} / ${RECEPTOR} ? " opt
fi
case ${opt} in
"y"|"yes"|"Yes"|"Y"|"YES")
    for PROTOCOL in ${PROTOCOL_LIST[@]}  ; do
        for RECEPTOR in ${RECEPTOR_LIST[@]} ; do
            rm -rf ${WORKDIR}/${PROJECT}.chemflow/DockFlow/${PROTOCOL}/${RECEPTOR}/*/
            echo "[ DockFlow ] Done removing docking folders."

         done
    done
;;
esac
}


DockFlow_postdock_plants_results() {
#===  FUNCTION  ================================================================
#          NAME: DockFlow_PostDock_PlantsResults
#   DESCRIPTION: Post processing DockFlow run while using plants.
#                Extract results and organize files to ChemFlow standard.
#
#    PARAMETERS: ${PROJECT}
#
#          NOTE: Must be run while at "${RUNDIR}
#       RETURNS: DockFlow.csv, top.csv
#
#        Author: Diego E. B. Gomes
#                Cedric Bouysset
#
#        UPDATE: mar. mai 29 14:49:50 CEST 2018
#
#          TODO: A summary of protocols would be interesting
#===============================================================================
for LIGAND in ${LIGAND_LIST[@]}; do
    if [ ! -f ${LIGAND}/PLANTS/docked_ligands.mol2 ] ; then
        echo "[ ERROR ] Plants result for ligand ${LIGAND} does not exists."
        FAIL="true"
    else
        # Fill the DockFlow.csv file
        echo -ne "PostDock: ${PROTOCOL} - ${LIGAND}        \r"
        awk -v protocol=${PROTOCOL} -v target=${RECEPTOR_NAME} -v ligand=${LIGAND} -F, '!/LIGAND_ENTRY/ {print "PLANTS",protocol,target,ligand,$1,$2}' ${LIGAND}/PLANTS/ranking.csv >> DockFlow.csv

        # Create the docked_ligands.mol2, a file containing every conformations of every ligands.
        cat ${LIGAND}/PLANTS/docked_ligands.mol2 >> docked_ligands.mol2
    fi
done
# rename the ligand in the created file
if [ -f docked_ligands.mol2 ] && [ -f DockFlow.csv ] ; then
    sed -i 's/\.*_entry_[[:digit:]]*//' docked_ligands.mol2
    sed -i 's/[a-zA-Z0-9]*_entry_[[:digit:]]*_conf_//' DockFlow.csv
fi
}


DockFlow_postdock_vina_results() {
#===  FUNCTION  ================================================================
#          NAME: DockFlow_PostDock_VinaResults
#   DESCRIPTION: Post processing DockFlow run while using vina.
#                Extract results and organize files to ChemFlow standard.
#
#    PARAMETERS: ${PROJECT}
#                ${LIGAND_LIST}
#
#       RETURNS: docked_ligands.mol2, DockFlow.csv, top.csv
#
#        Author: Dona de Francquen
#
#        UPDATE: fri. July 6 14:49:50 CEST 2018
#
#===============================================================================

if [ ${OVERWRITE}  == 'yes' ] ; then
    rm -rf ${RUNDIR}/docked_ligands.mol2
fi

for LIGAND in ${LIGAND_LIST[@]}; do
    if [ ! -f  ${RUNDIR}/${LIGAND}/VINA/output.pdbqt ] ; then
        echo "[ ERROR ] Vina's result for ligand ${LIGAND} does not exists."
        FAIL="true"
    else
        # Fill the DockFlow.csv file
        awk -v protocol=${PROTOCOL} -v target=${RECEPTOR_NAME} -v ligand=${LIGAND} -v conf=1 '/REMARK VINA RESULT/ {print "VINA",protocol,target,ligand,conf,$4; conf++}' ${RUNDIR}/${LIGAND}/VINA/output.pdbqt >> DockFlow.csv

        # Create the docked_ligands.mol2, a file containing every conformations of every ligands.
        if [ ! -f  ${RUNDIR}/${LIGAND}/VINA/output.mol2 ] || [ ${OVERWRITE} == 'yes' ] ; then
            babel -h -ipdbqt ${RUNDIR}/${LIGAND}/VINA/output.pdbqt -omol2 ${RUNDIR}/${LIGAND}/VINA/output.mol2
        fi

        OLDIFS=$IFS
        IFS='%'
        n=0
        while read line ; do
            if [ "${line}" == "${RUNDIR}/${LIGAND}/VINA/output.pdbqt" ] ; then
                let n++
                echo ${LIGAND}_conf_${n} >>  ${RUNDIR}/docked_ligands.mol2
            else
                echo "${line}" >> ${RUNDIR}/docked_ligands.mol2
            fi
        done < ${RUNDIR}/${LIGAND}/VINA/output.mol2
        IFS=${OLDIFS}
    fi
done

if [ -f DockFlow.csv ] ; then
    sed -i 's/[a-zA-Z0-9]*_conf_//' DockFlow.csv
fi
}


DockFlow_postdock() {
#===  FUNCTION  ================================================================
#          NAME: DockFlow_PostDock
#   DESCRIPTION: Post processing DockFlow runs depending on the dock program used
#                Each project / receptor will have: - a DockFlow.csv
#                                                   - a docked_ligands.mol2
#
#    PARAMETERS: ${DOCK_PROGRAM}
#
#        Author: Diego E. B. Gomes
#                Dona de Francquen
#
#        UPDATE: thur. july 5 14:49:50 CEST 2018
#
#===============================================================================

PROJECT=$(echo ${PROJECT} | cut -d. -f1)

# Start up going to the project folder.
cd ${WORKDIR}/${PROJECT}.chemflow/DockFlow

# Retrieve available protocols
if [ ! -z ${POSTDOCK_ALL} ] ; then
    PROTOCOL_LIST=($(ls -d */ | cut -d/ -f1))
else
    PROTOCOL_LIST=${PROTOCOL}
fi
#echo "Protocols: ${PROTOCOL_LIST[@]}"


for PROTOCOL in ${PROTOCOL_LIST[@]}  ; do

    # Start up going to the project folder.
    cd ${WORKDIR}/${PROJECT}.chemflow/DockFlow/${PROTOCOL}

    # Retrieve available receptors
    if [ ! -z ${POSTDOCK_ALL} ] ; then
        RECEPTOR_LIST=($(ls -d */| cut -d/ -f1))
    else
        RECEPTOR_LIST=${RECEPTOR_NAME}
    fi
#    echo "Receptors: ${RECEPTOR_LIST[@]}"

    for RECEPTOR in ${RECEPTOR_LIST[@]} ; do
        RUNDIR="${WORKDIR}/${PROJECT}.chemflow/DockFlow/${PROTOCOL}/${RECEPTOR}"
        cd ${RUNDIR}

        # Cleanup
        if [ -f DockFlow.csv ] ; then rm DockFlow.csv ; fi
        if [ -f docked_ligands.mol2 ] ; then rm docked_ligands.mol2 ; fi

        echo "DOCK_PROGRAM PROTOCOL LIGAND POSE SCORE" > DockFlow.csv

        # Organize to ChemFlow standard.
        if [ "${DOCK_PROGRAM}" == "PLANTS" ] ; then
            DockFlow_postdock_plants_results
        elif [ "${DOCK_PROGRAM}" == "VINA" ] ; then
            DockFlow_postdock_vina_results
        fi

    done
done

if [ ! -z ${FAIL} ] ; then
    echo "[ DockFlow ] Error during post-docking, see error above." ; exit 0
else
    echo "[ DockFlow ] Done with post-processing."

    # Archiving.
    if [ ! -z ${POSTDOCK_ALL} ] ; then
        read -p "[ DockFlow ] Archive the docking results (folders) in TAR files? " opt
    else
        read -p "[ DockFlow ] Archive the docking results (folders) in a TAR file? " opt
    fi
    case ${opt} in
    "y"|"yes"|"Yes"|"Y"|"YES")
        DockFlow_archive
    ;;
    esac
fi

unset FAIL
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
 --postdock          : Process DockFlow output for the specified project/protocol/receptor.
 --postdock-all      : Process DockFlow output in a ChemFlow project.
 --archive           : Compress the docking folders for the specified project/protocol/receptor.
 --archive-all       : Compress the docking folders in a ChemFLow project.
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
    ERROR_MESSAGE="DockFlow called without arguments."
    ChemFlow_error ;
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
            DOCK_CENTER=("$2" "$3" "$4")
            shift 3 # past argument
        ;;
        --size)
            DOCK_LENGHT=("$2" "$3" "$4")
            shift 3
        ;;
        --radius)
            DOCK_RADIUS="$2"
            DOCK_LENGHT=("$2" "$2" "$2")
            shift # past argument
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
        # HPC options
        -nn|--nodes) # Number of NODES [1]
            NNODES="$2" # Same as above.
            shift # past argument
        ;;
        -w|--workload) # Workload manager, [SLURM] or PBS
            JOB_SCHEDULLER="$2"
            shift # past argument
        ;;
        ## PLANTS arguments
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
        #       USER_INPUT="$2"
        #       shift
        --postdock)
            POSTDOCK="yes"
        ;;
        --postdock-all)
            POSTDOCK="yes"
            POSTDOCK_ALL="yes"
        ;;
        --archive)
            ARCHIVE='yes'
        ;;
        --archive-all)
            ARCHIVE='yes'
            ARCHIVE_ALL="yes"
        ;;
        *)
            unknown="$1"        # unknown option
            echo "Unknown flag \"$unknown\""
        ;;
    esac
    shift # past argument or value
done
}
