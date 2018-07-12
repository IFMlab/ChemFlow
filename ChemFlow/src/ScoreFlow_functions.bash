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
#   DESCRIPTION: call the right function for the rescoring
#
#    PARAMETERS: ${SCORE_PROGRAM}
#
#        Author: Dona de Francquen
#===============================================================================
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


ScoreFlow_rescore_plants () {
#===  FUNCTION  ================================================================
#          NAME: ScoreFlow_rescore_plants
#   DESCRIPTION: Rescore docking poses using plants
#                
#    PARAMETERS: ${RUNDIR}
#                ${LIGAND}
#                ${SCORING_FUNCTION}
#                ${DOCK_CENTER}
#                ${DOCK_RADIUS}
#                ${DOCK_POSES}
#
#       COMMENT: It's not worthy to rescore in parallel using VINA or PLANTS
#===============================================================================
if [ -d ${RUNDIR}/PLANTS ] ; then
    case "${OVERWRITE}" in
    "yes")
        rm -rf   ${RUNDIR}/PLANTS
    ;;
    "no")
        ERROR_MESSAGE="PLANTS folder exists. Use --overwrite " ; ChemFlow_error ${PROGRAM} ;
    ;;
    esac
fi

cd ${RUNDIR}
ScoreFlow_write_plants_config

# Run plants
PLANTS1.2_64bit --mode rescore ${RUNDIR}/rescore_input.in &>rescoring.log
}


ScoreFlow_write_plants_config() {
#===  FUNCTION  ================================================================
#          NAME: ScoreFlow_write_plants_config
#   DESCRIPTION: Write the dock input for plants (configuration file)
#
#        Author: Diego E. B. Gomes
#                Dona de Francquen
#
#    PARAMETERS: ${RUNDIR}
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
protein_file receptor.mol2
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
" > ${RUNDIR}/rescore_input.in
}


ScoreFlow_rescore_vina() {
#===  FUNCTION  ================================================================
#          NAME: ScoreFlow_rescore_plants
#   DESCRIPTION: Rescore docking poses using vina
#
#        Author: Dona de Francquen
#
#    PARAMETERS: ${RUNDIR}
#                ${LIGAND}
#                ${SCORING_FUNCTION}
#                ${DOCK_CENTER}
#                ${DOCK_RADIUS}
#                ${DOCK_POSES}
#===============================================================================

# Cleanup
if [ -f ${RUNDIR}/ScoreFlow.csv ] ; then
    rm -rf ${RUNDIR}/ScoreFlow.csv
fi

# Prepare RECEPTOR
    ${mgltools_folder}/bin/python \
    ${mgltools_folder}/MGLToolsPckgs/AutoDockTools/Utilities24/prepare_receptor4.py \
        -r ${RUNDIR}/receptor.mol2 \
        -o ${RUNDIR}/receptor.pdbqt


for LIGAND in ${LIGAND_LIST[@]} ; do
    # DONA fix this please.
    ${mgltools_folder}/bin/python \
    ${mgltools_folder}/MGLToolsPckgs/AutoDockTools/Utilities24/prepare_ligand4.py \
        -l ${RUNDIR}/${LIGAND}/ligand.mol2 \
        -o ${RUNDIR}/${LIGAND}/ligand.pdbqt
done

for LIGAND in ${LIGAND_LIST[@]} ; do
    vina --local_only --receptor ${RUNDIR}/receptor.pdbqt --ligand ${RUNDIR}/${LIGAND}/ligand.pdbqt \
         --center_x ${DOCK_CENTER[0]} --center_y ${DOCK_CENTER[1]} --center_z ${DOCK_CENTER[2]} \
         --size_x ${DOCK_RADIUS} --size_y ${DOCK_RADIUS} --size_z ${DOCK_RADIUS} \
         --out ${RUNDIR}/${LIGAND}/output.pdbqt --log ${RUNDIR}/${LIGAND}/output.log ${VINA_EXTRA} &> /dev/null
done
}


