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
## Initializes all DockFlow variables, then reads user input from command line
##
## Author:
## dgomes    - Diego Enry Barreto Gomes - dgomes@pq.cnpq.br
## cbouy     - Cedric Bouysset - cbouysset@unice.fr
##
## Last Update: (date, by who and where )
## vendredi 25 mai 2018, 13:54:40 (UTC+0200) by dgomes @ Universite de Strasbourg.
##
###############################################################################

DockFlow_dock() {
#===  FUNCTION  ================================================================
#          NAME: DockFlow_Dock.
#   DESCRIPTION: Loop over LIGAND_LIST and dock them to receptor.mol2
#                (Diego is not very confident BASH will confortably handle > 1 million of elemente in the array.)
#
#    PARAMETERS: ${WORKDIR}
#                ${PROJECT}
#                ${RUNDIR}
#                ${LIGAND}
#       RETURNS: ${LIGAND_LIST} - List of ligands to dock.
#===============================================================================
# Always work here
cd ${RUNDIR}

#DockFlow_update_ligand_list
DockFlow_update_ligand_list_DEV
NDOCK=${#LIGAND_LIST[@]}

if [ ${NDOCK} == 0 ] ; then
    echo "[ DockFlow ] All compounds already docked ! " ; exit 0
else
    echo "There are ${NLIGANDS} compounds and ${NDOCK} remaining to dock"
fi

# config file for plants
if [ ${DOCK_PROGRAM} == "PLANTS" ] ; then
    # Write plants config
    RECEPTOR_FILE="../receptor.mol2"
    if [ -z "${PLANTS_WATER}" -a -z "${File_plants_pre}" -a -z "${File_plants_fil}" ]; then
        file=$(cat ${CHEMFLOW_HOME}/templates/plants/plants_config_original.in)
    fi 
    if [ ! -z "${File_plants_pre}" ]; then
       file=$(cat ${File_plants_pre})
    fi
    if [ ! -z "${File_plants_fil}" ]; then
       file=$(cat ${File_plants_fil})
    fi
    if [ ! -z "${PLANTS_WATER}" ]; then
      file=$(cat ${CHEMFLOW_HOME}/templates/plants/plants_water_config.in)
    fi
    eval echo \""${file}"\" > ${RUNDIR}/dock_input.in
fi

# config file for smina
if [ ${DOCK_PROGRAM} == "SMINA" ] ; then
    # Write smina config
    RECEPTOR_FILE="../receptor.mol2"
    if [ -z "${File_vina_config}" -a -z "${File_vina_fil}" ]; then
        file=$(cat ${CHEMFLOW_HOME}/templates/smina/config-basic.txt)
    fi
    if [ ! -z "${File_vina_config}" ]; then
       file=$(cat ${File_vina_config})
    fi
    if [ ! -z "${File_vina_fil}" ]; then
       file=$(cat ${File_vina_fil})
    fi
    eval echo \""${file}"\" > ${RUNDIR}/dock_input.txt
fi
#check_config

case ${JOB_SCHEDULLER} in
"None")
    if [ -f  dock.xargs ] ; then
      rm -rf dock.xargs
    fi
    # Write dock.xargs
    case ${DOCK_PROGRAM} in
    "PLANTS")
        for LIGAND in ${LIGAND_LIST[@]} ; do
            if [ -d ${RUNDIR}/${LIGAND}/PLANTS ] ; then
                ERROR_MESSAGE="PLANTS folder exists. Use --overwrite " ; ChemFlow_error ;
            fi
            echo "cd ${RUNDIR}/${LIGAND} ; echo [ Docking ] ${RECEPTOR_NAME} - ${LIGAND} ;  PLANTS1.2_64bit --mode screen ../dock_input.in &> PLANTS.log ; rm -rf PLANTS/{protein.log,descent_ligand_1.dat,protein_bindingsite_fixed.mol2}" >> dock.xargs
        done
    ;;
    "SMINA")
        for LIGAND in ${LIGAND_LIST[@]} ; do
            if [ ! -d ${RUNDIR}/${LIGAND}/SMINA ] ; then
                echo "mkdir -p ${RUNDIR}/${LIGAND}/SMINA " >> dock.xargs
            fi
	    if [ -f  "${WORKDIR}/${conf_file}" ] ; then
	        cp  ${WORKDIR}/${conf_file} ${RUNDIR}/ 
		# rm ${RUNDIR}/dock_input.txt	
		echo "echo [ Docking ] ${RECEPTOR_NAME} - ${LIGAND} ; smina.static --receptor ${RUNDIR}/receptor.pdbqt --ligand ${RUNDIR}/${LIGAND}/ligand.pdbqt --config ${WORKDIR}/${conf_file} --out ${RUNDIR}/${LIGAND}/SMINA/output.pdbqt --log ${RUNDIR}/${LIGAND}/SMINA/output.log &>/dev/null " >> dock.xargs
            else
	        echo "echo [ Docking ] ${RECEPTOR_NAME} - ${LIGAND} ; smina.static --receptor ${RUNDIR}/receptor.pdbqt --ligand ${RUNDIR}/${LIGAND}/ligand.pdbqt --center_x ${DOCK_CENTER[0]} --center_y ${DOCK_CENTER[1]} --center_z ${DOCK_CENTER[2]} --size_x ${DOCK_LENGTH[0]} --size_y ${DOCK_LENGTH[1]} --size_z ${DOCK_LENGTH[2]} --num_modes ${DOCK_POSES} --accurate_line --energy_range ${ENERGY_RANGE} --exhaustiveness ${EXHAUSTIVENESS} --out ${RUNDIR}/${LIGAND}/SMINA/output.pdbqt --log ${RUNDIR}/${LIGAND}/SMINA/output.log &>/dev/null " >> dock.xargs            
	    fi
        done
    ;;
    "QVINA")
        for LIGAND in ${LIGAND_LIST[@]} ; do
            if [ ! -d ${RUNDIR}/${LIGAND}/QVINA ] ; then
                echo "mkdir -p ${RUNDIR}/${LIGAND}/QVINA " >> dock.xargs
            fi
            echo "echo [ Docking ] ${RECEPTOR_NAME} - ${LIGAND} ; qvina2.1 --receptor ${RUNDIR}/receptor.pdbqt --ligand ${RUNDIR}/${LIGAND}/ligand.pdbqt --center_x ${DOCK_CENTER[0]} --center_y ${DOCK_CENTER[1]} --center_z ${DOCK_CENTER[2]} --size_x ${DOCK_LENGTH[0]} --size_y ${DOCK_LENGTH[1]} --size_z ${DOCK_LENGTH[2]} --num_modes ${DOCK_POSES} --energy_range ${ENERGY_RANGE} --exhaustiveness ${EXHAUSTIVENESS}  --out ${RUNDIR}/${LIGAND}/QVINA/output.pdbqt --log ${RUNDIR}/${LIGAND}/QVINA/output.log  ${VINA_EXTRA} &>/dev/null " >> dock.xargs
        done
    ;;
    "VINA")
        for LIGAND in ${LIGAND_LIST[@]} ; do
            if [ ! -d ${RUNDIR}/${LIGAND}/VINA ] ; then
                echo "mkdir -p ${RUNDIR}/${LIGAND}/VINA " >> dock.xargs
            fi
            echo "echo [ Docking ] ${RECEPTOR_NAME} - ${LIGAND} ; vina --receptor ${RUNDIR}/receptor.pdbqt --ligand ${RUNDIR}/${LIGAND}/ligand.pdbqt --center_x ${DOCK_CENTER[0]} --center_y ${DOCK_CENTER[1]} --center_z ${DOCK_CENTER[2]} --size_x ${DOCK_LENGTH[0]} --size_y ${DOCK_LENGTH[1]} --size_z ${DOCK_LENGTH[2]} --num_modes ${DOCK_POSES} --energy_range ${ENERGY_RANGE} --exhaustiveness ${EXHAUSTIVENESS} --out ${RUNDIR}/${LIGAND}/VINA/output.pdbqt --log ${RUNDIR}/${LIGAND}/VINA/output.log --cpu 1 ${VINA_EXTRA} &>/dev/null " >> dock.xargs
        done
    ;;
    esac

    cd ${RUNDIR} ; cat dock.xargs | xargs -P${NCORES} -I '{}' bash -c '{}'
