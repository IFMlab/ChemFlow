# Color output
RED="\e[0;31m"
BLUE="\e[0;34m"
GREEN="\e[0;32m"
PURPLE="\e[0;35m"
NC="\033[0m"

welcome() {
echo -e "\
//=======================================================\\\\\\
||                        ${RED}DockFlow${NC}                       ||
|| Laboratoire d'Ingenierie des Fonctions Moleculaires   ||
|| Institut de Science et d'Ingenierie Supramoleculaires ||
|| Cedric Bouysset - cbouysset@unistra.fr                ||
|| Diego E.B. Gomes - dgomes@pq.cnpq.br                  ||
\\\\\=======================================================//
"
}

exit_message() {
echo "Thank you for using DockFlow !
The ChemFlow team @IFMlab"
}


usage() {
echo "\
Usage : DockFlow
                 -h/--help           : Show this help message and quit
                 -hh/--fullhelp      : Show a more detailed help
                 -f/--file           : Path to DockFlow configuration file
                 -r/--receptor       : Path to the receptor's mol2 file
                 -l/--ligand         : Path to the ligand folder
                 -bsc/--center       : xyz coordinates of the center of the 
                                       spheric binding site, separated by a space
                 -bsr/--radius       : Radius of the spheric binding site
                 -n/--number         : Number of poses to generate, per ligand
                 --run               : local, parallel, mazinger
_________________________________________________________________________________
For parallel :
                 -c/--core_number    : Number of cores for parallel
_________________________________________________________________________________
Optionnal :
                 -w/--water          : Path to the structural water molecule
                 -wxyzr/--water_xyzr : xyz coordinates and radius of the water
                                       sphere, separated by a space"
}

requirements() {
echo "\
###################################### Requirements ##########################################
This script is designed to work with PLANTS (for now).
It can perform an automatic VS based on information given by the user :
ligands, receptor, binding site info, and extra options.
PLANTS only accepts mol2 files as input (1 or more compounds per file).
Ligands in the mol2 format should be all put in the same directory.
All paths given must be absolute paths.
DockFlow will try to read a DockFlow.config file in the current directory.
If such file doesn't exist, please run ConfigFlow to guide you,
or copy $CHEMFLOW_HOME/config_files/DockFlow.config here.
If you already have an existing config file and which to rerun DockFlow
only modifying some options, see the help below.
"
}


DF_CLI() {
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
    -f|--file)
    CONFIG_FILE="$2"
    shift # past argument
    ;;
    -r|--receptor)
    rec="$2"
    shift # past argument
    ;;
    -l|--ligand)
    lig_folder="$2"
    shift # past argument
    ;;
    -bsc|--center)
    bs_center="$2 $3 $4"
    shift 3 # past argument
    ;;
    -bsr|--radius)
    bs_radius="$2"
    shift # past argument
    ;;
    -n|--number)
    poses_number="$2"
    shift # past argument
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
    -c|--core_number)
    core_number="$2"
    shift # past argument
    ;;
    *)
    unknown="$1"        # unknown option
    echo "Unknown flag \"$unknown\""
    ;;
esac
shift # past argument or value
done
}

# write config file for DockFLow from CLI
write_DF_config() {
# Save the old config file
if [ -f DockFlow.config ]; then cp DockFlow.config DockFlow.${datetime}.config ; fi

# Overwrite. This only works because we used the same variable names in the interface and the config file.
source temp.config

echo "# Config file generated from CLI
# Absolute path to receptor's mol2 file
rec=\"$rec\"

# Absolute path to ligands folder
lig_folder=\"$lig_folder\"

# Binding site :
# xyz coordinates of the center of the sphere, separated by a space
bs_center=\"$bs_center\"

# Radius of the sphere in Angstrom
bs_radius=\"$bs_radius\"

# Number of docking poses to generate
poses_number=\"$poses_number\"

# Optionnal input ------------------------------------------------------------------------------------------------------

# Add a structural water molecule, centered on an xyz sphere and moving in a radius
# Absolute path to water molecule
water=\"$water\"
# xyz coordinates and radius of the sphere, separated by a space
water_xyzr=\"$water_xyzr\"

# Add any other parameter here
plants_user_parameters=\"\"

# Run on this machine (default), in parallel, or on mazinger
# local, parallel, mazinger
run_mode=\"$run_mode\"

# If parallel is chosen, please specify the number of cores available
core_number=\"$core_number\"
" > DockFlow.config

# remove temporary file
rm -f temp.config
}

error() {
usage
echo -e "${RED}FATAL ERROR${NC} : ${RED}${1}${NC} is missing"
exit 1
}

check_input() {
# Verify user input
# exit if fatal error, otherwise, continue
if [ -z "${rec}" ]          ; then error "the receptor's mol2 file"                          ; fi 
if [ -z "${lig_folder}" ]   ; then error "the ligands folder"                                ; fi
if [ -z "${bs_center}" ]    ; then error "the definition of binding site center coordinates" ; fi
if [ -z "${bs_radius}" ]    ; then error "the binding site radius"                           ; fi
if [ -z "${poses_number}" ] ; then error "the number of docking poses to create"             ; fi
if [ -z "${plants_exec}" ] && [ ! "${run_mode}" = "mazinger" ] ; then error "the location of PLANTS's executable"  ; fi
echo -e "${GREEN}Successfully read all mandatory parameters${NC}"

# Optionnal parameters
## Water
if [ ! -z "${water}" ] && [ ! -z "${water_xyzr}" ]
then
  echo -e "${BLUE}Docking with water${NC}"
  dock_water="water_molecule ${water_xyzr}
              water_molecule_definition ${water}"
elif [ ! -z "${water}" ] && [ -z "${water_xyzr}" ]
then
  echo -e "${RED}ERROR${NC} : ${BLUE}water${NC} parameters incomplete (coordinates missing)"
  exit 1
elif [ -z "${water}" ] && [ ! -z "${water_xyzr}" ]
then
  echo -e "${RED}ERROR${NC} : ${BLUE}water${NC} parameters incomplete (water molecule missing)"
  exit 1
else
  echo -e "${BLUE}Docking without water${NC}"
  dock_water=""
fi

## Running mode
# if empty, set local to default
if [ -z "${run_mode}" ]; then run_mode="local"
# if set to local, nothing particular to do...
elif [ "${run_mode}" = "local" ]; then :
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
  module load plants/1.2
  plants_exec=$(which plants)
else
  echo -e "${RED}ERROR${NC} : ${RED}Running mode${NC} not recognized"
fi


## Check for an already existing rescoring with the same scoring function, and make backup if necessary
if [ -d "${run_folder}/docking" ]; then
  mv ${run_folder}/docking ${run_folder}/docking.${datetime}.bak
  echo "Made a backup of an already existing docking campaign"
fi
}

