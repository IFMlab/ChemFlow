#!/bin/bash

# Color output
RED="\e[0;31m"
BLUE="\e[0;34m"
GREEN="\e[0;32m"
PURPLE="\e[0;35m"
NC="\033[0m"

welcome() {
echo -e "\
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
echo -e "\
Usage : ScoreFlow
                  -h/--help           : Show this help message and quit
                  -hh/--fullhelp      : Show a more detailed help
                  -c/--config         : Path to ScoreFlow configuration file
                  -m/--mode           : ALL, BEST, PDB
                  -f/--folder         : Path to a custom \"docking\" or \"input_files/lig\" folder
                  -sf/--function      : chemplp, plp, plp95, vina, PB3, GB5, GB8
                  --run               : local, parallel, mazinger
_________________________________________________________________________________
For ALL and BEST modes :
                  -r/--receptor       : Path to the receptor's file
_________________________________________________________________________________
For MM-PB/GB-SA :
                  -b/--base           : Base calculations on 1 frame (1F) or 
                                        on a quick implicit solvent (GB) MD simulation
                  -sm/--stripmask     : Amber mask of atoms needed to be stripped from the 
                                        solvated complex to make the dry complex topology file
                  -lm/--ligmask       : Amber mask of atoms needed to be stripped 
                                        from COMPLEX to create LIGAND
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
For calculations on 1 frame :
                  -ms/--minsteps      : Number of steps for minimization 
                                        Use \"\" for no minimization
                  -mr/--restraint     : Restraint applied to your selection, in kcal/mol/A2
                  -mt/--mintype       : apply a simple backbone restriction, 
                                        or use a custom mask : backbone, custom
                  -mm/--minmask       : If backbone, for resid x to y, write x-y.
                                        If custom, use NAB atom expression
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
For calculations on implicit solvent MD :
                  -t/--time           : Length of the production, in ps
                  -im/--model         : Implicit GB model used for solvation (1,5,8)
_________________________________________________________________________________
For parallel :
                  -cn/--corenumber    : Number of cores for parallel
_________________________________________________________________________________
Optionnal :
                  -w/--water          : Path to the structural water molecule
                  -wxyzr/--water_xyzr : xyz coordinates and radius of the water
                                        sphere, separated by a space"
}

requirements() {
echo -e "\
###################################### Requirements ##########################################
Mode PDB : performs a rescoring of X-ray structures in PDB format.
The user must have SPORES installed.
Structures must be put in a common \"complex\" folder.
If several complexes are given, please align them before using ScoreFlow.
##############################################################################################
Mode ALL : rescores all results from docking with another scoring function.
##############################################################################################
Mode BEST : rescores a selection of docking poses.
${RED}/!\ ${NC}: run ${PURPLE}LigFlow --amber${NC} before using this mode
##############################################################################################
All paths given must be absolute paths.
ScoreFlow will try to read a ScoreFlow.config file in the current directory.
If such file doesn't exist, please run ConfigFlow to guide you,
or copy $CHEMFLOW_HOME/config_files/ScoreFlow.config here.
If you already have an existing config file and wish to rerun DockFlow
only modifying some options, see the help below.
"
}

# User Command Line Interface, reading flags to assign variables
SF_CLI() {
while [[ $# -gt 0 ]]; do
key="$1"

case $key in
    -h|--help)
    usage
    exit
    shift # past argument
    ;;
    -hh|--fullhelp)
    requirements
    usage
    exit
    shift
    ;;
    -c|--config)
    CONFIG_FILE="$2"
    shift # past argument
    ;;
    -r|--receptor)
    rec="$2"
    shift # past argument
    ;;
    -f|--folder)
    folder="$2"
    shift
    ;;
    -m|--mode)
    mode="$2"
    shift # past argument
    ;;
    -sf|--function)
    scoring_function="$2"
    shift # past argument
    ;;
    -b|--base)
    pb_method="$2"
    shift # past argument
    ;;
    -sm|--stripmask)
    strip_mask="$2"
    shift # past argument
    ;;
    -lm|--ligmask)
    lig_mask="$2"
    shift
    ;;
    -ms|--minsteps)
    min_steps="$2"
    shift
    ;;
    -mr|--restraint)
    min_energy="$2"
    shift
    ;;
    -mt|--mintype)
    min_type="$2"
    shift
    ;;
    -mm|--minmask)
    min_mask="$2"
    shift
    ;;
    -t|--time)
    md_time="$2"
    shift
    ;;
    -im/--model)
    gb_model="$2"
    shift
    ;;
    -w|--water)
    water="$2"
    shift # past argument
    ;;
    -wxyzr|--water_xyzr)
    water_xyzr="$2 $3 $4 $5"
    shift 4 # past argument
    ;;
    --run)
    run_mode="$2"
    shift # past argument
    ;;
    -cn|--corenumber)
    core_number="$2"
    shift # past argument
    ;;
    *)
    unknown="$1" # unknown option
    echo "Unknown flag \"$unknown\""
    ;;
