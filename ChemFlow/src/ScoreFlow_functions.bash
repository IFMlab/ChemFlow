#!/bin/bash

#####################################################################
#   ChemFlow  -   Computational Chemistry is great again            #
#####################################################################
#
# Diego E. B. Gomes(1,2,3) - dgomes@pq.cnpq.br
# Cedric Bouysset (3,4) - cbouysset@unice.fr
# Marco Cecchini (3) - cecchini@unistra.fr
#
# 1 - Instituto Nacional de Metrologia, Qualidade e Tecnologia - Brazil
# 2 - Coordenacao Aperfeicoamento de Pessoal de Ensino Superior - CAPES - Brazil.
# 3 - Universite de Strasbourg - France
# 4 - Universite de Nice - France
#
#===============================================================================
#
#          FILE:  ScoreFlow2.bash
#
#         USAGE: ./ScoreFlow2.bash -p myproject -r receptor.mol2 -l multilig.mol2 -sf chemplp [-w SLURM]...
#
#
#         BRIEF: Main routine for ScoreFlow
#   DESCRIPTION: Prepare and run a rescoring calculation.
#    COMPLIANCY: The ChemFlow standard version 1.0
#
#     MANDATORY:  -r receptor.mol2 -l ligand.mol2 -p myproject
#  MAIN OPTIONS: [-protocol default] [-nc 8] [-sf chemplp]
#  REQUIREMENTS:  PLANTS or VINA, [SLURM, PBS]
#          BUGS:  ---
#         NOTES:  ---
#        AUTHOR:  Diego E. B. Gomes, dgomes@pq.cnpq.br
#       COMPANY:  Universite de Strasbourg / CAPES
#       VERSION:  1.0
#       CREATED:  mardi 29 mai 2018, 15:49:45 (UTC+0200)
#      REVISION:  ---
#===============================================================================

ScoreFlow_rescore() {
#===  FUNCTION  ================================================================
#          NAME: ScoreFlow_rescore
#   DESCRIPTION: Creates the dock list, to avoid redoundant calculations.
#                Call the right function for the rescoring.
#
#        Author: Dona de Francquen
#
#    PARAMETERS: ${SCORE_PROGRAM}
#                ${OVERWRITE}
#                ${LIGAND_LIST}
#                ${RUNDIR}
#                ${RECEPTOR_NAME}
#                ${NLIGANDS}
#===============================================================================
# Always work here
cd ${RUNDIR}

if [ -f "ScoreFlow.run" ] ; then
    rm -f ScoreFlow.run
fi

ScoreFlow_update_ligand_list
NDOCK=${#LIGAND_LIST[@]}

if [ ${NDOCK} == 0 ] ; then
    echo "[ DockFlow ] All compounds already docked ! " ; exit 0
else
    echo "There are ${NLIGANDS} compounds and ${NDOCK} remaining to rescore"
fi

case ${SCORE_PROGRAM} in
    "PLANTS")
        ScoreFlow_rescore_plants
    ;;
    "VINA")
        ScoreFlow_rescore_vina
    ;;
    "AMBER")
        ScoreFlow_rescore_mmgbsa
    ;;
esac
}


ScoreFlow_update_ligand_list() {
# Creation of the docking list, checkpoint calculations.
DOCK_LIST=""
case ${SCORE_PROGRAM} in
"PLANTS")
    # If the folder exists but there's no "bestranking.csv" its incomplete.
    FILE="${SCORE_PROGRAM}/bestranking.csv"
;;
"VINA")
    # If the folder exists but there's no "output.pdbqt" its incomplete.
    FILE="${SCORE_PROGRAM}/output.pdbqt"
;;
"AMBER")
    # If the folder exists but there's no "output.pdbqt" its incomplete.
    FILE="MMPBSA.dat"
;;
esac
if [ "${OVERWRITE}" == "no" ] ; then # Useless to process this loop if we overwrite anyway.
    for LIGAND in ${LIGAND_LIST[@]} ; do
        if [ ! -f ${RUNDIR}/${LIGAND}/${FILE} ] ; then
#            if [ -d ${RUNDIR}/${LIGAND}/ ] ; then
#                echo "[ NOTE ] ${RECEPTOR_NAME} and ${LIGAND} incomplete... redoing it !"
#            fi
            DOCK_LIST="${DOCK_LIST} $LIGAND"
        fi
    done
    DOCK_LIST=(${DOCK_LIST})
else
    DOCK_LIST=(${LIGAND_LIST[@]})
fi