;;
"SLURM"|"PBS")
    echo -ne "\nHow many Dockings per PBS/SLURM job? "
    read nlig
###
### Marion! WHAT THE HELL WHAT THIS ?

    # Check if the user gave a int
    #nb=${nlig}
    #nlig=1
#    nb=${nlig}
#    not_a_number
# if [ "${nb}" -eq "${nlig}" ] ; then
# 	for LIGAND in ${LIGAND_LIST[@]} ; do
# 		jobname="${LIGAND}"
# 		if [ -f ${RUNDIR}/DockFlow.${JOB_SCHEDULLER,,} ] ; then
#             		rm -rf ${RUNDIR}/DockFlow.${JOB_SCHEDULLER,,}
#         	fi
# 		if [ "${DOCK_PROGRAM}" == "PLANTS" ] ; then
# echo "
# #SBATCH --output=${LIGAND}.out

# cd ${RUNDIR}

#     # plants command.
# echo \"cd ${RUNDIR}/${LIGAND} ; time PLANTS1.2_64bit --mode screen ../dock_input.in &> docking.log ; rm -rf PLANTS/{protein.log,descent_ligand_1.dat,protein_bindingsite_fixed.mol2}\" >> ${LIGAND}.xargs
# cat ${LIGAND}.xargs | xargs -P${NCORES} -I '{}' bash -c '{}'
# "> DockFlow.run
#             	fi	
# 		DockFlow_write_HPC_header2	
# 	        if [ "${JOB_SCHEDULLER}" == "SLURM" ] ; then
#             		sbatch DockFlow.slurm
# 		fi
# 	done
# else
###
    for (( first=0;${first}<${NDOCK} ; first=${first}+${nlig} )) ; do
#        echo -ne "Docking $first         \r"
        jobname="${first}"

        if [ -f ${RUNDIR}/DockFlow.${JOB_SCHEDULLER,,} ] ; then
            rm -rf ${RUNDIR}/DockFlow.${JOB_SCHEDULLER,,}
        fi

        if [ "${DOCK_PROGRAM}" == "PLANTS" ] ; then
            DockFlow_write_plants_HPC

        elif [ "${DOCK_PROGRAM}" == "VINA" ] ; then
            DockFlow_write_vina_HPC

	    elif [ "${DOCK_PROGRAM}" == "SMINA" ] ; then
            DockFlow_write_smina_HPC

        elif [ "${DOCK_PROGRAM}" == "QVINA" ] ; then
            DockFlow_write_qvina_HPC
        fi

        DockFlow_write_HPC_header

        if [ "${JOB_SCHEDULLER}" == "SLURM" ] ; then
            sbatch DockFlow.slurm
        elif [ "${JOB_SCHEDULLER}" == "PBS" ] ; then
            qsub DockFlow.pbs
        fi
    done
### fi
### [END] WHAT THE HELL WHAT THIS ?

;;
esac
}


DockFlow_update_ligand_list() {
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
"SMINA")
    # If the folder exists but there's no "output.pdbqt" its incomplete.
    FILE="output.pdbqt"
;;
"QVINA")
    # If the folder exists but there's no "output.pdbqt" its incomplete.
    FILE="output.pdbqt"
;;
esac

if [ "${OVERWRITE}" == "no" ] ; then # Useless to update ligand list if we overwrite
    for LIGAND in ${LIGAND_LIST[@]} ; do
        if [ -d ${LIGAND}/${DOCK_PROGRAM} ] && [ ! -f ${LIGAND}/${DOCK_PROGRAM}/${FILE} ] ; then
#            echo "[ NOTE ] ${RECEPTOR_NAME} and ${LIGAND} incomplete... redoing it !"
            rm -rf ${LIGAND}/${DOCK_PROGRAM}
            DOCK_LIST="${DOCK_LIST} $LIGAND"
        fi
        if [ -f ${LIGAND}/${DOCK_PROGRAM}/${FILE} ] ; then
            if [ $(wc -l  ${LIGAND}/${DOCK_PROGRAM}/${FILE} | cut -d' ' -f1) -lt 2 ] ; then
#                echo "[ NOTE ] ${RECEPTOR_NAME} and ${LIGAND} incomplete... redoing it !"
                rm -rf ${LIGAND}/${DOCK_PROGRAM}
                DOCK_LIST="${DOCK_LIST} $LIGAND"
            fi
        fi
        if [ ! -d ${LIGAND}/${DOCK_PROGRAM} ] ; then
            DOCK_LIST="${DOCK_LIST} $LIGAND"  # Still unused.
        fi
    done
    DOCK_LIST=(${DOCK_LIST})
else
    DOCK_LIST=(${LIGAND_LIST[@]})
fi

unset LIGAND_LIST
LIGAND_LIST=(${DOCK_LIST[@]})
}

DockFlow_update_ligand_list_DEV() {
# Creation of the docking list, checkpoint calculations.
DOCK_LIST=""
case ${DOCK_PROGRAM} in
"PLANTS")
    # If the folder exists but there's no "bestranking.csv" its incomplete.
    FILE="bestranking.csv"
;;
"QVINA")
    # If the folder exists but there's no "output.pdbqt" its incomplete.
    FILE="output.pdbqt"
;;
"SMINA")
    # If the folder exists but there's no "output.pdbqt" its incomplete.
    FILE="output.pdbqt"
;;
"VINA")
    # If the folder exists but there's no "output.pdbqt" its incomplete.
    FILE="output.pdbqt"
;;
esac


if [ "${OVERWRITE}" == "no" ] ; then # Useless to update ligand list if we overwrite

    counter=0
    for LIGAND in ${LIGAND_LIST[@]} ; do
        if [ -d ${LIGAND}/${DOCK_PROGRAM} ] && [ ! -f ${LIGAND}/${DOCK_PROGRAM}/${FILE} ] ; then
#            echo "[ NOTE ] ${RECEPTOR_NAME} and ${LIGAND} incomplete... redoing it !"
            rm -rf ${LIGAND}/${DOCK_PROGRAM}
            DOCK_LIST[${counter}]="$LIGAND"
        fi
        if [ -f ${LIGAND}/${DOCK_PROGRAM}/${FILE} ] ; then
            if [ $(wc -l  ${LIGAND}/${DOCK_PROGRAM}/${FILE} | cut -d' ' -f1) -lt 2 ] ; then
#                echo "[ NOTE ] ${RECEPTOR_NAME} and ${LIGAND} incomplete... redoing it !"
                rm -rf ${LIGAND}/${DOCK_PROGRAM}
                DOCK_LIST[${counter}]="$LIGAND"
            fi
        fi
        if [ ! -d ${LIGAND}/${DOCK_PROGRAM} ] ; then
                DOCK_LIST[${counter}]="$LIGAND"
  # Still unused.
        fi

        let counter++
    done
else
    DOCK_LIST=(${LIGAND_LIST[@]})
fi

unset LIGAND_LIST
LIGAND_LIST=(${DOCK_LIST[@]})
}





