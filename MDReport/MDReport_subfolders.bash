#!/bin/bash
#
# Copyright (c) 2017 Diego Gomes and Marco Cecchini
# 
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#  
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#  
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#

#
# How to use:
# Step 1 - Change what's necessary in the configuration below 
# Step 2 - Run this at "summary" folder
# Step 3 - Smile
#
# Configuration -----------------------------------------------------
#

# Source "amber.sh". 
  source /home/dgomes/software/amber16/amber.sh

# Where are the simulations? 
  basedir=$PWD

# List of protein names
  folder_list="fp2 fp3"

# List of variables
  subfolder_list="apo v1b v5b et2b et4c"


# WARNING! - ATTENTION ! - ACHTUNG ! ATENCAO! - ATENCION !
#
# Do not change anything below unless you know what you're doing.
# Ne modifiez rien ci-dessous, sauf si vous savez ce que vous faites.
# Ändern Sie nichts unter, wenn Sie nicht wissen, was Sie tun.
# Nao modifique nada abaixo, salvo se voce sabe o que faz.
# No cambie nada abajo a menos que sepa lo que está haciendo.
# 
# WARNING! - ATTENTION ! - ACHTUNG ! ATENCAO! - ATENCION !



# Functions ---------------------------------------------------------
#bash colors 
RED="\e[31m" 
GREEN="\e[32m" 
MAGENTA="\e[35m"
BLUE="\e[34m" 
YELLOW="\e[33m"
CYAN="\033[0;36m"
LIGHT_CYAN="\033[1;36m"
NO_COLOUR="\033[0m"

welcome() {
echo -e "
    ${MAGENTA}MD Report v0.5 - Copyright 2017${NO_COLOUR}
  Molecular Dynamics Simulation Report

             Developed by
 Priscila SFC Gomes(1), Nicolas Martin(2) 
Marco Cecchini(2), Diego E. B. Gomes(1,2,3)
---------------------------------------------
"
}

list_folders() {
echo -e "${BLUE}Current simulations:${NO_COLOUR}\n${folder_list}\n"
echo -e "${BLUE}Current temperatures:${NO_COLOUR}\n${subfolder_list}\n"
}



check_status_subfolder() {
# Shows the last run part (it may not be complete).
for folder in ${folder_list} ; do
  for subfolder in ${subfolder_list} ; do
    cd ${basedir}/${folder}/${subfolder}/
 
    i=0
    for j in $(ls prod.*.mdinfo) ; do
      let i=${i}+1
    done
  
    echo -e "prod.${i}\t- ${folder} - ${subfolder}"
  done
done
}



make_summary_subfolder() {
cd  ${basedir}
if [ ! -d "summary" ] ; then mkdir summary ; fi

for folder in ${folder_list} ; do
  for subfolder in ${subfolder_list} ; do
    cd ${basedir}/${folder}/${subfolder}
    i=0
    for j in $(ls prod.*.mdinfo) ; do
      let i=${i}+1
    done

echo -e "# create sample trajectory
parm      ionized_solvated.prmtop
reference ionized_solvated.rst7
$(for j in $(seq ${i}) ; do
  echo "trajin prod.${j}.nc"
  done)
strip :WAT,Na+,Cl-
trajout ../../summary/${folder}_${subfolder}.nc
go
quit
" > sample.cpptraj

echo -e "# create topology with complex
parm       ionized_solvated.prmtop
loadRestrt ionized_solvated.rst7
strip :WAT,Na+,Cl-
parmout          ../../summary/${folder}_${subfolder}.prmtop
writeCoordinates ../../summary/${folder}_${subfolder}.rst7
outPDB           ../../summary/${folder}_${subfolder}.pdb
go
quit" > sample.parmed
  echo -e "prod.${i}\t- ${folder} - ${subfolder}"
  cpptraj -i sample.cpptraj
  parmed  -i sample.parmed

  done
done
}


welcome
list_folders
check_status_subfolder
make_summary_subfolder

