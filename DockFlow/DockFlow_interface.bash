# Welcome message
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

# Exit message
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
                 -l/--ligand         : Path to the ligands input file/folder
                 -o/--output         : Path to output folder
                 -n/--number         : Number of poses to generate, per ligand
                 -sf/--function      : vina, chemplp, plp, plp95
                                       Default : chemplp
                 --run               : local, parallel, PBS
_________________________________________________________________________________
For PLANTS :
                 --speed             : Search speed for Plants. 1, 2 or 4
                                       Default : 1
                 --ants              : Number of ants
                                       Default : 20
                 --evap_rate         : Evaporation rate of pheromones
                                       Default : 0.15
                 --iteration_scaling : Iteration scaling factor
                                       Default : 1.00
                 --center            : xyz coordinates of the center of the
                                       binding site, separated by a space
                 --radius            : Radius of the spheric binding site
                 --water             : Path to a structural water molecule
                 --water_xyzr        : xyz coordinates and radius of the water
                                       sphere, separated by a space
_________________________________________________________________________________
For Vina :
                 --center            : xyz coordinates of the center of the grid,
                                       separated by a space
                 --size              : Size of the grid along the x, y and z axis
                                       separated by a space
                 --exhaustiveness    : Exhaustiveness of the global search
                                       Default : 8
                 --energy_range      : Max energy difference (kcal/mol) between
                                       the best and worst poses displayed
                                       Default : 3.00
_________________________________________________________________________________
For parallel :
                 -c/--corenumber    : Number of cores to run in parallel
"
}

requirements() {
echo "\
################################# Requirements #################################
This script is designed to work with PLANTS or Vina.
It can perform an automatic VS based on information given by the user :
ligands, receptor, binding site info, and extra options.
All paths given must be absolute paths.
DockFlow needs a configuration file, an example can be found in:
$CHEMFLOW_HOME/config_files/DockFlow.config
If you already have an existing config file and wish to rerun DockFlow
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
    lig_input="$2"
    shift # past argument
    ;;
    -o|--output)
    output_folder="$2"
    shift
    ;;
    -sf|--function)
    scoring_function="$2"
    shift
    ;;
    --center)
    bs_center="$2 $3 $4"
    shift 3 # past argument
    ;;
    --radius)
    bs_radius="$2"
    shift # past argument
    ;;
    --size)
    bs_size="$2 $3 $4"
    shift 3
    ;;
    -n|--number)
    poses_number="$2"
    shift # past argument
    ;;
    --water)
    water="$2"
    shift # past argument
    ;;
    --water_xyzr)
    water_xyzr="$2 $3 $4 $5"
    shift 4 # past argument
    ;;
    --run)
    run_mode="$2"
    shift # past argument
    ;;
    -c|--corenumber)
    core_number="$2"
    shift # past argument
    ;;
    --speed)
    speed="$2"
    shift
    ;;
    --ants)
    ants="$2"
    shift
    ;;
    --evap_rate)
    evap_rate="$2"
    shift
    ;;
    --iteration_scaling)
    iteration_scaling="$2"
    shift
    ;;
    --exhaustiveness)
    exhaustiveness="$2"
    shift
    ;;
    --energy_range)
    energy_range="$2"
    shift
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

# Overwrite. This only works because we used the same variable names in the interface and the config file.
source temp.config

echo "# Config file for DockFlow
# Absolute path to receptor's mol2 file
rec=\"$rec\"
# Absolute path to ligands file/folder
lig_input=\"$lig_input\"
# Output folder
output_folder=\"$output_folder\"
# Number of docking poses to generate
poses_number=\"$poses_number\"
# Scoring function: vina, chemplp, plp or plp95
scoring_function=\"$scoring_function\"
# xyz coordinates of the center of the sphere/grid binding site, separated by a space
bs_center=\"$bs_center\"

##########
# PLANTS #
##########
# Radius of the spheric binding site in Angstrom
bs_radius=\"$bs_radius\"
# Search speed : 1, 2 or 4. Default: 1
speed=\"$speed\"
# Number of ants. Default : 20
ants=\"$ants\"
# Evaporation rate of pheromones. Default : 0.15
evap_rate=\"$evap_rate\"
# Iteration scaling factor. Default : 1.00
iteration_scaling=\"$iteration_scaling\"

########
# Vina #
########
# Size of the sphere along the x, y and z axis in Angstrom, separated by a space
bs_size=\"$bs_size\"
# Exhaustiveness of the global search. Default : 8
exhaustiveness=\"$exhaustiveness\"
# Max energy difference (kcal/mol) between the best and worst poses displayed. Default : 3.00
energy_range=\"$energy_range\"

