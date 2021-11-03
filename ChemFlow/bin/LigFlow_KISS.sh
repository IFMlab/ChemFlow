#!/bin/bash
# LigFlow KISS - "Keep It Simple Stupid"

#####################################################################
# Config
#####################################################################

export ROOT_DIR=$PWD

# Config
PROJECT='mytest'
CHARGE='bcc'

LIGAND_FILE="ligands_crystal.mol2"
LIGAND_FILE="ligands_crystal_msketch.mol2"


# LigFlow variables
NCPUS=16
MAXMEM=8

# HPC
HPC='slurm'
HPC_HEADER='slurm.header'
HPC_SUBMIT='false'


#####################################################################
# Functions
#####################################################################
LigFlow_prepare() {

    if [ -f $OUT_FOLDER/${LIGAND}.mol2 ] ; then
        echo "$OUT_FOLDER/${LIGAND}.mol2 ready"
    else

        if [ ${HPC} == 'slurm' ] ; then
            run_LigFlow_prepare_HPC > LigFlow.run
            sbatch LigFlow.run
        
        elif [ ${HPC} == 'pbs' ] ; then
            run_LigFlow_prepare_HPC > LigFlow.run
            qsub LigFlow.run
        
        else 
            run_LigFlow_prepare
        fi
    fi

}

run_LigFlow_prepare () {

    # Create tmp directory
    tmp_dir=$(mktemp -d -t ligflow-XXXXXXXXXX)
    
    # Go to tmp_dir
    cd ${tmp_dir}
    
    # Extract one molecule from a .mol2 file
    awk -v id=${LIGAND} -v line='@<TRIPOS>MOLECULE' 'BEGIN {print line}; $0~id{flag=1} /MOLECULE/{flag=0} flag'  ${LIGAND_FILE} > ligand.mol2
        
    if [ "$CHARGE" == "bcc" ] ; then 
        antechamber -fi mol2  -i ligand.mol2 \
                    -fo mol2  -o bcc.mol2 \
                    -at gaff2 -c bcc -eq 2 \
                    -rn MOL -dr no -pf y
    fi

    if [ "$CHARGE" == "resp" ] ; then
        antechamber -fi mol2 -i ligand.mol2 \
                    -fo gcrt -o ligand.gau  \
                    -ge ligand.gesp \
                    -ch ligand -eq 1 -gv 1 \
                    -gm %mem=${MAXMEM}Gb -gn %nproc=${NCPUS} \
                    -rn MOL -dr no -pf y

        if [ -f ligand.gau ] ; then 
            g09 <ligand.gau>ligand.gout

            # If gaussian ended normally
            if [ "$(awk '/Normal/' ligand.gout )" != '' ] ; then
                antechamber -fi gout -i ligand.gout  \
                            -fo mol2 -o resp.mol2 \
                            -c resp  -at gaff2 \
                            -rn MOL -pf y -dr y 
            fi

        fi
    fi

    # Wrap up
    if [ -f ${CHARGE}.mol2 ] ; then

      # Copy results
      cp ${CHARGE}.mol2 $OUT_FOLDER/${LIGAND}.mol2

      # Clean up tmp files.
      rm -rf ${tmp_dir}

    else 

      echo "
[ Error ] Failed to create ${LIGAND} with ${CHARGE} charges.
      
Check output at ${tmp_dir}
"

    fi
}

run_LigFlow_prepare_HPC() {
    # Writes content of this function to stdout

    # Copy HPC header to run file
    cat ${HPC_HEADER}

    # Write out relevant variables
    echo "
#######################################
# Config
#######################################
LIGAND=${LIGAND}
LIGAND_FILE=${LIGAND_FILE}
CHARGE=${CHARGE}
OUT_FOLDER=${OUT_FOLDER}
NCPUS=${NCPUS}
MAXMEM=${MAXMEM}

#######################################
# Functions
#######################################
"
    declare -f run_LigFlow_prepare
    
    echo "
#######################################
# Program
#######################################
run_LigFlow_prepare

    "
}



#####################################################################
# Program
#####################################################################
LIGAND_FILE="$(realpath  ${LIGAND_FILE})"

# Step 1 - Get ligand list
LIGAND_LIST=$(sed -n '/@<TRIPOS>MOLECULE/{n;p}' ${LIGAND_FILE})

# Show ligand list
echo ${LIGAND_LIST}

# Create output folder
OUT_FOLDER="${ROOT_DIR}/${PROJECT}.chemflow/LigFlow/${CHARGE}"
if [  ! -d   "${OUT_FOLDER}" ] ; then
    mkdir -p ${OUT_FOLDER}
fi

# Extract a ligand on demand. (Fine for Thousands of ligands... Not quite efficient for Milions of ligands)
# It is faster than splitting .mol2 file anyway.
for LIGAND in ${LIGAND_LIST} ; do 
    LigFlow_prepare
done


