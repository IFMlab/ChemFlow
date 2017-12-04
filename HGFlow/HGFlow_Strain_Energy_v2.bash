#!/bin/bash
##################################################################### 
#   HGFlow  -  ChemFlow: Computational Chemistry is great again     #
#####################################################################
#
# Diego E. B. Gomes(1,2,3) - dgomes@pq.cnpq.br
# Paulina Pacack (3,4)     - ppacak@unistra.fr
# Marco Cecchini (3)       - cecchini@unistra.fr
#
# 1 - Instituto Nacional de Metrologia, Qualidade e Tecnologia - Brazil
# 2 - Coordenacao Aperfeicoamento de Pessoal de Ensino Superior - CAPES - Brazil.
# 3 - Universite de Strasbourg - France
# 4 - Novartis Institutes for BioMedical Research, Basel - Switzerland
#
#===============================================================================
#
#          FILE:  HGFlow_Strain_Energy.bash
#
#         USAGE:  ./HGFlow_Strain_Energy.bash 
#
#   DESCRIPTION: Computes the strain energy of the guest to a host.
#                1) Minimizes the COMPLEX.
#                2) Minimizes the HOST.
#                The strain energy will be the difference between the
#                first (single point) and last steps of minimization.
#
#                The strain energy is computed both for VACUUM and GBSA (igb=1).
#
#       OPTIONS:  ---
#  REQUIREMENTS:  AmberTools17, Amber16
#          BUGS:  ---
#         NOTES:  ---
#        AUTHOR:  Diego E. B. Gomes, dgomes@pq.cnpq.br
#       COMPANY:  Universite de Strasbourg / INMETRO / CAPES
#       VERSION:  1.0
#       CREATED:  Thu Nov 30 14:09:40 CET 2017
#      REVISION:  ---
#===============================================================================

# 
# Instructions ----------------------------------------------------------------
#
# This script should be used following HGFlow standards.
# Refer to the documentation appropriate file naming and directory structure.
# 


# Configuration ---------------------------------------------------------------

# Source amber variables
source $HOME/software/amber16/amber.sh

# List with names of all system folders
system_list=$(ls -d */ | cut -d/ -f1)




# Functions -------------------------------------------------------------------
echo '
&cntrl
! General flags
!----------------------------------------------------------------------
 imin=1,          ! (0 = molecular dynamics, 1 = energy minimization)

! Energy Minimization
!----------------------------------------------------------------------
 maxcyc=50000,
 ncyc=2000, !(RTFM)
 ntmin=1,   !(0 full, 1 SD then CG after ncyc . RTFM) 
 dx0=0.01,  !default
 drms=0.01  ! (default=1E-04)

! Nature and format of the input
!----------------------------------------------------------------------
! irest=0,         ! restart md (0 no, 1 yes)
! ntx=0,           ! coordinates & velocities (0 = coor only, 5 = restart MD)
!
! Run control options
!----------------------------------------------------------------------
  cut=12.0,        !

! Constraints
!----------------------------------------------------------------------
 ntc=1,            ! (1 = no shake ; SHAKE 2 = bonds involving hydrogen)
 ntf=1,            ! (1 = no shake ; 2 = bond inter involving H-atoms omitted SHAKE)

! Ensemble & Barostat
!----------------------------------------------------------------------
 ntb=1,            ! (PBC for constant 1 = VOLUME 2 = PRESSURE) 

!Nature and format of the output 
!----------------------------------------------------------------------
 ntxo=2,           ! Write Final coor, vel & box to "restr" as (1 ASCII, 2 NetCDF)
 ntwe=100,
 ioutfm=1,         ! Format of coor, vel & traj files (0 ASCII, 1 NetCDF)
/
end
' > min.in

echo '
&cntrl
! General flags
!----------------------------------------------------------------------
 imin=1,          ! (0 = molecular dynamics, 1 = energy minimization)

! Energy Minimization
!----------------------------------------------------------------------
 maxcyc=50000,
 ncyc=2000, !(RTFM)
 ntmin=1,   !(0 full, 1 SD then CG after ncyc . RTFM) 
 dx0=0.01,  !default
 drms=0.01  ! (default=1E-04)

