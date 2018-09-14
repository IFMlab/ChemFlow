#!/bin/bash

#####################################################################
#   ChemFlow  -   Computational Chemistry is great again            #
#####################################################################
#
# Diego E. B. Gomes(1,2,3) - dgomes@pq.cnpq.br
# Cedric Boysset (3,4) - cboysset@unice.fr
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
    ${mgltools_folder}/bin/python \
    ${mgltools_folder}/MGLToolsPckgs/AutoDockTools/Utilities24/prepare_receptor4.py \
        -r ${RUNDIR}/receptor.mol2 \
        -o ${RUNDIR}/receptor.pdbqt
fi

# Prepare ligands
for LIGAND in ${LIGAND_LIST[@]} ; do
    # Prepare Ligands
    if [ ! -f ${RUNDIR}/${LIGAND}/ligand.pdbqt ] ; then
        ${mgltools_folder}/bin/python \
        ${mgltools_folder}/MGLToolsPckgs/AutoDockTools/Utilities24/prepare_ligand4.py \
            -l ${RUNDIR}/${LIGAND}/ligand.mol2 \
            -o ${RUNDIR}/${LIGAND}/ligand.pdbqt
    fi
    # Run vina
    vina --local_only --receptor ${RUNDIR}/receptor.pdbqt --ligand ${RUNDIR}/${LIGAND}/ligand.pdbqt \
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
    if [ ! -f ${RUNDIR}/${LIGAND}/complex.rst7 ] && [ ${WATER} != 'yes' ] ; then
        echo "tleap -f ../tleap.in &> tleap.job" > ScoreFlow.run.template
    fi
    if [ ! -f ${RUNDIR}/${LIGAND}/ionized_solvated.rst7 ] && [ ${WATER} == 'yes' ] ; then
        echo "tleap -f ../tleap.in &> tleap.job" > ScoreFlow.run.template
    fi

    echo -e "$(cat ScoreFlow.run)" >> ScoreFlow.run.template
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

            if [ ! -f ${RUNDIR}/${LIGAND}/complex.rst7 ] && [ ${WATER} != 'yes' ] ; then
                echo "tleap -f ../tleap.in &> tleap.job" >> ScoreFlow.run
            fi
            if [ ! -f ${RUNDIR}/${LIGAND}/ionized_solvated.rst7 ] && [ ${WATER} == 'yes' ] ; then
                echo "tleap -f ../tleap.in &> tleap.job" >> ScoreFlow.run
            fi

            echo -e "$(cat ../ScoreFlow.run)" >> ScoreFlow.run
        fi

        if [ "${WRITE_ONLY}" != "yes" ] ; then
            if [ ${JOB_SCHEDULLER} != "None" ] ; then
                ScoreFlow_rescore_mmgbsa_write_HPC
            fi

            case "${JOB_SCHEDULLER}" in
            "None")
                echo -ne "Computing MMPBSA for ${RECEPTOR_NAME} - ${LIGAND}                                               \r"
                bash ScoreFlow.run
            ;;
            "PBS")
                qsub ScoreFlow.pbs
            ;;
            "SLURM")
                sbatch ScoreFlow.slurm
            ;;
            esac
        fi
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
# The name of the ligand, without any conformational info
LIGAND_NAME=`echo ${LIGAND} | sed -e 's/_conf_[0-9]*//'`

# Mandatory Gasteiger charges
if [ ! -f ligand_gas.mol2 ] ; then
    antechamber -i ligand.mol2 -fi mol2 -o ligand_gas.mol2 -fo mol2 -c gas -s 2 -eq 1 -rn MOL -pf y -dr no &> antechamber.log
fi