DockFlow_write_plants_HPC() {
#===  FUNCTION  ================================================================
#          NAME: DockFlow_write_plants_HPC
#   DESCRIPTION: Writes the plants script for each ligand (or range of ligands).
#                Filenames and parameters are hardcoded.
#    PARAMETERS:
#               ${list[@]}  -   Array with all ligand names
#               ${first}    -   First ligand in the array
#               ${$nlig}    -   Number of compounds to dock
#               ${NCORES}   -   Number of cores/node
#
#          NOTE: Must be run while at "${RUNDIR}
#       RETURNS: -
#===============================================================================
echo "
cd ${RUNDIR}

if [ -f ${first}.xargs ] ; then rm -rf ${first}.xargs ; fi
for LIGAND in ${LIGAND_LIST[@]:$first:$nlig} ; do
    # plants command.
    echo \"cd ${RUNDIR}/\${LIGAND} ; time PLANTS1.2_64bit --mode screen ../dock_input.in &> docking.log ; rm -rf PLANTS/{protein.log,descent_ligand_1.dat,protein_bindingsite_fixed.mol2}\" >> ${first}.xargs
done
cat ${first}.xargs | xargs -P${NCORES} -I '{}' bash -c '{}'
"> DockFlow.run
}


DockFlow_write_vina_HPC() {
#===  FUNCTION  ================================================================
#          NAME: DockFlow_write_vina_HPC
#   DESCRIPTION: Writes the vina script for each ligand (or range of ligands). for VINA
#                Filenames and parameters are hardcoded.
#    PARAMETERS:
#               ${list[@]}  -   Array with all ligand names
#               ${first}    -   First ligand in the array
#               ${$nlig}    -   Number of compounds to dock
#               ${NCORES}   -   Number of cores/node
#
#          NOTE: Must be run while at "${RUNDIR}
#       RETURNS: -
#===============================================================================
echo "
cd ${RUNDIR}

if [ -f ${first}.xargs ] ; then rm -rf ${first}.xargs ; fi
for LIGAND in ${LIGAND_LIST[@]:$first:$nlig} ; do
    # Vina command.
    echo \"mkdir -p ${RUNDIR}/\${LIGAND}/VINA/ ; vina --receptor ${RUNDIR}/receptor.pdbqt --ligand ${RUNDIR}/\${LIGAND}/ligand.pdbqt \
        --center_x ${DOCK_CENTER[0]} --center_y ${DOCK_CENTER[1]} --center_z ${DOCK_CENTER[2]} \
        --size_x ${DOCK_LENGTH[1]} --size_y ${DOCK_LENGTH[2]} --size_z ${DOCK_LENGTH[3]} \
	--num_modes ${DOCK_POSES}\
        --energy_range ${ENERGY_RANGE} --exhaustiveness ${EXHAUSTIVENESS} \
        --out ${RUNDIR}/\${LIGAND}/VINA/output.pdbqt --log ${RUNDIR}/\${LIGAND}/VINA/output.log --cpu 1 &>/dev/null \" >> ${first}.xargs
done
cat ${first}.xargs | xargs -P${NCORES} -I '{}' bash -c '{}'
"> DockFlow.run
}

DockFlow_write_qvina_HPC() {
#===  FUNCTION  ================================================================
#          NAME: DockFlow_write_qvina_HPC
#   DESCRIPTION: Writes the qvina script for each ligand (or range of ligands). for VINA
#                Filenames and parameters are hardcoded.
#    PARAMETERS:
#               ${list[@]}  -   Array with all ligand names
#               ${first}    -   First ligand in the array
#               ${$nlig}    -   Number of compounds to dock
#               ${NCORES}   -   Number of cores/node
#
#          NOTE: Must be run while at "${RUNDIR}
#       RETURNS: -
#===============================================================================
echo "
cd ${RUNDIR}

if [ -f ${first}.xargs ] ; then rm -rf ${first}.xargs ; fi
for LIGAND in ${LIGAND_LIST[@]:$first:$nlig} ; do
    # qvina command.
    echo \"mkdir -p ${RUNDIR}/\${LIGAND}/QVINA/ ; qvina2.1 --receptor ${RUNDIR}/receptor.pdbqt --ligand ${RUNDIR}/\${LIGAND}/ligand.pdbqt \
        --center_x ${DOCK_CENTER[0]} --center_y ${DOCK_CENTER[1]} --center_z ${DOCK_CENTER[2]} \
        --size_x ${DOCK_LENGTH[1]} --size_y ${DOCK_LENGTH[2]} --size_z ${DOCK_LENGTH[3]} \
	--num_modes ${DOCK_POSES}\
        --energy_range ${ENERGY_RANGE} --exhaustiveness ${EXHAUSTIVENESS} \
        --out ${RUNDIR}/\${LIGAND}/QVINA/output.pdbqt --log ${RUNDIR}/\${LIGAND}/QVINA/output.log --cpu 1 &>/dev/null \" >> ${first}.xargs
done
cat ${first}.xargs | xargs -P${NCORES} -I '{}' bash -c '{}'
"> DockFlow.run
}

DockFlow_write_smina_HPC() {
#===  FUNCTION  ================================================================
#          NAME: DockFlow_write_smina_HPC
#   DESCRIPTION: Writes the smina script for each ligand (or range of ligands). for VINA
#                Filenames and parameters are hardcoded.
#    PARAMETERS:
#               ${list[@]}  -   Array with all ligand names
#               ${first}    -   First ligand in the array
#               ${$nlig}    -   Number of compounds to dock
#               ${NCORES}   -   Number of cores/node
#
#          NOTE: Must be run while at "${RUNDIR}
#       RETURNS: -
#===============================================================================
echo "
cd ${RUNDIR}

if [ -f ${first}.xargs ] ; then rm -rf ${first}.xargs ; fi
for LIGAND in ${LIGAND_LIST[@]:$first:$nlig} ; do
    # Vina command.
    echo \"mkdir -p ${RUNDIR}/\${LIGAND}/SMINA/ ; smina.static --receptor ${RUNDIR}/receptor.pdbqt --ligand ${RUNDIR}/\${LIGAND}/ligand.pdbqt \
        --center_x ${DOCK_CENTER[0]} --center_y ${DOCK_CENTER[1]} --center_z ${DOCK_CENTER[2]} \
        --size_x ${DOCK_LENGTH[1]} --size_y ${DOCK_LENGTH[2]} --size_z ${DOCK_LENGTH[3]} \
	--num_modes ${DOCK_POSES}\
        --energy_range ${ENERGY_RANGE} --exhaustiveness ${EXHAUSTIVENESS} \
	--accurate_line --scoring vinardo
        --out ${RUNDIR}/\${LIGAND}/SMINA/output.pdbqt --log ${RUNDIR}/\${LIGAND}/SMINA/output.log --cpu 1 &>/dev/null \" >> ${first}.xargs
done
cat ${first}.xargs | xargs -P${NCORES} -I '{}' bash -c '{}'
"> DockFlow.run
}


DockFlow_write_HPC_header() {
#===  FUNCTION  ================================================================
#          NAME: DockFlow_write_HPC_header
#   DESCRIPTION: Add the HPC header to DockFlow.run.
#                Default or provided header.
#
#    PARAMETERS: ${RUNDIR}
#                ${CHEMFLOW_HOME}
#                ${JOB_SCHEDULLER}
#                ${WORKDIR}
#                ${HEADER_PROVIDED}
#                ${HEADER_FILE}
#
#       RETURNS: ScoreFlow.pbs for ${LIGAND}
#===============================================================================
if [ ! -f ${RUNDIR}/DockFlow.header ] ; then
    if [ ${HEADER_PROVIDED} != "yes" ] ; then
        file=$(cat ${CHEMFLOW_HOME}/templates/dock_${JOB_SCHEDULLER,,}.template)
        eval echo \""${file}"\" > ${RUNDIR}/DockFlow.header
    else
        cp ${HEADER_FILE} ${RUNDIR}/DockFlow.header
    fi
fi
case "${JOB_SCHEDULLER}" in
        "PBS")
            sed "/PBS -N .*$/ s/$/_${first}/" ${RUNDIR}/DockFlow.header > ${RUNDIR}/DockFlow.${JOB_SCHEDULLER,,}
        ;;
        "SLURM")
            sed "/--job-name=.*$/  s/$/_${first}/" ${RUNDIR}/DockFlow.header > ${RUNDIR}/DockFlow.${JOB_SCHEDULLER,,}
        ;;
        esac