ScoreFlow_rescore_mmgbsa() {
#===  FUNCTION  ================================================================
#          NAME: ScoreFlow_rescore_mmgbsa
#   DESCRIPTION: Rescore docking poses using mmgbsa
#
#        Author: Diego E. B. Gomes
#                
#    PARAMETERS: ${RUNDIR}
#                ${LIGAND_LIST}
#       RETURNS: -
#
#===============================================================================
ScoreFlow_compute_charges
ScoreFlow_write_run_tleap
ScoreFlow_implicit_write_MIN

if [ ${MD} == 'yes' ] ; then
  ScoreFlow_implicit_write_MD
fi

ScoreFlow_MMGBSA_write

for LIGAND in ${LIGAND_LIST[@]} ; do
    echo -ne "Computing MMBSA ${RECEPTOR_NAME} - ${LIGAND}     \r"
    cd ${RUNDIR}/${LIGAND}
    ScoreFlow_implicit_run_MIN

    if [ ${MD} == 'yes' ] ; then
      ScoreFlow_implicit_run_MD
    fi

    ScoreFlow_MMGBSA_run
done
}


ScoreFlow_compute_charges() {
#===  FUNCTION  ================================================================
#          NAME: ScoreFlow_compute_charges
#   DESCRIPTION: compute charge to run mmgbsa calculation
#
#        Author: Diego E. B. Gomes
#
#    PARAMETERS: ${RUNDIR}
#                ${LIGAND_LIST}
#                ${CHARGE}
#                ${NCORES}
#       RETURNS: -
#
#===============================================================================
# Clean up
if [  -f ${RUNDIR}/charges.xargs ] ; then
    rm -rf ${RUNDIR}/charges.xargs
fi

for LIGAND in ${LIGAND_LIST[@]} ; do
    echo -ne "Computing ${CHARGE} charges for ${LIGAND}     \r"
    cd ${RUNDIR}/${LIGAND}

    # Mandatory Gasteiger charges
    if [ ! -f ligand_gas.mol2 ] ; then
        antechamber -i ligand.mol2 -fi mol2 -o ligand_gas.mol2 -fo mol2 -c gas -s 2 -eq 1 -rn MOL -pf y -dr no &> antechamber.log
    fi

    case ${CHARGE} in
    "bcc")
        # Compute am1-bcc charges
        if [ ! -f ligand_bcc.mol2 ] ; then
            echo "cd ${RUNDIR}/${LIGAND} ; antechamber -i ligand_gas.mol2 -fi mol2 -o ligand_bcc.mol2 -fo mol2 -c bcc -s 2 -eq 1 -rn MOL -pf y -dr no &> antechamber.log" >> ${RUNDIR}/charges.xargs
        fi
        ;;
    "resp")
        # Prepare Gaussian
        if [ ! -f ligand_resp.mol2 ] ; then
            antechamber -i ligand_gas.mol2 -fi mol2 -o ligand.gau -fo gcrt -gv 1 -ge ligand.gesp -gm "%mem=16Gb" -gn "%nproc=${NCORES}" -s 2 -eq 1 -rn MOL -pf y -dr no &> antechamber.log

            # Run Gaussian to optimize structure and generate electrostatic potential grid
            g09 <ligand.gau>ligand.gout

            # Read Gaussian output and write new optimized ligand with RESP charges
            antechamber -i ligand.gout -fi gout -o ligand_resp.mol2 -fo mol2 -c resp -s 2 -rn MOL -pf y -dr no &>> ${RUNDIR}/antechamber.log
        fi
    ;;
    esac
done 

if [ ${CHARGE} == "bcc" ] && [ -f ${RUNDIR}/charges.xargs ] ; then
    cat ${RUNDIR}/charges.xargs | xargs -P${NCORES} -I '{}' bash -c '{}'
fi

for LIGAND in ${LIGAND_LIST[@]} ; do
    cd ${RUNDIR}/${LIGAND}
    if [ ! -f ligand.frcmod ] && [ -f ligand_gas.mol2 ] ; then
            parmchk2 -i ligand_gas.mol2 -o ligand.frcmod -s 2 -f mol2
    else
        echo "${LIGAND} gas" >> ${RUNDIR}/antechamber_errors.lst
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
done
}