! Nature and format of the input
!----------------------------------------------------------------------
! irest=0,         ! restart md (0 no, 1 yes)
! ntx=0,           ! coordinates & velocities (0 = coor only, 5 = restart MD)
!
! Run control options
!----------------------------------------------------------------------
  cut=12.0,        !
  igb=1

! Constraints
!----------------------------------------------------------------------
 ntc=1,            ! (1 = no shake ; SHAKE 2 = bonds involving hydrogen)
 ntf=1,            ! (1 = no shake ; 2 = bond inter involving H-atoms omitted SHAKE)

! Ensemble & Barostat
!----------------------------------------------------------------------
 ntb=0,            ! (PBC for constant 1 = VOLUME 2 = PRESSURE) 

!Nature and format of the output 
!----------------------------------------------------------------------
 ntxo=2,           ! Write Final coor, vel & box to "restr" as (1 ASCII, 2 NetCDF)
 ntwe=100,
 ioutfm=1,         ! Format of coor, vel & traj files (0 ASCII, 1 NetCDF)
/
end
' > min_gbsa.in


pmemd_cpu() {
pmemd -O -i ../${mdin}.in -p ${top}.prmtop -c ${coor}.rst7 \
         -o ${run}.mdout  -r ${run}.rst7   -x ${run}.nc -e ${run}.mden
}

cleanup() {
rm -rf com.rst7 com.prmtop host.prmtop host.rst7 host_gbsa.rst7
}


compute_strain_energy(){

# Initialize ------------------------------------------------------------------
# Extract complex.
parmed -p complex_box.prmtop -c prod.rst7 <<EOF
strip :WAT,Na+,Cl-
parmout com.prmtop
writeCoordinates com.rst7
EOF


# PART 1 - Vacuum -----------------------------------------
mdin="min"      # Input for minimization

# Complex - Minimization
top="com"       # Complex topology
coor="com"      # Initial complex coordinates
run="min_com"   # Name for this run
pmemd_cpu       # Run Minimization

# Host - Extract
parmed -p com.prmtop -c min_com.rst7 <<EOF
strip :2
parmout host.prmtop
writeCoordinates host.rst7 netcdf
EOF

# Host - Minimization
top="host"      # Host topology
coor="host"     # Host coordinates, from minimized complex
run="min_host"  # Name for this run
pmemd_cpu       # Run Minimization


# PART 2 - GBSA -------------------------------------------
mdin="min_gbsa"

# COMPLEX - Minimization
top="com" ; coor="com" ; run="min_gbsa_com"
pmemd_cpu

# HOST
# Extract host.
parmed -p com.prmtop -c min_gbsa_com.rst7 <<EOF
strip :2
parmout host.prmtop
writeCoordinates host_gbsa.rst7 netcdf
EOF

top="host"  ; coor="host_gbsa" ; run="min_gbsa_host"
pmemd_cpu

}


# COPY FILES HERE - THIS WAS VERY SPECIFIC TO ME
workdir=$PWD

copy_CB7_CXX() {
for i in $(seq -w 14) ; do
  echo "CB7-C$i"
  cd ${workdir}
  if [ ! -d CB7-C${i} ] ; then mkdir CB7-C${i} ; fi
  cd CB7-C${i}
  cp /data/dgomes/toy_systems/complex-sampl4/CB7-C${i}/solution/complex/{complex_box.prmtop,prod.rst7} .
done
}

copy_OAH_OXX() {
for i in $(seq -w 09) ; do
  echo "OAH-O${i}"
  cd ${workdir}
  if [ ! -d OAH-O${i} ] ; then mkdir OAH-O${i} ; fi
  cd OAH-O${i}
  cp /data/dgomes/toy_systems/complex-sampl4/OAH_charged/OAH-O${i}/solution/complex/{complex_box.prmtop,prod.rst7} .
done
}

#copy_CB7_CXX
#copy_OAH_OXX

for system in ${system_list} ; do
  cd ${workdir}/${system}
  compute_strain_energy  
done