# Make DOCK_LIST into an array.
unset LIGAND_LIST
LIGAND_LIST=(${DOCK_LIST[@]})
}


ScoreFlow_rescore_plants() {
#===  FUNCTION  ================================================================
#          NAME: ScoreFlow_rescore_plants
#   DESCRIPTION: Rescore docking poses using plants
#
#        Author: Dona de Francquen
#
#    PARAMETERS: ${RUNDIR}
#                ${OVERWRITE}
#
#       COMMENT: It's not worthy to rescore in parallel using VINA or PLANTS
#===============================================================================
if [ -d ${RUNDIR}/PLANTS ] ; then
    case "${OVERWRITE}" in
    "yes")
        rm -rf ${RUNDIR}/PLANTS
    ;;
    "no")
        ERROR_MESSAGE="PLANTS folder exists. Use --overwrite " ; ChemFlow_error ;
    ;;
    esac
fi

ScoreFlow_rescore_plants_write_config

# Run plants
cd ${RUNDIR}
PLANTS1.2_64bit --mode rescore rescore_input.in &>rescoring.log
}


ScoreFlow_rescore_plants_write_config() {
#===  FUNCTION  ================================================================
#          NAME: ScoreFlow_write_plants_config
#   DESCRIPTION: Write the dock input for plants (configuration file)
#
#        Author: Diego E. B. Gomes
#                Dona de Francquen
#
#    PARAMETERS: ${RUNDIR}
#                ${CHEMFLOW_HOME}
#
#       RETURNS: rescore_input file
#===============================================================================
RECEPTOR_FILE="receptor.mol2"
file=$(cat ${CHEMFLOW_HOME}/templates/plants/plants_config.in)
eval echo \""${file}"\" > ${RUNDIR}/rescore_input.in
}


ScoreFlow_rescore_vina() {
#===  FUNCTION  ================================================================
#          NAME: ScoreFlow_rescore_vina
#   DESCRIPTION: Rescore docking poses using vina
#
#        Author: Dona de Francquen
#
#    PARAMETERS: ${mgltools_folder}
#                ${RUNDIR}
#                ${LIGAND_LIST}
#                ${DOCK_CENTER}
#                ${DOCK_LENGHT}
#===============================================================================
# Prepare RECEPTOR
if [ ! -f ${RUNDIR}/receptor.pdbqt ] ; then
    python2 $(which prepare_receptor4.py) \
        -r ${RUNDIR}/receptor.mol2 \
        -o ${RUNDIR}/receptor.pdbqt
fi

# Prepare ligands
for LIGAND in ${LIGAND_LIST[@]} ; do
    # Prepare Ligands
    if [ ! -f ${RUNDIR}/${LIGAND}/ligand.pdbqt ] ; then
        python2	$(which prepare_ligand4.py) \
            -l ${RUNDIR}/${LIGAND}/ligand.mol2 \
            -o ${RUNDIR}/${LIGAND}/ligand.pdbqt -U 'lps'
    fi
    # Run vina
    vina --${VINA_MODE} --cpu 1 --receptor ${RUNDIR}/receptor.pdbqt --ligand ${RUNDIR}/${LIGAND}/ligand.pdbqt \
         --center_x ${DOCK_CENTER[0]} --center_y ${DOCK_CENTER[1]} --center_z ${DOCK_CENTER[2]} \
         --size_x ${DOCK_LENGHT[0]} --size_y ${DOCK_LENGHT[1]} --size_z ${DOCK_LENGHT[2]} \
         --out ${RUNDIR}/${LIGAND}/output.pdbqt --log ${RUNDIR}/${LIGAND}/output.log &> /dev/null
done
}


