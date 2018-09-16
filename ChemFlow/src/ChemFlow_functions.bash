#!/usr/bin/env bash


ChemFlow_error() {
#===  FUNCTION  ================================================================
#          NAME: ChemFlow_error
#   DESCRIPTION: A function to standardize ChemFlow error message
#
#    PARAMETERS: ${ERROR_MESSAGE}
#                ${WORKFLOW} (global)
#       RETURNS: -
#
#        Author: Dona de Francquen
#===============================================================================
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
#    PARAMETERS: ${LIGAND_FILE}
#       RETURNS: LIGAND_LIST
#                NLIGANDS
#
#        Author: Dona de Francquen
#===============================================================================
if [ ! -s ${LIGAND_FILE} ] ; then
    ERROR_MESSAGE="The ligand file ${LIGAND_FILE} is empty" ; ChemFlow_error
else
    LIGAND_LIST=$(awk 'f{print;f=0} /MOLECULE/{f=1}' ${LIGAND_FILE})
    LIGAND_LIST=(${LIGAND_LIST})  # transform a list into an array
    NLIGANDS=${#LIGAND_LIST[@]}
fi
}


ChemFlow_validate_input() {
#===  FUNCTION  ================================================================
#          NAME: ChemFlow_validate_input
#   DESCRIPTION: Validates the command line options and parameter combination.
#
#    PARAMETERS: Every global variables.
#       RETURNS: -
#
#        Author: Dona de Francquen
#===============================================================================
echo "[ ChemFlow ] Checking input files..."

# Mandatory parameters for all programs
# Check if the project name has been given-------------------------------------
if [ -z "${PROJECT}" ] ; then
    ERROR_MESSAGE="No PROJECT name (-p myproject)" ;
    ChemFlow_error ;
fi
# Check if the receptor file has been given------------------------------------

if [ -z "${RECEPTOR_FILE}" ] ; then
    if [ "${SCORING_FUNCTION}" != "mmgbsa" ] ; then
        ERROR_MESSAGE="No RECEPTOR file name (-r receptor_file.mol2)" ;
        ChemFlow_error ;
    else
        ERROR_MESSAGE="No RECEPTOR file name (-r receptor_file.pdb)" ;
        ChemFlow_error ;
    fi
fi
# Check if the receptor file exists--------------------------------------------
if [ ! -f "${RECEPTOR_FILE}" ]  && [ "${WORKFLOW}" != "LigFlow" ] ; then
    ERROR_MESSAGE="The receptor file ${RECEPTOR_FILE} does not exist." ;
    ChemFlow_error ;
fi

# Check if the ligand file has been given----------------------------------
if [ -z "${LIGAND_FILE}" ] ; then
    ERROR_MESSAGE="No LIGAND filename (-l ligand_file.mol2)" ;
    ChemFlow_error ;
fi

# Check if the ligand file exists------------------------------------------
if [ ! -f "${LIGAND_FILE}" ] ; then
    ERROR_MESSAGE=="The ligand file ${LIGAND_FILE} does not exist." ;
    ChemFlow_error ;
fi

# Set the docking program or score program-------------------------------------
case "${WORKFLOW}" in
"DockFlow")
    case "${SCORING_FUNCTION}" in
    "chemplp"|"plp"|"plp95") # PLANTS is the default DOCK_PROGRAM
        # check if docking with water
        check_water
    ;;
    "vina")
        DOCK_PROGRAM="VINA" ;
    ;;
    *)
        ERROR_MESSAGE="SCORING_FUNCTION ${SCORING_FUNCTION} not implemented"; ChemFlow_error;
    ;;
    esac
    if [ "$(basename ${RECEPTOR_FILE} | cut -d. -f2 )" != "mol2" ] ; then
        ERROR_MESSAGE="Docking requires a mol2 file as receptor input"; ChemFlow_error;
    fi
    # Center is required for docking.
    check_center