ScoreFlow_write_run_tleap() {
#===  FUNCTION  ================================================================
#          NAME: ScoreFlow_write_run_tleap
#   DESCRIPTION:
#
#        Author: Diego E. B. Gomes
#
#    PARAMETERS: ${RUNDIR}
#                ${RECEPTOR_NAME}
#                ${LIGAND_LIST}
#                ${CHARGE}
#                ${NCORES}
#       RETURNS: -
#
#===============================================================================

cd ${RUNDIR}/

echo "
source oldff/leaprc.ff99SBildn
source leaprc.gaff

set default pbradii mbondi2 

ptn = loadpdb ../receptor.pdb
#saveamberparm ptn ptn.prmtop ptn.rst7
#savePDB ptn ptn.pdb
#charge ptn

# Ligand --------------------------------------------------
# Load ligand parameters
loadAmberParams ligand.frcmod
ligand = loadmol2  ligand_${CHARGE}.mol2
saveamberparm ligand ligand.prmtop ligand.rst7
#savePDB ligand ligand.pdb
#charge ligand

complex = combine{ptn,ligand}
saveamberparm complex complex.prmtop complex.rst7
#savePDB complex complex.pdb
#charge complex
quit
" > tleap_gbsa.in

# Goes back to rundir to prepare in parallel.

if [ -f tleap.xargs ] ; then rm -rf tleap.xargs ; fi
 
for LIGAND in ${LIGAND_LIST[@]} ; do
    echo -ne "Preparing complex: ${RECEPTOR_NAME} - ${LIGAND}     \r"
    if [ ! -f ${RUNDIR}/${LIGAND}/complex.rst7 ] ; then
        echo "cd ${RUNDIR}/${LIGAND}/ ; echo \"${RECEPTOR_NAME} - ${LIGAND}\" ;  tleap -f ../tleap_gbsa.in &> tleap.job" >> tleap.xargs
    fi
done

if [ ! -f tleap.xargs ] ; then
    ERROR_MESSAGE="run tleap impossible (TODO)"
else
    cat tleap.xargs | xargs -P${NCORES} -I '{}' bash -c '{}'
fi
}

ScoreFlow_implicit_write_MIN() {
#===  FUNCTION  ================================================================
#          NAME: ScoreFlow_MMGBSA_implicit_write_MIN
#   DESCRIPTION: Write mmgbsa implicit MIN config
#
#        Author: Diego E. B. Gomes
#
#    PARAMETERS: -
#       RETURNS: -
#
#===============================================================================

cd ${RUNDIR}

echo "MD GB2, infinite cut off
&cntrl
  imin=1,maxcyc=1000,
  irest=0,ntx=1,
  cut=9999.0, rgbmax=15.0,
  igb=2
! Frozen or restrained atoms
!----------------------------------------------------------------------
 ntr=1,
 restraintmask='@CA,C,N,O',
 restraint_wt=1.0,
/
" > min_gbsa.in
}


ScoreFlow_implicit_write_MD() {
#===  FUNCTION  ================================================================
#          NAME: ScoreFlow_MMGBSA_implicit_write_MIN
#   DESCRIPTION: Write mmgbsa implicit config
#
#        Author: Diego E. B. Gomes
#
#    PARAMETERS: -
#       RETURNS: -
#
#===============================================================================

cd ${RUNDIR}

echo "MD GB2, infinite cut off
&cntrl
  imin=0,irest=0,ntx=1,
  nstlim=10000,dt=0.002,ntb=0,
  ntf=2,ntc=2,
  ntpr=1000, ntwx=1000, ntwr=30000,
  cut=9999.0, rgbmax=15.0,
  igb=2,ntt=3,gamma_ln=1.0,nscm=0,
  temp0=300.0,
! Frozen or restrained atoms
!----------------------------------------------------------------------
! ibelly,
! bellymask,
 ntr=1,
 restraintmask=':1-242@CA,C,N,O', 
 restraint_wt=10.0,
/
" > md_gbsa.in
}

ScoreFlow_implicit_run_MIN() {
#===  FUNCTION  ================================================================
#          NAME: ScoreFlow_MMGBSA_implicit_run_MIN
#   DESCRIPTION: Run mmgbsa implicit MIN
#
#        Author: Diego E. B. Gomes
#
#    PARAMETERS: ${OVERWRITE}
#       RETURNS: -
#
#===============================================================================
init=complex
input=min_gbsa
prev=complex
run=mini

var=""

# Check if simulations finished
if [ -f mini.mdout ] ; then 
    var=$(tail -1 mini.mdout | awk '/Total wall time/{print $1}')
fi
 
# If empty or simulation finished, (re)run.
if [ "${var}" == "" ] || [ "${OVERWRITE}" == 'yes' ] ; then
    pmemd.cuda -O  \
    -i ../${input}.in -o   ${run}.mdout   -e ${run}.mden   -r ${run}.rst7  \
    -x ${run}.nc      -v   ${run}.mdvel -inf ${run}.mdinfo -c ${prev}.rst7 \
    -p ${init}.prmtop -ref ${prev}.rst7 &>   ${run}.job
fi
}


