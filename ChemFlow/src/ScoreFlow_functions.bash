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

case ${SCORING_FUNCTION} in
  "chemplp"|"plp"|"plp95")
    ScoreFlow_rescore_plants
  ;;
  "mmgbsa")
    ScoreFlow_rescore_mmgbsa
  ;;
  esac
}


ScoreFlow_rescore_plants () {
#===  FUNCTION  ================================================================
#          NAME: ScoreFlow_rescore_plants
#   DESCRIPTION: Writes the PLANTS input file for each ligand. 
#                Input/Output filenames are hardcoded to comply with standard.
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

echo "
# input files
protein_file ${RECEPTOR}
ligand_file ${LIGAND_FILE} 

# output
output_dir PLANTS

# scoring function and search settings
scoring_function ${SCORING_FUNCTION}
search_speed speed1

# write mol2 files as a single (1) or multiple (0) mol2 files
write_multi_mol2 1

# binding site definition
bindingsite_center ${DOCK_CENTER}
bindingsite_radius ${DOCK_RADIUS}

# cluster algorithm, save the best DOCK_POSES.
cluster_structures ${DOCK_POSES}
cluster_rmsd 2.0

# write 
write_ranking_links 0
write_protein_bindingsite 1
write_protein_conformations 0
####
" > rescore_input.in

nlig=$( rgrep -c MOLECULE ${LIGAND_FILE} )

echo "[ ScoreFlow ] Rescoring ${nlig} poses, please wait"

PLANTS1.2_64bit --mode rescore rescore_input.in &>rescoring.log
}


ScoreFlow_rescore_mmgbsa() {
#===  FUNCTION  ================================================================
#          NAME: ScoreFlow_rescore_mmgbsa
#   DESCRIPTION: 
#                
#                
#    PARAMETERS: ${RUNDIR}
#                ${LIGAND_LIST}
#       RETURNS: -
#
#===============================================================================
  ScoreFlow_compute_charges
  ScoreFlow_write_run_tleap

  for LIGAND in ${LIGAND_LIST[@]} ; do
    echo -ne "Computing MMBSA ${RECEPTOR_NAME} - ${LIGAND}     \r" 
    cd ${RUNDIR}/${LIGAND}
    ScoreFlow_MMGBSA_implicit_write_MIN
    ScoreFlow_MMGBSA_implicit_run_MIN
    ScoreFlow_MMGBSA_write
    ScoreFlow_MMGBSA_run_MIN
  done
}


ScoreFlow_compute_charges() {

# Clean up
if [  -f ${RUNDIR}/charges.xargs ] ; then
  rm -rf ${RUNDIR}/charges.xargs
fi

for LIGAND in ${LIGAND_LIST[@]} ; do

echo -ne "Computing ${CHARGE} charges for ${LIGAND}     \r" 
cd ${RUNDIR}/${LIGAND}

# Mandatory Gasteiger charges
if [ ! -f lig_gas.mol2 ] ; then 
  antechamber -i lig.mol2 -fi mol2 -o lig_gas.mol2 -fo mol2 -c gas -s 2 -eq 1 -rn MOL -pf y -dr no &> antechamber.log
fi

case ${CHARGE} in
#"gas")
# Compute gasteiger charges
#    if [ ! -f lig_gas.mol2 ] ; then 
#      antechamber -i lig.mol2 -fi mol2 -o lig_gas.mol2 -fo mol2 -c gas -s 2 -eq 1 -rn MOL -pf y -dr no &> antechamber.log
#    fi
#    ;;
"bcc")
    # Compute am1-bcc charges
    if [ ! -f lig_bcc.mol2 ] ; then 
     # Mandatory Gasteiger charges
     echo "cd ${RUNDIR}/${LIGAND} ; antechamber -i lig_gas.mol2 -fi mol2 -o lig_bcc.mol2 -fo mol2 -c bcc -s 2 -eq 1 -rn MOL -pf y -dr no &> antechamber.log" >> ${RUNDIR}/charges.xargs
    fi
    ;;
"resp")
    # Prepare Gaussian
    if [ ! -f lig_resp.mol2 ] ; then 
      antechamber -i lig_gas.mol2 -fi mol2 -o lig.gau -fo gcrt -gv 1 -ge lig.gesp -gm "%mem=16Gb" -gn "%nproc=${NCORES}" -s 2 -eq 1 -rn MOL -pf y -dr no &> antechamber.log 

    # Run Gaussian to optimize structure and generate electrostatic potential grid
      g09 lig.gau > lig.gout

    # Read Gaussian output and write new optimized ligand with RESP charges
      antechamber -i lig.gout -fi gout -o lig_resp.mol2 -fo mol2 -c resp -s 2 -rn MOL -pf y -dr no &>> ${RUNDIR}/antechamber.log
    fi
    ;;
esac
done 