###################
# Optionnal input #
###################
# Run on this machine (default), in parallel, or on PBS
# local, parallel, PBS
run_mode=\"$run_mode\"
# If parallel is chosen, please specify the number of cores to use
core_number=\"$core_number\"
" > DockFlow.config
if [ ! -z "${water}" ] ; then
echo "
# Add a structural water molecule for PLANTS, centered on an xyz sphere and moving in a radius
# Absolute path to water molecule
water_molecule=\"$water\"
# xyz coordinates and radius of the sphere, separated by a space
water_molecule_definition=\"$water_xyzr\"
">>DockFlow.config
fi

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
if [ -z "${rec}" ]          ; then error "the receptor's file" ; fi
if [ -z "${lig_input}" ]    ; then error "the ligands input" ; fi
if [ -z "${bs_center}" ]    ; then error "the definition of binding site center coordinates" ; fi
if [ -z "${poses_number}" ] ; then error "the number of docking poses to create" ; fi
# Scoring function
# default is chemplp for PLANTS
if [ -z "${scoring_function}" ]; then scoring_function="chemplp"; fi
# recognize which program to use
if $(list_include_item "chemplp plp plp95" "${scoring_function}"); then
  docking_program="plants"
elif [ "${scoring_function}" = 'vina' ]; then
    docking_program="vina"
#  elif $(list_include_item "insert_new_function_here" "${scoring_function}"); then
#    docking_program="insert_program_name_here"
# Error if scoring function not recognized
else
  echo -e "Scoring function ${RED}\"${scoring_function}\"${NC} not recognized"
  exit 1
fi
echo -e "${GREEN}Successfully read all mandatory parameters for docking with ${docking_program}${NC}"

# Optional parameters
if [ "${docking_program}" = "plants" ]; then
  if [ -z "${bs_radius}" ]    ; then error "the binding site radius" ; fi
  if [ -z "${plants_exec}" ] && [ ! "${run_mode}" = "PBS" ] ; then error "the location of PLANTS's executable"  ; fi
  # Water
  if [ ! -z "${water}" ] && [ ! -z "${water_xyzr}" ]
  then
    echo -e "${BLUE}Docking with water${NC}"
    dock_water="water_molecule ${water_xyzr}"
    dock_water2="water_molecule_definition ${water}"
  elif [ ! -z "${water}" ] && [ -z "${water_xyzr}" ]
  then
    echo -e "${RED}ERROR${NC} : ${BLUE}water${NC} parameters incomplete (coordinates missing)"
    exit 1
  elif [ -z "${water}" ] && [ ! -z "${water_xyzr}" ]
  then
    echo -e "${RED}ERROR${NC} : ${BLUE}water${NC} parameters incomplete (water molecule missing)"
    exit 1
  else
    dock_water=""
    dock_water2=""
  fi
  # Search speed : 1, 2 or 4. Default: 1
  if [ -z "${speed}" ]; then speed="1"; fi
  # Number of ants. Default : 20
  if [ -z "${ants}" ]; then ants="20"; fi
  # Evaporation rate of pheromones. Default : 0.15
  if [ -z "${evap_rate}" ]; then evap_rate="0.15"; fi
  # Iteration scaling factor. Default : 1.00
  if [ -z "${iteration_scaling}" ]; then iteration_scaling="1.00"; fi

elif [ "${docking_program}" = "vina" ]; then
  if [ -z "${bs_size}" ]    ; then error "the binding site size" ; fi
  if [ -z "${vina_exec}" ] && [ ! "${run_mode}" = "PBS" ] ; then error "the location of VINA's executable"; fi
  if [ -z "${mgltools_folder}" ]; then error "the location of MGLTools folder"; fi
  # Exhaustiveness of the global search. Default : 8
  if [ -z "${exhaustiveness}" ]; then exhaustiveness="8"; fi
  # Max energy difference (kcal/mol) between the best and worst poses displayed. Default : 3.00
  if [ -z "${energy_range}" ]; then energy_range="3.00"; fi
  # transform binding site to an array
  bs_center=(${bs_center})
  bs_size=(${bs_size})
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
# if set to PBS
elif [ "${run_mode}" = "PBS" ]
then
  if [ "${docking_program}" = "plants" ]; then
    ${load_plants_PBS}
    plants_exec=$(which plants)
  elif [ "${docking_program}" = "vina" ]; then
    ${load_vina_PBS}
    vina_exec=$(which vina)
  fi
else
  echo -e "${RED}ERROR${NC} : ${RED}Running mode${NC} not recognized"
fi

## Create folder if it doesn't exist
if [ ! -d "${output_folder}" ]; then mkdir -p ${output_folder}; fi
}
