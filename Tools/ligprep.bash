#!/bin/bash

#######################################################################
################### Script for ligand preparation #####################
#######################################################################
# This script will prepare docking poses mol2 files using gaff 
# and either RESP, AM1-BCC or Gasteiger for charges.
# Total charges need to be already known for each ligand, and put in a
# csv file : charges.csv
# The structure of the file should be as follow : ligand_name,charge,comment
# One can use MarvinSketch Protonation state tools for charge prediction.
# The script will then submit the job through qsub.
#######################################################################
# User input
#######################################################################

# set absolute path to the directory containing the desired docking poses.
# Hint: if you used DockFlow and/or ChemFlowTools, this should be the 
# "VS" or "lig_selection" folder.
path="${PWD}/output/lig_selection"

# Use gasteiger charges : gas
# Use am1-bcc charges : bcc
# Use Resp charges : resp
charge_method="bcc"

#######################################################################
# Program
#######################################################################

RED="\e[31m" 
BLUE="\e[34m" 
NC="\033[0m"

user=$(whoami)

# Deprecated
prepare_ligand() {
if [ "${charge_method}" = "bcc" ]; then

mkdir -p temp

# Copy necessary files to scratch disk and go there
cd $path/$ligand/docking
cp ${pose}.mol2 temp/lig.mol2
cd temp

# Run ligand preparation
antechamber -i lig.mol2 -fi mol2 -o ${pose}.mol2 -fo mol2 -at gaff -c ${charge_method} -s 2 -rn MOL -pf y 
parmchk2    -i ${pose}.mol2 -f  mol2 -o ${pose}.frcmod

echo "source leaprc.gaff
loadAmberParams ${pose}.frcmod
MOL = loadMol2 ${pose}.mol2
saveOff MOL ${pose}.lib
quit
" > tleap_lig.in
tleap -f tleap_lig.in

# Copy back all necessary files and delete scratch
mv ${pose}.lib ${pose}.frcmod $path/$ligand/docking/
rm -rf temp


elif [ "${charge_method}" = "resp" ]; then
  # MOL2 to Gaussian (GAFF atom types)
  antechamber -i ${ligand}_*.mol2 -fi mol2 -o lig.gau -eq 2 -at gaff -rn MOL -nc ${charge} \
              -fo gcrt -gv 1 -ge lig.gesp -gm "%mem=8GB" -gn "%nproc=8"
  
  # Run Gaussian to optimize structure and generate electrostatic potential grid
  g09 lig.gau
  
  # Read Gaussian output and write new optimized ligand with RESP charges
  antechamber -i lig.log  -fi gout -o lig_opt.mol2 -fo mol2  -c resp -s 2 -rn MOL -at gaff -nc ${charge}
  
  # Read optimized Gaussian output and write frcmod 
  parmchk -i lig_opt.mol2 -f mol2 -o lig.frcmod

else
  echo -e "${RED}ERROR${NC} : Charge method not recognized or empty."
  exit 1
fi
}

write_pbs() { # Write the job
echo "
#!/bin/bash
#PBS -V
#PBS -l  nodes=1:ppn=1
#PBS -l  walltime=08:00:00
#PBS -N  ${pose}
#PBS -o  ${dir}/${pose}.o
#PBS -e  ${dir}/${pose}.e

# AMBER Paths
source /home/dgomes/software/amber16/amber.sh

# Make temporary dir at Scratch disk and go there
scratch=/scratch/${user}/${pose}
mkdir -p \${scratch}

# Copy necessary files to scratch disk and go there
cd $path/$ligand/docking
cp ${pose}.mol2 \${scratch}/lig.mol2
cd \${scratch}

# Run ligand preparation
antechamber -i lig.mol2 -fi mol2 -o ${pose}.mol2 -fo mol2 -at gaff -c ${charge_method} -s 2 -rn MOL -pf y 
parmchk2    -i ${pose}.mol2 -f  mol2 -o ${pose}.frcmod

echo \"source leaprc.gaff
loadAmberParams ${pose}.frcmod
MOL = loadMol2 ${pose}.mol2
saveOff MOL ${pose}.lib
quit
\" > tleap_lig.in
tleap -f tleap_lig.in

# Copy back all necessary files and delete scratch
mv ${pose}.lib ${pose}.frcmod $path/$ligand/docking/
rm -rf \${scratch}

" > pbs_scripts/${pose}.qsub
}

write_pbs_converge() { # Write the job
echo "
#!/bin/bash
#PBS -V
#PBS -l  nodes=1:ppn=1
#PBS -l  walltime=08:00:00
#PBS -N  ${pose}
#PBS -o  ${dir}/${pose}.o
#PBS -e  ${dir}/${pose}.e

# AMBER Paths
source /home/dgomes/software/amber16/amber.sh

# Make temporary dir at Scratch disk and go there
scratch=/scratch/${user}/${pose}
mkdir -p \${scratch}

# Copy necessary files to scratch disk and go there
cd $path/$ligand/docking
cp ${pose}.mol2 \${scratch}/lig.mol2
cd \${scratch}

# Run ligand preparation
antechamber -i lig.mol2 -fi mol2 -o ${pose}.mol2 -fo mol2 -at gaff -c ${charge_method} -s 2 -rn MOL -pf y -pl 30
parmchk2    -i ${pose}.mol2 -f  mol2 -o ${pose}.frcmod

echo \"source leaprc.gaff
loadAmberParams ${pose}.frcmod
MOL = loadMol2 ${pose}.mol2
saveOff MOL ${pose}.lib
quit
\" > tleap_lig.in
tleap -f tleap_lig.in

# Copy back all necessary files and delete scratch
mv ${pose}.lib ${pose}.frcmod $path/$ligand/docking/
rm -rf \${scratch}

" > pbs_scripts/${pose}.qsub
}


# 1 - List of ligands
lig_list=$(cd $path; \ls -ld * | grep "^d" | awk '{print $9}')

# 2 - Create a directory containing PBS scripts
mkdir -p pbs_scripts

# 3 - Loop through each ligand and do stuff
for ligand in ${lig_list} ; do
  
  dir="$path/$ligand/lig_prepared"
  mkdir -p $dir

  # 4 - Search for the ligand's charge
  #charge=$(awk -F, -v lig="${ligand}" '$0 ~ lig "," {print $2}' charges.csv)

  # 5 - Run
  pose_list=$(cd $path/$ligand/docking; ls *.mol2 | sed s/.mol2//g)
  for pose in $pose_list; do
    write_pbs_converge
    jobid=$(qsub pbs_scripts/${pose}.qsub)
    echo -ne "Processing docking pose ${BLUE}${pose}${NC} on ${RED}${jobid}${NC}              \r"
  done
done
echo ""
echo "All jobs submitted"
