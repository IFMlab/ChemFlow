#!/bin/bash
#
# ChemFlow - Computational Chemistry is Great again
# 
# @collection Reference file for ChemFlow_tools
#
# @brief Extracts Top "N" pose(s) for Top "N" compound(s)
# 
# @Software requiter: bash, python, pandas (python module)

CSV_IN="rank.csv"       # Input rank.csv. We want the "SCORE" column.
CSV_OUT="rank_out.csv"  # Output .csv (only with selected compounds+poses)
LST_OUT="list_out.lst"  # List of compound+poses
ncompounds=2000         # How many compounds
nposes=5                # How many poses / compound.

echo -e "
-----------------------------
Summary:
-----------------------------
${CSV_IN}  \t : Input  .csv
${CSV_OUT} \t : Output .csv 
${LST_OUT} \t : Pose list

${ncompounds}\t : Compounds
${nposes}    \t : Poses/compound
"


#5) Top "N" pose(s) of Top N compounds
python << END
import pandas as pd
df=pd.read_csv('${CSV_IN}',delim_whitespace=True)
compounds=df.sort_values('SCORE').groupby('LIGAND').head(${nposes}).head($ncompounds)
compounds['POSE'].sort_index().to_csv('${LST_OUT}',header=None,index=None)
compounds.to_csv('${CSV_OUT}',index=None)
END

echo "
[ NOTE ] Output list is NOT sorted by score
"