cat ${RUNDIR}/DockFlow.run >> ${RUNDIR}/DockFlow.${JOB_SCHEDULLER,,}
}

not_a_number() {
re=^[0-9]+$
if ! [[ $nb =~ $re ]] ; then
   ERROR_MESSAGE="Not a number. I was expecting an integer." ; ChemFlow_error ;
fi
}


DockFlow_prepare_receptor() {
#===  FUNCTION  ================================================================
#          NAME: DockFlow_prepare_receptor
#   DESCRIPTION: Prepare the receptor for the docking:
#                Copy the receptor file into the rundir folder as receptor.mol2
#                 - PLANTS uses the mol2 file,
#                 - VINA, QVINA,SMINA use a pdbqt file. It is converted using AutoDockTools
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
cp ${RECEPTOR_FILE} ${RUNDIR}/receptor.mol2
 case ${DOCK_PROGRAM} in

   "VINA" )
        if  [ ! -f  ${RUNDIR}/receptor.pdbqt ] ; then
		python2 $(which prepare_receptor4.py) -r ${RUNDIR}/receptor.mol2 -o ${RUNDIR}/receptor.pdbqt
        fi
   ;;
   "QVINA")
        if  [ ! -f  ${RUNDIR}/receptor.pdbqt ] ; then
	        python2 $(which prepare_receptor4.py) -r ${RUNDIR}/receptor.mol2 -o ${RUNDIR}/receptor.pdbqt
	fi
   ;;
   "SMINA")
        if  [ ! -f  ${RUNDIR}/receptor.pdbqt ] ; then
        	python2 $(which prepare_receptor4.py) -r ${RUNDIR}/receptor.mol2 -o ${RUNDIR}/receptor.pdbqt
	fi
   ;;

    esac
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

echo "[Preparing ligands]"
# Create ligand folder into the project
for LIGAND in ${LIGAND_LIST[@]} ; do
    if [ ! -d  ${LIGAND} ] ; then
        mkdir -p  ${LIGAND}
        if [ ! -d ${LIGAND} ] ; then
            echo "[ ERROR ] Could not create ${LIGAND} directory in ${RUNDIR}."
            exit 0
        fi
    fi
    case ${DOCK_PROGRAM} in
    "PLANTS")
        if [ ! -f ${LIGAND}/ligand.mol2 ] ; then
            cp ${WORKDIR}/${PROJECT}.chemflow/DockFlow/${PROTOCOL}/input/${LIGAND}.mol2 ${LIGAND}/ligand.mol2
        fi
    ;;
    "VINA")
    	    if [ ! -f  ${LIGAND}/ligand.pdbqt ] ; then
		cp ${WORKDIR}/${PROJECT}.chemflow/DockFlow/${PROTOCOL}/input/${LIGAND}.mol2 ${LIGAND}/ligand.mol2
		cd ${LIGAND}/
		python2 $(which prepare_ligand4.py) -l  ligand.mol2 -o  ligand.pdbqt -U 'lps'
#        fi
		cd ${RUNDIR}
	fi
    ;; 
    "SMINA")
        if [ ! -f  ${LIGAND}/ligand.pdbqt ] ; then
                cp ${WORKDIR}/${PROJECT}.chemflow/DockFlow/${PROTOCOL}/input/${LIGAND}.mol2 ${LIGAND}/ligand.mol2
                cd ${LIGAND}/
		python2 $(which prepare_ligand4.py) -l ligand.mol2 -o ligand.pdbqt -U 'lps'
	fi
		cd ${RUNDIR}
    ;;
    "QVINA")
        if [ ! -f  ${LIGAND}/ligand.pdbqt ] ; then
		cp ${WORKDIR}/${PROJECT}.chemflow/DockFlow/${PROTOCOL}/input/${LIGAND}.mol2 ${LIGAND}/ligand.mol2
		cd ${LIGAND}/
		python2 $(which prepare_ligand4.py) -l ligand.mol2 -o ligand.pdbqt -U 'lps'
        fi
		cd ${RUNDIR}
    ;;
    esac
done
echo "[ DONE ]"
}


DockFlow_divide_input_ligands() {
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
#
#        Author: Dona de Francquen
#
#        UPDATE: fri. july 6 14:49:50 CEST 2018
#                09 10 19 Sisquellas Marion
#
#===============================================================================
OLDIFS=$IFS
IFS='%'
n=-1
if [ ! -d ${WORKDIR}/${PROJECT}.chemflow/DockFlow/${PROTOCOL}/input/ ] ; then
    mkdir -p ${WORKDIR}/${PROJECT}.chemflow/DockFlow/${PROTOCOL}/input/
fi
while read line ; do
    #echo ${line}
    if [ "${line}" == '@<TRIPOS>MOLECULE' ]; then
        let n=$n+1
        echo -e "${line}" > ${WORKDIR}/${PROJECT}.chemflow/DockFlow/${PROTOCOL}/input/${LIGAND_LIST[$n]}.mol2
    else
        echo -e "${line}" >> ${WORKDIR}/${PROJECT}.chemflow/DockFlow/${PROTOCOL}/input/${LIGAND_LIST[$n]}.mol2
    fi
done < ${LIGAND_FILE}
IFS=${OLDIFS}
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
#     Modify on 091019 to use the input file
#===============================================================================
# 1. Folder
if [ ${OVERWRITE} == "yes" ] ; then
    for LIGAND in ${LIGAND_LIST[@]} ; do
        rm -rf ${RUNDIR}/${LIGAND}
    done
fi

if [  ! -d ${RUNDIR} ] ; then
  mkdir -p ${RUNDIR}
fi

# Always work here
cd ${RUNDIR}

# 2. Receptor
DockFlow_prepare_receptor

# 3. Ligands


if [ -e ${WORKDIR}/${PROJECT}.chemflow/DockFlow/${PROTOCOL}/*.mol2 ] ; then
    if [ $( diff ${LIGAND_FILE} ${WORKDIR}/${PROJECT}.chemflow/DockFlow/${PROTOCOL}/*.mol2 | wc -l ) == 0 ] ; then 
    echo "Same input file as before"
    fi
else 
    cp ${LIGAND_FILE} ${WORKDIR}/${PROJECT}.chemflow/DockFlow/${PROTOCOL}/
    DockFlow_divide_input_ligands
fi

DockFlow_prepare_ligands

#if [ ! -d ${WORKDIR}/${PROJECT}.chemflow/LigFlow/original/ ] ; then
#    echo "Please run LigFlow before DockFlow to prepare the input ligands."
#    exit 0
#else
#    DockFlow_prepare_ligands
#fi
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
    if [ ! -z ${ARCHIVE_ALL} ] || [ ! -z ${POSTPROCESS_ALL} ] ; then
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
            if [ ! -z ${ARCHIVE_ALL} ] || [ ! -z ${POSTPROCESS_ALL} ] ; then
                RECEPTOR_LIST=($(ls -d */| cut -d/ -f1))
            else
                RECEPTOR_LIST=${RECEPTOR_NAME}
            fi
        #    echo "Receptors: ${RECEPTOR_LIST[@]}"

            for RECEPTOR in ${RECEPTOR_LIST[@]} ; do
                if [ -d ${WORKDIR}/${PROJECT}.chemflow/DockFlow/${PROTOCOL}/${RECEPTOR} ] ; then
                    #  Go to the receptor folder.
                    cd ${WORKDIR}/${PROJECT}.chemflow/DockFlow/${PROTOCOL}/${RECEPTOR}

                    if [ -d ${WORKDIR}/${PROJECT}.chemflow/DockFlow/${PROTOCOL}/${RECEPTOR}/${LIGAND_LIST}/ ] ; then
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
if [ ! -z ${ARCHIVE_ALL} ] || [ ! -z ${POSTPROCESS_ALL} ] ; then
    echo -n "[ DockFlow ] Remove all docking folders? [y/n] "
    read opt