ScoreFlow_rescore_mmgbsa() {
#===  FUNCTION  ================================================================
#          NAME: ScoreFlow_rescore_mmgbsa
#   DESCRIPTION: Rescore docking poses using mmgbsa
#
#        Author: Diego E. B. Gomes
#                Dona de Francquen
#
#    PARAMETERS: ${RUNDIR}
#                ${RUN_ONLY_PROVIDED}
#                ${WORKDIR}
#                ${RUN_ONLY}
#                ${LIGAND_LIST}
#                ${RECEPTOR_NAME}
#                ${JOB_SCHEDULLER}
#                ${WRITE_ONLY}
#===============================================================================
# Write all input files
if [ ${RUN_ONLY} == "no" ] ; then
    ScoreFlow_rescore_mmgbsa_write_inputs
fi

# Clean up
if [ -f  ScoreFlow.run ] ; then
    rm -rf  ${RUNDIR}/ScoreFlow.run
fi
# Write the commands to run the program
if [ ${RUN_ONLY} != "yes" ] ; then
    ScoreFlow_rescore_mmgbsa_write_commun_ScoreFlow_run
fi

if [ ${WRITE_ONLY} == 'yes' ] ; then
    for LIGAND in ${LIGAND_LIST[@]} ; do
        if [ ! -f ${RUNDIR}/${LIGAND}/complex.rst7 ] && [ "${WATER}" != 'yes' ] ; then
            echo "$(which tleap) -f ../tleap_implicit.in &> tleap.job" > ScoreFlow.run.template
            break
        fi
        if [ ! -f ${RUNDIR}/${LIGAND}/ionized_solvated.rst7 ] && [ "${WATER}" == 'yes' ] ; then
            echo -e "$(which tleap) -f ../tleap_water.in &> water.job\n$(which tleap) -f ../tleap_salt-tot.in  &> tleap.job " > ScoreFlow.run.template
            break
        fi
    done
    echo -e "$(cat ${RUNDIR}/ScoreFlow.run)" >> ScoreFlow.run.template
    rm -f ScoreFlow.run
else
    for LIGAND in ${LIGAND_LIST[@]} ; do
    cd ${RUNDIR}/${LIGAND}

        if [ ${RUN_ONLY} == 'yes' ] ; then
            echo -e "cd ${RUNDIR}/${LIGAND}" > ScoreFlow.run

            ScoreFlow_rescore_mmgbsa_write_compute_charges

            echo -e "$(cat ../ScoreFlow.run.template)" >> ScoreFlow.run
        else
            echo -e "cd ${RUNDIR}/${LIGAND}" > ScoreFlow.run

            ScoreFlow_rescore_mmgbsa_write_compute_charges
    fi
     if [ ! -f ${LIGFLOW_FILE} ] ; then
        continue
     fi
         if [ ! -f ${RUNDIR}/${LIGAND}/complex.rst7 ] && [ ${WATER} != 'yes' ] ; then
                echo "$(which tleap) -f ../tleap_implicit.in &> tleap.job" >> ScoreFlow.run
	else
                echo "Running tleap with physiological salt concentration of 0.15M"

		run_salt

	fi
		if [ ! -f ${RUNDIR}/${LIGAND}/ionized_solvated_SALT.prmtop ] && [ "${WATER}" == 'yes' ] ; then

        echo "You must run tleap_salt!"
	continue
	fi

        if [ ${JOB_SCHEDULLER} != "None" ] ; then
            ScoreFlow_rescore_mmgbsa_write_HPC
        fi

        case "${JOB_SCHEDULLER}" in
        "None")
            echo -e "Computing MMPBSA for ${RECEPTOR_NAME} - ${LIGAND}                                               \r"
            bash ScoreFlow.run
        ;;
        "PBS")
            qsub ScoreFlow.pbs
        ;;
        "SLURM")
            sbatch ScoreFlow.slurm
        ;;
        esac
    done
fi
}









ScoreFlow_rescore_mmgbsa_write_compute_charges() {
#===  FUNCTION  ================================================================
#          NAME: ScoreFlow_rescore_mmgbsa_write_compute_charges
#   DESCRIPTION: compute charge to run mmgbsa calculation
#
#        Author: Diego E. B. Gomes
#                Dona de Francquen
#
#    PARAMETERS: ${RUNDIR}
#                ${LIGAND_LIST}
#                ${CHARGE}
#                ${CHEMFLOW_HOME}
#                ${WORKDIR}
#                ${PROJECT}
#                ${NCORES}
#===============================================================================

# Ligand name without docking _conf_XX suffix. (in case you're rescoring from DockFlow)
LIGAND_NAME=$(echo ${LIGAND} | awk -F '_conf' '{print $1}')

# Path to LigFlow file. (if any)
LIGFLOW_FILE=${WORKDIR}/${PROJECT}.chemflow/LigFlow/${CHARGE}/${LIGAND_NAME}.mol2

# Check if charges already exists for this ligand
if [ -f ${LIGFLOW_FILE} ] ; then

    echo "${CHARGE} charges found in LigFlow for ${LIGAND}"

    # Copy charges to file
    awk '/ MOL/&&!/TEMP/ {print $9}' ${LIGFLOW_FILE} > charges.dat

    # Prepare .mol2 with right charges
    antechamber -i ${RUNDIR}/${LIGAND}/ligand.mol2 -o ligand_${CHARGE}.mol2 -fi mol2 -fo mol2 -cf charges.dat -c rc -rn MOL -pf yes -dr no &> /dev/null

    # Prepare the .frcmod file.
    parmchk2 -i ${LIGFLOW_FILE} -o ${RUNDIR}/${LIGAND}/ligand.frcmod -s 2 -f mol2

else 

msg="\"${CHARGE}\" charges not found for ligand: ${LIGAND_NAME}.

Did you run LigFlow first ?

LigFlow -p ${PROJECT} -l ${LIGAND_FILE} --${CHARGE}"

ScoreFlow_error

echo "\"${CHARGE}\" charges not found for ligand: ${LIGAND_NAME}." >> ${RUNDIR}/FAILED_CHARGE.txt

fi

}


