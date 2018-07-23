#!/bin/bash
#
# ChemFlow - Computational chemistry is great again.
# Gomes D.E.B.(1,2,3), Bouysset Cedric(1), Marco Cecchini(1)
# 1 - Universite de Strasbourg - France
# 2 - Instituto Nacional de Metrologia, Qualidade e Tecnologia - INMETRO - Brazil
# 3 - CAPES - Brazil
#
# @tool PDBbind2amber.bash
# @brief Convert Hydrogen atom names as in PDBbind database format to comply with AMBER format.
# @author Diego Enry Barreto Gomes | dgomes@live.com
# @lundi 23 juillet 2018, 14:50:27 (UTC+0200)
#

# Config ------------------------------------------------
FILENAME="protein.pdb"

# Program -----------------------------------------------
for var in "B" "D" "G" "E" ; do 
  for i in 1 2 3 ; do 
    sed -i "s/${i}H${var}1/H${var}1${i}/" ${FILENAME}
    sed -i "s/${i}H${var}2/H${var}2${i}/" ${FILENAME}
  done
done

sed -i "s/HG12 ILE/HG13 ILE/" ${FILENAME}
sed -i "s/HG11 ILE/HG12 ILE/" ${FILENAME}
