#!/bin/bash
#
# ChemFlow - Computational Chemistry is great again
#
# ScoreFlow - benchmark for multiple complexes
#
# This is an exclusive PORT of ScoreFlow for running locally.
# It should not be included in the official ChemFlow distribution.
# 
#
# For the Bioinformatics 2018 we'll demonstrate DockFlow and ScoreFlow for at least 100 protein-ligand complexes.
## This dataset was obtained from Didier Rognan, and used many times, noticeably in Kellenberber2004.
## Protein and ligand structures were carefully prepared using Sybyl
#* I'm concerned about protonation states since I noticed ASP25 of HIV-1 protease (1aaq) are not properly protonated.
#* However, I double checked with Schrodinger Maestro 2018.1, which uses PropKa and sidechain flips, and it's optimized protonation suggests the same state as Sybyl.
#
# The structure database used as input, is like that:
#DATASET/${receptor}
#where ${receptor} is the PDBid
#
# The DATASET folder is this, and do
# /home/dgomes/Desktop/DockFlow_Kellemberger_Benchmark/docking/
#
# It contains the folder with the complexes and two information files:
# | File | Description |
# | description100cplx.txt| Description of pdb, resolution, name, etc
# | docking.lst | List of PDB names to dock (same as folders)
#
#
#* Each PDB name designates a single folder that contains:
#| File | Description | 
#| ligandX.mol2 | Ligand from crystal structure |
#| ligandr.mol2 | Ligand with randomized dihedrals | 
#|  protein.pdb | Protein structure from PDB |
#| protein.mol2 | Protein prepared with Sybyl |
#|     site.pdb | Binding site |

# Top comply with ChemFlow standards we should keep the proposed structure:
#
# [NOT NOW] For portability we'll create a folder with all the original files.
# [NOT NOW] ${project}.chemflow/original/${receptor}/${ligand}/
#
# Runtime will be organized as bellow:
# ${project}.chemflow/${ChemFlow_module}/${protocol}/${receptor}/${ligand}/
#
#
# DESCRIPTION
# This ScoreFlow port will:
# 1 - Organize files to ChemFlow Standard
 


#-----------------------------------------------------------------------
# Configuration
# ----------------------------------------------------------------------

# Working directory
     workdir=$PWD
     project=benchmark  # your choice
      action=rescore    # "rescore" instead of ScoreFlow 
    protocol=md         # vina, plants, gbsa, md_gbsa, md

input_folder="${PWD}/docking/"
 folder_list=$(cat ${input_folder}/docking.lst)

# Configure Amber16
source /home/dgomes/software/amber16/amber.sh
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/cuda-8.0/lib64


# Advanced control
#OVERWRITE_parameters='yes' 
#  OVERWRITE_min_gbsa='yes'
#   OVERWRITE_md_gbsa='yes'




# Functions ------------------------------------------------------------
ScoreFlow_init() {
# 1 - Create folders
# 2 - Copy input files
   
for receptor in ${folder_list} ; do
    run_folder=${workdir}/${project}.chemflow/${action}/${protocol}/${receptor}/      

    if [ ! -f ${run_folder} ] ; then
        mkdir -p ${run_folder}             
    fi

done       
}