ScoreFlow_error() {

echo -e "\e[31m
-------------------------------------------------
         ScoreFlow stopped with ERROR 
-------------------------------------------------

$msg

-------------------------------------------------
\e[0m
"    

}


ScoreFlow_rescore_mmgbsa_write_inputs() {
#===  FUNCTION  ================================================================
#          NAME: ScoreFlow_rescore_mmgbsa_write_inputs
#   DESCRIPTION: Write mmgbsa MIN (and MD if asked) config
#
#        Author: Diego E. B. Gomes
#                Dona de Francquen
#
#    PARAMETERS: ${RUNDIR}
#                ${CHEMFLOW_HOME}
#                ${WATER}
#                ${MD}
#
#       RETURNS: all .in files required
#===============================================================================
# tleap inputs
	copy_tleap

echo "Tleap input file copied."


# Simulation inputs
if [ "${WATER}" != "yes" ] ; then
    solvent="implicit"
    if [ "${MD}" != 'yes' ] ; then
        scoreflow_protocol="min"
    else
        scoreflow_protocol="min md"
    fi
else
    solvent="explicit"
    if [ "${MD}" != 'yes' ] ; then
        scoreflow_protocol="min1 min2 min3 min4"
    else
        scoreflow_protocol="min1 min2 min3 min4 heat_nvt heat_npt prod"
    fi
fi

for filename in ${scoreflow_protocol} ; do
    file=$(cat ${CHEMFLOW_HOME}/templates/mmgbsa/${solvent}/${filename}.template)
    eval echo \""${file}"\" > ${RUNDIR}/${filename}.in
done

#mm(pb,gb)sa input
echo "$(cat ${CHEMFLOW_HOME}/templates/mmgbsa/${SCORING_FUNCTION}.template)" > ${RUNDIR}/${SCORING_FUNCTION}.in
}


ScoreFlow_rescore_mmgbsa_write_commun_ScoreFlow_run() {
#===  FUNCTION  ================================================================
#          NAME: ScoreFlow_rescore_mmgbsa_write_run
#   DESCRIPTION: Write the run file for MIN (MD if asked)
#
#        Author: Diego E. B. Gomes
#                Dona de Francquen
#
#    PARAMETERS: ${RUNDIR}
#                ${WATER}
#                ${MD}
#                ${AMBER_EXEC}
#
#       RETURNS: ScoreFlow.run
#===============================================================================
if [ "${WATER}" != "yes" ] ; then
    init=complex           # Do not change Init
    prev="${init}"
    if [ "${MD}" != 'yes' ] ; then
        scoreflow_protocol="min"
        TRAJECTORY="min.rst7"
    else
        scoreflow_protocol="min md"
        TRAJECTORY="md.nc"
    fi
else
#   init=ionized_solvated    # Do not change Init
    init=ionized_solvated_SALT    # Do not change Init
    prev="${init}"
    if [ "${MD}" != 'yes' ] ; then
        scoreflow_protocol="min1 min2 min3 min4"
        TRAJECTORY="min4.rst7"
    else
        scoreflow_protocol="min1 min2 min3 min4 heat_nvt heat_npt prod"
        TRAJECTORY="prod.nc"
    fi
fi

# Loop  over minimization protocol
echo "init=${init}
prev=${prev}

for run in ${scoreflow_protocol} ; do
    input=\"../\${run}\"
    var=''

    # Check if run finished.
    if [ -f \${run}.mdout ] ; then
        var=\$(tail -1 \${run}.mdout | awk '/Total wall time/{print \$1}')
    fi

    if [ \"\${var}\" == '' ] ; then
        ${AMBER_EXEC} -O  \
-i \${input}.in -o \${run}.mdout -e \${run}.mden -r \${run}.rst7  \
-x \${run}.nc -v  \${run}.mdvel -inf \${run}.mdinfo -c \${prev}.rst7 \
-p \${init}.prmtop -ref \${prev}.rst7 &> \${run}.job
    fi

    if [ -f \${run}.mdout ] ; then
        var=\$(tail -1 \${run}.mdout | awk '/Total wall time/{print \$1}')
    fi
    if [ \"\${var}\" == '' ] ; then
        echo \"[ ERROR ]Fail in step \${run}\"
        exit 1
    fi

    prev=\${run}
done" >> ${RUNDIR}/ScoreFlow.run


if [ ! -f MMPBSA.dat ] ; then
echo "rm -rf com.top rec.top ligand.top
amber.python $(which ante-MMPBSA.py) -p ${init}.prmtop -c com.top -r rec.top -l ligand.top -n :MOL -s ':WAT,Na+,Cl-' --radii=mbondi2 &> ante_mmpbsa.job" >>${RUNDIR}/ScoreFlow.run

if [ "${WATER}" != "yes" ] ; then
    echo "amber.python $(which MMPBSA.py) -O -i ../mmgbsa.in -cp com.top -rp rec.top -lp ligand.top -o MMPBSA.dat -eo MMPBSA.csv -y ${TRAJECTORY} &> MMPBSA.job" >>${RUNDIR}/ScoreFlow.run
else
    echo "amber.python $(which MMPBSA.py) -O -i ../mmgbsa.in -sp ${init}.prmtop -cp com.top -rp rec.top -lp ligand.top -o MMPBSA.dat -eo MMPBSA.csv -y ${TRAJECTORY} &> MMPBSA.job" >>${RUNDIR}/ScoreFlow.run
fi
echo "rm -rf reference.frc " >> ${RUNDIR}/ScoreFlow.run
fi
}


ScoreFlow_rescore_mmgbsa_write_HPC() {
#===  FUNCTION  ================================================================
#          NAME: ScoreFlow_rescore_mmgbsa_write_pbs
#   DESCRIPTION: Writes the PBS script by adding the pbs template to ScoreFlow.run.
#
#    PARAMETERS: ${RUNDIR}
#                ${CHEMFLOW_HOME}
#                ${LIGAND}
#
#       RETURNS: ScoreFlow.pbs for ${LIGAND}
#===============================================================================
if [ ${HEADER_PROVIDED} != "yes" ] ; then
    file=$(cat ${CHEMFLOW_HOME}/templates/mmgbsa/job_scheduller/${JOB_SCHEDULLER,,}.template)
    eval echo \""${file}"\" > ${RUNDIR}/ScoreFlow.header
else
    cp ${HEADER_FILE} ${RUNDIR}/ScoreFlow.header
fi
case "${JOB_SCHEDULLER}" in
    "PBS")
        sed "/PBS -N .*$/ s/$/$LIGAND/" ${RUNDIR}/ScoreFlow.header > ${RUNDIR}/${LIGAND}/ScoreFlow.${JOB_SCHEDULLER,,}
    ;;
    "SLURM")
        sed "s/--job-name=[.]*/--job-name=$LIGAND/" ${RUNDIR}/ScoreFlow.header > ${RUNDIR}/${LIGAND}/ScoreFlow.${JOB_SCHEDULLER,,}
    ;;
    esac


cat ${RUNDIR}/${LIGAND}/ScoreFlow.run >> ${RUNDIR}/${LIGAND}/ScoreFlow.${JOB_SCHEDULLER,,}

}


ScoreFlow_organize() {
#===  FUNCTION  ================================================================
#          NAME: ScoreFlow_organize
#   DESCRIPTION: Organise folders and files before rescoring
#
#        Author: Diego E. B. Gomes
#
#    PARAMETERS: ${OVERWRITE}
#                ${RUNDIR}
#                ${SCORE_PROGRAM}
#                ${LIGAND_LIST}
#                ${LIGAND_FILE}
#
#       RETURNS: the project tree
#===============================================================================
# TODO
# Improve extracting mol2 to separate folders.

if [ ${OVERWRITE} == "yes" ] ; then
    for LIGAND in ${LIGAND_LIST[@]} ; do
        rm -rf ${RUNDIR}/${LIGAND}
    done
fi

if [  ! -d ${RUNDIR} ] ; then
    mkdir -p ${RUNDIR}
fi

# Copy files to project folder.
if [ ${SCORE_PROGRAM} == "AMBER" ] ; then
    cp ${RECEPTOR_FILE} ${RUNDIR}/receptor.pdb
else
    cp ${RECEPTOR_FILE} ${RUNDIR}/receptor.mol2
fi
cp ${LIGAND_FILE} ${RUNDIR}/ligand.mol2

OLDIFS=$IFS
IFS='%'
if [ ${SCORE_PROGRAM} != "PLANTS" ] ; then

    for LIGAND in ${LIGAND_LIST[@]} ; do
        if [ ! -d  ${RUNDIR}/${LIGAND} ] ; then
            mkdir -p ${RUNDIR}/${LIGAND}
        fi
    done

    # Copy each ligand to it's folder.
    n=-1
    while read line ; do
        if [ "${line}" == '@<TRIPOS>MOLECULE' ]; then
            let n=$n+1
            echo -ne "" > ${RUNDIR}/${LIGAND_LIST[$n]}/ligand.mol2
        fi
        echo -e "${line}" >> ${RUNDIR}/${LIGAND_LIST[$n]}/ligand.mol2
    done < ${LIGAND_FILE}
fi
IFS=$OLDIFS
}


ScoreFlow_postprocess() {
#===  FUNCTION  ================================================================
#          NAME: ScoreFlow_postprocess
#   DESCRIPTION: Post processing ScoreFlow run depending on the dock program used
#                Each project / receptor will have a ScoreFlow.csv file.
#
#        Author: Dona de Francquen
#
#    PARAMETERS: ${RUNDIR}
#                ${SCORING_FUNCTION}
#                ${SCORE_PROGRAM}
#                ${PROTOCOL}
#                ${RECEPTOR_NAME}
#                ${LIGAND_LIST}
#
#       RETURNS: ScoreFlow.csv, csv file with the docking result.
#===============================================================================
echo "
Scoring function: ${SCORING_FUNCTION}
         Rundir : ${RUNDIR}
"
if [ -f ${RUNDIR}/ScoreFlow.csv ]  ; then
    rm -rf ${RUNDIR}/ScoreFlow.csv
fi

SCOREFLOW_HEADER="SCORE_PROGRAM PROTOCOL RECEPTOR LIGAND POSE SCORE"

case ${SCORE_PROGRAM} in
"PLANTS")
    if [ -f ${RUNDIR}/PLANTS/ranking.csv ] ; then
        echo ${SCOREFLOW_HEADER} > ${RUNDIR}/ScoreFlow.csv
        sed 's/\.*_entry.*_conf_[[:digit:]]*//' ${RUNDIR}/PLANTS/ranking.csv | awk -v protocol=${PROTOCOL} -v target=${RECEPTOR_NAME} -F, '!/LIGAND/ {print "PLANTS",protocol,target,$1,$1,$2}' >> ${RUNDIR}/ScoreFlow.csv
    fi
;;
"VINA")
    for LIGAND in ${LIGAND_LIST[@]} ; do
        if [ -f ${RUNDIR}/${LIGAND}/output.log ] ; then
            if [ ! -f ${RUNDIR}/ScoreFlow.csv ] ; then
                echo ${SCOREFLOW_HEADER} > ${RUNDIR}/ScoreFlow.csv
            fi
            awk -v protocol=${PROTOCOL} -v target=${RECEPTOR_NAME} -v ligand=${LIGAND} '/Affinity:/ {print "VINA",protocol,target,ligand,ligand,$2}' ${RUNDIR}/${LIGAND}/output.log >> ${RUNDIR}/ScoreFlow.csv
        fi
     done
