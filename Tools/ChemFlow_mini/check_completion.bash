#!/bin/bash
ligand_folder=../all_leads/
nlig=500

echo "Getting ligand list... please wait"
list=$(cd ${ligand_folder} ; ls *.pdbqt | cut -d. -f1 )
list=($list)
list_max=${#list[@]}

incomplete=""
echo "Checking for completion"
for (( i=0;$i<$list_max; i++ )) ; do
  echo -ne "Checking $i         \r"
  if [ ! -f results/${list[${i}]}.pdbqt ] ; then
    incomplete="$incomplete ${list[${i}]}"
  fi 
done
echo

# Redo the "list"
list=($incomplete)
list_max=${#list[@]}

write_slurm() {
echo "#! /bin/bash
# 1 noeud 8 coeurs
#SBATCH -p public
#SBATCH --job-name=$jobname
#SBATCH -N 1
#SBATCH -n 16
#SBATCH -t 6:00:00

cd \$SLURM_SUBMIT_DIR

if [ -f ${first}.parallel ] ; then rm -rf ${first}.parallel ; fi
for i in ${list[@]:$first:$nlig} ; do
 echo \"/b/home/isis/dbarreto/software/autodock_vina_1_1_2_linux_x86/bin/vina --cpu 1 --ligand ../all_leads/\${i}.pdbqt --receptor receptor.pdbqt --config config.txt --out results/\${i}.pdbqt --log results/\${i}.log >results/\${i}.out\" >> ${first}.parallel
done

cat ${first}.parallel | xargs -P16 -I '{}' bash -c '{}'
" > vina.slurm
}

 
for (( first=0;$first<$list_max; first=$first+$nlig )) ; do
  echo -ne "Docking $first         \r"
  jobname="${first}"
  write_slurm
  sbatch vina.slurm
done
echo 