#
# PLANTS ---------------------------------------------------------------
#
# Plants works fine with multi-mol2 files.
#
ScoreFlow_plants() {

    ScoreFlow_prepare_plants() {
    
        run_folder=${workdir}/${project}.chemflow/${action}/${protocol}/${receptor}/      
        cd ${run_folder}
   
        if [ ! -f receptor.mol2 ] || [ ! -f ligand.mol2 ] ; then
            echo "Preparing ${receptor}"
  
            if [ -z ${USE_SPORES} ] ; then 
                cp ${input_folder}/${receptor}/protein.mol2 receptor.mol2
                cp ${input_folder}/${receptor}/ligandX.mol2 ligand.mol2

            else
                SPORES_64bit --mode reprot ${input_folder}/${receptor}/protein.mol2 receptor.mol2 &> spores_receptor.log
                SPORES_64bit --mode reprot ${input_folder}/${receptor}/ligandX.mol2 ligand.mol2   &> spores_ligand.log
            fi
    
        else
            echo "${receptor} already prepared"
        fi

    }

    ScoreFlow_run_plants() {
  
   
        run_folder=${workdir}/${project}.chemflow/${action}/${protocol}/${receptor}/        
        cd ${run_folder}

        if [ ! -f plants.log ] ; then
            echo "Running ${receptor}"
            
            ScoreFlow_write_plants_input
    
            PLANTS1.2_64bit --mode rescore dock_input.in &> plants.log
        else
            echo "${receptor} already rescored"
        fi
    }

    ScoreFlow_write_plants_input() {

binding_center=$(awk '/@<TRIPOS>ATOM/{flag=1;next}/@<TRIPOS>BOND/{flag=0}flag{NAT++; x+=$3; y+=$4; z+=$5}END{print x/NAT, y/NAT, z/NAT}' ligand.mol2 )

echo "
# input files
protein_file receptor.mol2
ligand_file  ligand.mol2
# output directory
output_dir docking
# scoring function and search settings
scoring_function chemplp
search_speed speed1
# write single mol2 files (e.g. for RMSD calculation)
write_multi_mol2 1
# binding site definition
bindingsite_center ${binding_center}
bindingsite_radius 25.0
" > dock_input.in

    }


i=0; waitevery=8; 
for receptor in ${folder_list} ; do 
    ScoreFlow_prepare_plants &
    (( i++%waitevery==0 )) && wait;
done
wait


i=0; waitevery=8; 
for receptor in ${folder_list} ; do 
    ScoreFlow_run_plants &
    (( i++%waitevery==0 )) && wait;
done
wait

}

#
# END OF PLANTS
#

#
# VINA
# Is a painfull, need to convert to pdbqt all the time.
ScoreFlow_vina() {
    ScoreFlow_prepare_vina() {

        run_folder=${workdir}/${project}.chemflow/${action}/${protocol}/${receptor}/      
        cd ${run_folder}
   
        if [ ! -f receptor.pdbqt ] || [ ! -f ligand.pdbqt ] ; then
            echo "Preparing ${receptor}"
            cp ${input_folder}/${receptor}/protein.mol2 receptor.mol2
            cp ${input_folder}/${receptor}/ligandX.mol2 ligand.mol2
            
            prepare_receptor4.py -r receptor.mol2 -o receptor.pdbqt
            prepare_ligand4.py   -l ligand.mol2  -o ligand.pdbqt
        else
            echo "${receptor} already prepared"
        fi
    }

    ScoreFlow_run_vina() {
        run_folder=${workdir}/${project}.chemflow/${action}/${protocol}/${receptor}/      
        cd ${run_folder}
        
        ScoreFlow_write_vina_input
        
        vina --score_only --config dock_input.in &> vina.log

    }

    ScoreFlow_write_vina_input() {
    # Transform into array
    binding_center=$(awk '/@<TRIPOS>ATOM/{flag=1;next}/@<TRIPOS>BOND/{flag=0}flag{NAT++; x+=$3; y+=$4; z+=$5}END{print x/NAT, y/NAT, z/NAT}' ligand.mol2 )
    binding_center=($(echo $binding_center))

echo "
receptor = receptor.pdbqt
ligand   = ligand.pdbqt

center_x = ${binding_center[0]}
center_y = ${binding_center[1]}
center_z = ${binding_center[2]}

size_x = 25
size_y = 25
size_z = 25

cpu = 1
" > dock_input.in
}


i=0; waitevery=8; 
for receptor in ${folder_list} ; do 
    ScoreFlow_prepare_vina &
    (( i++%waitevery==0 )) && wait;
done
wait


i=0; waitevery=8; 
for receptor in ${folder_list} ; do 
    ScoreFlow_run_vina &
    (( i++%waitevery==0 )) && wait;
done
wait
    
}
#
# END of VINA
#