else
    echo -n "[ DockFlow ] Remove docking folders for ${PROTOCOL} / ${RECEPTOR}? [y/n] "
    read opt
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
let DOCK_POSES++


if [ ! -z ${POSTPROCESS_ALL} ] ; then
  unset LIGAND_LIST
  LIGAND_LIST=($(ls -d */ | cut -d/ -f1))
fi


# First, a clean up.
if [ -f ${RUNDIR}/docked_ligands.mol2 ] ; then
    rm -rf ${RUNDIR}/docked_ligands.mol2
fi

for LIGAND in ${LIGAND_LIST[@]}; do
    if [ ! -f ${LIGAND}/PLANTS/docked_ligands.mol2 ] ; then
        echo "[ ERROR ] Plants result for ligand ${LIGAND} does not exists."
        FAIL="true"
    else
        # Fill the DockFlow.csv file
        echo -ne "PostDock: ${PROTOCOL} - ${LIGAND}                              \r"
#        head -${DOCK_POSES} ${LIGAND}/PLANTS/ranking.csv | awk -v protocol=${PROTOCOL} -v target=${RECEPTOR_NAME} -v ligand=${LIGAND} -F, '!/LIGAND_ENTRY/ {print "PLANTS",protocol,target,ligand,$1,$2}' >> DockFlow.csv
# Patch by Kgalentino & Dgomes
        awk -F, -v protocol=${PROTOCOL} -v target=${RECEPTOR_NAME} -v ligand=${LIGAND} -v dock_poses=${DOCK_POSES} '!/LIGAND/{cc++; if(cc<=dock_poses){gsub(".*_entry_00001_conf_","",$1); print "PLANTS",protocol,target,ligand, $1,$2}}'  ${LIGAND}/PLANTS/ranking.csv >> DockFlow.csv


        # Create the docked_ligands.mol2, a file containing every conformations of every ligands.
        OLDIFS=$IFS
        IFS='%'
        n=0
        while read line && [ "${n}" -lt ${DOCK_POSES} ] ; do
            if [ "${line}" == "@<TRIPOS>MOLECULE" ] ; then
                let n++
                if [ "${n}" -lt ${DOCK_POSES} ] ; then
                    echo "${line}" >>  ${RUNDIR}/docked_ligands.mol2
                fi
            else
                echo "${line}" >> ${RUNDIR}/docked_ligands.mol2
            fi
        done < ${LIGAND}/PLANTS/docked_ligands.mol2
        IFS=${OLDIFS}

#        cat ${LIGAND}/PLANTS/docked_ligands.mol2 >> docked_ligands.mol2
    fi
done
# rename the ligand in the created file
if [ -f docked_ligands.mol2 ] && [ -f DockFlow.csv ] ; then
    sed -i 's/\.*_entry_[[:digit:]]*//' docked_ligands.mol2
# Patch by Kgalentino & Dgomes    sed -i 's/[a-zA-Z0-9]*_entry_[[:digit:]]*_conf_//' DockFlow.csv
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


if [ ! -z ${POSTPROCESS_ALL} ] ; then
  unset LIGAND_LIST
  LIGAND_LIST=($(ls -d */ | cut -d/ -f1))
fi

for LIGAND in ${LIGAND_LIST[@]}; do
    if [ ! -f  ${RUNDIR}/${LIGAND}/VINA/output.pdbqt ] ; then
        echo "[ ERROR ] Vina's result for ligand ${LIGAND} does not exists."
        FAIL="true"
    else
        # Fill the DockFlow.csv file
        awk -v protocol=${PROTOCOL} -v target=${RECEPTOR_NAME} -v ligand=${LIGAND} -v conf=1 '/REMARK VINA RESULT/ {print "VINA",protocol,target,ligand,conf,$4; conf++}' ${RUNDIR}/${LIGAND}/VINA/output.pdbqt |  head -${DOCK_POSES}  >> DockFlow.csv

        # Create the docked_ligands.mol2, a file containing every conformations of every ligands.
        if [ ! -f  ${RUNDIR}/${LIGAND}/VINA/output.mol2 ] ; then
            obabel -h -ipdbqt ${RUNDIR}/${LIGAND}/VINA/output.pdbqt -omol2 -O${RUNDIR}/${LIGAND}/VINA/output.mol2
		#${mgltools_folder}/bin/python ${mgltools_folder}/MGLToolsPckgs/AutoDockTools/Utilities24/pdbqt_to_pdb.py -f ${RUNDIR}/${LIGAND}/VINA/output.pdbqt -o${RUNDIR}/${LIGAND}/VINA/${LIGAND}.pdb

#		obabel -ipdb ${RUNDIR}/${LIGAND}/VINA/${LIGAND}.pdb -omol2 -O${RUNDIR}/${LIGAND}/VINA/${LIGAND}_conv.mol2 -m --title MOL
#	sed -i "s/${LIGAND}.pdb/MOL/g" ${RUNDIR}/${LIGAND}/VINA/${LIGAND}_conv1.mol2 
#		id=`grep -A 1 "@<TRIPOS>MOLECULE" ${RUNDIR}/${LIGAND}/VINA/${LIGAND}_conv1.mol2 | tail -1`
#		antechamber -i ${i}_conv1.mol2 -fi mol2 -at sybyl -o ${i}_ok.mol2 -fo mol2  -pf y -dr n
	
       fi

        OLDIFS=$IFS
        IFS='%'
        n=0
        nt=0
        while read line  && [ "${n}" -le ${DOCK_POSES} ] ; do
            if [ "${line}" == "@<TRIPOS>MOLECULE" ] ; then
                let n++
                if [ "${n}" -le ${DOCK_POSES} ] ; then
                    echo "${line}" >>  ${RUNDIR}/docked_ligands.mol2
                fi
            elif [ "${line}" == "${RUNDIR}/${LIGAND}/VINA/output.pdbqt" ] ; then
                let nt++
                echo ${LIGAND}_conf_${nt} >>  ${RUNDIR}/docked_ligands.mol2
            else
                echo "${line}" >> ${RUNDIR}/docked_ligands.mol2
            fi
        done < ${RUNDIR}/${LIGAND}/VINA/output.mol2
#	 done < ${RUNDIR}/${LIGAND}/VINA/${LIGAND}_conv1.mol2
        IFS=${OLDIFS}
    fi
done
        cat DockFlow.csv | LC_ALL=C sort -nk6 >> SORTED.csv

        #KEEP JUST ONE CONFORMER PER LIGAND

        cat SORTED.csv | awk '{split($4,a,"_"); print a[1], $6, $4}' | awk '!a[$1]++' >> SORTED-uniq-lig.csv
	
if [ -f DockFlow.csv ] ; then
    sed -i 's/[a-zA-Z0-9]*_conf_//' DockFlow.csv
fi
}

