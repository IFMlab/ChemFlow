#!/bin/bash

# Color output
RED="\e[0;31m"
BLUE="\e[0;34m"
GREEN="\e[0;32m"
PURPLE="\e[0;35m"
NC="\033[0m"

welcome() {
echo -e "
//=======================================================\\\\\\
||                       ${GREEN}ScoreFlow${NC}                       ||
|| Laboratoire d'Ingenierie des Fonctions Moleculaires   ||
|| Institut de Science et d'Ingenierie Supramoleculaires ||
|| Cedric Bouysset - cedric.bouysset@etu.unistra.fr      ||
|| Diego E.B. Gomes - dgomes@pq.cnpq.br                  ||
\\\\\=======================================================//
"
}

usage() {
echo -e "
###################################### Requirements ##########################################
Mode PDB : performs a rescoring of X-ray structures in PDB format.
The user must have SPORES installed.
Structures must be put in a common \"complex\" folder.
If several complexes are given, please align them before using ScoreFlow.
##############################################################################################
Mode VS : rescores results from Virtual screening with another function.
##############################################################################################
Mode BEST : rescores a selection of docking poses.
${GREEN}/!\\${NC} : run ${GREEN}ChemFlow/Tools/ligfind.bash${NC} before using this mode
##############################################################################################
For ${RED}MMPBSA${NC} calculations, run ${GREEN}ChemFlow/Tools/ligprep.bash${NC} before using.
A new 'rescoring' folder will be created in the output folder.
All paths given must be absolute paths.
"
}

error() {
usage
echo -e "${RED}FATAL ERROR${NC} : ${RED}${1}${NC} is missing"
exit 1
}

list_include_item() {
  local list="$1"
  local item="$2"
  if [[ $list =~ (^|[[:space:]])"$item"($|[[:space:]]) ]] ; then
    # yes, list include item
    result=0
  else
    result=1
  fi
  return $result
}

