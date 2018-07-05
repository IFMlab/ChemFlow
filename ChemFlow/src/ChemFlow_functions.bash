

# Functions --------------------------------------------------------------------
#
ChemFlow_checkfile_ERROR() {
# Checks if file exists. If not, exit with error.
if [ ! -f "${1}" ] ; then
  echo "[ Error ] File: ${1} not found"
  exit 1
fi
}

ChemFlow_error() {
# ${1} is the program

echo "
[ERROR] ${ERROR_MESSAGE}

For help, type: ${1} -h 
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

	LIGAND_LIST=$(awk 'f{print;f=0} /MOLECULE/{f=1}' ${LIGAND_FILE})
	LIGAND_LIST=(${LIGAND_LIST})  # transform a list into an array
	NLIGANDS=${#LIGAND_LIST[@]}

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

PROGRAM=${1}

# Sanity check for input file
# 1 - Check if all variables were set, if not, set them as default

# Mandatory parameters --------------------------------------------------------
if [ -z "${PROJECT}"  ]          ; then ERROR_MESSAGE="No PROJECT name (-p myproject)"				; ChemFlow_error ${PROGRAM} ; fi
if [ -z "${RECEPTOR_FILE}" ]     ; then ERROR_MESSAGE="No RECEPTOR file name (-r receptor_file.mol2)"		; ChemFlow_error ${PROGRAM} ; fi
ChemFlow_checkfile_ERROR ${RECEPTOR_FILE}

if [ -z ${POSTDOCK} ] && [ -z ${ARCHIVE} ] ; then

  if [ -z "${LIGAND_FILE}"   ]     ; then ERROR_MESSAGE="No LIGAND filename (-l ligand_file.mol2)"		; ChemFlow_error ${PROGRAM} ; fi
  ChemFlow_checkfile_ERROR ${LIGAND_FILE}

  
  if [ -z "${SCORING_FUNCTION}" ]  ; then ERROR_MESSAGE="No SCORING_FUNCTION defined (-sf scoring_function)"	; ChemFlow_error ${PROGRAM} ; fi

  if [ -z "${DOCK_CENTER}" ] && [ "${SCORING_FUNCTION}" != "mmgbsa"  ] ; then ERROR_MESSAGE="No DOCKING CENTER defined (--center x y z)"             ; ChemFlow_error ${PROGRAM} ; fi

  #Sanity check for implemented options parameters -----------------------------
	case "${SCORING_FUNCTION}" in 
	"vina"|"chemplp"|"plp"|"plp95"|"mmgbsa") 
	;;
	*) echo "[ ERROR ] SCORING_FUNCTION ${SCORING_FUNCTION} not implemented" ; exit 0 
	esac

	if [ "${SCORING_FUNCTION}" == "vina" ] ; then DOCK_PROGRAM="VINA" ; fi

	if [ "${SCORING_FUNCTION}" == "mmgbsa" ] ; then
		SCORE_PROGRAM="AMBER"
  		DOCK_PROGRAM="AMBER" # FIX THIS <--------------------
                RECEPTOR_NAME="$(basename -s .pdb ${RECEPTOR_FILE})"
		if [ "$(basename ${RECEPTOR_FILE} | cut -d. -f2 )" != "pdb" ] ; then
  			echo "[ ScoreFlow ] mmgbsa rescoring requires a PDB file as input"
		fi 
	fi

	case "${DOCK_PROGRAM}" in
	"VINA"|"PLANTS"|"AMBER")
	;;
	*) echo "[ ERROR ] DOCK/SCORE_PROGRAM ${DOCK_PROGRAM} not implemented" ; exit 0
	esac

	# [ DockFlow ] Verify program locations
	if [ "${DOCK_PROGRAM}" == "PLANTS" ] && [ "$(command -v PLANTS1.2_64bit)" == "" ] ; then
	  echo "[ERROR ] PLANTS is not installed or on PATH" ; exit 0
	fi

	if [ "${DOCK_PROGRAM}" == "VINA" ] && [ "$(command -v vina)" == "" ] ; then
	  echo "[ERROR ] Autodock Vina is not installed or on PATH" ; exit 0
	fi

	# [ ScoreFlow ] Verify program locations
	if [ "${SCORE_PROGRAM}" == "PLANTS" ] && [ "$(command -v PLANTS1.2_64bit)" == "" ] ; then
	  echo "[ERROR ] PLANTS is not installed or on PATH" ; exit 0
	fi

	if [ "${SCORE_PROGRAM}" == "VINA" ] && [ "$(command -v vina)" == "" ] ; then
	  echo "[ERROR ] Autodock Vina is not installed or on PATH" ; exit 0
	fi

	if [ "${SCORE_PROGRAM}" == "AMBER" ] && [ "$(command -v sander)" == "" ] ; then
	  echo "[ERROR ] AmberTools is not installed or on PATH" ; exit 0
	fi

	# HPC adjustments
	case ${JOB_SCHEDULLER} in
	"None"|"PBS"|"SLURM") ;;
	*) ERROR_MESSAGE="Invalid JOB_SCHEDULLER" 
	   ChemFlow_error ${PROGRAM}
	   ;;
	esac

	# Safety check
	if [ "${OVERWRITE}" == "yes" ] ; then
	  read -p "
	  Are you sure you want to OVERWRITE your dockings? : " opt
	  
	  case ${opt} in 
		"Y"|"YES"|"Yes"|"yes"|"y")  ;;
		*)  echo "Safe decison. Rerun without '--overwrite'" ; exit 0 ;;
	  esac
	fi
	ChemFlow_set_ligand_list ${LIGAND_FILE}
fi
}