esac
shift # past argument or value
done
}

# write config file for DockFLow from CLI
write_SF_config() {

# Overwrite. This only works because we used the same variable names in the interface and the config file.
source temp.config

echo "# Config file generated from CLI
# Type of rescoring : 
  # Virtual Screening results from DockFlow : ALL
  # A selection of ligands from DockFlow's VS results : BEST
  # Crystal structure from a PDB file : PDB
mode=\"$mode\"

# Scoring function : chemplp, plp, plp95, vina, PB3, GB5, GB8
scoring_function=\"$scoring_function\"

#######################################################################################################################
# Additional input
#######################################################################################################################

# If the PDB mode is chosen, absolute path to the complexes folder
pdb_folder=\"${pdb_folder}\"

# If the ALL or BEST modes are chosen :
# Path to the receptor : PDB file for MMPBSA and MMGBSA, MOL2 file for chemplp, plp, and plp95, PDB or MOL2 for vina
rec=\"$rec\"

# By default, ScoreFlow will assume that you are running from the same folder that contains your lig, rec and docking results directories.
# This way, depending on the mode you chose (ALL or BEST ), it will automatically find the location of your mol2 files. 
# If necessary, you can overwrite the path to a custom \"docking\" or \"input_files/lig\" folder here.
folder=\"$folder\"

# If mmpbsa or mmgbsa scoring function is chosen :
# base calculations on 1 frame (1F) or on a quick implicit solvent (GB) MD simulation : 1F, MD
pb_method=\"${pb_method}\"
# Amber mask of atoms needed to be stripped from the solvated complex to make the dry complex topology file
strip_mask=\"$strip_mask\"
# Amber mask of atoms needed to be stripped from COMPLEX to create LIGAND
lig_mask=\"$lig_mask\"
# Minimization or simulation length :
# If the 1 frame approach was chosen :
  # Number of minimization steps prior to MMPBSA/MMGBSA calculations. Leave empty for no minimization
  min_steps=\"$min_steps\"
  # Restraint applied to your selection, in kcal/mol/A2
  min_energy=\"$min_energy\"
    # If a minimization is made, apply a simple backbone restriction, or use a custom mask : backbone, custom
    min_type=\"$min_type\"
      # If backbone, for resid x to y of all chains of the receptor, write x-y.
      # If custom, specify residues or atoms to be tethered in their motion using NAB atom expression (see amber manual).
      min_mask=\"$min_mask\"
# If the quick MD simulation approach was chosen :
  # Length of the production, in ps
  md_time=\"$md_time\"
  # GB model used for implicit solvation : 1,5,8
  gb_model=\"$gb_model\"

#######################################################################################################################
# Optionnal input
#######################################################################################################################

# Add a structural water molecule, centered on an xyz sphere and moving in a radius
# Absolute path to water molecule
water=\"$water\"
# For Chemplp, plp and plp95 : xyz coordinates and radius of the sphere, separated by a space
water_xyzr=\"$water_xyzr\"

# For chemplp, plp, and plp95 :
# User defined parameters, for PLANTS
plants_user_parameters=\"$plants_user_parameters\"

# Run on this machine (default), in parallel, or on mazinger (only available for MMPBSA)
# local, parallel, mazinger
run_mode=\"$run_mode\"
  # If parallel is chosen, please specify the number of cores available
  core_number=\"$core_number\"
  # If mazinger is chosen, please specify the maximum number of jobs to submit
  # If you leave this variable empty, ScoreFlow will submit 1 job per docking pose
  max_submissions=\"$max_submissions\"
" > ScoreFlow.config

# remove temporary file
rm -f temp.config
}

