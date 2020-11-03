#!/usr/bin/env bash


ChemFlow_echo_software_header() {
echo "
########################################################################
#        ChemFlow  -   Computational Chemistry is great again          #
########################################################################
#                                                                      #
#      +++++++++++++++++++                  ::  ++++  +   +            #
#      + Université ||| |+                  ++  +     ++ ++            #
#      +++++++++++++++++++++++              ++  +++   + + +            #
#          + ||de Strasbourg +              ++  +     +   +            #
#          +++++++++++++++++++              ++  +     +   + LAB        #
#                                                                      #
#         Laboratoire d'Ingenierie des Fonctions Moleculaires          #
#                                                                      #
# Marco Cecchini - cecchini@unistra.fr                                 #
# Diego E. B. Gomes - dgomes@pq.cnpq.br                                #
#======================================================================#"
}

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
    LIGAND_LIST=($(sed -n '/Mrv/{g;1!p;};h' ${LIGAND_FILE}))
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

if [ -z "${RECEPTOR_FILE}" ] && [ ${WORKFLOW} != "LigFlow" ] ; then
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
    ERROR_MESSAGE="The ligand file ${LIGAND_FILE} does not exist." ;
    ChemFlow_error ;
fi

# Set the docking program or score program-------------------------------------
case "${WORKFLOW}" in
"DockFlow")
    case "${SCORING_FUNCTION}" in
    "chemplp"|"plp"|"plp95") # PLANTS is the default DOCK_PROGRAM
        # check if docking with water
        check_water
	# Center is required for docking.
    check_center
    ;;
    "vina")
        DOCK_PROGRAM="VINA" ;
       # Center is required for docking.
    check_center	
    "vina")
        DOCK_PROGRAM="QVINA" ;
       # Center is required for docking.
    check_center
    ;;
    "vina"|"vinardo"|"dkoes_fast"|"dkoes_scoring")
        DOCK_PROGRAM="SMINA" ;
	#check if you put the config input file
        check_config
    ;;
    *)
        ERROR_MESSAGE="SCORING_FUNCTION ${SCORING_FUNCTION} not implemented"; ChemFlow_error;
    ;;
    esac
    if [ "$(basename ${RECEPTOR_FILE} | cut -d. -f2 )" != "mol2" ] ; then
        ERROR_MESSAGE="Docking requires a mol2 file as receptor input"; ChemFlow_error;
    fi
    # Center is required for docking.
    #check_center
;;
"ScoreFlow")
    case "${SCORING_FUNCTION}" in
        "chemplp"|"plp"|"plp95") # PLANTS is the default SCORE_PROGRAM
            if [ "$(basename ${RECEPTOR_FILE} | cut -d. -f2 )" != "mol2" ] ; then
                ERROR_MESSAGE="Plants rescoring requires a mol2 file as receptor input"; ChemFlow_error ;
            fi
            check_center
        ;;
        "vina")
            SCORE_PROGRAM="VINA" ;
            if [ "$(basename ${RECEPTOR_FILE} | cut -d. -f2 )" != "mol2" ] ; then
                ERROR_MESSAGE="Vina rescoring requires a mol2 file as receptor input"; ChemFlow_error ;
            fi
            if [ "${VINA_MODE}" != "local_only" ] && [ "${VINA_MODE}" != "score_only" ] ; then
                ERROR_MESSAGE="Vina rescoring mode ${VINA_MODE} does not exist"; ChemFlow_error ;
            fi
            check_center
        ;;
        "mmgbsa"|"mmpbsa") # mmgbsa as scoring function is only allowed for ScoreFlow.
            SCORE_PROGRAM="AMBER"
            RECEPTOR_NAME="$(basename ${RECEPTOR_FILE} .pdb)"
            if [ "$(basename ${RECEPTOR_FILE} | cut -d. -f2 )" != "pdb" ] ; then
                ERROR_MESSAGE="MM(PB,GB)SA rescoring requires a PDB file as receptor input"; ChemFlow_error ;
            fi
        ;;
        *)
            ERROR_MESSAGE="SCORING_FUNCTION ${SCORING_FUNCTION} not implemented"; ChemFlow_error ;
        ;;
    esac

;;
esac

# If we are using the major program (no postprocessing or archiving) ------------
if [ -z "${POSTPROCESS}" ] && [ -z "${ARCHIVE}" ] ; then

    # HPC adjustments
    case "${JOB_SCHEDULLER}" in
    "None") ;;
    "PBS"|"SLURM")
