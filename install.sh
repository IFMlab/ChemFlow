#!/bin/bash

source ~/.bashrc

if [ -z "$CHEMFLOW_HOME" ]
then
  echo "
# ChemFlow
export CHEMFLOW_HOME=\"$PWD\"
export PATH=\$PATH:\$CHEMFLOW_HOME/DockFlow:\$CHEMFLOW_HOME/ScoreFlow:\$CHEMFLOW_HOME/Tools
" >> ~/.bashrc
  echo "ChemFlow successfully installed !"

else
  echo "ChemFlow is already installed on your session. Check ~/.bashrc for more info."

fi