# function to output errors
error() {
usage
echo -e "${RED}FATAL ERROR${NC} : ${RED}${1}${NC} is missing"
exit 1
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
  if [ -z "${plants}" ] && [ ! "${run_mode}" = "mazinger" ] ; then error "the location of PLANTS's executable"; fi

# VINA
elif [ "${rescore_method}" = "vina" ]; then
  if [ -z "${rec}" ] && [ ! "$mode" = "PDB" ]; then 
    error "the location of the receptor MOL2 or PDB file";
  else 
    filename=$(basename "$rec")
    extension="${filename##*.}"
    if [ ! "${extension}" = "mol2" ] && [ ! "${extension}" = "pdb" ]; then echo -e "${RED}ERROR${NC} : your receptor is ${RED}not a MOL2 or PDB file${NC}"; exit 1; fi
  fi
  if [ -z "${vina_exec}" ] && [ ! "${run_mode}" = "mazinger" ] ; then error "the location of VINA's executable"; fi
  if [ -z "${adt_u24}" ]; then error "the location of AutoDockTools folder"; fi

# MMGBSA
elif [ "${rescore_method}" = "mmpbsa" ]; then
  if [ -z "${rec}" ] && [ ! "$mode" = "PDB" ]; then 
    error "the location of the receptor PDB file";
  else 
    filename=$(basename "$rec")
    extension="${filename##*.}"
    if [ ! "${extension}" = "pdb" ]; then echo -e "${RED}ERROR${NC} : your receptor is ${RED}not a PDB file${NC}"; exit 1; fi
  fi

  if ! $(list_include_item "1F MD" "${pb_method}"); then 
    echo -e "${RED}FATAL ERROR${NC} : ${RED}MMPBSA calculations method${NC} not recognized (1F or MD : ${pb_method})"; exit 1; fi
  if [ -z "$amber" ]     ;  then error "the path to amber.sh"; fi
  if [ -z "$strip_mask" ];  then error "the amber strip mask to create the dry complex from the solvated system"; fi
  if [ -z "$lig_mask" ]  ;  then error "the amber strip mask to create the ligand from the complex"; fi
  if [ "${pb_method}" = "1F" ]; then
    if [ ! -z "$min_steps" ]; then
      if [ -z "$min_energy" ]; then
        error "the restraint applied to your selection for the minimization"
      else
        echo -e "${PURPLE}Rescoring with a $min_steps steps minimization${NC}"
      fi
    else
      echo -e "${PURPLE}Rescoring without minimization${NC}"
    fi

  elif [ "${pb_method}" = "MD" ]; then
    if [ -z "${md_time}" ];  then error "the length of the production"; fi
    if [ -z "${gb_model}" ]; then error "the GB model used for implicit solvation"; fi
  fi

else
  echo -e "${RED}FATAL ERROR${NC} : ${RED}Scoring function${NC} not recognized"; exit 1
fi

if [ "${mode}" = "PDB" ]; then
  if [ -z "${pdb_folder}" ]    ; then error "the complex's directory"                ; fi
  if [ -z "${spores_exec}" ]        ; then error "the location of SPORES's executable"    ; fi
elif [ "${mode}" = "ALL" ]; then
  if [ -z "${folder}" ]     ; then folder="${run_folder}/docking/"                   ; fi
elif [ "${mode}" = "BEST" ]; then
  if [ -z "${folder}" ]   ; then folder="${run_folder}/input_files/lig"              ; fi
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
  echo -e "${BLUE}Rescoring with structural water molecule${NC}"
 
else
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
    plants=$(which plants)
  elif [ "$rescore_method" == "vina" ]; then
    module load vina/1.1.2
    plants=$(which vina)
  fi

# if set to local, do nothing
elif [ "${run_mode}" = "local" ]; then true

else
  echo -e "${RED}ERROR${NC} : ${RED}Running mode${NC} (${run_mode}) not recognized"
fi

## Check for an already existing rescoring with the same scoring function, and make backup if necessary
if [ -d "${run_folder}/rescoring/${scoring_function}" ]; then
  mv ${run_folder}/rescoring/${scoring_function} ${run_folder}/rescoring/${scoring_function}.${datetime}.bak
  echo "Made a backup of an already existing ${scoring_function} rescoring"
fi
}

exit_message() {
echo "
Thank you for using ScoreFlow !
The ChemFlow team @IFMlab"
}


