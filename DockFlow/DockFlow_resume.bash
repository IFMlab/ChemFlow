#!/bin/bash 
#
#               ChemFlow 2017
#             Module: DockFlow
# 
# This script has the following funcions.
#
#      list_incomplete - List incomplete Dockings
#  resubmit_incomplete - Resubmit incomplete dockings.
#

root=$PWD/docking/

# Go to root folder.
cd ${root}

list_incomplete() {
# Create a list of incomplete dockings.
incomplete=""
for lig in $(ls -v -d lig_*) ; do
  echo -ne "Checking $lig\r"
  if [ "$(awk '/finished/'  ${lig}/plants.job)" == "" ] ; then 
    incomplete="${incomplete} ${lig}"
  fi
done

# Write out the list.
echo "
Incomplete list:
${incomplete}"
}

resubmit_incomplete() {
# Resubmit the incompletes.
for i in ${incomplete} ; do
  cd ${root}/${i}
  rm -rf docking/
  /home/dgomes/software/plants/PLANTS1.2_64bit --mode screen config.plants > plants.job 2>&1 &
done
}



list_incomplete
resubmit_incomplete

# Sit back and relax.