#
# AmberTools MMGBSA
# 
ScoreFlow_gbsa() {
    ScoreFlow_prepare_gbsa() {

        run_folder=${workdir}/${project}.chemflow/${action}/${protocol}/${receptor}/ 
        cd ${run_folder}
   
        if [ ! -f receptor_b4amber.pdb ] || [ ! -f ligand_bcc.mol2 ] || [ "${OVERWRITE_parameters}" == 'yes' ]  ; then
            echo "Preparing ${receptor}"
            cp ${input_folder}/${receptor}/protein.pdb protein.pdb
            cp ${input_folder}/${receptor}/ligandX.mol2 ligand.mol2
            
            pdb4amber -i protein.pdb -o receptor_b4amber.pdb --reduce --add-missing-atoms --prot 
            antechamber -i ligand.mol2 -o ligand_bcc.mol2 -c bcc -eq 2 -s 2 -fi mol2 -fo mol2 -at gaff2 -dr no -rn MOL
            parmchk2 -i ligand_bcc.mol2 -o ligand.frcmod -f mol2
        else
            echo "${receptor} already prepared"
        fi
    }
    
    ScoreFlow_gbsa_tleap() {
        run_folder=${workdir}/${project}.chemflow/${action}/${protocol}/${receptor}/ 
        cd ${run_folder}
        
        if [ -f ligand_bcc.mol2 ] && [ ! -f complex.prmtop ] ; then
      
echo "#tleap
source leaprc.protein.ff14SB
source leaprc.water.tip3p
source leaprc.gaff2

receptor = loadpdb receptor_b4amber.pdb

set default PBradii mbondi2
set default nocenter on
saveAmberParm receptor receptor.prmtop receptor.rst7
savePDB receptor receptor.pdb

loadAmberParams ligand.frcmod
ligand = loadmol2 ligand_bcc.mol2

set default PBradii mbondi2
set default nocenter on
saveAmberParm ligand ligand.prmtop ligand.rst7
savePDB ligand ligand.pdb

complex = combine {receptor,ligand}
saveAmberParm complex complex.prmtop complex.rst7
savePDB complex complex.pdb

quit " >tleap.in

            tleap -f tleap.in
        
        fi
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
 restraintmask='@CA,C,N,O & !:MOL', 
 restraint_wt=1.0,
/
" > min_gbsa.in
    }


    ScoreFlow_MMGBSA_implicit_write_MD() {
echo "MD GB2, infinite cut off
&cntrl
  imin=0,irest=0,ntx=1,
  nstlim=50000,dt=0.002,ntb=0,
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
 restraintmask='@CA,C,N,O & !:MOL', 
 restraint_wt=10.0,
/
" > md_gbsa.in
    }

    ScoreFlow_run_gbsa_min() {
        run_folder=${workdir}/${project}.chemflow/${action}/${protocol}/${receptor}/ 
        cd ${run_folder}
        
        if [ ! -f min_gbsa.rst7 ] || [ "${OVERWRITE_min_gbsa}" == 'yes' ] ; then 
                
            if [ -f complex.rst7 ] ; then 
                echo "[ Run - MIN - GBSA ] ${receptor}"

                ScoreFlow_MMGBSA_implicit_write_MIN
                    
                input="min_gbsa"
                init="complex"
                prev="complex"
                run="min_gbsa"
                    
                pmemd.cuda -O \
                -i   ${input}.in  -o ${run}.mdout -e ${run}.mden  -r ${run}.rst7 \
                -x   ${run}.nc    -v ${run}.mdvel -c ${prev}.rst7 -p ${init}.prmtop \
                -ref ${prev}.rst7 -inf ${run}.mdinfo 
            else
              echo "[ Skip ] ${receptor}"
            fi
        else
            echo "[ Run - MIN - GBSA ] ${receptor} already run"
        fi
    }
    
    ScoreFlow_run_gbsa_md() {
        run_folder=${workdir}/${project}.chemflow/${action}/${protocol}/${receptor}/ 
        cd ${run_folder}
        
        if [ ! -f md_gbsa.rst7 ] || [ "${OVERWRITE_md_gbsa}" == 'yes' ] ; then 
                
            if [ -f min_gbsa.rst7 ]  ; then 
                echo "[ Run - MD - GBSA  ] ${receptor}"

                ScoreFlow_MMGBSA_implicit_write_MD
                    
                input="md_gbsa"
                init="complex"
                prev="min_gbsa"
                run="md_gbsa"
                    
                pmemd.cuda -O \
                -i   ${input}.in    -o ${run}.mdout -e ${run}.mden  -r ${run}.rst7 \
                -x   ${run}.nc      -v ${run}.mdvel -c ${prev}.rst7 -p ${init}.prmtop \
                -ref ${prev}.rst7 -inf ${run}.mdinfo 
            else
              echo "[ Skip ] ${receptor}"
            fi
        else
            echo "[ Run - MD - GBSA ] ${receptor} already run"
        fi
    }


i=0; waitevery=8; 
for receptor in ${folder_list} ; do 
    (( i++%waitevery==0 )) && wait
    ScoreFlow_prepare_gbsa &
done
wait

i=0; waitevery=8; 
for receptor in ${folder_list} ; do 
    (( i++%waitevery==0 )) && wait;
    ScoreFlow_gbsa_tleap &
done
wait

for receptor in ${folder_list} ; do 
    ScoreFlow_run_gbsa_min
done

if [ "${protocol}" == "md_gbsa" ] ; then 
    for receptor in ${folder_list} ; do 
        ScoreFlow_run_gbsa_md
    done
fi

}
#
# AmberTools MMGBSA
# 





