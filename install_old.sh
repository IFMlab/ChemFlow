#!/bin/bash
###############################################################################
## ChemFlow - Computational Chemistry is Great Again
##
## Description:
## Install ChemFlow, set necessary variables, check for missing dependencies
##
## Author:
## cbouy - Cedric Bouysset - cbouysset@unice.fr
##
###############################################################################

RELEASE="v0.7-beta"
GUI_NAME="chemflow"

# ChemFlow installation script

not_on_path(){
  echo "[ $1 ] $2 is not on your PATH"
  if [ "$1" == "WARNING" ]; then
    let warning_count+=1
  else
    let error_count+=1
  fi
}

_install(){
  if [ -z "$1" ]; then
    echo "Installing ChemFlow in $DESTINATION..."
    # Move files if necessary
    if [ "$DESTINATION" != $(abspath "$PWD") ]; then
      echo "Copying files from $PWD to $DESTINATION/"
      cp -r "$PWD" "$DESTINATION/"
      COPY=1
    fi
    # Create environment variable and add to .bashrc
    CHEMFLOW_HOME="$DESTINATION/ChemFlow"
    echo -e "\n# ChemFlow" >> ~/.bashrc
    echo "export CHEMFLOW_HOME=\"$CHEMFLOW_HOME\"" >> ~/.bashrc
    echo "export PATH=\$PATH:\$CHEMFLOW_HOME/bin" >> ~/.bashrc
    echo "ChemFlow successfully installed !"
  else
    echo "ChemFlow would be installed in $DESTINATION"
    CHEMFLOW_HOME="$DESTINATION/ChemFlow"
    if [ "$DESTINATION" != $(abspath "$PWD") ]; then
      echo "Would copy files from $PWD to $DESTINATION/"
      COPY=1
    fi
  fi
}

_update(){
  echo "ChemFlow has already been installed on your system."
  if [ -z "$1" ]; then
    echo "Updating installation to $DESTINATION..."
    # Move files if necessary
    if [ "$DESTINATION" != $(abspath "$PWD") ]; then
      echo "Copying files from $PWD to $DESTINATION/"
      cp -r "$PWD" "$DESTINATION/"
      COPY=1
    fi
    # Backup
    cp ~/.bashrc ~/.bashrc.bak
    # Replace with new path (not using sed -i because it's not available on all sed versions)
    CHEMFLOW_HOME="$DESTINATION/ChemFlow"
    sed -e 's?export CHEMFLOW_HOME=".*"?export CHEMFLOW_HOME="'$DESTINATION'\/ChemFlow"?g' ~/.bashrc > ~/.bashrc.new && mv ~/.bashrc.new ~/.bashrc
    echo "Update successful"
  else
    echo "ChemFlow would be updated to $DESTINATION"
    CHEMFLOW_HOME="$DESTINATION/ChemFlow"
    if [ "$DESTINATION" != $(abspath "$PWD") ]; then
      echo "Would copy files from $PWD to $DESTINATION/"
      COPY=1
    fi
  fi
}

_install_gui(){
  if [ -z "$1" ]; then
    echo "Installing GUI from release $RELEASE"
    wget -P ${CHEMFLOW_HOME}/bin/ https://github.com/IFMlab/ChemFlow/releases/download/${RELEASE}/${GUI_NAME}
  else
    echo "Would download GUI from release $RELEASE"
  fi
}

_check(){
  # Check if programs are on PATH
  echo "Checking softwares available on your PATH..."
  source ~/.bashrc

  ## Core tools
  if [ -z "$(command -v perl)" ] ; then not_on_path ERROR Perl ; fi

  ## Python modules
  _pyv=($(python -V 2>&1))
  if [ "$(echo ${_pyv[1]} | cut -d. -f1)" -lt 3 ]; then
    echo "[ ERROR ] Python 3 is not your current Python version"
    let error_count+=1
  fi
  python -c 'import pandas' 2>/dev/null
  if [ "$?" -eq 1 ]; then
    echo "[ ERROR ] Pandas is not installed in your current Python environment"
    let error_count+=1
  fi
  python -c 'import rdkit' 2>/dev/null
  if [ "$?" -eq 1 ]; then
    echo "[ ERROR ] RDKit is not installed in your current Python environment"
    let error_count+=1
  fi

  ## Softwares
  if [ -z "$(command -v babel)" ] ; then not_on_path ERROR OpenBabel ; fi
  if [ -z "$mgltools_folder" ]; then
    mgltools_folder=$(find /home /bin /opt /soft* -type d -name 'MGLToolsPckgs' 2>/dev/null | sed 's/\/MGLToolsPckgs//' | head -1)
    if [ -z "$mgltools_folder" ]; then
      echo "[ WARNING ] MGLTools could not be found. Please install it and run this script if you plan on using Vina."
      let warning_count+=1
    else
      if [ -z "$1" ]; then
        # Add to .bashrc
        echo "# MGLTools for ChemFlow" >> ~/.bashrc
        echo "export mgltools_folder=$mgltools_folder" >> ~/.bashrc
      else
        echo "Would set MGLTools directory to $mgltools_folder"
      fi
    fi
  fi
  if [ -z "$(command -v PLANTS1.2_64bit)" ]; then not_on_path WARNING PLANTS; fi
  if [ -z "$(command -v vina)" ];            then not_on_path WARNING Vina; fi
  if [ -z "$(command -v sander)" ] ;         then not_on_path WARNING AmberTools; fi
  if [ -z "$(command -v g09)" ] ;            then not_on_path WARNING Gaussian09; fi
  if [ -z "$(command -v IChem)" ] ;          then not_on_path WARNING IChem; fi

  # ChemFlow
  if [ ! -x "$CHEMFLOW_HOME/bin/DockFlow" ]; then
    echo "[ ERROR ] Binaries in $CHEMFLOW_HOME are not executable"
    let error_count+=1
  fi
}

_help(){
echo "\
Usage:  $0
        -h|--help             : show this help message and quit
        -d|--destination  STR : install ChemFlow at the specified destination
        --gui                 : install GUI from release $RELEASE
        --debug               : only verify the installation, don't do anything
"
}

# CLI
while [[ $# -gt 0 ]]; do
  key="$1"
  case ${key} in
    "-h"|"--help")
      _help
      exit 0
    ;;
    "--gui")
      GUI=1
    ;;
    "-d"|"--destination")
      if [ -w "$2" ] && [ -d "$2" ] && [ ! -f "$2/ChemFlow" ]; then
        DESTINATION="$2"
        shift
      else
        echo "$2 is not writable, is not a directory, or already exists"
        exit 1
      fi
    ;;
    "--debug")
      echo "DEBUG mode activated"
      DEBUG=1
    ;;
    *)
      echo "Unknown flag \"$1\""
      exit 1
    ;;
  esac
  shift
done

# Main

warning_count=0
error_count=0
cd $(dirname $0)
source ~/.bashrc
source ./ChemFlow/src/ChemFlow_functions.bash

if [ -z "$DESTINATION" ]; then DESTINATION="$PWD"; fi
DESTINATION=$(abspath $DESTINATION)
if [ -z "$CHEMFLOW_HOME" ]
then
  _install $DEBUG
else
  _update $DEBUG
fi
if [ ! -z "$GUI" ]; then
  _install_gui $DEBUG
fi
_check $DEBUG

echo "Installation finished with $error_count error(s) and $warning_count warning(s)."
if [ ! -z "$COPY" ]; then
  echo "ChemFlow was installed in $DESTINATION. You can safely remove the directory $PWD"
fi
echo "Don't forget to run the following command to use ChemFlow right away:"
echo "source ~/.bashrc"