DockFlow_postdock_smina_results() {
#===  FUNCTION  ================================================================
#          NAME: DockFlow_PostDock_SminaResults
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


if [ ! -z ${POSTPROCESS_ALL} ] ; then
  unset LIGAND_LIST
  LIGAND_LIST=($(ls -d */ | cut -d/ -f1))
fi

for LIGAND in ${LIGAND_LIST[@]}; do
    if [ ! -f  ${RUNDIR}/${LIGAND}/SMINA/output.pdbqt ] ; then
        echo "[ ERROR ] Smina's result for ligand ${LIGAND} does not exists."
        FAIL="true"
    else
        # Fill the DockFlow.csv file
	unset value
	value=$(awk '/REMARK minimizedAffinity/ {print $3;exit;}' ${RUNDIR}/${LIGAND}/SMINA/output.pdbqt )
	zero=0

	if awk 'BEGIN {exit !('$value' != '$zero')}' ; then
        awk -v protocol=${PROTOCOL} -v target=${RECEPTOR_NAME} -v ligand=${LIGAND} -v conf=1 '/REMARK minimizedAffinity / {print "SMINA",protocol,target,ligand,conf,$3; conf++}' ${RUNDIR}/${LIGAND}/SMINA/output.pdbqt |  head -${DOCK_POSES}  >> DockFlow.csv


	else
	awk -v protocol=${PROTOCOL} -v target=${RECEPTOR_NAME} -v ligand=${LIGAND} -v conf=1 '/REMARK minimizedRMSD / {print "SMINA-MIN",protocol,target,ligand,conf,$3; conf++}' ${RUNDIR}/${LIGAND}/SMINA/output.pdbqt |  head -${DOCK_POSES}  >> DockFlow-min.csv
        fi

	# Create the docked_ligands.mol2, a file containing every conformations of every ligands.
        if [ ! -f  ${RUNDIR}/${LIGAND}/SMINA/output.mol2 ] ; then
           obabel -h -ipdbqt ${RUNDIR}/${LIGAND}/SMINA/output.pdbqt -omol2 -O${RUNDIR}/${LIGAND}/SMINA/output.mol2 
        fi

        OLDIFS=$IFS
        IFS='%'
        n=0
        nt=0
        while read line  && [ "${n}" -le ${DOCK_POSES} ] ; do
            if [ "${line}" == "@<TRIPOS>MOLECULE" ] ; then
                let n++
                if [ "${n}" -le ${DOCK_POSES} ] ; then
                    echo "${line}" >>  ${RUNDIR}/docked_ligands.mol2
                fi
            elif [ "${line}" == "${RUNDIR}/${LIGAND}/SMINA/output.pdbqt" ] ; then
                let nt++
                echo ${LIGAND}_conf_${nt} >>  ${RUNDIR}/docked_ligands.mol2
            else
                echo "${line}" >> ${RUNDIR}/docked_ligands.mol2
            fi
        done < ${RUNDIR}/${LIGAND}/SMINA/output.mol2
        IFS=${OLDIFS}
    fi
done
        cat DockFlow.csv | LC_ALL=C sort -nk6 >> SORTED.csv

        #KEEP JUST ONE CONFORMER PER LIGAND

        cat SORTED.csv | awk '{split($4,a,"_"); print a[1], $6, $4}' | awk '!a[$1]++' >> SORTED-uniq-lig.csv
	
if [ -f DockFlow.csv ] ; then
    sed -i 's/[a-zA-Z0-9]*_conf_//' DockFlow.csv
    elif [ -f DockFlow-min.csv ] ; then
    sed -i 's/[a-zA-Z0-9]*_conf_//' DockFlow-min.csv
fi
}

DockFlow_postdock_qvina_results() {
#===  FUNCTION  ================================================================
#          NAME: DockFlow_PostDock_QvinaResults
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


if [ ! -z ${POSTPROCESS_ALL} ] ; then
  unset LIGAND_LIST
  LIGAND_LIST=($(ls -d */ | cut -d/ -f1))
fi

for LIGAND in ${LIGAND_LIST[@]}; do
    if [ ! -f  ${RUNDIR}/${LIGAND}/QVINA/output.pdbqt ] ; then
        echo "[ ERROR ] Qvina's result for ligand ${LIGAND} does not exists."
        FAIL="true"
    else
        # Fill the DockFlow.csv file
        awk -v protocol=${PROTOCOL} -v target=${RECEPTOR_NAME} -v ligand=${LIGAND} -v conf=1 '/REMARK VINA RESULT/ {print "QVINA",protocol,target,ligand,conf,$4; conf++}' ${RUNDIR}/${LIGAND}/QVINA/output.pdbqt |  head -${DOCK_POSES}  >> DockFlow.csv

        # Create the docked_ligands.mol2, a file containing every conformations of every ligands.
        if [ ! -f  ${RUNDIR}/${LIGAND}/QVINA/output.mol2 ] ; then
            obabel -h -ipdbqt ${RUNDIR}/${LIGAND}/QVINA/output.pdbqt -omol2 -O${RUNDIR}/${LIGAND}/QVINA/output.mol2
        fi

        OLDIFS=$IFS
        IFS='%'
        n=0
        nt=0
        while read line  && [ "${n}" -le ${DOCK_POSES} ] ; do
            if [ "${line}" == "@<TRIPOS>MOLECULE" ] ; then
                let n++
                if [ "${n}" -le ${DOCK_POSES} ] ; then
                    echo "${line}" >>  ${RUNDIR}/docked_ligands.mol2
                fi
            elif [ "${line}" == "${RUNDIR}/${LIGAND}/QVINA/output.pdbqt" ] ; then
                let nt++
                echo ${LIGAND}_conf_${nt} >>  ${RUNDIR}/docked_ligands.mol2
            else
                echo "${line}" >> ${RUNDIR}/docked_ligands.mol2
            fi
        done < ${RUNDIR}/${LIGAND}/QVINA/output.mol2
        IFS=${OLDIFS}
    fi
done
        cat DockFlow.csv | LC_ALL=C sort -nk6 >> SORTED.csv

        #KEEP JUST ONE CONFORMER PER LIGAND

        cat SORTED.csv | awk '{split($4,a,"_"); print a[1], $6, $4}' | awk '!a[$1]++' >> SORTED-uniq-lig.csv
	
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
if [ ! -z ${POSTPROCESS_ALL} ] ; then
    PROTOCOL_LIST=($(ls -d */ | cut -d/ -f1))
else
    PROTOCOL_LIST=${PROTOCOL}
fi
echo "Protocols: ${PROTOCOL_LIST[@]}"


for PROTOCOL in ${PROTOCOL_LIST[@]}  ; do

    # Start up going to the project folder.
    cd ${WORKDIR}/${PROJECT}.chemflow/DockFlow/${PROTOCOL}

    # Retrieve available receptors
    if [ ! -z ${POSTPROCESS_ALL} ] ; then
     	RECEPTOR_LIST=($(ls -d */ | egrep -v input/ | cut -d/ -f1))
        #to avoid selecting the input/ directory that exists in the $PROTOCOL/
	#RECEPTOR_LIST=($(ls -d */| cut -d/ -f1))
    else
        RECEPTOR_LIST=${RECEPTOR_NAME}
    fi
    echo "Receptors: ${RECEPTOR_LIST[@]}"

    for RECEPTOR in ${RECEPTOR_LIST[@]} ; do
        RUNDIR="${WORKDIR}/${PROJECT}.chemflow/DockFlow/${PROTOCOL}/${RECEPTOR}"
        cd ${RUNDIR}

# You should always overwrite docked_ligands.mol2 and DockFlow.csv
#        if [ "${OVERWRITE}"  == 'yes' ] ; then
            rm -rf ${RUNDIR}/docked_ligands.mol2
            rm -rf ${RUNDIR}/DockFlow.csv
            rm -rf ${RUNDIR}/DockFlow-min.csv
#        fi

        # Cleanup
        if [ ! -f ${RUNDIR}/DockFlow.csv ] ; then
		echo "DOCK_PROGRAM PROTOCOL RECEPTOR LIGAND POSE SCORE/RMSD(SMINA-MIN)" > DockFlow.csv
        fi

        # Organize to ChemFlow standard.
        if [ "${DOCK_PROGRAM}" == "PLANTS" ] ; then
            DockFlow_postdock_plants_results
        elif [ "${DOCK_PROGRAM}" == "VINA" ] ; then
            DockFlow_postdock_vina_results
        elif [ "${DOCK_PROGRAM}" == "SMINA" ] ; then
            DockFlow_postdock_smina_results
        elif [ "${DOCK_PROGRAM}" == "QVINA" ] ; then
            DockFlow_postdock_qvina_results 
        fi

    done
done

if [ ! -z ${FAIL} ] ; then
    echo "[ DockFlow ] Error during post-docking, see error above." ; exit 0
else
    echo "[ DockFlow ] Done with post-processing."

    # Archiving.
    if [ ! -z ${ARCHIVE} ] ; then
        echo -n "[ DockFlow ] Archive the docking results (folders) in TAR files? [y/n] "
        read opt
        case ${opt} in
        "y"|"yes"|"Yes"|"Y"|"YES")
            DockFlow_archive
        ;;
        esac
    fi