;;
"AMBER")
    for LIGAND in ${LIGAND_LIST[@]} ; do
        if [ -f ${RUNDIR}/${LIGAND}/MMPBSA.dat ] ; then
            if [ ! -f ${RUNDIR}/ScoreFlow.csv ] ; then
                echo ${SCOREFLOW_HEADER} > ${RUNDIR}/ScoreFlow.csv
            fi
            awk -v protocol=${PROTOCOL} -v target=${RECEPTOR_NAME} -v ligand=${LIGAND} '/DELTA TOTAL/{print "AMBER",protocol,target,ligand,ligand,$3}' ${RUNDIR}/${LIGAND}/MMPBSA.dat >> ${RUNDIR}/ScoreFlow.csv
        fi
    done
;;
esac
if [ ! -f ${RUNDIR}/ScoreFlow.csv ] ; then
     ERROR_MESSAGE="${SCORE_PROGRAM} results for PROJECT '${PROJECT}' / PROTOCOL '${PROTOCOL}' does not exists."
     ChemFlow_error
else
    sed -i 's/[a-zA-Z0-9]*_conf_//2' ${RUNDIR}/ScoreFlow.csv
    sed -i 's/_conf_[[:digit:]]*//' ${RUNDIR}/ScoreFlow.csv
fi
}


