#!/bin/bash
#
# ChemFlow - Computational Chemistry is great again.
#
# Template to run MM-GBSA with amber for Myosin II from Dictyo.
#  

# Configuration 
# Load some stuff to use Amber16 with cuda --------------------------
source $HOME/software/amber16/amber.sh
export CUDA_HOME=/usr/local/cuda-8.0
export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:/usr/local/cuda-8.0/lib64/
export CUDA_VISIBLE_DEVICES=0



# Functions ---------------------------------------------------------

prepare() {
# Step 1 - Prepare the input files ----------------------------------
tleap -f tleap_gbsa.in &> tleap.lob

}

run_mini() {
# Step 2 - Run Energy minimization ----------------------------------
# config
 init="complex"
input="min_gbsa"
  run="min_gbsa"
 prev="complex"

# run
run_amber
}


run_md() {
# Step 3 - Also run a short MD --------------------------------------
# config
 init="complex"
input="md_gbsa"
  run="md_gbsa"
 prev="min_gbsa"
# run
run_amber
}


# Amber -------------------------------------------------------------
run_amber() {
pmemd.cuda -O \
-i   ${input}.in \
-c   ${prev}.rst7 \
-p   ${init}.prmtop \
-o   ${run}.mdout \
-e   ${run}.mden \
-r   ${run}.rst7  \
-x   ${run}.nc \
-v   ${run}.mdvel \
-inf ${run}.mdinfo \
-ref ${prev}.rst7 &> ${input}.log
}


ScoreFlow_MMGBSA_write() {
echo "Input file for running GB2
&general
   verbose=1,keep_files=0,interval=10
/
&gb
  igb=2, saltcon=0.150
/
" >GB2.in
}


ScoreFlow_MMGBSA_run_MIN() {
if [ ! -f MMPBSA_MINI.dat ] || [ "${OVERWRITE}" == 'yes' ] ; then
echo "[ ScoreFlow ] MMGBSA - MINI"
rm -rf com.top rec.top lig.top
ante-MMPBSA.py -p complex.prmtop -c com.top -r rec.top -l lig.top -n :MOL -s ':WAT,Na+,Cl-' --radii=mbondi2 &> ante_mmpbsa.job
MMPBSA.py -O -i GB2.in -cp com.top -rp rec.top -lp lig.top -o MMPBSA_MINI.dat -eo MMPBSA_MINI.csv -y min_gbsa.rst7 &> MMPBSA_MINI.job
rm -rf reference.frc
fi
}


ScoreFlow_MMGBSA_run_MD() {
if [ ! -f MMPBSA_MD.dat ] || [ "${OVERWRITE}" == 'yes' ] ; then
echo "[ ScoreFlow ] MMGBSA MD"
rm -rf com.top rec.top lig.top
ante-MMPBSA.py -p complex.prmtop -c com.top -r rec.top -l lig.top -n :MOL -s ':WAT,Na+,Cl-' --radii=mbondi2 &> ante_mmpbsa.job

mpirun -n 8 MMPBSA.py.MPI -O -i GB2.in -cp com.top -rp rec.top -lp lig.top -o MMPBSA_MD.dat -eo MMPBSA_MD.csv -y md_gbsa.nc &> MMPBSA_MD.job

rm -rf reference.frc
fi
}



# The actual program ------------------------------------------------
prepare 
run_mini 
run_md
ScoreFlow_MMGBSA_write
ScoreFlow_MMGBSA_run_MIN
ScoreFlow_MMGBSA_run_MD

