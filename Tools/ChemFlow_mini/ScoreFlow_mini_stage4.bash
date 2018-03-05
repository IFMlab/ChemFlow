#!/bin/bash
#
# ScoreFlow stage 4
# Reads a list of simulations to run MD in explicit solvent for 20ns.
# In this stage it ONLY computes the RESP charges for the best ligands. 
#
# For Stage3 -> Stage4 interchange, we need to organize the ScoreFlow_input and ScoreFlow_output variables.
# 
rundir=$PWD
DEBUG=1

#ScoreFlow_ligand="DockFlow_TOP"
#ScoreFlow_input="ScoreFlow/input"
ScoreFlow_input="ScoreFlow/MMGBSA_implicit"
ScoreFlow_output="ScoreFlow/MMGBSA_explicit"
ScoreFlow_parameters="ScoreFlow/parameters"

source $HOME/software/amber16/amber.sh


# Functions #########################################################
ScoreFlow_init_stage4() {
# 1) Find the best compounds
# 2) 
read -p "How many top compounds to run? " ntop

IFS=,
resp_list=""
j=0
while [ $j -le ${ntop} ] ; do 
  read ligand energy
  resp_list="${resp_list} ${ligand}"
  let j++
done < MMGBSA_implicit_rank.csv 
IFS=" "
}

# DO NOT CHANGE ANYTHING BELLOW !!!
# I DID IT !!! This is the SAME as "STAGE 1" 
smart_submit_slurm() {

if [ "$RESP" == 1 ] ; then

  # Count the number of ligands RESP.
  list=($resp_list)
  list_max=${#list[@]}
  #echo ${list[@]}

  echo "There are $list_max RESP simulations to run"
  read -p "How many do you want per PBS job? : " nlig

  for (( first=0;$first<$list_max; first=$first+$nlig )) ; do
    echo -ne "Preparing from ${first}          \r"
    jobname="${first}"
    write_gaussian_smart
    sbatch gaussian.slurm
  done
fi

if [ "$BCC" == 1 ] ; then
  # Count the number of ligands BCC.
  list=($bcc_list)
  list_max=${#list[@]}
  #echo ${list[@]}

  echo "There are $list_max AM1-BCC simulations to run"
  read -p "How many do you want per PBS job? : " nlig

  for (( first=0;$first<$list_max; first=$first+$nlig )) ; do
    echo -ne "Preparing from ${first}          \r"
    jobname="${first}"
    write_bcc_smart
    sbatch sqm.slurm
  done
fi
}

write_gaussian_smart() {
# I did my best, no far NO changes here !!!
echo "#! /bin/bash
# 1 noeud 14 coeurs
#SBATCH -p public
#SBATCH --sockets-per-node=1
#SBATCH --cores-per-socket=8
#SBATCH -N 1
##SBATCH -n 16
#SBATCH -t 12:00:00
#SBATCH --job-name=${first}
#SBATCH --mem=16000

# Environnement par défaut : contient les compilateurs Intel 11
source /b/home/configfiles/bashrc.default

module load gaussian/g09d01_pgi
source \$GPROFILE
export GAUSS_SCRDIR=/scratch/job.\$SLURM_JOB_ID 

# Source amber variables
source $HOME/software/amber16/amber.sh 

# Go to run folder
cd \$SLURM_SUBMIT_DIR

run_gaussian() {
antechamber -i lig.mol2 -fi mol2 -o lig.gau -fo gcrt  -gv 1 -ge lig.gesp -gm \"%mem=16Gb\" -gn \"%nproc=8\" -s 2 -eq 2 -rn MOL -pf y -dr no
g09 lig.gau
antechamber -i lig.out -fi gout -o lig_resp.mol2 -fo mol2 -c resp -s 2 -rn MOL -pf y -dr no

if [ -f lig.frcmod ] ; then
  parmchk2 -i lig_resp.mol2 -o lig.frcmod -s 2 -f mol2
fi
}

for RUN_DIR in ${list[@]:${first}:${nlig}} ; do
  cd \$SLURM_SUBMIT_DIR/${output}/\${RUN_DIR}
  run_gaussian
done
wait
" > gaussian.slurm
}




# Program ###########################################################

ScoreFlow_init_stage4

# Thats for Gaussian SLURM
output=${ScoreFlow_parameters}
RESP=1

smart_submit_slurm