fi

unset FAIL
}


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
#                ${DOCK_LENGTH}
#                ${DOCK_RADIUS}
#                ${JOB_SCHEDULLER}
#                ${NCORES}
#                ${OVERWRITE}
#                
#       RETURNS: -
#
#===============================================================================

echo "\
DockFlow summary:
-------------------------------------------------------------------------------
[ General info ]
    HOST: ${HOSTNAME}
    USER: ${USER}
 PROJECT: ${PROJECT}
PROTOCOL: ${PROTOCOL}
 WORKDIR: ${WORKDIR}

[ Docking setup ]
RECEPTOR NAME: ${RECEPTOR_NAME}
RECEPTOR FILE: $(relpath "${RECEPTOR_FILE}" "${WORKDIR}")
  LIGAND FILE: $(relpath "${LIGAND_FILE}"   "${WORKDIR}")
     NLIGANDS: ${NLIGANDS}
       NPOSES: ${DOCK_POSES}
 DOCKING PROG: ${DOCKING_PROGRAM}
      SCORING: ${SCORING_FUNCTION}
       CENTER: ${DOCK_CENTER[@]}"
case ${DOCK_PROGRAM} in
"VINA")
    echo "         SIZE: ${DOCK_LENGTH[@]} (X,Y,Z)"
    echo " EXHAUSTIVITY: ${EXHAUSTIVENESS}"
    echo " ENERGY RANGE: ${ENERGY_RANGE}"
;;
"QVINA")
    echo "         SIZE: ${DOCK_LENGTH[@]} (X,Y,Z)"
    echo " EXHAUSTIVITY: ${EXHAUSTIVENESS}"
    echo " ENERGY RANGE: ${ENERGY_RANGE}"
;;
"SMINA")
    echo "         SIZE: ${DOCK_LENGTH[@]} (X,Y,Z)"
    echo " EXHAUSTIVITY: ${EXHAUSTIVENESS}"
    echo " ENERGY RANGE: ${ENERGY_RANGE}"
#    echo "  CONFIG FILE: ${conf_file}"
    if [ ! -z "${File_vina_config}" ]; then
        echo " INPUT SMINA: ${File_vina_config}"
    fi
    if [ ! -z "${File_vina_fil}" ]; then
        echo " INPUT SMINA: ${File_vina_fil}" 
    fi
    if [ -n "${conf_file}" ] ; then
	    echo " CONFIG FILE : ${conf_file}"
    fi
    echo " ACCURATE_LINE: yes "
;;
"PLANTS")
    echo "       RADIUS: ${DOCK_RADIUS}"
    echo "        SPEED: ${SPEED}"
    echo "         ANTS: ${ANTS}"
    echo "   EVAP. RATE: ${EVAP_RATE}"
    echo "ITER. SCALING: ${ITERATION_SCALING}"
    echo " CLUSTER RMSD: ${CLUSTER_RMSD}"
    if [ ! -z "${File_plants_pre}" ]; then
        echo " INPUT PLANTS: ${File_plants_pre}"
    fi  
    if [ ! -z "${File_plants_fil}" ]; then
        echo " INPUT PLANTS: ${File_plants_fil}" 
    fi   
    if [ ! -z "${PLANTS_WATER}" ]; then
        echo "   WATER FILE: ${WATER_FILE}"
        echo " WATER CENTER: ${WATER_XYZR[@]:0:3}"
        echo " WATER RADIUS: ${WATER_XYZR[3]}"
    fi
esac

echo "
[ Run options ]
JOB SCHEDULLER: ${JOB_SCHEDULLER}
    CORES/NODE: ${NCORES}
     OVERWRITE: ${OVERWRITE}
"

if [ "${YESTOALL}" != 'yes' ] ; then

echo -n "
Continue [y/n]? "
read opt
case $opt in
"Y"|"YES"|"Yes"|"yes"|"y")  ;;
*)  echo "Exiting" ; exit 0 ;;
esac

fi
}


DockFlow_help() {
echo "Example usage:
DockFlow -r receptor.mol2 -l ligand.mol2 -p myproject --center X Y Z [--protocol protocol-name] [-n 8] [-sf chemplp]

[Options]
 -h/--help           : Show this help message and quit
 -hh/--fullhelp      : Detailed help

 -r/--receptor       : Receptor's mol2 file.
 -l/--ligand         : Ligands .mol2 input file.
 -p/--project        : ChemFlow project.
 -dp/--program	     : Docking program

Dock:
 --center            : X Y Z coordinates of the center of the binding site, separated by a space.

Postprocess:
 --postprocess       : Process DockFlow output in a ChemFlow project.
"
exit 0
}


