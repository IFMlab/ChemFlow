#!/bin/bash
#
# ChemFlow  - Computational Chemistry WorkFlows (awesome)
#
# SplitMol2 - Splits a single mol2 file with multiple moleculs into multiple mol2 files with a single molecule.
# To split a mol2 or sdf file containing multiple ligands in batches, see splitmol
#
# Diego Enry B. Gomes
# dgomes@pq.cnpq.br
#
# Instituto Nacional de Metrologia, Qualidade e Tecnologia - INMETRO - Brazil
# Av. Nossa Senhora das Gracas
#
# Universite de Strasbourg - UNISTRA - France
#

help() {
  echo -e "\
//=======================================================\\\\\\
||                  ${RED}ChemFlow Tools${NC}                       ||
|| Laboratoire d'Ingenierie des Fonctions Moleculaires   ||
|| Institut de Science et d'Ingenierie Supramoleculaires ||
||                                                       ||
||                                                       ||
|| Cedric Bouysset  - cbouysset@unistra.fr               ||
|| Diego E.B. Gomes - dgomes@pq.cnpq.br                  ||
\\\\\=======================================================//

Splits a single mol2 file with multiple moleculs into multiple mol2 files with a single molecule. Usage:
./splitmol2 input_file.mol2 output_folder

SplitMol2 is part of ChemFlow Tools, developed by
Cedric Bouysset(1)
 - cbouysset@unistra.fr
Diego Enry Barreto Gomes(1,2,3)
 - dgomes@pq.cnpq.br

1 - Laboratoire d'Ingenierie des Fonctions Moleculaires - LIFM
    Universite de Strasbourg - France
2 - Divisao de Metrologia Aplicada as Ciencias da Vida - DIMAV
    Instituto Nacional de Metrologia, Qualidade e Tecnologi (INMETRO) - Brazil
"
}

# Color output
source $CHEMFLOW_HOME/common/colors.bash

splitmol2() {
# check input and output
if [ ! -f "$1" ];then
  echo -e "${RED}ERROR${NC} : Ligand input file doesn't exists"
  exit 1
fi
if [ ! -d "$2" ];then
  mkdir -p "$2"
fi

n=0
# keep leading whitespaces
OLD_IFS="$IFS"
IFS=""
while read line ; do
  if [ "${line}" == '@<TRIPOS>MOLECULE' ]; then
    let n=$n+1
  fi
  echo -e "${line}" >> ${2}/lig_${n}.mol2
done < "$1"
IFS="$OLD_IFS"
}

if [ "$1" = "--help" ] || [ "$1" = "-h" ] || [ -z "$1" ]; then
  help
else
  splitmol2 "$@"
fi
