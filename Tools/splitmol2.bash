#!/bin/bash
#
# ChemFlow  - Computational Chemistry WorkFlows (awesome)
#
# SplitMol2 - a simple tool to split mol2 files.
#
# Diego Enry B. Gomes
# dgomes@pq.cnpq.br
#
# Instituto Nacional de Metrologia, Qualidade e Tecnologia - INMETRO - Brazil
# Av. Nossa Senhora das Gracas
#
# Universite de Strasbourg - UNISTRA - France
#

# Color output
RED="\e[0;31m"
BLUE="\e[0;34m"
GREEN="\e[0;32m"
PURPLE="\e[0;35m"
NC="\033[0m"


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

Splits a single mol2 file into multiple mol2 files. Usage:
./splitmol2 input_file.mol2 10

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


splitmol2() {
# check input and output
if [ ! -f "$1" ];then
  echo -e "${RED}ERROR${NC} : Ligand input file doesn't exists"
  exit 1
fi

#Basename for output
mol=$(echo $1 | cut -d. -f1)
maxmol=$2
if [ "$maxmol" == "" ] ; then
  echo "[NOTE] Using 10 molecules as output"
fi

j=0
n=0
# keep leading whitespaces
OLD_IFS="$IFS"
IFS=""
while read line ; do

  if [ "${line}" == '@<TRIPOS>MOLECULE' ]; then
    let n=$n+1
  fi

  if [ "${n}" == "${maxmol}" ] ; then
    n=0
    echo -e "${line}" >> ${mol}_${j}.mol2
    let j+=1
  else
    echo -e "${line}" >> ${mol}_${j}.mol2
  fi


done < "$1"
IFS="$OLD_IFS"
}

if [ "$1" = "--help" ] || [ "$1" = "-h" ] || [ -z "$1" ]; then
  help
else
  splitmol2 "$@"
fi