if [ ${CHARGE} != 'gas' ] ; then
    DONE_CHARGE="false"
    # Check if charges already exists for this ligand
    if [ -f ligand_${CHARGE}.mol2 ] ; then
        DONE_CHARGE="true"
    fi

    # Check if the charges are in ChemBase.
    if [ "${DONE_CHARGE}" == "false" ] && [ -s ${CHEMFLOW_HOME}/ChemBase/${CHARGE}/ChemBase_${CHARGE}.lst ] && [ -s ${CHEMFLOW_HOME}/ChemBase/${CHARGE}/ChemBase_${CHARGE}.mol2 ] ; then
        if [ "$(grep ${LIGAND_NAME} ${CHEMFLOW_HOME}/ChemBase/${CHARGE}/ChemBase_${CHARGE}.lst)" == ${LIGAND_NAME} ] ; then
            echo "${CHARGE} charges found in ChemBase for ${LIGAND}"

            awk -v LIGAND=${LIGAND_NAME} '$0 ~ LIGAND {flag=1;next}/BOND/{flag=0}flag' ${CHEMFLOW_HOME}/ChemBase/${CHARGE}/ChemBase_${CHARGE}.mol2 | awk '/1 MOL/&&!/TEMP/ {print $9}' > charges.dat
            antechamber -i ligand_gas.mol2 -o ligand_${CHARGE}.mol2 -fi mol2 -fo mol2 -cf charges.dat -c rc -pf yes &> /dev/null

            # Done
            DONE_CHARGE="true"
        fi
    fi

    # If it was not in ChemBase, look into the LigFlow folder.
    if [ "${DONE_CHARGE}" == "false" ] && [ -f ${WORKDIR}/${PROJECT}.chemflow/LigFlow/${CHARGE}/${LIGAND_NAME}.mol2 ] ; then
        echo "${CHARGE} charges found in LigFlow for ${LIGAND}"

        awk '/1 MOL/&&!/TEMP/ {print $9}' ${WORKDIR}/${PROJECT}.chemflow/LigFlow/${CHARGE}/${LIGAND_NAME}.mol2 > charges.dat
        antechamber -i ligand_gas.mol2 -o ligand_${CHARGE}.mol2 -fi mol2 -fo mol2 -cf charges.dat -c rc -pf yes &> /dev/null

        # Done
        DONE_CHARGE="true"
    fi

    # If it was not in ChemBase or LigFlow, compute them.
    if [ ${DONE_CHARGE} == "false" ] ; then

        case ${CHARGE} in
        "bcc")
            # Compute am1-bcc charges
            if [ ! -f ligand_bcc.mol2 ] ; then
                echo "echo \"Computing ${CHARGE} charges for ${LIGAND}\" ;  antechamber -i ligand_gas.mol2 -fi mol2 -o ligand_bcc.mol2 -fo mol2 -c bcc -s 2 -eq 1 -rn MOL -pf y -dr no &> antechamber.log ; cp ligand_bcc.mol2 ${WORKDIR}/${PROJECT}.chemflow/LigFlow/${CHARGE}/${LIGAND_NAME}.mol2" >> ScoreFlow.run
            fi

            ;;
        "resp")
            # Prepare Gaussian
            if [ ! -f ligand_resp.mol2 ] ; then
                echo "You asked for resp charges. I was not able no find those in the ChemBase or LigFlow for ligand ${LIGAND}. Use LigFlow to compute them and try the rescoring later please. I can't do it, it would take to much time.. I'm just a simple rescoring program.. I'm very sorry, please accept my apologies."
    #                antechamber -i ligand_gas.mol2 -fi mol2 -o ligand.gau -fo gcrt -gv 1 -ge ligand.gesp -gm "%mem=16Gb" -gn "%nproc=${NCORES}" -s 2 -eq 1 -rn MOL -pf y -dr no &> antechamber.log
    #
    #                # Run Gaussian to optimize structure and generate electrostatic potential grid
    #                g09 <ligand.gau>ligand.gout
    #
    #                # Read Gaussian output and write new optimized ligand with RESP charges
    #                antechamber -i ligand.gout -fi gout -o ligand_resp.mol2 -fo mol2 -c resp -s 2 -rn MOL -pf y -dr no &>> ${RUNDIR}/antechamber.log
    #                if [ ! -f ${WORKDIR}/${PROJECT}.chemflow/LigFlow/${CHARGE}/${LIGAND_NAME}.mol2 ] ; then
    #                    cp ligand_resp.mol2 ${WORKDIR}/${PROJECT}.chemflow/LigFlow/${CHARGE}/${LIGAND_NAME}.mol2
    #                fi
            fi
        ;;
        esac
    fi
fi

if [ ! -f ligand.frcmod ] && [ -f ligand_gas.mol2 ] ; then
    parmchk2 -i ligand_gas.mol2 -o ligand.frcmod -s 2 -f mol2

    if [ ! -f ligand.frcmod ]  ; then
        echo "${LIGAND} gas" >> ${RUNDIR}/antechamber_errors.lst
    fi
fi

case ${CHARGE} in
"bcc")
    if [ ! -f ligand_bcc.mol2 ] ; then
        echo "${LIGAND} bcc" >> ${RUNDIR}/antechamber_errors.lst
    fi
;;
"resp")
    if [ ! -f ligand_resp.mol2 ]; then
        echo "${LIGAND} resp">> ${RUNDIR}/antechamber_errors.lst
    fi
;;
esac
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
if [ "${WATER}" != "yes" ] ; then
    template="tleap_implicit.template"
else
    template="tleap_explicit.template"
fi
file=$(cat ${CHEMFLOW_HOME}/templates/mmgbsa/tleap/${template})
eval echo \""${file}"\" >> ${RUNDIR}/tleap.in

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