;;
"ScoreFlow")
    case "${SCORING_FUNCTION}" in
    "chemplp"|"plp"|"plp95") # PLANTS is the default SCORE_PROGRAM
    if [ "$(basename ${RECEPTOR_FILE} | cut -d. -f2 )" != "mol2" ] ; then
        ERROR_MESSAGE="Plants rescoring requires a mol2 file as receptor input"; ChemFlow_error ;
    fi
    ;;
    "vina")
        SCORE_PROGRAM="VINA" ;
    if [ "$(basename ${RECEPTOR_FILE} | cut -d. -f2 )" != "mol2" ] ; then
        ERROR_MESSAGE="Vina rescoring requires a mol2 file as receptor input"; ChemFlow_error ;
    fi
    ;;
    "mmgbsa") # mmgbsa as scoring function is only allowed for ScoreFlow.
        SCORE_PROGRAM="AMBER"
        RECEPTOR_NAME="$(basename ${RECEPTOR_FILE} .pdb)"
        if [ "$(basename ${RECEPTOR_FILE} | cut -d. -f2 )" != "pdb" ] ; then
            ERROR_MESSAGE="mmgbsa rescoring requires a PDB file as receptor input"; ChemFlow_error ;
        fi
    ;;
    *)
        ERROR_MESSAGE="SCORING_FUNCTION ${SCORING_FUNCTION} not implemented"; ChemFlow_error ;
    ;;
    esac


    if [ "${SCORING_FUNCTION}" != "mmgbsa"  ] ; then
        # Center is not required for mmgbsa rescoring.
        check_center
    fi
;;
esac

# If we are using the major program (no postprocessing or archiving) ------------
if [ -z "${POSTPROCESS}" ] && [ -z "${ARCHIVE}" ] ; then

    # HPC adjustments
    case "${JOB_SCHEDULLER}" in
    "None"|"PBS"|"SLURM") ;;
    *) ERROR_MESSAGE="Invalid JOB_SCHEDULLER" ; ChemFlow_error ;
       ;;
    esac

    # Check program locations ---------------------------------------------------
    case "${DOCK_PROGRAM}" in
    "PLANTS")
        if [ -z "$(command -v PLANTS1.2_64bit)" ] ; then
            ERROR_MESSAGE="PLANTS is not installed or on PATH" ; ChemFlow_error ;
        fi
    ;;
    "VINA")
        if  [ -z "$(command -v vina)" ] ; then
            ERROR_MESSAGE="Autodock Vina is not installed or on PATH" ; ChemFlow_error ;
        fi
        if [ -z "$(command -v ${mgltools_folder}/MGLToolsPckgs/AutoDockTools/Utilities24/prepare_ligand4.py)" ] ; then
            ERROR_MESSAGE="MglTools is not installed or on PATH" ; ChemFlow_error ;
        fi
    ;;
    esac

    case "${SCORE_PROGRAM}" in
    "PLANTS")
        if [ -z "$(command -v PLANTS1.2_64bit)" ] ; then
            ERROR_MESSAGE="PLANTS is not installed or on PATH" ; ChemFlow_error ;
        fi
    ;;
    "VINA")
        if  [ -z "$(command -v vina)" ] ; then
            ERROR_MESSAGE="Autodock Vina is not installed or on PATH" ; ChemFlow_error ;
        fi
        if [ -z "$(command -v ${mgltools_folder}/MGLToolsPckgs/AutoDockTools/Utilities24/prepare_ligand4.py)" ] ; then
            ERROR_MESSAGE="MglTools is not installed or on PATH" ; ChemFlow_error ;
        fi
    ;;
    "AMBER")
        if  [ -z "$(command -v sander)" ] ; then
            ERROR_MESSAGE="AmberTools 17+ is not installed or on PATH" ; ChemFlow_error ;
        fi
        if [ "${CHARGE}" == "resp" ] && [ -z "$(command -v g09)" ] ; then
            ERROR_MESSAGE="Gaussian is not installed or on PATH" ; ChemFlow_error ;
        fi

        if  [ -z "$(command -v pmemd.cuda)" ] ; then
            if  [ -z "$(command -v pmemd)" ] ; then
                echo "[ ERROR ] Amber (pmemd) is not installed or on PATH, changing to SANDER."
                AMBER_EXEC="mpirun -n ${NCORES} sander.MPI"
                if  [ -z "$(command -v sander.MPI)" ] ; then
                    AMBER_EXEC="sander"
                fi
            else
                AMBER_EXEC="mpirun -n ${NCORES} pmemd.MPI"
                if  [ -z "$(command -v pmemd.MPI)" ] ; then
                    AMBER_EXEC="pmemd"
                fi
            fi
        else
            AMBER_EXEC="pmemd.cuda"
        fi
     ;;
    esac

    if [ "${HEADER_PROVIDED}" != 'no' ] ; then
        if [ ! -f ${HEADER_FILE} ] ; then
            ERROR_MESSAGE="Header file ${HEADER_FILE} does not exist." ; ChemFlow_error ;
        fi
    fi

    # Check overwriting ---------------------------------------------------------
    if [ "${OVERWRITE}" == "yes" ] ; then
      read -p "[ Note ] Are you sure you want to OVERWRITE [y/n]? " opt

      case "${opt}" in
        "Y"|"YES"|"Yes"|"yes"|"y")  ;;
        *)  echo "Safe decision. Rerun without '--overwrite'" ; exit 0 ;;
      esac
    fi
