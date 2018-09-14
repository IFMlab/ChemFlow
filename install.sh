#!/bin/bash

source ~/.bashrc

if [ -z "$CHEMFLOW_HOME" ]
then
  # Create environment variable and add to PATH
  CHEMFLOW_HOME="$PWD/ChemFlow"
  echo -e "\n# ChemFlow" >> ~/.bashrc
  echo "export CHEMFLOW_HOME=\"$CHEMFLOW_HOME\"" >> ~/.bashrc
  echo "export PATH=\$PATH:\$CHEMFLOW_HOME/bin" >> ~/.bashrc
  echo "ChemFlow successfully installed !"

else
  echo "ChemFlow is already installed on your session. Check ~/.bashrc, remove the 2 lines after #ChemFlow and run this script."
fi

# Check if programs are on PATH
echo "Checking softwares on your PATH variable..."

## Python modules
_pyv=($(python -V 2>&1))
if [ "$(echo ${_pyv[1]} | cut -d. -f1)" -lt 3 ]; then echo "[ ERROR ] Python 3 is not your current Python version"; fi
python -c 'import pandas' 2>/dev/null
if [ "$?" -eq 1 ]; then echo "[ ERROR ] Pandas is not installed in your current Python environment"; fi
python -c 'import rdkit' 2>/dev/null
if [ "$?" -eq 1 ]; then echo "[ ERROR ] RDKit is not installed in your current Python environment"; fi

## Softwares
if [ -z "$(command -v babel)" ] ; then echo "[ ERROR ] OpenBabel is not on your PATH" ; fi
if [ -z "$mgltools_folder" ]; then
  _MGLToolsPckgs=$(find /home /bin /opt /soft* -type d -name 'MGLToolsPckgs' 2>/dev/null)
  if [ -z "$_MGLToolsPckgs" ]; then
    echo "[ WARNING ] MGLTools is not installed. Please install it and run this script if you plan on using Vina."
  else
    echo "# MGLTools for ChemFlow" >> ~/.bashrc
    echo "export mgltools_folder=$(echo $_MGLToolsPckgs | sed 's/\/MGLToolsPckgs//')" >> ~/.bashrc
  fi
fi
if [ -z "$(command -v PLANTS1.2_64bit)" ]; then echo "[ WARNING ] PLANTS is not on your PATH"; fi
if [ -z "$(command -v vina)" ]; then echo "[ WARNING ] Vina is not on your PATH"; fi
if [ -z "$(command -v sander)" ] ; then echo "[ WARNING ] AmberTools is not on your PATH"; fi
if [ -z "$(command -v g09)" ] ; then echo "[ WARNING ] Gaussian09 is not on your PATH"; fi
if [ -z "$(command -v IChem)" ] ; then echo "[ WARNING ] IChem is not on your PATH"; fi
