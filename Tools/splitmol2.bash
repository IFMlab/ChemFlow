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
welcome() {
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
"
}

help() {
echo -e "\
//=======================================================\\\\\\
||                  ${RED}ChemFlow Tools${NC}                       ||
|| 
\\\\\=======================================================//

Usage, just split file into multiple mol2 files.
./splitmol2


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
n=0
mkdir lig_split

while read line ; do 
  if [ "${line}" == '@<TRIPOS>MOLECULE' ] ; then 
    let n=$n+1
    echo $n
  fi
  echo ${line} >> lig_split/lig_${n}.mol2
done < lig.mol2

}


welcome
help

exit 0