check_input() {
# Verify user input

# Identify which program to use
if $(list_include_item "chemplp plp plp95" "${scoring_function}"); then
  rescore_method="plants"
elif $(list_include_item "PB3 GB5 GB8" "${scoring_function}"); then
  rescore_method="mmpbsa"
  if [ "${scoring_function}" = "PB3" ]; then radii="parse";   implicit_model="1"; fi
  if [ "${scoring_function}" = "GB5" ]; then radii="mbondi2"; implicit_model="5"; fi
  if [ "${scoring_function}" = "GB8" ]; then radii="mbondi3"; implicit_model="8"; fi
elif [ "${scoring_function}" = "vina" ]; then
  rescore_method="vina"
fi

# exit if fatal error, otherwise, continue
if [ -z "${scoring_function}" ]; then error "the scoring function"; fi

# Depending on the mode chosen, some other parameters might be missing too
# PLANTS
if [ "${rescore_method}" = "plants" ]; then
  if [ -z "${rec}" ] && [ ! "$mode" = "PDB" ]; then 
    error "the location of the receptor MOL2 file";
  else
    filename=$(basename "$rec")
    extension="${filename##*.}"
    if [ ! "${extension}" = "mol2" ]; then echo -e "${RED}ERROR${NC} : your receptor is ${RED}not a MOL2 file${NC}"; exit 1; fi
  fi
  if [ -z "${PLANTS}" ] && [ ! "${run_mode}" = "mazinger" ] ; then error "the location of PLANTS's executable"; fi

# VINA
elif [ "${rescore_method}" = "vina" ]; then
  if [ -z "${rec}" ] && [ ! "$mode" = "PDB" ]; then 
    error "the location of the receptor MOL2 or PDB file";
  else 
    filename=$(basename "$rec")
    extension="${filename##*.}"
    if [ ! "${extension}" = "mol2" ] && [ ! "${extension}" = "pdb" ]; then echo -e "${RED}ERROR${NC} : your receptor is ${RED}not a MOL2 or PDB file${NC}"; exit 1; fi
  fi
  if [ -z "${VINA}" ] && [ ! "${run_mode}" = "mazinger" ] ; then error "the location of VINA's executable"; fi
  if [ -z "${ADT}" ]; then error "the location of AutoDockTools folder"; fi

# MMGBSA
elif [ "${rescore_method}" = "mmpbsa" ]; then
  if [ -z "${rec}" ] && [ ! "$mode" = "PDB" ]; then 
    error "the location of the receptor PDB file";
  else 
    filename=$(basename "$rec")
    extension="${filename##*.}"
    if [ ! "${extension}" = "pdb" ]; then echo -e "${RED}ERROR${NC} : your receptor is ${RED}not a PDB file${NC}"; exit 1; fi
  fi

  if ! $(list_include_item "1F MD" "${PB_method}"); then 
    echo -e "${RED}FATAL ERROR${NC} : ${RED}MMPBSA calculations method${NC} not recognized (1F or MD : ${PB_method})"; exit 1; fi
  if [ "${PB_method}" = "1F" ]; then
    if [ -z "$amber" ]     ;  then error "the path to amber.sh"; fi
    if [ -z "$strip_mask" ];  then error "the amber strip mask to create the dry complex from the solvated system"; fi
    if [ -z "$lig_mask" ]  ;  then error "the amber strip mask to create the ligand from the complex"; fi
    if [ ! -z "$min_steps" ]; then
      if [ -z "$min_energy" ]; then
        error "the restraint applied to your selection for the minimization"
      else
        echo -e "${PURPLE}Rescoring with a $min_steps steps minimization${NC}"
      fi
    else
      echo -e "${PURPLE}Rescoring without minimization${NC}"
    fi

  elif [ "${PB_method}" = "MD" ]; then
    if [ -z "${MD_time}" ];  then error "the length of the production"; fi
    if [ -z "${GB_model}" ]; then error "the GB model used for implicit solvation"; fi
  fi

else
  echo -e "${RED}FATAL ERROR${NC} : ${RED}Scoring function${NC} not recognized"; exit 1
fi

if [ "${mode}" = "PDB" ]; then
  if [ -z "${PDB_folder}" ]    ; then error "the complex's directory"                           ; fi
  if [ -z "${SPORES}" ]        ; then error "the location of SPORES's executable"               ; fi
elif [ "${mode}" = "VS" ]; then
  if [ -z "${VS_folder}" ]     ; then VS_folder="${PWD}/output/VS"                              ; fi
elif [ "${mode}" = "BEST" ]; then
  if [ -z "${BEST_folder}" ]     ; then BEST_folder="${PWD}/output/lig_selection"                 ; fi
else
  echo -e "${RED}ERROR${NC} : ${RED}Rescoring mode${NC} not recognized"; exit 1
fi

## Water
if [ "${rescore_method}" = "plants" ]   && [ ! -z "${water}" ] && [ ! -z "${water_xyzr}" ]; then
  echo -e "${BLUE}Rescoring with water${NC}"
  dock_water="water_molecule ${water_xyzr}\nwater_molecule_definition ${water}"
elif [ "${rescore_method}" = "plants" ] && [ ! -z "${water}" ] && [ -z "${water_xyzr}" ]; then
  echo -e "${RED}ERROR${NC} : ${BLUE}water${NC} parameters incomplete (coordinates missing)"
  exit 1
elif [ "${rescore_method}" = "plants" ] && [ -z "${water}" ] && [ ! -z "${water_xyzr}" ]; then
  echo -e "${RED}ERROR${NC} : ${BLUE}water${NC} parameters incomplete (water molecule missing)"
  exit 1

elif [ "${rescore_method}" = "mmpbsa" ] && [ ! -z "${water}" ]; then
  echo -e "${BLUE}Rescoring with water${NC}"
 
else
  echo -e "${BLUE}Rescoring without water${NC}"
  dock_water=""
fi

echo -e "${GREEN}Successfully read all parameters for ${scoring_function} rescoring${NC}"

## Running mode
# if empty, set local to default
if [ -z "${run_mode}" ]; then run_mode="local"
# if set to parallel
elif [ "${run_mode}" = "parallel" ]
then
  # Check path to parallel
  if [ -z "${parallel}" ]
  then
    echo -e "${RED}ERROR${NC} : Missing path to ${RED}parallel${NC}"
    exit 1
  # Check number of cores
  elif [ -z "${core_number}"  ]
  then
    echo -e "${RED}ERROR${NC} : Missing number of ${RED}cores${NC}"
    exit 1
  fi

# if set to mazinger
elif [ "${run_mode}" = "mazinger" ]
then
  if [ "$rescore_method" == "plants" ]; then
    module load plants/1.2
    PLANTS=$(which plants)
  elif [ "$rescore_method" == "vina" ]; then
    module load vina/1.1.2
    VINA=$(which vina)
  fi

else
  echo -e "${RED}ERROR${NC} : ${RED}Running mode${NC} (${run_mode}) not recognized"
fi

## Check for an already existing rescoring with the same scoring function, and make backup if necessary
if [ -d "$dir/output/${scoring_function}_rescoring" ]; then
  mv $dir/output/${scoring_function}_rescoring $dir/output/${scoring_function}_rescoring.${datetime}.bak
  echo "Made a backup of an already existing ${scoring_function} rescoring"
fi
}

exit_message() {
echo "Thank you for using ScoreFlow !
The ChemFlow team @IFMlab"
}