ScoreFlow_implicit_run_MD() {
#===  FUNCTION  ================================================================
#          NAME: ScoreFlow_MMGBSA_implicit_run_MIN
#   DESCRIPTION: Run mmgbsa implicit MIN
#
#        Author: Diego E. B. Gomes
#
#    PARAMETERS: ${OVERWRITE}
#       RETURNS: -
#
#===============================================================================
init=complex
input=md_gbsa
prev=mini
run=md

var=""
var_md=""
# Check if simulations finished
if [ -f mini.mdout ] ; then
    var=$(tail -1 mini.mdout | awk '/Total wall time/{print $1}')
fi

if [ -f md.mdout ] ; then
    var_md=$(tail -1 md.mdout | awk '/Total wall time/{print $1}')
fi

# If empty or simulation finished, (re)run.
if [ "${var}" != "" ] ; then
    if [ "${var_md}" == "" ] ||  [ ${OVERWRITE} == 'yes' ]  ; then
        pmemd.cuda -O  \
        -i ../${input}.in -o   ${run}.mdout   -e ${run}.mden   -r ${run}.rst7  \
        -x ${run}.nc      -v   ${run}.mdvel -inf ${run}.mdinfo -c ${prev}.rst7 \
        -p ${init}.prmtop -ref ${prev}.rst7 &>   ${run}.job
    fi
fi
}



ScoreFlow_MMGBSA_write() {
#===  FUNCTION  ================================================================
#          NAME: ScoreFlow_MMGBSA_write
#   DESCRIPTION: Write mmgbsa config
#
#        Author: Diego E. B. Gomes
#
#    PARAMETERS: -
#       RETURNS: -
#
#===============================================================================
cd ${RUNDIR}

echo "Input file for running GB2
&general
   verbose=1,keep_files=0,interval=10
/
&gb
  igb=2, saltcon=0.150
/
" > GB2.in
}


ScoreFlow_MMGBSA_run() {
#===  FUNCTION  ================================================================
#          NAME: ScoreFlow_MMGBSA_implicit_run_MIN
#   DESCRIPTION: Run mmgbsa
#
#        Author: Diego E. B. Gomes
#
#    PARAMETERS: ${OVERWRITE}
#       RETURNS: -
#
#===============================================================================

TRAJECTORY="mini.rst7"
if [ ${MD} == 'yes' ] ; then
    TRAJECTORY="md.nc"
fi

if [ ! -f MMPBSA.dat ] || [ "${OVERWRITE}" == 'yes' ] ; then
    rm -rf com.top rec.top ligand.top

    ante-MMPBSA.py -p complex.prmtop -c com.top -r rec.top -l ligand.top -n :MOL -s ':WAT,Na+,Cl-' --radii=mbondi2 &> ante_mmpbsa.job

    MMPBSA.py -O -i ../GB2.in -cp com.top -rp rec.top -lp ligand.top -o MMPBSA.dat -eo MMPBSA.csv -y ${TRAJECTORY} &> MMPBSA.job

    rm -rf reference.frc
fi

}

ScoreFlow_organize() {
#===  FUNCTION  ================================================================
#          NAME: ScoreFlow_organize
#   DESCRIPTION: Organise folders and files before rescoring
#
#        Author: Diego E. B. Gomes
#
#    PARAMETERS: ${OVERWRITE}
#       RETURNS: -
#
#===============================================================================
# TODO 
# Improve extracting mol2 to separate folders.
# 


#if [ ${ORGANIZE} == 'yes' ] ; then

if [  ! -d ${RUNDIR} ] ; then
  mkdir -p ${RUNDIR}
fi

if [ ${SCORE_PROGRAM} == "PLANTS" ] ; then
      for LIGAND in ${LIGAND_LIST[@]} ; do
        if [  ! -d ${RUNDIR}/${LIGAND}/ ] ; then
          mkdir -p ${RUNDIR}/${LIGAND}/
        fi
      done
fi

# if [ ${REWRITE_LIGANDS} == 'yes' ] ; then 

# Copy files to project folder.
if [ ${SCORING_FUNCTION} == "mmgbsa" ] ; then
    cp ${RECEPTOR_FILE} ${RUNDIR}/receptor.pdb
else
    cp ${RECEPTOR_FILE} ${RUNDIR}/receptor.mol2
fi
cp ${LIGAND_FILE} ${RUNDIR}/ligand.mol2


for LIGAND in ${LIGAND_LIST[@]} ; do
    if [ ! -d  ${RUNDIR}/${LIGAND} ] ; then
      mkdir -p ${RUNDIR}/${LIGAND}
    fi
done


OLDIFS=$IFS
IFS='%'
if [ ${SCORE_PROGRAM} != "PLANTS" ] ; then
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

#fi
}


