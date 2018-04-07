#!/bin/bash
#
# ChemFlow  - Computational Chemistry WorkFlows (awesome)
#
# SplitMol2 - Splits a single mol2 file with multiple molecules into multiple mol2 files with a single molecule.
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

Splits a single mol2 file with multiple molecules into multiple mol2 files with a single molecule. Usage:
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

count=0
# keep leading whitespaces
OLD_IFS="$IFS"
IFS=""
while read line ; do
  if [ "${line}" == '@<TRIPOS>MOLECULE' ]; then
    n=0
    let count+=1
    start="${line}"
  fi
  if [ ${n} == 1 ]; then
    lig_name="${line}"
    # some files converted by babel have "******" as nae inside the mol2 file --> replace by ligand_$count
    if [ "${lig_name}" == '*****' ]; then
      lig_name="ligand_${count}"
    fi
    echo -e "${start}" > ${2}/${lig_name}.mol2
    echo -e "${lig_name}" >> ${2}/${lig_name}.mol2
  elif [ ${n} -gt 1 ]; then
    echo -e "${line}" >> ${2}/${lig_name}.mol2
  fi
  let n+=1
done < "$1"
IFS="$OLD_IFS"
}

if [ "$1" = "--help" ] || [ "$1" = "-h" ] || [ -z "$1" ]; then
  help
else
  splitmol2 "$@"
fi
