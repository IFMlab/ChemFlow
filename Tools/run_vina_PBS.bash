#!/bin/bash
# 
# ChemFlow - Prepare Vina Docking and virtual screening.
#
# Diego E. B. Gomes(1,2,3) - dgomes@pq.cnpq.br
# 1 - Instituto Nacional de Metrologia, Qualidade e Tecnologia - Brazil
# 2 - Universite de Strasbourg - France
# 3 - Coordenacao Aperfeicoamento de Pessoal de Ensino Superior - CAPES - Brazil.
#
# This is a script to prepare multiple #PBS files for a Virtual Screening.
# The current implementation it to run Autodock Vina (also Qvina2).
# You can easly modify to run anything else.
#

# User configuration ################################################

# Input files
receptor="receptor.pdbqt"
ligand_folder="lig_vina"

# Number of ligands per PBS job
nlig=5

# Technical details #################################################

# Autodock Vina Executable
vina_exec=/home/dgomes/software/qvina-master/bin/qvina02


#####################################################################
# Do not change anything unless you know what you're doing          #
#####################################################################


run_PBS_split() {
echo "
#!/bin/bash
#PBS -q  small
#PBS -V
#PBS -l  nodes=1:ppn=1
#PBS -l  walltime=24:00:00
#PBS -N  ${begin}_${end}
#PBS -o  pbs_output_error/${begin}_${end}.o
#PBS -e  pbs_output_error/${begin}_${end}.e

cd \$PBS_O_WORKDIR

for i in \$(seq ${begin} ${end}) ; do
  ${vina_exec} \
   --receptor receptor.pdbqt \
   --ligand   lig_vina/lig_\${i}.pdbqt \
   --out      out_vina/lig_\${i}.out \
   --log      out_vina/lig_\${i}.log \
   --center_x  20.220  \
   --center_y   8.921  \
   --center_z -29.889 \
   --size_x    20.0 \
   --size_y    20.0 \
   --size_z    20.0 \
   --cpu 1          \
   > out_vina/lig_\${i}.job
done

" > pbs_scripts/${begin}_${end}.pbs
}




# The actual program #

# Create the PBB scripts folder
mkdir pbs_scripts

# Create the PBS output and error folder
mkdir pbs_output_error

# Count the number of ligands.
last=$(ls -v lig_vina |wc -l)
end=0

while [ "$end" -lt "${last}" ] ; do

  let begin=${end}+1
  let end=${begin}+${nlig}-1

  if [ ${end} -gt ${last} ] ; then end=${last} ; fi

  run_PBS_split

  qsub pbs_scripts/${begin}_${end}.pbs

done