#mmgbsa input
echo "$(cat ${CHEMFLOW_HOME}/templates/mmgbsa/GB2.template)" > ${RUNDIR}/GB2.in
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
    init=ionized_solvated    # Do not change Init
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
ante-MMPBSA.py -p ${init}.prmtop -c com.top -r rec.top -l ligand.top -n :MOL -s ':WAT,Na+,Cl-' --radii=mbondi2 &> ante_mmpbsa.job
MMPBSA.py -O -i ../GB2.in -sp ${init}.prmtop -cp com.top -rp rec.top -lp ligand.top -o MMPBSA.dat -eo MMPBSA.csv -y ${TRAJECTORY} &> MMPBSA.job
rm -rf reference.frc " >> ${RUNDIR}/ScoreFlow.run
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
if [ ! -f ${RUNDIR}/ScoreFlow.${JOB_SCHEDULLER,,} ] ; then
    if [ ${HEADER_PROVIDED} != "yes" ] ; then
        file=$(cat ${CHEMFLOW_HOME}/templates/mmgbsa/job_scheduller/${JOB_SCHEDULLER,,}.template)
        eval echo \""${file}"\" > ${RUNDIR}/${LIGAND}/ScoreFlow.${JOB_SCHEDULLER,,}
    else
        case "${JOB_SCHEDULLER}" in
        "PBS")
            sed "s/LIGAND/$LIGAND/" ${WORKDIR}/${HEADER_FILE} > ${RUNDIR}/${LIGAND}/ScoreFlow.${JOB_SCHEDULLER,,}
        ;;
        "SLURM")
            sed "s/--job-name=[.]*/--job-name=$LIGAND/" ${WORKDIR}/${HEADER_FILE} > ${RUNDIR}/${LIGAND}/ScoreFlow.${JOB_SCHEDULLER,,}
        ;;
        esac

    fi
fi

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

SCOREFLOW_HEADER="DOCK_PROGRAM PROTOCOL RECEPTOR LIGAND POSE SCORE"

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
echo "
ScoreFlow summary:
-------------------------------------------------------------------------------
[ General info ]
    HOST: ${HOSTNAME}
    USER: ${USER}
 PROJECT: ${PROJECT}
PROTOCOL: ${PROTOCOL}
 WORKDIR: ${PWD}

[ Docking setup ]
RECEPTOR NAME: ${RECEPTOR_NAME}
RECEPTOR FILE: ${RECEPTOR_FILE}
  LIGAND FILE: ${LIGAND_FILE}
     NLIGANDS: ${NLIGANDS}
       CHARGE: ${CHARGE}
      PROGRAM: ${SCORE_PROGRAM}
      SCORING: ${SCORING_FUNCTION}"
case ${SCORE_PROGRAM} in
"VINA")
    echo "       CENTER: ${DOCK_CENTER[@]}"
    echo "         SIZE: ${DOCK_LENGHT[@]} (X,Y,Z)"
;;
"PLANTS")
    echo "       CENTER: ${DOCK_CENTER[@]}"
    echo "       RADIUS: ${DOCK_RADIUS}"
;;
"AMBER")
    echo "           MD: ${MD}"
    if [ ${WATER} = 'no' ] ; then
        echo "      SOLVENT: implicit"
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
read -p "
Continue [y/n]? " opt

case $opt in
"Y"|"YES"|"Yes"|"yes"|"y")  ;;
*)  echo "Exiting" ; exit 0 ;;
esac
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
ScoreFlow -r receptor.pdb -l ligand.mol2 -p myproject [--protocol protocol-name] -sf mmgbsa

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
echo "
ScoreFlow is a bash script designed to work with PLANTS, Vina, IChem and AmberTools16+.
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
 -sf/--function     STR : vina, chemplp, plp, plp95, mmgbsa [chemplp]

[ Charge Scheme - MMGBSA ]
 --gas                  : Default Gasteiger-Marsili (default)
 --bcc                  : BCC charges
 --resp                 : RESP charges (require gaussian)

[ Simulation ]
 --water                : Explicit solvent [implicit solvent]
 --md                   : Molecular dynamics

[ Parallel execution - MMGBSA ]
 -nc/--cores        INT : Number of cores per node [${NCORES}]
 --pbs/--slurm          : Workload manager, PBS or SLURM
 -nn/--nodes        INT : Number of nodes to use (ony for PBS or SLURM) [1]
 --header          FILE : Header file provided to run on your cluster.
 --write-only           : Write a template file (ScoreFlow.run.template) command without running.
 --run-only             : Run using the ScoreFlow.run.template file.


[ Additional ]
 --overwrite            : Overwrite results

[ Rescoring with vina or plants ]
*--center           STR : xyz coordinates of the center of the binding site, separated by a space

[ Post Processing ]
 --postprocess          : Process DockFlow output for the specified project/protocol/receptor.
_________________________________________________________________________________
"
exit 0
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
            shift # past argument
        ;;
        "-hh"|"--full-help")
            ScoreFlow_help_full
            exit 0
            shift
        ;;
        "-r"|"--receptor")
            RECEPTOR_FILE="$2"
            RECEPTOR_NAME="$(basename ${RECEPTOR_FILE} .mol2 )"
            shift # past argument
        ;;
        "-l"|"--ligand")
            LIGAND_FILE="$2"
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
        "-nc"|"--cores") # Number of Cores [1] (or cores/node)
            NCORES="$2" # Same as above.
            shift # past argument
        ;;
        # Charge calculation
        "--gas")
            CHARGE="gas"
        ;;
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
        "-maxcyc") # Maximun number of Energy minimization steps.
            maxcyc="$2" # Same as above.
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
            HEADER_FILE=$2
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
        *)
            unknown="$1"        # unknown option
            echo "Unknown flag \"$unknown\". RTFM"
            exit 0
        ;;
    esac
    shift # past argument or value
done
}
