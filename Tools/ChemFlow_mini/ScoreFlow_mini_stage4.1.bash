#!/bin/bash
# Add this to step 4, I forgot it.

source $HOME/software/amber16/amber.sh

rundir=$PWD
DEBUG=1

#ScoreFlow_ligand="DockFlow_TOP"
#ScoreFlow_input="ScoreFlow/input"
ScoreFlow_input="ScoreFlow/MMGBSA_implicit"
ScoreFlow_output="ScoreFlow/MMGBSA_explicit"
ScoreFlow_parameters="ScoreFlow/parameters"


###########################################################

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

write_top() {
echo "
source leaprc.gaff
data = loadmol2 lig_resp.mol2
check data
loadamberparams lig.frcmod
saveoff data lig.lib 
saveamberparm data lig.prmtop lig.inpcrd      
quit" >tleap.in
tleap -f tleap.in &>tleap.log
}

# Fix this to Match STAGE1 standards
get_resp_charges() {
# Read Gaussian output and write new optimized ligand with RESP charges
antechamber -i lig.log -fi gout -o lig_resp.mol2 -fo mol2 -c resp -s 2 -rn MOL -pf y

# Write RESP charges to initial coordinates
awk '/1 MOL/ {print $9}' lig_resp.mol2 >charges.dat
antechamber -i lig.mol2 -o lig_resp.mol2 -rn MOL -fi mol2 -fo mol2 -cf charges.dat -c rc -dr no
}




# Program -------------------------------------------------
ScoreFlow_init_stage4
list=${resp_list}
for mol in $list ; do
  cd ${rundir}/${ScoreFlow_parameters}/${mol}
  #get_resp_charges
  write_top
done