ScoreFlow_postprocess() {
#===  FUNCTION  ================================================================
#          NAME: ScoreFlow_postprocess
#   DESCRIPTION: Post processing ScoreFlow run depending on the dock program used
#                Each project / receptor will have a ScoreFlow.csv file.
#
#        Author: Dona de Francquen
#
#    PARAMETERS: ${OVERWRITE}
#       RETURNS: -
#
#===============================================================================
echo "
Scoring function: ${SCORING_FUNCTION}
         Rundir : ${RUNDIR}
"
if [ -f ${RUNDIR}/ScoreFlow.csv ]  ; then
    rm -rf ${RUNDIR}/ScoreFlow.csv
fi

case ${SCORE_PROGRAM} in
"PLANTS")
    if [ ! -f ${RUNDIR}/PLANTS/ranking.csv ] ; then
        ERROR_MESSAGE="Plants results for PROJECT '${PROJECT}' / PROTOCOL '${PROTOCOL}' does not exists."
        ChemFlow_error
    else
        echo "DOCK_PROGRAM PROTOCOL LIGAND POSE SCORE" > ${RUNDIR}/ScoreFlow.csv
        sed 's/\.*_entry.*_conf_[[:digit:]]*//' ${RUNDIR}/PLANTS/ranking.csv | awk -v protocol=${PROTOCOL} -v target=${RECEPTOR_NAME} -v ligand=${LIGAND} -F, '!/LIGAND/ {print "PLANTS",protocol,target,ligand,$1,$2}' >> ${RUNDIR}/ScoreFlow.csv
    fi
;;
"VINA")
    for LIGAND in ${LIGAND_LIST[@]} ; do
        if [ -f ${RUNDIR}/${LIGAND}/output.log ] ; then
            if [ ! -f ${RUNDIR}/ScoreFlow.csv ] ; then
                echo "DOCK_PROGRAM PROTOCOL LIGAND POSE SCORE" > ${RUNDIR}/ScoreFlow.csv
            fi
            awk -v protocol=${PROTOCOL} -v target=${RECEPTOR_NAME} -v ligand=${LIGAND} '/Affinity:/ {print "VINA",protocol,target,ligand,ligand,$2}' ${RUNDIR}/${LIGAND}/output.log >> ${RUNDIR}/ScoreFlow.csv
        fi
     done
     if [ ! -f ${RUNDIR}/ScoreFlow.csv ] ; then
         ERROR_MESSAGE="Vina results for PROJECT '${PROJECT}' / PROTOCOL '${PROTOCOL}' does not exists."
         ChemFlow_error
    else
        sed -i 's/[a-zA-Z0-9]*_conf_//2' ${RUNDIR}/ScoreFlow.csv
        sed -i 's/_conf_[[:digit:]]*//' ${RUNDIR}/ScoreFlow.csv
    fi
;;
"AMBER")
    for LIGAND in ${LIGAND_LIST[@]} ; do
        if [ -f ${RUNDIR}/${LIGAND}/MMPBSA.dat ] ; then
            if [ ! -f ${RUNDIR}/ScoreFlow.csv ] ; then
                echo "DOCK_PROGRAM PROTOCOL LIGAND POSE SCORE" > ${RUNDIR}/ScoreFlow.csv
            fi
            awk -v protocol=${PROTOCOL} -v target=${RECEPTOR_NAME} -v ligand=${LIGAND} '/DELTA TOTAL/{print "AMBER",protocol,target,ligand,ligand,$3}' ${RUNDIR}/${LIGAND}/MMPBSA.dat >> ${RUNDIR}/ScoreFlow.csv
        fi
    done
    if [ ! -f ${RUNDIR}/ScoreFlow.csv ] ; then
         ERROR_MESSAGE="Amber results for PROJECT '${PROJECT}' / PROTOCOL '${PROTOCOL}' does not exists."
         ChemFlow_error
    else
        sed -i 's/[a-zA-Z0-9]*_conf_//2' ${RUNDIR}/ScoreFlow.csv
        sed -i 's/_conf_[[:digit:]]*//' ${RUNDIR}/ScoreFlow.csv
    fi

;;
esac
}


