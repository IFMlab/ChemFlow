#!/bin/bash

source ~/.bashrc

if [ -z "$CHEMFLOW_HOME" ]
then

  # Create environment variable
  echo -e "\n# ChemFlow\nexport CHEMFLOW_HOME=\"$PWD\"\nexport PATH=\$PATH:\$CHEMFLOW_HOME/DockFlow:\$CHEMFLOW_HOME/ScoreFlow:\$CHEMFLOW_HOME/Tools" >> ~/.bashrc

  echo "ChemFlow successfully installed !"
  echo "Please check ChemFlow.config before using ChemFlow."

else
  echo "ChemFlow is already installed on your session. Check ~/.bashrc for more info.
Overwriting ChemFlow.config"
fi

# Autofill the ChemFlow.config
plants_exec=$(which PLANTS1.2_64bit)
spores_exec=$(which SPORES_64bit)
vina_exec=$(which vina)
adt_u24=$(which prepare_ligand4.py | sed 's/\(.\+\)\/prepare_ligand4.py/\1/')
parallel=$(which parallel)
amber_folder=$(which cpptraj | sed 's/\(.\+\)\/bin\/cpptraj/\1/')
amber="${amber_folder}/amber.sh"

# Write ChemFLow.config
echo "# This file contains the path to all programs used by ChemFlow, as well as some default parameters.

# Path to PLANTS executable (not required for mazinger)
plants_exec=\"$plants_exec\"

# Path to SPORES executable, only needed for the PDB mode in ScoreFlow
spores_exec=\"$spores_exec\"

# Path to AutoDock Vina executable (not required for mazinger)
vina_exec=\"$vina_exec\"

# Path to Utilities24 folder of AutoDockTools (in MGLTools)
adt_u24=\"$adt_u24\"

# Path to GNU Parallel executable, needed to run procedures in parallel locally.
parallel=\"$parallel\"

# Path to amber.sh
amber=\"$amber\"

# Run Amber MD with sander or pmemd
amber_md=\"pmemd\"

# Path to Gaussian executable
gaussian_exec=\"\"
" > $CHEMFLOW_HOME/ChemFlow.config