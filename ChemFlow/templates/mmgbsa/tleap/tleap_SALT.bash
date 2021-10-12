#!/bin/bash

tleap <<- EOF 
source leaprc.protein.ff14SB
source leaprc.water.tip3p
source leaprc.gaff2

set default PBradii mbondi2
#set default nocenter on

#PROTEIN -------------------------------------------------
ptn = loadpdb ../receptor.pdb
saveamberparm ptn ptn.prmtop ptn.rst7
savePDB ptn ptn.pdb
charge ptn

# Ligand --------------------------------------------------
# Load ligand parameters
loadAmberParams ligand.frcmod
ligand = loadmol2  ligand.mol2
saveamberparm ligand ligand.prmtop ligand.rst7
savePDB ligand ligand.pdb
charge ligand

#COMPLEX--------------------------------------------------
complex = combine{ptn,ligand}
saveamberparm complex complex.prmtop complex.rst7
savePDB complex complex.pdb
charge complex
 
# Add enough ions to neutralize
AddIons2 complex Cl- 0
AddIons2 complex Na+ 0

# Save ligand with ions: topology and coordinates
saveamberparm complex ionized.prmtop ionized.rst7

# Solvate with at least 14 Angstrom buffer region
solvateOct complex TIP3PBOX 14

# Save solvated complex: topology and coordinates
saveamberparm complex ionized_solvated.prmtop ionized_solvated.rst7
savePDB complex ionized_solvated.pdb
quit
EOF


WAT=$(cat ${RUNDIR}/${LIGAND}/ionized_solvated.prmtop | grep WAT | sed 's/ /\n/g' | grep WAT | wc -l)
nsalt=$(awk -v R=0.0187 -v C=0.15 -v WAT=$WAT 'BEGIN{print R*C*WAT}')
ncl=$(awk -v nsalt=$nsalt 'BEGIN{print int(nsalt)}')
nna=$(awk -v nsalt=$nsalt 'BEGIN{print int(nsalt)}')
echo $nna $ncl

tleap <<- EOF
source leaprc.protein.ff14SB
source leaprc.water.tip3p
source leaprc.gaff2

set default PBradii mbondi2
#set default nocenter on

#PROTEIN -------------------------------------------------
ptn = loadpdb ../receptor.pdb
saveamberparm ptn ptn.prmtop ptn.rst7
savePDB ptn ptn.pdb
charge ptn

# Ligand --------------------------------------------------
# Load ligand parameters
loadAmberParams ligand.frcmod
ligand = loadmol2  ligand.mol2
saveamberparm ligand ligand.prmtop ligand.rst7
savePDB ligand ligand.pdb
charge ligand

#COMPLEX--------------------------------------------------
complex = combine{ptn,ligand}
saveamberparm complex complex.prmtop complex.rst7
savePDB complex complex.pdb
charge complex


# Add enough ions to neutralize
AddIons2 complex Cl- 0
AddIons2 complex Na+ 0

# Add enough ions to put the concentration high
AddIons2 complex Cl- ${ncl}
AddIons2 complex Na+ ${nna}

# Save ligand with ions: topology and coordinates
saveamberparm complex ionized_SALT.prmtop ionized_SALT.rst7

# Solvate with at least 14 Angstrom buffer region
solvateOct complex TIP3PBOX 14

# Save solvated complex with salt: topology and coordinates
saveamberparm complex ionized_solvated_SALT.prmtop ionized_solvated_SALT.rst7
savePDB complex ionized_solvated_SALT.pdb
quit
EOF