ScoreFlow_summary() {
#===  FUNCTION  ================================================================
#          NAME: ScoreFlow_summary
#   DESCRIPTION: Summary of the run options
#
#        Author: Diego E. B. Gomes
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
#                ${CHARGE}
#                ${SCORE_PROGRAM}
#                ${SCORING_FUNCTION}
#                ${DOCK_CENTER}
#                ${DOCK_LENGHT}
#                ${DOCK_RADIUS}
#                ${MD}
#                ${JOB_SCHEDULLER}
#                ${NCORES}
#                ${OVERWRITE}
#===============================================================================
echo "\
ScoreFlow summary:
-------------------------------------------------------------------------------
[ General info ]
    HOST: ${HOSTNAME}
    USER: ${USER}
 PROJECT: ${PROJECT}
PROTOCOL: ${PROTOCOL}
 WORKDIR: ${WORKDIR}

[ Rescoring setup ]
RECEPTOR NAME: ${RECEPTOR_NAME}
RECEPTOR FILE: $(relpath "${RECEPTOR_FILE}" "${WORKDIR}")
  LIGAND FILE: $(relpath "${LIGAND_FILE}"   "${WORKDIR}")
     NLIGANDS: ${NLIGANDS}
       CHARGE: ${CHARGE}
      PROGRAM: ${SCORE_PROGRAM}
      SCORING: ${SCORING_FUNCTION}"
case ${SCORE_PROGRAM} in
"VINA")
    echo "       CENTER: ${DOCK_CENTER[@]}"
    echo "         SIZE: ${DOCK_LENGHT[@]} (X,Y,Z)"
    echo " SCORING MODE: ${VINA_MODE}"
