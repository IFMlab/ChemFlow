#!/bin/bash
##################################################################### 
#   ChemFlow  -   Making Computational Chemistry is great again     #
#####################################################################
#
# Diego E. B. Gomes(1,2,3) - dgomes@pq.cnpq.br
# Cedric Boysset (3) - cboysset@unistra.fr
# Marco Cecchini (3) - cecchini@unistra.fr
#
# 1 - Instituto Nacional de Metrologia, Qualidade e Tecnologia - Brazil
# 2 - Coordenacao Aperfeicoamento de Pessoal de Ensino Superior - CAPES - Brazil.
# 3 - Universite de Strasbourg - France
#
#===============================================================================
#
#          FILE:  mmpbsa_slurm.bash
#
#         USAGE:  ./mmpbsa_slurm.bash
#
#   DESCRIPTION: Prepare and run MMPBSA for an MD trajectory using the SLURM scheduller.
#
#       OPTIONS:  ---
#  REQUIREMENTS:  AmberTools16, SLURM
#          BUGS:  ---
#         NOTES:  ---
#        AUTHOR:  Diego E. B. Gomes, dgomes@pq.cnpq.br
#       COMPANY:  Universite de Strasbourg / CAPES
#       VERSION:  1.0
#       CREATED:  Mon Oct 9 09:41:38 CEST 2017
#      REVISION:  ---
#===============================================================================


welcome() {
echo "\
##################################################### 
# ChemFlow - Computational Chemistry is great again #
#####################################################
"
}


initialize() {
export root=$PWD/ScoreFlow/MMGBSA_implicit/
cd $root
list=$(ls -d */ | cut -d/ -f1)
incomplete=""
ncomplete=0                    # Number of complete calculations
ncomplete_MMPBSA=0
ntotal=$(echo "$list" | wc -w)  # Number of ligands 

show_incomplete=false
submit=false
}

# Review user input and files
review() {
echo "review"
}

write_slurm() {
#===  FUNCTION  ================================================================
#          NAME: write_slurm
#   DESCRIPTION: Writes the SLURM script to for each ligand.
#                so far it is very specific for Myosin. 
#                Filenames and parameters are hardcoded.
#    PARAMETERS: $root ; $LIGAND ; GB5.in 
#       RETURNS: -
#===============================================================================
echo "#! /bin/bash
# 1 noeud 8 coeurs
#SBATCH -p publicgpu
##SBATCH -p public
#SBATCH --job-name=${LIGAND}
##SBATCH --sockets-per-node=1
##SBATCH --cores-per-socket=8
#SBATCH --ntasks=24
##SBATCH --gres=gpu:4
#SBATCH -t 1:00:00
##SBATCH --constraint=gpu1080

module load batch/slurm                        
module load compilers/intel15
module load libs/zlib-1.2.8
module load mpi/openmpi-1.8.3.i15             
module load compilers/cuda-8.0
module load languages/python-2.7.10
module load libs/mpi4py.python2.7.10-openmpi  

source $HOME/software/amber16_publicgpu/amber.sh

cd ${root}/${LIGAND} 

rm -rf com.top rec.top lig.top

ante-MMPBSA.py -p complex.prmtop -c com.top -r rec.top -l lig.top -n :MOL -s '!:1-793' --radii=mbondi2 &> ante_mmpbsa.job

mpirun -n 8 MMPBSA.py.MPI -O -i ${root}/GB5.in -cp com.top -rp rec.top -lp lig.top -o MMPBSA_MD.dat -eo MMPBSA_MD.csv -y md.mdcrd &> MMPBSA_MD.job  

"> mmpbsa.slurm
}


# Functions
check_completion() {
#===  FUNCTION  ================================================================
#          NAME: check completion
#   DESCRIPTION: 
#    PARAMETERS: $list ; regex and file names are hardcoded so far.
#       RETURNS: $incomplete - a list of incomplete folders.
#===============================================================================
for lig in $list ; do
  if [ -f ${lig}/md.mdout ] ; then 
    if [ "$(tail -1 ${lig}/md.mdout | awk '/hours/')" != "" ] ; then
      let ncomplete++
    fi
  fi

  if [ -f ${lig}/MMPBSA_MD.dat ] ; then
    if [ "$(awk '/DELTA TOTAL/' ${lig}/MMPBSA_MD.dat)" != "" ] ; then
      let ncompleteMMPBSA++
    fi
  else
    incomplete="${incomplete} ${lig}"
  fi
done

completion=$(echo "scale=1; 100*(${ncomplete}/${ntotal})" | bc)
completion_MMPBSA=$(echo "scale=1; 100*(${ncompleteMMPBSA}/${ntotal})" | bc)

echo "${completion}% MD complete" 
echo "${completion_MMPBSA}% MMPBSA complete" 
echo "Incomplete compounds: $incomplete" 

}


submit_incomplete() {
#===  FUNCTION  ================================================================
#          NAME: submit_incomplete
#   DESCRIPTION: Uses the list of incomplete folders to submit the MMPBSA
#    PARAMETERS: $incomplete 
#       RETURNS: -
#===============================================================================
list="$incomplete"
for LIGAND in $list ; do
  write_slurm
  sbatch mmpbsa.slurm
done
}


# Program -----------------------------------------------------------
welcome
initialize
check_completion

submit=1
if [ "${submit}" == 1 ] ; then submit_incomplete ; fi