ScoreFlow_md() {
    ScoreFlow_prepare_md() {

        run_folder=${workdir}/${project}.chemflow/${action}/${protocol}/${receptor}/
        cd ${run_folder}

        if [ ! -f receptor_b4amber.pdb ] || [ ! -f ligand_bcc.mol2 ] || [ "${OVERWRITE_parameters}" == 'yes' ]  ; then
            echo "Preparing ${receptor}"
            cp ${input_folder}/${receptor}/protein.pdb protein.pdb
            cp ${input_folder}/${receptor}/ligandX.mol2 ligand.mol2

            pdb4amber   -i protein.pdb     -o receptor_b4amber.pdb --reduce --add-missing-atoms --prot
            antechamber -i ligand.mol2     -o ligand_bcc.mol2 -c bcc -eq 2 -s 2 -fi mol2 -fo mol2 -at gaff2 -dr no -rn MOL
            parmchk2    -i ligand_bcc.mol2 -o ligand.frcmod -f mol2
        else
            echo "${receptor} already prepared"
        fi
    }

    ScoreFlow_md_tleap() {
        run_folder=${workdir}/${project}.chemflow/${action}/${protocol}/${receptor}/
        cd ${run_folder}

        if [ -f ligand_bcc.mol2 ] && [ ! -f ionized_solvated.prmtop ] ; then

echo "#tleap
source leaprc.protein.ff14SB
source leaprc.water.tip3p
source leaprc.gaff2

set default PBradii mbondi2
set default nocenter on

receptor = loadpdb receptor_b4amber.pdb
saveAmberParm receptor receptor.prmtop receptor.rst7
savePDB receptor receptor.pdb

loadAmberParams ligand.frcmod
ligand = loadmol2 ligand_bcc.mol2
saveAmberParm ligand ligand.prmtop ligand.rst7
savePDB ligand ligand.pdb

complex = combine {receptor,ligand}
saveAmberParm complex complex.prmtop complex.rst7
savePDB complex complex.pdb

# Add enough ions to neutralize
AddIons2 complex Cl- 0
AddIons2 complex Na+ 0

# Solvate with at least 12 Angtron buffer region
solvateOct complex TIP3PBOX 12

# Save solvated complex: topology and coordinates
saveamberparm complex ionized_solvated.prmtop ionized_solvated.rst7
savePDB complex ionized_solvated.pdb

quit " >tleap.in

            tleap -f tleap.in

        fi
    }

    ScoreFlow_md_write_input() {

        run_folder=${workdir}/${project}.chemflow/${action}/${protocol}/${receptor}/
        cd ${run_folder}
echo "Minimize
  &cntrl
  imin=1,maxcyc=5000,
  irest=0,ntx=1,
  cut=8, 
! Frozen or restrained atoms
!----------------------------------------------------------------------
 ntr=1,
 restraintmask='@CA,C,N,O', 
 restraint_wt=1.0,
/
" > min.in

echo "Heat NVT
MD heating
&cntrl
  imin=0,irest=1,ntx=5,
  nstlim=50000,dt=0.002,ntb=1,
  ntf=2,ntc=2,
  ntpr=1000, ntwx=1000, ntwr=3000,
  cut=8.0,
  ntt=3,gamma_ln=1.0
  tempi=10,temp0=300.0,
! Frozen or restrained atoms
!----------------------------------------------------------------------
! ibelly,
! bellymask,
 ntr=1,
 restraintmask='@CA,C,N,O',
 restraint_wt=1.0,
&end
&wt type='REST', istep1=0, istep2=0, value1=1.0, value2=1.0, &end
&wt type='TEMP0', istep1=0, istep2=2500, value1=10.0, value2=300, &end
&wt type='END' &end
/
" > heat.in

echo "MD equilibration
&cntrl
  imin=0,irest=1,ntx=5,
  nstlim=50000,dt=0.002,ntb=2,
  ntf=2,ntc=2,
  ntpr=1000, ntwx=1000, ntwr=3000,
  cut=8.0,
  ntt=3,gamma_ln=1.0
  temp0=300.0,
! Frozen or restrained atoms
!----------------------------------------------------------------------
! ibelly,
! bellymask,
 ntr=1,
 restraintmask='@CA,C,N,O',
 restraint_wt=1.0,
/
" > equil.in

echo "MD
&cntrl
  imin=0,irest=1,ntx=5,
  nstlim=500000,dt=0.002,ntb=2,
  ntf=2,ntc=2,
  ntpr=1000, ntwx=1000, ntwr=3000,
  cut=8.0,
  ntt=3,gamma_ln=1.0
  temp0=300.0,
! Frozen or restrained atoms
!----------------------------------------------------------------------
! ibelly,
! bellymask,
 ntr=1,
 restraintmask='@CA,C,N,O',
 restraint_wt=1.0,
/
" > md.in
    }


i=0; waitevery=8;
for receptor in ${folder_list} ; do
    (( i++%waitevery==0 )) && wait
    ScoreFlow_prepare_md &
done
wait

i=0; waitevery=8;
for receptor in ${folder_list} ; do
    (( i++%waitevery==0 )) && wait;
    ScoreFlow_md_tleap &
done
wait

for receptor in ${folder_list} ; do
    ScoreFlow_md_write_input
    ScoreFlow_md_run
done

}



#
# Main program --------------------------------------------------------------
#
ScoreFlow_init

case $protocol in 
"plants")
echo "[${protocol} ${action}] selected"
ScoreFlow_plants
;;
"vina")
echo "[${protocol} ${action}] selected"
ScoreFlow_vina
;;
"gbsa")
echo "[${protocol} ${action}] selected"
ScoreFlow_gbsa
;;
"md_gbsa")
echo "[${protocol} ${action}] selected"
ScoreFlow_gbsa
;;
"md_gbsa")
echo "[${protocol} ${action}] selected"
ScoreFlow_md
;;
*) 
echo "[Error] ${protocol} ${action} is not implemented"
exit 0
;;
esac