;;
"PLANTS")
    echo "       CENTER: ${DOCK_CENTER[@]}"
    echo "       RADIUS: ${DOCK_RADIUS}"
;;
"AMBER")
    echo "           MD: ${MD}"
    if [ ${WATER} = 'no' ] ; then
        echo "      SOLVENT: implicit"
        echo "       MAXCYC: ${MAXCYC}"
    else
        echo "      SOLVENT: explicit"
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


ScoreFlow_help() {
#===  FUNCTION  ===============================================================
#          NAME: ScoreFlow_help
#   DESCRIPTION: Help displayed with -h
#
#        Author: Diego E. B. Gomes
#
#    PARAMETERS: -
#==============================================================================
echo "Example usage:
# For VINA and PLANTS scoring functions:
ScoreFlow -r receptor.mol2 -l ligand.mol2 -p myproject --center X Y Z [--protocol protocol-name] [-sf vina]

# For MMGBSA only
ScoreFlow -r receptor.pdb -l ligand.mol2 -p myproject [--protocol protocol-name] -sf mmgbsa --write-only

ScoreFlow -r receptor.pdb -l ligand.mol2 -p myproject [--protocol protocol-name] -sf mmgbsa --run-only


[Options]
 -h/--help           : Show this help message and quit
 -hh/--fullhelp      : Detailed help

 -r/--receptor       : Receptor .mol2 or .pdb file.
 -l/--ligand         : Ligands .mol2 input file.
 -p/--project        : ChemFlow project.

Rescoring:
 --center            : X Y Z coordinates of the center of the binding site, separated by a space.

Postprocess:
 --postprocess       : Process ScoreFlow output in a ChemFlow project.
"
exit 0
}


