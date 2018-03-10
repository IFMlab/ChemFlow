#!/bin/bash
 
source ~/.bashrc
 
if [ -z "$CHEMFLOW_HOME" ]
then
  # Create environment variable
  CHEMFLOW_HOME="$PWD"
  echo -e "\n\
  # ChemFlow\n\
  export CHEMFLOW_HOME=\"$CHEMFLOW_HOME\"\n\
  export PATH=\$PATH:\$CHEMFLOW_HOME/DockFlow:\$CHEMFLOW_HOME/ScoreFlow:\$CHEMFLOW_HOME/Tools" >> ~/.bashrc
 
  echo "ChemFlow successfully installed !"
  echo "Please check ChemFlow.config before using ChemFlow."
 
else
  echo "ChemFlow is already installed on your session. Check ~/.bashrc for more info.
Overwriting ChemFlow.config"
fi
 
# Autofill the ChemFlow.config
plants_exec=$(which PLANTS1.2_64bit 2> /dev/null)
spores_exec=$(which SPORES_64bit 2> /dev/null)
vina_exec=$(which vina 2> /dev/null)
parallel=$(which parallel 2> /dev/null)
amber_folder=$(which cpptraj 2> /dev/null | sed 's/\(.\+\)\/bin\/cpptraj/\1/')
if [ ! -z "$amber_folder" ]; then amber="${amber_folder}/amber.sh"; fi
 
# Write ChemFLow.config
echo "# This file contains the path to all programs used by ChemFlow, as well as some default parameters.
 
# Path to PLANTS executable (not required for PBS)
plants_exec=\"$plants_exec\"
# Command to load PLANTS on PBS server
load_plants_PBS=\"module load plants/1.2\"
 
# Path to SPORES executable, only needed for the PDB mode in ScoreFlow
spores_exec=\"$spores_exec\"
 
# Path to AutoDock Vina executable (not required for PBS)
vina_exec=\"$vina_exec\"
# Command to load Vina on PBS server
load_vina_PBS=\"module load vina\"
 
# Path to Utilities24 folder of AutoDockTools (in MGLTools)
mgltools_folder=\"\"
 
# Path to GNU Parallel executable, needed to run procedures in parallel locally.
parallel=\"$parallel\"
 
# Path to amber.sh
amber=\"$amber\"
 
# Run Amber MD with sander or pmemd
amber_md=\"pmemd\"
 
# Path to Gaussian executable
gaussian_exec=\"\"
" > $CHEMFLOW_HOME/ChemFlow.config
