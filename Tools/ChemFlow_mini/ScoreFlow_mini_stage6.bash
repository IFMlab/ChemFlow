#!/bin/bash
#
# 
#
#


rundir=$PWD
DEBUG=1

#
# ScoreFlow stage 4 - Running the MD in GBSA in explicit solvent for 20ns.
#

ScoreFlow_ligand="DockFlow_TOP"
ScoreFlow_input="ScoreFlow/input"
ScoreFlow_output="ScoreFlow/MMGBSA_explicit"
ScoreFlow_parameters="ScoreFlow/parameters"

source $HOME/software/amber16/amber.sh



# Functions #########################################################

ScoreFlow_init() {
# List compounds, and check for parametrization.

# List compounds prioritized by docking
list=$(ls ${ScoreFlow_ligand}/ | cut -d. -f1 )       # MOL2 file
list=($list)
list_orig=${#list[@]}

# List compounds with successfull parametrization
parametrized=""
for i in ${list[@]} ; do
  if [ -f ${ScoreFlow_parameters}/${i}/lig_resp.mol2 ] ; then
    parametrized="${parametrized} ${i}"
  fi
done

# Count the number of ligands.
list=($parametrized)
list_max=${#list[@]}

echo "
 Prioritized compounds: ${list_orig}
Parametrized compounds: ${list_max}
"
}


ScoreFlow_prepare_explicit() {
# 1) Create folders
# 2) Copy input files for receptor, including extra frcmod for heteroatoms
# 3) Copy Ligand parameters
# 3) Write and run tleap

if [ "${DEBUG}" == 1 ] ; then echo -ne "\n[Creating folders and copying files]\n" ; fi


# Create folders and copy files ---------------------------
for i in ${list[@]} ; do 
  if [ "${DEBUG}" == 1 ] ; then echo -ne "[COPY Receptor etc] ${i}    \r" ; fi
  mkdir -p ${rundir}/${ScoreFlow_output}/${i}
  cp ${rundir}/${ScoreFlow_input}/* ${rundir}/${ScoreFlow_output}/${i}/ 
done

if [ "${DEBUG}" == 1 ] ; then echo -ne "\n[COPY Receptor] DONE \n" ; fi
# END - Create folders and copy files ---------------------


# Copy ligand parameters ----------------------------------
for i in ${list[@]} ; do
  if [ "${DEBUG}" == 1 ] ; then echo -ne "[COPY Ligand] ${i}    \r" ; fi
  cp ${rundir}/${ScoreFlow_parameters}/${i}/{lig_resp.mol2,lig.frcmod,lig.lib} ${rundir}/${ScoreFlow_output}/${i}/  
done
if [ "${DEBUG}" == 1 ] ; then echo -ne "\n[COPY Ligand] DONE \n" ; fi
# END - Copy ligand parameters ----------------------------


# Run tleap -----------------------------------------------
for i in ${list[@]} ; do
  if [ "${DEBUG}" == 1 ] ; then echo -ne "[TLEAP] ${i}    \r" ; fi
  cd ${rundir}/${ScoreFlow_output}/${i}
  ScoreFlow_write_run_tleap_explicit
#  ScoreFlow_MMGBSA_implicit_write_MIN  
#  ScoreFlow_MMGBSA_implicit_write_MD
done
if [ "${DEBUG}" == 1 ] ; then echo -ne "\n[TLEAP] DONE \n" ; fi
# end Run tleap -------------------------------------------

}



ScoreFlow_write_run_tleap_explicit() {
echo "
source oldff/leaprc.ff99SBildn
source leaprc.gaff

set default pbradii mbondi2 

ptn = loadpdb b4amber.pdb
saveamberparm ptn ptn.prmtop ptn.inpcrd
savePDB ptn ptn.pdb
charge ptn

# ATP -----------------------------------------------------
# Load ADP parameters 
loadAmberPrep   ADP.prep
loadAmberParams frcmod.phos

# Structure
adp = loadpdb adp_clean.pdb
saveAmberParm adp adp.prmtop adp.rst7
savePDB adp   adp_tleap.pdb

# Load Inorganic Phosphate (Pi) parameters 
loadOff PIH.lib
loadAmberParams PIH.frcmod

# Original coordinates with resp charges.
PIH = loadpdb pih_clean.pdb

saveAmberParm PIH PIH.prmtop PIH.rst7
savePDB PIH   PIH_tleap.pdb

# Mg2+ ----------------------------------------------------
# Load Mg2+ parameters
loadAmberPrep   magnesium.prep
loadAmberParams frcmod.magnesium

# Magnesium Structure
mg = loadpdb  mg.pdb
saveAmberParm mg mg.prmtop mg.rst7

# Ligand --------------------------------------------------
# Load ligand parameters
loadAmberParams lig.frcmod
lig = loadmol2  lig_bcc.mol2
saveamberparm lig lig.prmtop lig.inpcrd
savePDB lig lig.pdb
charge lig

complex = combine{ptn,adp,PIH,mg,lig}
saveamberparm complex complex.prmtop complex.rst7
savePDB complex complex.pdb
charge complex

# Add enough ions to neutralize
AddIons2 complex Cl- 0
AddIons2 complex Na+ 0

# Save protein with ions: topology and coordinates
saveamberparm complex ionized.prmtop ionized.rst7

# Solvate with at least 12 Angtron buffer region
solvateOct complex TIP3PBOX 12

# Save solvated complex: topology and coordinates
saveamberparm complex ionized_solvated.prmtop ionized_solvated.rst7
savePDB complex ionized_solvated.pdb

quit
" > tleap.in

tleap -f tleap.in &> tleap.job
}


ScoreFlow_MMGBSA_implicit_write_MIN() {
echo "MD GB2, infinite cut off
&cntrl
  imin=1,maxcyc=1000,
  irest=0,ntx=1,
  cut=9999.0, rgbmax=15.0,
  igb=2
! Frozen or restrained atoms
!----------------------------------------------------------------------
 ntr=1,
 restraintmask=':1-792@CA,C,N,O', 
 restraint_wt=1.0,
/
" > min_gbsa.in
}


ScoreFlow_MMGBSA_implicit_write_MD() {
echo "MD GB2, infinite cut off
&cntrl
  imin=0,irest=0,ntx=1,
  nstlim=500000,dt=0.002,ntb=0,
  ntf=2,ntc=2,
  ntpr=1000, ntwx=1000, ntwr=30000,
  cut=9999.0, rgbmax=15.0,
  igb=2,ntt=3,gamma_ln=1.0,nscm=0,
  temp0=300.0,
! Frozen or restrained atoms
!----------------------------------------------------------------------
! ibelly,
! bellymask,
 ntr=1,
 restraintmask=':1-792@CA,C,N,O', 
 restraint_wt=10.0,
/
" > md_gbsa.in
}


ScoreFlow_MMGBSA_implicit_write_slurm() {
echo "#! /bin/bash
# 1 noeud 8 coeurs
##SBATCH -p pri2015gpu
##SBATCH -A gpuisis
#SBATCH -p publicgpu
#SBATCH --job-name=${first}
#SBATCH --nodes=1                    # Use one node
#SBATCH --ntasks=4                   # Run a single task        
#SBATCH --cpus-per-task=1            # Number of CPU cores per task
#SBATCH --gres=gpu:4
#SBATCH -t 12:00:00
#SBATCH --constraint=gpu1080

module load batch/slurm                        
module load compilers/intel15
module load libs/zlib-1.2.8
module load mpi/openmpi-1.8.3.i15             
module load compilers/cuda-8.0
module load languages/python-2.7.10
module load libs/mpi4py.python2.7.10-openmpi  

source $HOME/software/amber16_publicgpu/amber.sh

pmemd_gpu() {
pmemd.cuda -O  \
-i \${input}.in    -o \${run}.mdout   -e   \${run}.mden   -r \${run}.rst7  \
-x \${run}.mdcrd   -v   \${run}.mdvel -inf \${run}.mdinfo -c \${prev}.rst7 \
-p \${init}.prmtop -ref \${prev}.rst7 &> \${run}.job&
}


init=complex
gpu=0
for ligand in ${list[@]:$first:$nlig} ; do

  cd ${rundir}/${ScoreFlow_output}/\${ligand}/
  export CUDA_VISIBLE_DEVICES=\${gpu}

  # Mini
  input=min_gbsa ; prev=complex ; run=mini ; pmemd_gpu
  let gpu++
done
wait

gpu=0
for ligand in ${list[@]:$first:$nlig} ; do
  cd ${rundir}/${ScoreFlow_output}/\${ligand}/
  export CUDA_VISIBLE_DEVICES=\${gpu}

  # MD
  input=md_gbsa   ; prev=mini    ; run=md  ; pmemd_gpu
  let gpu++
done
wait
" > job.slurm
}


ScoreFlow_MMGBSA_explicit_write_slurm() {
echo "#! /bin/bash
# 1 noeud 8 coeurs
##SBATCH -p pri2015gpu
##SBATCH -A gpuisis
#SBATCH -p publicgpu
#SBATCH --job-name=${first}
#SBATCH --nodes=1                    # Use one node
#SBATCH --ntasks=4                   # Run a single task        
#SBATCH --cpus-per-task=1            # Number of CPU cores per task
#SBATCH --gres=gpu:4
#SBATCH -t 24:00:00
##SBATCH --constraint=gpu1080

module load batch/slurm                        
module load compilers/intel15
module load libs/zlib-1.2.8
module load mpi/openmpi-1.8.3.i15             
module load compilers/cuda-8.0
module load languages/python-2.7.10
module load libs/mpi4py.python2.7.10-openmpi  

source $HOME/software/amber16_publicgpu/amber.sh

pmemd_cpu() {
pmemd -O  \
-i \${input}.in    -o \${run}.mdout   -e   \${run}.mden   -r \${run}.rst7  \
-x \${run}.mdcrd   -v   \${run}.mdvel -inf \${run}.mdinfo -c \${prev}.rst7 \
-p \${init}.prmtop -ref \${prev}.rst7 &> \${run}.job
}

pmemd_gpu() {
pmemd.cuda -O  \
-i \${input}.in    -o \${run}.mdout   -e   \${run}.mden   -r \${run}.rst7  \
-x \${run}.mdcrd   -v   \${run}.mdvel -inf \${run}.mdinfo -c \${prev}.rst7 \
-p \${init}.prmtop -ref \${prev}.rst7 &> \${run}.job
}


run_amber() {
init=ionized_solvated
prev=heat_npt
for run in density equil prod ; do
  input=${rundir}/amber_inputs/\${run}
  pmemd_gpu
  prev=\${run}
done
}

gpu=0
for ligand in ${list[@]:$first:$nlig} ; do
  export CUDA_VISIBLE_DEVICES=\${gpu}
  cd ${rundir}/${ScoreFlow_output}/\${ligand}/
  run_amber &
  let gpu++
done
wait
" > md.slurm
}



ScoreFlow_submit_explicit_slurm() {
first=0
nlig=4

cd ${rundir}

for (( first=0;${first}<=${list_max}; first=${first}+${nlig} )) ; do
  ScoreFlow_MMGBSA_explicit_write_slurm
  sbatch md.slurm
done
}




# Program ###########################################################
ScoreFlow_init
#ScoreFlow_prepare
#ScoreFlow_submit_slurm
#ScoreFlow_prepare_explicit
ScoreFlow_submit_explicit_slurm
