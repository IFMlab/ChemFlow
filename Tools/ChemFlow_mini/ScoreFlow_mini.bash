#!/bin/bash
#
# User input

# PDB INPUT !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

SLURM=1            # [ 0 = no ;  1 = yes ]
BCC=1
RESP=0

ligand_folder="DockFlow_TOP"

list=$(ls ${ligand_folder}/ | cut -d. -f1 )       # MOL2 file
output="ScoreFlow/parameters"

rundir=$PWD

#####################################################################

# DO NOT CHANGE ANYTHING BELLOW !!!
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
echo "#! /bin/bash
# 1 noeud 14 coeurs
#SBATCH -p public
#SBATCH --sockets-per-node=1
#SBATCH --cores-per-socket=8
#SBATCH -t 20:00:00
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
antechamber -i lig.gout -fi gout -o lig_resp.mol2 -fo mol2 -c resp -s 2 -rn MOL -pf y -dr no

parmchk2 -i lig_resp.mol2 -o lig.frcmod -s 2 -f mol2
}

for RUN_DIR in ${list[@]:${first}:${nlig}} ; do
  cd \$SLURM_SUBMIT_DIR/${output}/\${RUN_DIR}
  run_gaussian
done
wait
" > gaussian.slurm
}


write_bcc_smart() {
echo "#! /bin/bash
# 1 noeud 14 coeurs
#SBATCH -p pri2013-short
#SBATCH -A qosisisifm
##SBATCH -p public
#SBATCH --sockets-per-node=2
#SBATCH --cores-per-socket=8
#SBATCH -t 5:00:00
#SBATCH --job-name=${first}
#SBATCH --mem=16000

# Environnement par défaut : contient les compilateurs Intel 11
source /b/home/configfiles/bashrc.default

# Source amber variables
source $HOME/software/amber16/amber.sh 

# Go to run folder
cd \$SLURM_SUBMIT_DIR

if [ -f sqm_${first}.xargs ] ; then rm -rf sqm_${first}.xargs ; fi
for RUN_DIR in ${list[@]:${first}:${nlig}} ; do
  echo \"cd \$SLURM_SUBMIT_DIR/${output}/\${RUN_DIR} ; antechamber -i lig.mol2 -fi mol2 -o lig_bcc.mol2 -fo mol2 -c bcc -s 2 -eq 1 -rn MOL -pf y -dr no ; parmchk2 -i lig_bcc.mol2 -o lig.frcmod -s 2 -f mol2\" >> sqm_${first}.xargs
done
cat sqm_${first}.xargs | xargs -P16 -I '{}' bash -c '{}'
wait
" > sqm.slurm

}


write_gaussian_slurm() {
echo "#! /bin/bash
# 1 noeud 14 coeurs
#SBATCH -p public
#SBATCH --sockets-per-node=2
#SBATCH --cores-per-socket=14
#SBATCH -t 2:00:00
#SBATCH --job-name=$mol2
#SBATCH --mem=16000

# Environnement par défaut : contient les compilateurs Intel 11
source /b/home/configfiles/bashrc.default

module load gaussian/
source \$GPROFILE
export GAUSS_SCRDIR=/scratch/job.\$SLURM_JOB_ID 

# Source amber variables
source $HOME/software/amber16/amber.sh 

# Go to run folder
cd \$SLURM_SUBMIT_DIR

antechamber -i lig.mol2 -fi mol2 -o lig.gau -fo gcrt  -gv 1 -ge lig.gesp -gm \"%mem=16Gb\" -gn \"%nproc=28\" -s 2 -eq 2 -rn MOL -pf y

g09 lig.gau

antechamber -i lig.gout -fi gout -o lig_resp.mol2 -fo mol2 -c resp -s 2 -rn MOL -pf y
parmchk2 -i lig_resp.mol2 -o lig.frcmod -s 2 -f mol2

" > gaussian.slurm
}

write_sqm_slurm() {
echo "#! /bin/bash
# 1 noeud 14 coeurs
#SBATCH -p public
#SBATCH --sockets-per-node=1
#SBATCH --cores-per-socket=1
#SBATCH -t 2:00:00
#SBATCH --job-name=$mol2
#SBATCH --mem=16000

module load compilers/intel15
module load libs/zlib-1.2.8

# Environnement par défaut : contient les compilateurs Intel 11
source /b/home/configfiles/bashrc.default

# Source amber variables
source $HOME/software/amber16/amber.sh 

# Go to run folder
cd \$SLURM_SUBMIT_DIR

antechamber -i lig.mol2 -fi mol2 -o lig_bcc.mol2 -fo mol2 -c bcc -s 2 -eq 2 -rn MOL -pf y
parmchk2 -i lig_bcc.mol2 -o lig.frcmod -s 2 -f mol2

" > sqm.slurm
}

##Stuff necessary at Mesocentre
module load batch/slurm
module load compilers/intel15
module load libs/zlib-1.2.8
module load languages/python-2.7.10
source $HOME/software/amber16/amber.sh

# Initialize variables
bcc_list=""
resp_list=""
list=($list)
list_max=${#list[@]}
errors=0


for mol2 in ${list[@]}; do
  cd ${rundir}
  
  # Create an output folder and go there.
  if [ ! -d $output/${mol2} ] ; then 
    mkdir -p $output/${mol2}
  fi

  cd $output/${mol2}

  # Simple Gasteinger charges
  if [ ! -f lig.mol2 ] ; then 
    echo -ne "${mol2}        \r" 
    antechamber -i ${rundir}/${ligand_folder}/${mol2}.mol2 -fi mol2 -o lig.mol2 -fo mol2 -c gas -rn MOL -dr no &>gas.log
  fi

  # Additional sanity check for lig.mol
  # Or else move on to the next molecule.
  if [ ! -f lig.mol2 ] ; then
    echo "[ERROR] in ${mol2}. lig.mol2 not generated." 
    let errors++
    let list_max=${list_max}-1
    continue
  fi
  
  # AM1-BCC charges
  if [ "$BCC" == "1" ] ; then 
    if [ ! -f "lig_bcc.mol2" ] ; then
      if [ "${SLURM}" == 1 ] ; then
#      write_sqm_slurm
#      sbatch sqm.slurm
      bcc_list="${bcc_list} ${mol2}"
      else
        antechamber -i lig.mol2 -fi mol2 -o lig_bcc.mol2 -fo mol2 -c bcc -s 2 -eq 1 -rn MOL -pf y -dr no 
      fi
    fi
  fi

  # RESP charges
  if [ "$RESP" == "1" ] ; then 
    if [ "$SLURM" == 1 ] ; then
#      write_gaussian_slurm
#      sbatch gaussian.slurm
      resp_list="${resp_list} ${mol2}"
    else

    # Prepare Gaussian
      antechamber -i lig.mol2 -fi mol2 -o lig.gau -fo gcrt -gv 1 -ge lig.gesp -gm "%mem=16Gb" -gn "%nproc=8" -s 2 -eq 1 -rn MOL -pf y -dr no

    # Run Gaussian to optimize structure and generate electrostatic potential grid
      g09 lig.gau > lig.gout

    # Read Gaussian output and write new optimized ligand with RESP charges
      antechamber -i lig.gout -fi gout -o lig_resp.mol2 -fo mol2 -c resp -s 2 -rn MOL -pf y -dr no
    fi
  fi
  let list_max=${list_max}-1
#  echo -ne "[DONE] ${mol2}. REMAINING: $list_max ; ERROR=$errors      \r"

done

# SUBMIT THE SHIT
cd $rundir
smart_submit_slurm