ScoreFlow_summary() {
echo "
ScoreFlow summary:
-------------------------------------------------------------------------------
[ General info ]
    HOST ${HOSTNAME}
    USER ${USER}
 PROJECT ${PROJECT}
PROTOCOL ${PROTOCOL}
 WORKDIR ${PWD} 

[ Docking setup ]
RECEPTOR ${RECEPTOR_NAME}
RECEPTOR_FILE ${RECEPTOR_FILE}
  LIGAND ${LIGAND_FILE}
  CHARGE ${CHARGE}
NLIGANDS ${NLIGANDS}
 PROGRAM ${SCORE_PROGRAM}
 SCORING ${SCORING_FUNCTION}"
case ${SCORE_PROGRAM} in
"VINA")
    echo "  CENTER ${DOCK_CENTER[@]}
   SIZE ${DOCK_LENGHT[@]} (X,Y,Z)"
;;
"PLANTS")
    echo "  CENTER ${DOCK_CENTER[@]}
  RADIUS ${DOCK_RADIUS}"
;;
"AMBER")
    echo "      MD ${MD}"
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


ScoreFlow_help() {
echo "Example usage: 
# For all Scoring functions except MMGBSA:
ScoreFlow -r receptor.mol2 -l ligand.mol2 -p myproject [-protocol 1] [-n 8] [-sf chemplp] 

# For MMGBSA only 
ScoreFlow -r receptor.pdb -l ligand.mol2 -p myproject [-protocol 1] [-n 8] -sf mmgbsa

[Options]
 -h/--help           : Show this help message and quit
-hh/--full-help      : Detailed help
 -f/--file           : ScoreFlow configuration file
 -r/--receptor       : Receptor's mol2 file.
 -l/--ligand         : Ligands .mol2 input file.
 -p/--project        : ChemFlow project name
"
exit 0
}


ScoreFlow_help_full(){
echo "
ScoreFlow is a bash script designed to work with PLANTS, Vina, IChem and AmberTools16+.
It can perform an rescoring of molecular complexes such as protein-ligand

ScoreFlow requires a project folder named \"project\".chemflow if absent, one will be created. 

Usage:
ScoreFlow -r receptor.mol2 -l ligand.mol2 -p myproject [-protocol 1] [-n 8] [-sf chemplp]

[Help]
 -h/--help           : Show this help message and quit
-hh/--full-help      : Detailed help

[Required]
 -f/--file           : ScoreFlow configuration file
 -r/--receptor       : Receptor's mol2 file
 -l/--ligand         : Ligands .mol2 input file
 -p/--project        : ChemFlow project name

[Optional]
 --protocol          : Name for this specific protocol [default]
 -sf/--function      : vina, chemplp, plp, plp95, mmgbsa, IFP

[ Charge Scheme ] 
 --gas               : Default Gasteiger-Marsili charges
 --bcc               : BCC charges
 --resp              : RESP charges (require gaussian)

[ Parallel execution ] 
 -nc/--cores         : Number of cores per node
  -w/--workload      : Workload manager, PBS or SLURM 
 -nn/--nodes         : Number of nodes to use (ony for PBS or SLURM)

[ Options for docking program ] 
_________________________________________________________________________________
"
exit 0
}

ScoreFlow_CLI() {

if [ "$1" == "" ] ; then
    ERROR_MESSAGE="ScoreFlow called without arguments."
    ChemFlow_error ;
fi

while [[ $# -gt 0 ]]; do
    key="$1"

    case ${key} in
        "--resume")
            echo -ne "\nResume not implemented"
            exit 0
        ;;
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
        -nc|--cores) # Number of Cores [1] (or cores/node)
            NCORES="$2" # Same as above.
            shift # past argument
        ;;
        --cuda)
            CUDA="yes"
        ;;
        # Charge calculation
        --gas)
            CHARGE="gas"
        ;;
        --resp)
            CHARGE="resp"
        ;;
        --bcc)
            CHARGE="bcc"
        ;;
        --md)
            MD="yes"
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
        ## Final arguments
        --overwrite)
            OVERWRITE="yes"
        ;;
        --no-organize)
            ORGANIZE="no"
        ;;
        ## ADVANCED USER INPUT
        #    --advanced)
        #      USER_INPUT="$2"
        #      shift
        --postprocess)
            POSTPROCESS="yes"
        ;;
        #    --archive)
        #      ARCHIVE='yes'
        #    ;;
        *)
            unknown="$1"        # unknown option
            echo "Unknown flag \"$unknown\""
        ;;
    esac
    shift # past argument or value
done
}