fi

# Create the ligand list
ChemFlow_set_ligand_list ${LIGAND_FILE}
}

check_center(){
if [ -z "${POSTPROCESS}" ] && [ -z "${ARCHIVE}" ]; then
    if [ -z "${DOCK_CENTER}" ] ; then
        ERROR_MESSAGE="No DOCKING CENTER defined (--center x y z)" ; ChemFlow_error ;
    fi
fi
}

check_water(){
if [ "${DOCK_PROGRAM}" == "PLANTS" ]; then
  if [ -s "${WATER_FILE}" ] && [ ! -z "${WATER_XYZR}" ]; then
    PLANTS_WATER="yes"
  fi
fi
}

ChemFlow_set_defaults(){
#===  FUNCTION  ================================================================
#          NAME: ChemFlow_set_defaults
#   DESCRIPTION: Set a default for parameters.
#
#    PARAMETERS: -
#       RETURNS: -
#
#        Author: Dona de Francquen
#===============================================================================
# General options
WORKDIR="${PWD}"
PROTOCOL="default"
SCORING_FUNCTION="chemplp"

# Run options
JOB_SCHEDULLER="None"
NCORES=$(getconf _NPROCESSORS_ONLN)
OVERWRITE="no"    # Don't overwrite stuff.
HEADER_PROVIDED="no"

if [ $1 == 'DockFlow' ] ; then
    WORKFLOW="DockFlow"

    # Docking options
    DOCK_PROGRAM="PLANTS"
    DOCK_LENGTH=("15" "15" "15")
    DOCK_RADIUS="15"
    DOCK_POSES="10"

    # PLANTS advanced options
    SPEED="1"
    ANTS="20"
    EVAP_RATE="0.15"
    ITERATION_SCALING="1.0"
    CLUSTER_RMSD="2.0"

    # Vina advanced options
    EXHAUSTIVENESS="8"
    ENERGY_RANGE="3.00"

    # Run options
    RESUME="No"
elif [ $1 == 'ScoreFlow' ] ; then
    WORKFLOW="ScoreFlow"

    # Scoring options
    SCORE_PROGRAM="PLANTS"
    DOCK_LENGTH=("15" "15" "15")
    DOCK_RADIUS="15"
    CHARGE="gas"

    # no MD
    MD="no"
    WATER="no"
    MAXCYC="1000"

    # run option
    WRITE_ONLY="no"
    RUN_ONLY="no"
fi
}
