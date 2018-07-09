#!/usr/bin/env bash


source ${CHEMFLOW_HOME}/test/test_function.sh


ChemFlow_error() {
echo "
[ ERROR ] ${ERROR_MESSAGE}

For help, type: ${WORKFLOW} -h
"
exit 0
}


ChemFlow_set_ligand_list() {
#===  FUNCTION  ================================================================
#          NAME: ChemFlow_set_ligand_list
#   DESCRIPTION: Get all molecule names in the .mol2 file and save into an array
#
#    PARAMETERS: Ligand_list
#       RETURNS: -
#
#===============================================================================
#    LIGAND_FILE=${1}
if [ ! -s ${LIGAND_FILE} ] ; then
    ERROR_MESSAGE="The ligand file ${LIGAND_FILE} is empty"
    ChemFlow_error
else
    LIGAND_LIST=$(awk 'f{print;f=0} /MOLECULE/{f=1}' ${LIGAND_FILE})
    LIGAND_LIST=(${LIGAND_LIST})  # transform a list into an array
    NLIGANDS=${#LIGAND_LIST[@]}
fi
}


ChemFlow_validate_input() {
#===  FUNCTION  ================================================================
#          NAME: ScoreFlow_validate_input
#   DESCRIPTION: Validates the command line options and parameter combination.
#
#    PARAMETERS: Program name as $1, all others come as global variables.
#       RETURNS: -
#
#===============================================================================

echo "[ ChemFlow ] Checking input files..."

# Sanity check for input file

# Mandatory parameters for all programs

# Check if the project name has been given-------------------------------------
if [ -z "${PROJECT}" ] ; then
    ERROR_MESSAGE="No PROJECT name (-p myproject)" ;
    ChemFlow_error ;
fi
# Check if the receptor file has been given------------------------------------

if [ -z "${RECEPTOR_FILE}" ] ; then
    ERROR_MESSAGE="No RECEPTOR file name (-r receptor_file.mol2)" ;
    ChemFlow_error ;
fi
# Check if the receptor file exists--------------------------------------------
if [ ! -f ${RECEPTOR_FILE} ] ; then
    ERROR_MESSAGE=="The receptor file ${RECEPTOR_FILE} does not exist." ;
    ChemFlow_error ;
fi

# Check if the receptor file has been given----------------------------------
if [ -z "${LIGAND_FILE}" ] ; then
    ERROR_MESSAGE="No LIGAND filename (-l ligand_file.mol2)" ;
    ChemFlow_error ;
fi

# Check if the receptor file exists------------------------------------------
if [ ! -f ${LIGAND_FILE} ] ; then
    ERROR_MESSAGE=="The ligand file ${RECEPTOR_FILE} does not exist." ;
    ChemFlow_error ;
fi

# Set the docking program or score program-------------------------------------
case ${WORKFLOW} in
"DockFlow")
    case ${SCORING_FUNCTION} in
    "chemplp"|"plp"|"plp95") # PLANTS is the default DOCK_PROGRAM
    ;;
    "vina")
        DOCK_PROGRAM="VINA" ;
    ;;
    *)
        ERROR_MESSAGE="SCORING_FUNCTION ${SCORING_FUNCTION} not implemented"; ChemFlow_error;
    ;;
    esac

    # Center is required for docking.
    check_center
;;
"ScoreFlow")
    case ${SCORING_FUNCTION} in
    "chemplp"|"plp"|"plp95") # PLANTS is the default SCORE_PROGRAM
    ;;
    "vina")
        SCORE_PROGRAM="VINA" ;
    ;;
    "mmgbsa") # mmgbsa as scoring function is only allowed for ScoreFlow.
        SCORE_PROGRAM="AMBER"
        RECEPTOR_NAME="$(basename -s .pdb ${RECEPTOR_FILE})"
        if [ "$(basename ${RECEPTOR_FILE} | cut -d. -f2 )" != "pdb" ] ; then
            ERROR_MESSAGE="mmgbsa rescoring requires a PDB file as input"; ChemFlow_error ;
        fi
    ;;
    *)
        ERROR_MESSAGE="SCORING_FUNCTION ${SCORING_FUNCTION} not implemented"; ChemFlow_error ;
    ;;
    esac

    # Center is not required for mmgbsa rescoring.
    if [ "${SCORING_FUNCTION}" != "mmgbsa"  ] ; then
        check_center
    fi
;;
esac

# If we are using the major program (no postprocessing or archiving) ------------
if [ -z ${POSTDOCK} ] && [ -z ${ARCHIVE} ]  && [ -z ${POSTPROCESS} ] ; then

    # HPC adjustments
    case ${JOB_SCHEDULLER} in
    "None"|"PBS"|"SLURM") ;;
    *) ERROR_MESSAGE="Invalid JOB_SCHEDULLER" ;
       ChemFlow_error ;
       ;;
    esac

    # Check program locations ---------------------------------------------------
    case "${SCORE_PROGRAM}" in
    "PLANTS")
        if [ "$(command -v PLANTS1.2_64bit)" == "" ] ; then
            echo "[ERROR ] PLANTS is not installed or on PATH" ; exit 0
        fi
    ;;
    "VINA")
        if  [ "$(command -v vina)" == "" ] ; then
            echo "[ERROR ] Autodock Vina is not installed or on PATH" ; exit 0
        fi
        if [ "$(command -v ${mgltools_folder}/MGLToolsPckgs/AutoDockTools/Utilities24/prepare_ligand4.py)" == "" ] ; then
          echo "[ERROR ] MglTools is not installed or on PATH" ; exit 0
        fi
    ;;
    "AMBER")
        if  [ "$(command -v sander)" == "" ] ; then
          echo "[ERROR ] AmberTools is not installed or on PATH" ; exit 0
        fi
    ;;
    esac

    # Check overwriting ---------------------------------------------------------
    if [ "${OVERWRITE}" == "yes" ] ; then
      read -p "[ Note ] Are you sure you want to OVERWRITE : " opt

      case ${opt} in
        "Y"|"YES"|"Yes"|"yes"|"y")  ;;
        *)  echo "Safe decison. Rerun without '--overwrite'" ; exit 0 ;;
      esac
    fi
fi

ChemFlow_set_ligand_list ${LIGAND_FILE}
}

check_center(){
if [ -z "${DOCK_CENTER}" ] ; then
    ERROR_MESSAGE="No DOCKING CENTER defined (--center x y z)" ;
    ChemFlow_error ;
fi
}

ChemFlow_set_defaults(){

# General options
WORKDIR=${PWD}
PROTOCOL="default"
SCORING_FUNCTION="chemplp"

# Run options
JOB_SCHEDULLER="None"
NCORES=$(getconf _NPROCESSORS_ONLN)
NNODES="1"
OVERWRITE="No"    # Don't overwrite stuff.

if [ $1 == 'DockFlow' ] ; then
    WORKFLOW="DockFlow"

    # Docking options
    DOCK_PROGRAM="PLANTS"
    DOCK_LENGHT="15 15 15"
    DOCK_RADIUS="15"
    DOCK_POSES="10"

    # Run options
    RESUME="No"
elif [ $1 == 'ScoreFlow' ] ; then
    WORKFLOW="ScoreFlow"
    ORGANIZE='yes'

    # Scoring options
    SCORE_PROGRAM="PLANTS"
    CHARGE="gas"
fi

}