if [ -f ${RUNDIR}/charges.xargs ] ; then
  cat ${RUNDIR}/charges.xargs | xargs -P${NCORES} -I '{}' bash -c '{}'
fi



for LIGAND in ${LIGAND_LIST[@]} ; do

cd ${RUNDIR}/${LIGAND}
if [ ! -f lig.frcmod ] ; then

case ${CHARGE} in
"gas")
    if [ ! -f lig_gas.mol2 ] ;        then 
      echo >> ${RUNDIR}/antechamber_errors.lst 
    else
      parmchk2 -i lig_gas.mol2 -o lig.frcmod -s 2 -f mol2
    fi
    ;;
"bcc")
    if [ ! -f lig_bcc.mol2 ] ; then 
      echo >> ${RUNDIR}/antechamber_errors.lst 
    else
      parmchk2 -i lig_bcc.mol2 -o lig.frcmod -s 2 -f mol2
    fi
    ;;
"resp")
    if [ ! -f lig.gau ] ;      then echo >> ${RUNDIR}/antechamber_errors.lst ; fi
    if [ ! -f lig_resp.mol2 ]; then 
      echo >> ${RUNDIR}/antechamber_errors.lst 
    else
      parmchk2 -i lig_resp.mol2 -o lig.frcmod -s 2 -f mol2
    fi
    ;;
esac

fi

done


}


ScoreFlow_write_run_tleap() {

for LIGAND in ${LIGAND_LIST[@]} ; do

echo -ne "Preparing complex: ${RECEPTOR_NAME} - ${LIGAND}     \r" 
cd ${RUNDIR}/${LIGAND}/

echo "
source oldff/leaprc.ff99SBildn
source leaprc.gaff

set default pbradii mbondi2 

ptn = loadpdb ../b4amber.pdb
saveamberparm ptn ptn.prmtop ptn.rst7
savePDB ptn ptn.pdb
charge ptn

# Ligand --------------------------------------------------
# Load ligand parameters
loadAmberParams lig.frcmod
lig = loadmol2  lig_${CHARGE}.mol2
saveamberparm lig lig.prmtop lig.rst7
savePDB lig lig.pdb
charge lig

complex = combine{ptn,lig}
saveamberparm complex complex.prmtop complex.rst7
savePDB complex complex.pdb
charge complex

quit
" > tleap_gbsa.in
done

# Goes back to rundir to prepare in parallel.
cd ${RUNDIR}

if [ -f tleap.xargs ] ; then rm -rf tleap.xargs ; fi
 
for LIGAND in ${LIGAND_LIST[@]} ; do
  if [ ! -f ${RUNDIR}/${LIGAND}/complex.rst7 ] ; then
    echo "cd ${RUNDIR}/${LIGAND}/ ; echo \"${RECEPTOR_NAME} - ${LIGAND}\" ;  tleap -f tleap_gbsa.in &> tleap.job" >> tleap.xargs
  fi

done

if [ -f tleap.xargs ] ; then
  cat tleap.xargs | xargs -P${NCORES} -I '{}' bash -c '{}'
fi

}