ScoreFlow_help_full(){
#===  FUNCTION  ===============================================================
#          NAME: ScoreFlow_help_full
#   DESCRIPTION: Full help displayed with -hh
#
#        Author: Diego E. B. Gomes
#
#    PARAMETERS: -
#==============================================================================
echo "ScoreFlow is a bash script designed to work with PLANTS, Vina, IChem and AmberTools16+.
It can perform an rescoring of molecular complexes such as protein-ligand

ScoreFlow requires a project folder named 'myproject'.chemflow. If absent, one will be created.

Usage:
# For VINA and PLANTS scoring functions:
ScoreFlow -r receptor.mol2 -l ligand.mol2 -p myproject --center X Y Z [--protocol protocol-name] [-sf vina]

# For MMGBSA only
ScoreFlow -r receptor.pdb -l ligand.mol2 -p myproject [-protocol protocol-name] -sf mmgbsa

[Help]
 -h/--help              : Show this help message and quit
 -hh/--fullhelp         : Detailed help

[Required]
*-p/--project       STR : ChemFlow project
*-r/--receptor     FILE : Receptor MOL2 file
*-l/--ligand       FILE : Ligands  MOL2 file

[Optional]
 --protocol         STR : Name for this specific protocol [default]
 -sf/--function     STR : vina, chemplp, plp, plp95, mmgbsa, mmpbsa [chemplp]

[ Charges for ligands - MMGBSA ]
 --bcc                  : AM1-BCC charges (default)
 --resp                 : RESP charges (require gaussian)

[ Simulation - MMGBSA ]
 --maxcyc           INT : Maximum number of energy minimization steps for implicit solvent simulations [1000]
 --water                : Explicit solvent simulation
 --md                   : Molecular dynamics

[ Parallel execution - MMGBSA ]
 -nc/--cores        INT : Number of cores per node [${NCORES}]
 --pbs/--slurm          : Workload manager, PBS or SLURM
 --header          FILE : Header file provided to run on your cluster.
 --write-only           : Write a template file (ScoreFlow.run.template) command without running.
 --run-only             : Run using the ScoreFlow.run.template file.

[ Additional ]
 --overwrite            : Overwrite results

[ Rescoring with vina or plants ]
Note: You can automatically get the center and radius/size for a particular ligand .mol2 file by using the ${CHEMFLOW_HOME}/bin/bounding_shape.py script
*--center           STR : xyz coordinates of the center of the binding site, separated by a space
[ PLANTS ]
 --radius         FLOAT : Radius of the spheric binding site [15]
[ Vina ]
 --size            LIST : Size of the grid along the x, y and z axis, separated by a space [15 15 15]
 --vina-mode        STR : local_only (local search then score) or score_only [local_only]

[ Post Processing ]
 --postprocess          : Process ScoreFlow output for the specified project/protocol/receptor.
_________________________________________________________________________________
"
exit 0
# TODO
# Implement archive
}


ScoreFlow_CLI() {
#===  FUNCTION  ===============================================================
#          NAME: ScoreFlow_CLI
#   DESCRIPTION: Set all parameters from the command line.
#
#        Author: Diego E. B. Gomes
#                Dona de Francquen
#==============================================================================
if [ "$1" == "" ] ; then
    ERROR_MESSAGE="ScoreFlow called without arguments."
    ChemFlow_error ;
fi

while [[ $# -gt 0 ]]; do
    key="$1"
    case ${key} in
        "-h"|"--help")
            ScoreFlow_help
            exit 0
        ;;
        "-hh"|"--full-help")
            ScoreFlow_help_full
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
        "-sf"|"--scoring_function")
            SCORING_FUNCTION="$2"
            shift
        ;;
        "--center")
            DOCK_CENTER=("$2" "$3" "$4")
            shift 3 # past argument
        ;;
        "--size")
            DOCK_LENGHT=("$2" "$3" "$4")
            shift 3
        ;;
        "--radius")
            DOCK_RADIUS="$2"
            DOCK_LENGHT=("$2" "$2" "$2")
            shift # past argument
        ;;
        "--vina-mode")
            VINA_MODE="$2"
            shift
        ;;
        "-nc"|"--cores") # Number of Cores [1] (or cores/node)
            NCORES="$2" # Same as above.
            shift # past argument
        ;;
        # Charge calculation
        "--resp")
            CHARGE="resp"
        ;;
        "--bcc")
            CHARGE="bcc"
        ;;
        "--md")
            MD="yes"
        ;;
        "--water")
            WATER='yes'
        ;;
        # Minimization specific options
        "--maxcyc") # Maximun number of Energy minimization steps.
            MAXCYC="$2"
            shift
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
        "--write-only")
            WRITE_ONLY="yes"
        ;;
        "--run-only")
            RUN_ONLY="yes"
        ;;
        ## Final arguments
        "--overwrite")
            OVERWRITE="yes"
        ;;
        ## ADVANCED USER INPUT
        #    --advanced)
        #      USER_INPUT="$2"
        #      shift
        "--postprocess")
            POSTPROCESS="yes"
        ;;
        #    --archive)
        #      ARCHIVE='yes'
        #    ;;
        "--yes")
            YESTOALL='yes'
        ;;
        "--cuda-double")
            CUDA_PRECISION="DOUBLE"
        ;;      
        *)
            unknown="$1"        # unknown option
            echo "Unknown flag \"$unknown\". RTFM"
            exit 0
        ;;
    esac
    shift # past argument or value
done
}
