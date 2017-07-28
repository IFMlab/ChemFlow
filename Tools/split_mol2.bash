#!bin/bash

# Count # of molecules
end=$(grep "TRIPOS>MOLECULE" lig/pr_decoys.mol2 |wc -l)

read -p "Maximum number of molecules per mol2 file : " maxmol

# Split 
for ((i=1;i<=${end};i=$i+$maxmol)) ; do
  let finish=${i}+${maxmol}-1
  if [ ${finish} -gt ${end} ] ; then finish=${end} ; fi 
  echo "babel lig/pr_decoys.mol2 lig_split/decoys_${i}_${finish}.mol2 -f ${i} -l ${finish}"
done