ScoreFlow_MMGBSA_implicit_write_MIN() {
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


ScoreFlow_MMGBSA_implicit_write_MD() {
echo "MD GB2, infinite cut off
&cntrl
  imin=0,irest=0,ntx=1,
  nstlim=500000,dt=0.002,ntb=0,
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

ScoreFlow_MMGBSA_implicit_run_MIN() {

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
-i ${input}.in    -o   ${run}.mdout   -e ${run}.mden   -r ${run}.rst7  \
-x ${run}.mdcrd   -v   ${run}.mdvel -inf ${run}.mdinfo -c ${prev}.rst7 \
-p ${init}.prmtop -ref ${prev}.rst7 &>   ${run}.job
fi

}



ScoreFlow_MMGBSA_write() {
echo "Input file for running GB2
&general
   verbose=1,keep_files=0,interval=10
/
&gb
  igb=2, saltcon=0.150
/
" >GB2.in
}


ScoreFlow_MMGBSA_run_MIN() {

if [ ! -f MMPBSA_MINI.dat ] || [ "${OVERWRITE}" == 'yes' ] ; then 

rm -rf com.top rec.top lig.top

ante-MMPBSA.py -p complex.prmtop -c com.top -r rec.top -l lig.top -n :MOL -s ':WAT,Na+,Cl-' --radii=mbondi2 &> ante_mmpbsa.job

MMPBSA.py -O -i GB2.in -cp com.top -rp rec.top -lp lig.top -o MMPBSA_MINI.dat -eo MMPBSA_MINI.csv -y mini.rst7 &> MMPBSA_MINI.job

rm -rf reference.frc
fi

}

ScoreFlow_organize() {
# TODO 
# Improve extracting mol2 to separate folders.
# 
RUNDIR=${WORKDIR}/${PROJECT}.chemflow/ScoreFlow/${PROTOCOL}/${RECEPTOR_NAME}/


if [ ${ORGANIZE} == 'yes' ] ; then

  if [  ! -d ${RUNDIR} ] ; then
    mkdir -p ${RUNDIR}
  fi


  for LIGAND in ${LIGAND_LIST[@]} ; do
    if [  ! -d ${RUNDIR}/${LIGAND}/ ] ; then
      mkdir -p ${RUNDIR}/${LIGAND}/
    fi
  done

# if [ ${REWRITE_LIGANDS} == 'yes' ] ; then 

    # Copy files to project folder.
    cp ${RECEPTOR_FILE} ${RUNDIR}/b4amber.pdb
    cp ${LIGAND_FILE}   ${RUNDIR}/

    # Copy each ligand to it's folder.
    n=-1
    while read line ; do
      if [ "${line}" == '@<TRIPOS>MOLECULE' ]; then
        let n=$n+1
        echo -ne "" > ${RUNDIR}/${LIGAND_LIST[$n]}/lig.mol2
      fi
      echo -e "${line}" >> ${RUNDIR}/${LIGAND_LIST[$n]}/lig.mol2
    done < ${LIGAND_FILE}
# fi
fi
}

ScoreFlow_postprocess() {
  for LIGAND in ${LIGAND_LIST[@]} ; do
    if [ -f ${RUNDIR}/${LIGAND}/MMPBSA_MINI.dat ] ; then
      awk -v LIGAND=${LIGAND} '/DELTA TOTAL/{print LIGAND,",",$3}' ${RUNDIR}/${LIGAND}/MMPBSA_MINI.dat
    fi
  done
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
 SCORING ${SCORING_FUNCTION}
  CENTER ${DOCK_CENTER[@]}
  
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

ScoreFlow_unset() {
# User variables
unset PROJECT  	   # Name for the current project, ChemFlow folders go after it
unset PROTOCOL     # Name for the current protocol. 

# ChemFlow internals
unset WORKFLOW     # Which ChemFlow protocol to use: ScoreFlow, ScoreFlow ...
##unset METHOD       # Internal of each workflow ( PLANTS, VINA, gbsa...)
##                   # Method will define which software to use.

# User input files ------------------------------------------------------------
unset RECEPTOR     # Filename (no extension) for the receptor file. 
                   # This can be equivalent to MOL_ID. 
                   # ScoreFlow requires a .MOL2.

unset LIGAND_FILE  # Filename .MOL2 for the ligand file. 
                   # An unique .mol2, properly prepared would do the job.

# Docking Variables
unset DOCK_PROGRAM # Program used for docking.
unset DOCK_CENTER  # Binding pocket center (X, Y and Z). 
unset DOCK_LENGHT  # Length of the X, Y and Z axis.
unset DOCK_RADIUS  # Radius from the Docking Center.

# Scoring Variables
unset SCORE_PROGRAM # Program used for docking.

unset RUNDIR       # Folder where the calculations will actually run. 
                   # RUNDIR=$WORKDIR/$PROJECT/$WORKFLOW/$PROTOCOL

unset POSTDOCK     # Either just post-process dockings
}

ScoreFlow_set_defaults() {

 ORGANIZE='yes'

# General options
  WORKDIR=${PWD}
 PROTOCOL="default"
 WORKFLOW="ScoreFlow"
 CHEMFLOW="No"

# Scoring options
   SCORE_PROGRAM="PLANTS"
SCORING_FUNCTION="chemplp"
          CHARGE="gas"
# Run options
JOB_SCHEDULLER="None"
        NCORES=$(nproc --all)
        NNODES="1"
     OVERWRITE="No"    # Don't overwrite stuff. 
}


ScoreFlow_help() {
echo "Example usage: 
# For all Scoring functions except MMGBSA:
ScoreFlow -r receptor.mol2 -l ligand.mol2 -p myproject [-protocol 1] [-n 8] [-sf chemplp] 

# For MMGBSA only 
ScoreFlow -pdb receptor.pdb -l ligand.mol2 -p myproject [-protocol 1] [-n 8] -sf mmgbsa 

[Options]
 -h/--help           : Show this help message and quit
-hh/--full-help      : Detailed help
 -f/--file           : ScoreFlow configuration file
 -r/--receptor       : Receptor's mol2 file.
 -pdb                : Receptor's PDB file  ( Required for MMGBSA )
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
 -pdb                : Receptor's PDB file  ( Required for MMGBSA )
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
  echo -ne "\n[ ERROR ] ScoreFlow called without arguments\n\n"
  ScoreFlow_help
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
    -pdb)
      RECEPTOR_FILE="$2"
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
      DOCK_LENGHT=(${DOCK_LENGHT}) # Transform into array
      shift 3
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
# HPC options ----------------------------------------------------------
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