#        if [ -z ${NC_CHANGED} ] ; then
#            NCORES=16
#        fi
       echo "Using ${JOB_SCHEDULLER}"
    ;;
    *) ERROR_MESSAGE="Invalid JOB_SCHEDULLER" ; ChemFlow_error ;
       ;;
    esac


    # AmberTools must be installed because we use AnteChamber everywhere
    if  [ -z "$(command -v antechamber)" ] ; then
        ERROR_MESSAGE="AmberTools 17+ is not installed or on PATH" ; ChemFlow_error ;
    fi


    # Check program locations ---------------------------------------------------
    case "${DOCK_PROGRAM}" in
    "PLANTS")
        if [ -z "$(command -v PLANTS1.2_64bit)" ] ; then
            ERROR_MESSAGE="PLANTS is not installed or on PATH" ; ChemFlow_error ;
        fi
    ;;
    "QVINA")
        if  [ -z "$(command -v qvina02)" ] ; then
            ERROR_MESSAGE="QVina is not installed or on PATH" ; ChemFlow_error ;
        fi
    ;;
    "SMINA")
        if  [ -z "$(command -v smina.static)" ] ; then
            ERROR_MESSAGE="smina is not installed or on PATH" ; ChemFlow_error ;
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
            if [ "${CUDA_PRECISION}" == "DOUBLE" ] ; then
                AMBER_EXEC="pmemd.cuda_DPFP"
            fi

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
      echo -n "[ Note ] Are you sure you want to overwrite? [y/n] "
      read opt

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


#check_config(){
#if [ "${DOCK_PROGRAM}" == "SMINA" ] ; then
  #if [ -z "${config}" ]; then
       #ERROR_MESSAGE="No configuration file defined (--config config.txt)" ; ChemFlow_error 
  #fi
#fi
#}

check_water(){
if [ "${DOCK_PROGRAM}" == "PLANTS" ]; then
  if [ -s "${WATER_FILE}" ] && [ ! -z "${WATER_XYZR[@]}" ]; then
    PLANTS_WATER="yes"
  fi
fi
}

relpath(){
  # returns path relative to the specified directory
  # $1 path
  # $2 directory
  perl -e 'use File::Spec; print File::Spec->abs2rel(@ARGV) . "\n"' "$1" "$2"
}

abspath(){
  # returns the canonical absolute version of a path
  # $1 path
  perl -MCwd -e 'print Cwd::realpath($ARGV[0]),qq<\n>' "$1"
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

    # Vina advanced options
    VINA_MODE="local_only"

    # no MD
    MD="no"
    WATER="no"
    MAXCYC="1000"

    # run option
    WRITE_ONLY="no"
    RUN_ONLY="no"
elif [ $1 == 'LigFlow' ] ; then
    WORKFLOW="LigFlow"

    CHARGE="gas"
    BCC="no"
    RESP="no"
fi
}


ChemFlow_set_defaults_vina(){
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
SCORING_FUNCTION="vina"

# Run options
JOB_SCHEDULLER="None"
NCORES=$(getconf _NPROCESSORS_ONLN)
OVERWRITE="no"    # Don't overwrite stuff.
HEADER_PROVIDED="no"

if [ $1 == 'DockFlow' ] ; then
    WORKFLOW="DockFlow"

    # Docking options
    DOCK_PROGRAM="VINA"|"QVINA"|"SMINA"
    DOCK_LENGTH=("15" "15" "15")
    DOCK_POSES="10"
   # Vina advanced options
    EXHAUSTIVENESS="8"
    ENERGY_RANGE="3.00"

    # Run options
    RESUME="No"
elif [ $1 == 'ScoreFlow' ] ; then
    WORKFLOW="ScoreFlow"

    # Scoring options
    SCORE_PROGRAM="VINA"
    DOCK_LENGTH=("15" "15" "15")
    CHARGE="gas"

    # Vina advanced options
    VINA_MODE="local_only"

    # no MD
    MD="no"
    WATER="no"
    MAXCYC="1000"

    # run option
    WRITE_ONLY="no"
    RUN_ONLY="no"
elif [ $1 == 'LigFlow' ] ; then
    WORKFLOW="LigFlow"

    CHARGE="gas"
    BCC="no"
    RESP="no"
fi
}