DockFlow_help_full(){
echo "DockFlow is a bash script designed to work with PLANTS, Vina, Qvina or Smina.

It can perform an automatic VS based on information given by the user :
ligands, receptor, binding site info, and extra options.

Usage:
DockFlow -r receptor.mol2 -l ligand.mol2 -p myproject --center X Y Z [--protocol protocol-name] [-n 10] [-sf chemplp]

[Help]
 -h/--help              : Show this help message and quit
 -hh/--fullhelp         : Detailed help

[ Required ]
*-p/--project       STR : ChemFlow project
*-r/--receptor     FILE : Receptor MOL2 file
*-l/--ligand       FILE : Ligands  MOL2 file
*-dp/--program	    STR : plants, vina, qvina, smina

[ Post Processing ]
 --postprocess          : Process DockFlow output for the specified project/protocol/receptor.
 --postprocess-all      : Process DockFlow output in a ChemFlow project.
 -n/--n-poses       INT : Number of docked poses to keep.
 --archive              : Compress the docking folders for the specified project/protocol/receptor.
 --archive-all          : Compress the docking folders in a ChemFLow project.

[ Optional ]
 --protocol         STR : Name for this specific protocol [default]
 -n/--n-poses       INT : Number of poses per ligand to generate while docking [10]
 -sf/--function     STR : vina, qvina, svina, chemplp, plp, plp95, vinardo, dkoes_fast, dkoes_scoring  [chemplp]

[ Parallel execution ]
 -nc/--cores        INT : Number of cores per node [${NCORES}]
 --pbs/--slurm          : Workload manager, PBS or SLURM
 --header          FILE : Header file provided to run on your cluster.

[ Additional ]
 --overwrite            : Overwrite results
 --yes                  : Yes to all questions

[ Options for docking program ]
*--center          LIST : xyz coordinates of the center of the binding site, separated by a space
_________________________________________________________________________________
[ PLANTS ]
 --radius         FLOAT : Radius of the spheric binding site [15]
 --speed            INT : Search speed for Plants. 1, 2 or 4 [1]
 --ants             INT : Number of ants [20]
 --evap_rate      FLOAT : Evaporation rate of pheromones [0.15]
 --iter_scaling   FLOAT : Iteration scaling factor [1.0]
 --cluster_rmsd   FLOAT : RMSD similarity threshold between poses, in Å [2.0]
 --water           FILE : Path to a structural water molecule (.mol2)
 --water_xyzr      LIST : xyz coordinates and radius of the water sphere, separated by a space
# --file_prefil     FILE : File input pre filled for PLANTS (.in)
 --file_filled      FILE : File input filled for PLANTS (.in)
_________________________________________________________________________________
[ Vina & qvina ]
 --size            LIST : Size of the grid along the x, y and z axis, separated by a space [15 15 15]
 --exhaustiveness   INT : Exhaustiveness of the global search [8]
 --energy_range   FLOAT : Max energy difference (kcal/mol) between the best and worst poses displayed [3.00]
________________________________________________________________________________
[ To provide your own smina config file ]
 --config_smina   ARG		    

[ If you provide Smina config file, here some options you can write inside. ]
[ For all the other possible options please consult : https://github.com/mwojcikowski/smina/blob/master/README  ]

 size            LIST      : Size of the grid along the x, y and z axis, separated by a space [15 15 15]
 exhaustiveness   INT      : Exhaustiveness of the global search [8]
 energy_range   FLOAT      : Max energy difference (kcal/mol) between the best and worst poses displayed [3.00]
 flexres CHAIN:RESID       : flexible side chains specified by comma separated list 
                               of chain:resid
 flexdist_ligand FILE      :Ligand MOL2 to use for flexdist 
 flexdist FLOAT            :Set all side chains within specified distance to 
                              flexdist_ligand to flexible (to use with flex_ligand)
 autobox_ligand FILE       : Ligand to use for autobox
 autobox_add FLOAT         : Amount of buffer space to add to auto-generated box 
                               (default +4 on all six sides) 
 no_lig                    : No ligand; for sampling/minimizing flexible residues
 scoring                   : Specify alternative scoring function [e.g. vinardo,dkoes_fast,dkoes_scoring]
 custom_scoring FILE       : Custom scoring function file
 custom_atoms FILE         : Custom atom type parameters file
 local_only                : Local search only using autobox (you probably
                                want to use --minimize)
 minimize                  :  Energy minimization
 minimize_iters arg (=0)   : Number iterations of steepest descent; default 
                               scales with rotors and usually isn't sufficient 
                               for convergence
 accurate_line             : Use accurate line search
 out_flex FILE             : Ouput file for flexible receptor residues


__________________________________________________________________________________________________________________

"
    # Not implemented in this version :
    # [ Post Processing ]
    # --report            : [not implemented]
    # --clean             : [not implemented] Clean up DockFlow output for a fresh start.

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
        "-h"|"--help")
            DockFlow_help
            exit 0
        ;;
        "-hh"|"--full-help")
            DockFlow_help_full
            exit 0
        ;;
        "-r"|"--receptor")
            RECEPTOR_FILE=$(abspath "$2")
            RECEPTOR_NAME="$(basename ${RECEPTOR_FILE} .mol2 )"
            shift # past argument
        ;;
        "-l"|"--ligand")
            LIGAND_FILE=$(abspath "$2")
            shift # past argument
        ;;
        "-p"|"--project")
            PROJECT="$2"
            shift
        ;;
        "--protocol")
            PROTOCOL="$2"
            shift
        ;;
        "-dp"|"--program")
            DOCKING_PROGRAM="$2"
            echo ${DOCKING_PROGRAM}
            if [ "${DOCKING_PROGRAM}" == "plants" ] ; then
                SCORING_FUNCTION="chemplp"
            else 
                SCORING_FUNCTION="vina"
            fi
            shift
        ;;
        "-sf"|"--function")
            SCORING_FUNCTION="$2"
            shift
        ;;
        "--center")
            DOCK_CENTER=("$2" "$3" "$4")
            shift 3 # past argument
        ;;
        "--size")
            DOCK_LENGTH=("$2" "$3" "$4")
            shift 3
        ;;
        "--radius")
            DOCK_RADIUS="$2"
            DOCK_LENGTH=("$2" "$2" "$2")
            shift # past argument
        ;;
        "--file_prefil")
            File_plants_pre=$(abspath "$2")
            shift # past argument
        ;;
        "--file_filled")
            File_plants_fil=$(abspath "$2")
            shift # past argument
        ;;
        "--file_config")
            File_vina_config=$(abspath "$2")
            shift # past argument
        ;;
        "--file_filled-vina")
            File_vina_fil=$(abspath "$2")
            shift # past argument
        ;;
        "-n"|"--n-poses")
            DOCK_POSES="$2"
            shift # past argument
        ;;
        "-nc"|"--cores") # Number of Cores [1] (or cores/node)
            NCORES="$2" # Same as above.
            shift # past argument
        ;;
        # HPC options
        "--pbs") #Activate the PBS workload
            JOB_SCHEDULLER="PBS"
        ;;
        "--slurm") #Activate the SLURM workload
            JOB_SCHEDULLER="SLURM"
        ;;
        "--header")
            HEADER_PROVIDED="yes"
            HEADER_FILE=$(abspath "$2")
            shift
        ;;
        ## PLANTS arguments
        "--speed")
            SPEED="$2"
            shift
        ;;
        "--iter_scaling")
            ITERATION_SCALING="$2"
            shift
        ;;
        "--ants")
            ANTS="$2"
            shift
        ;;
        "--evap_rate")
            EVAP_RATE="$2"
            shift
        ;;
        "--cluster_rmsd")
            CLUSTER_RMSD="$2"
            shift
        ;;
        "--water")
            WATER_FILE="$2"
            shift # past argument
        ;;
        "--water_xyzr")
            WATER_XYZR=("$2" "$3" "$4" "$5")
            shift 4 # past argument
        ;;
        ### VINA arguments
        "--exhaustiveness")
            EXHAUSTIVENESS="$2"
            shift
        ;;
        "--energy_range")
            ENERGY_RANGE="$2"
            shift
        ;;
	### QVINA arguments
        "--exhaustiveness")
            EXHAUSTIVENESS="$2"
            shift
        ;;
        "--energy_range")
            ENERGY_RANGE="$2"
            shift
        ;;
        ### SMINA arguments
        "--exhaustiveness")
            EXHAUSTIVENESS="$2"
            shift
        ;;
        "--energy_range")
            ENERGY_RANGE="$2"
            shift
	;;
        "--local_only")
	   LOCAL="$2"
           shift
	;;
        "--config_smina")
	  # conf_file=$(abspath "$2")
	   conf_file="$2"
        echo ${conf_file}
	   shift
	;;
        ## Final arguments
        "--overwrite")
            OVERWRITE="yes"
        ;;
        "--postprocess")
            POSTPROCESS="yes"
        ;;
        "--postprocess-all")
            POSTPROCESS="yes"
            POSTPROCESS_ALL="yes"
        ;;
        "--archive")
            ARCHIVE='yes'
        ;;
        "--archive-all")
            ARCHIVE='yes'
            ARCHIVE_ALL="yes"
        ;;
        "--yes")
            YESTOALL='yes'
        ;;
        *)
            unknown="$1"        # unknown option
            echo "Unknown flag \"$unknown\""
        ;;
    esac
    ###
    if [[ -n ${conf_file} ]] ; then
        x_val=$(grep center_x "${conf_file}"  | cut -d= -f2);
        y_val=$(grep center_y "${conf_file}"  | cut -d= -f2);
        z_val=$(grep center_z "${conf_file}"  | cut -d= -f2);
	DOCK_CENTER=("${x_val}" "${y_val}" "${z_val}");
        scoring_sf_name=$(grep scoring "${conf_file}" | cut -d= -f2);
        SCORING_FUNCTION="${scoring_sf_name}";
    fi
    ###
    shift # past argument or value
done
}
