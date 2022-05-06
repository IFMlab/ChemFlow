#!/usr/bin/env bash

LigFlow_sanity() {
    if [ -z ${CHEMFLOW_HOME} ] ; then
        echo "CHEMFLOW_HOME is not defined"
        exit 1
    fi

    if [ -z "$(command -v antechamber)" ] ; then
        echo "AmberTools 17+ is not installed or on PATH" ; exit 1;
    fi

    if [ "${CHARGE}" == "resp" ] && [ -z "$(command -v g09)" ] ; then
        echo "Gaussian is not installed or on PATH" ; exit 1
    fi
}

LigFlow_update_list() {
for LIGAND in ${LIGAND_LIST[@]} ; do
    if [ ! -f ${RUNDIR}/${CHARGE}/${LIGAND}.mol2 ] ; then
        UPDATE_LIST+=("${LIGAND}")
    fi
done
LIGAND_LIST=${UPDATE_LIST}
}

LigFlow_prepare() {
    
    if [ ! -d ${RUNDIR}/${CHARGE} ] ; then
      mkdir -p ${RUNDIR}/${CHARGE}
    fi

    # HPC adjustments
    case "${JOB_SCHEDULLER}" in
    "None") 
        for LIGAND in ${LIGAND_LIST[@]} ; do
            run_LigFlow_prepare
        done
        ;;

    "PBS")
        for LIGAND in ${LIGAND_LIST[@]} ; do
            run_LigFlow_prepare_HPC > ligflow.hpc
            qsub ligflow.hpc
        done
        
        ;;
    "SLURM")
        for LIGAND in ${LIGAND_LIST[@]} ; do
            run_LigFlow_prepare_HPC > ligflow.hpc
            sbatch ligflow.hpc
        done
        ;;

    *) ERROR_MESSAGE="Invalid JOB_SCHEDULLER" ; ChemFlow_error ;
       ;;
    esac
}

run_LigFlow_prepare () {

    # Create tmp directory
    tmp_dir=$(mktemp -d -t ligflow-XXXXXXXXXX)

    # Go to tmp_dir
    cd ${tmp_dir}

    # Extract one molecule from a .mol2 file
    awk -v id=${LIGAND} -v line='@<TRIPOS>MOLECULE' 'BEGIN {print line}; $0~id{flag=1} /MOLECULE/{flag=0} flag'  ${LIGAND_FILE} > ligand.mol2

if [ "${end_file}" == "mol2" ]; then

n=-1
while read line ; do
    #echo ${line}
    if [ "${line}" == '@<TRIPOS>MOLECULE' ]; then
        let n=$n+1
        #echo ${line}
        echo -e "${line}" > ${LIGAND_LIST[$n]}.mol2
        echo -e ${RUNDIR}/${LIGAND_LIST[$n]} >> Name.txt
    else
        echo -e "${line}" >> ${RUNDIR}/${LIGAND_LIST[$n]}.mol2
    fi
done < ${LIGAND_FILE}
IFS=${OLDIFS}
fi

#<<<<<<< HEAD
#=======
	python3 ${CHEMFLOW_HOME}/src/Charges_prog.py -i Name.txt -o Charges.dat -f ${end_file}
	CHARGE_FILE=Charges.dat


    #if [ "${CHARGE_FILE}" == '' ] ; then
    #  echo "No charge file provided"
    #else
    #net_charge=$(awk -v i=${LIGAND} '$0 ~ i {print $2}' ${CHARGE_FILE})
    net_charge=$(awk '{q+=$9}END{printf ("%1.0f\n", q)}' ligand.mol2)
    #fi
     echo -e "\e[33m

   
        The net charge for ${LIGAND} is ${net_charge}
    \e[0m
"

       
    if [ "$CHARGE" == "bcc" ] ; then 
        $(which antechamber) -fi mol2  -i ligand.mol2 \
                    -fo mol2  -o bcc.mol2 \
                    -c bcc -eq 2 -s 2 -at gaff2 \
                    -rn MOL -dr no -pf y -nc ${net_charge}
    fi

    if [ "$CHARGE" == "resp" ] ; then
        $(which antechamber) -fi mol2 -i ligand.mol2 \
                    -fo gcrt -o ligand.gau  \
                    -ge ligand.gesp \
                    -ch ligand -eq 1 -gv 1 \
                    -gm %mem=2Gb -gn %nproc=$(nproc --all) \
                    -rn MOL -dr no -pf y

        if [ -f ligand.gau ] ; then 
            g09 <ligand.gau>ligand.gout

            # If gaussian ended normally, post-process Gaussian Output to produce final .mol2
            if [ "$(awk '/Normal/' ligand.gout )" != '' ] ; then
                $(which antechamber) -fi gout -i ligand.gout  \
                            -fo mol2 -o resp.mol2 \
                            -c resp -s 2 -at gaff2 \
                            -rn MOL -pf y -dr y -nc ${net_charge} 
            fi

        fi
    fi

    # Wrap up
    if [ -f ${CHARGE}.mol2 ] ; then

        # Copy results
        cp ${CHARGE}.mol2 ${RUNDIR}/${CHARGE}/${LIGAND}.mol2

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
    cat ${HEADER_FILE}

    # Write out relevant variables
    echo "
#######################################
# Config
#######################################
RUNDIR=\"${RUNDIR}\"
CHARGE=\"${CHARGE}\"
LIGAND=\"${LIGAND}\"
LIGAND_FILE=\"${LIGAND_FILE}\"

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


LigFlow_summary() {
#===  FUNCTION  ================================================================
#          NAME: LigFlow_summary
#   DESCRIPTION: Summarize all docking information
#
#    PARAMETERS: ${HOSTNAME}
#                ${USER}
#                ${PROJECT}
#                ${PROTOCOL}
#                ${PWD}
#                ${LIGAND_FILE}
#                ${NLIGANDS}
#                ${JOB_SCHEDULLER}
#                ${NCORES}
#       RETURNS: -
#
#===============================================================================
echo "\
LigFlow summary:
-------------------------------------------------------------------------------
[ General info ]
    HOST: ${HOSTNAME}
    USER: ${USER}
 PROJECT: ${PROJECT}
 WORKDIR: ${WORKDIR}

[ Setup ]
  LIGAND FILE: $(relpath "${LIGAND_FILE}"   "${WORKDIR}")
     NLIGANDS: ${NLIGANDS}

[ Charge options ]
    BCC: ${BCC}
   RESP_gaff2: ${RESP_GAFF2}
   RESP_sybyl: ${RESP_SYBYL}

[ Run options ]
JOB SCHEDULLER: ${JOB_SCHEDULLER}
    CORES/NODE: ${NCORES}
        HEADER: ${HEADER_FILE}
"

echo -n "
Continue [y/n]? "
read opt
case $opt in
"Y"|"YES"|"Yes"|"yes"|"y")  ;;
*)  echo "Exiting" ; exit 0 ;;
esac
}


LigFlow_help() {
echo "Example usage:
LigFlow -l ligand.mol2 -p myproject [--bcc] [--resp][--resp_sybyl] --charges-file mychargefile.dat
or
LigFlow -l ligand.mol2 -p myproject [--bcc] [--resp][--resp_sybyl] 

[Options]
 -h/--help           : Show this help message and quit
 -hh/--full-help      : Detailed help

 -l/--ligand         : Ligands .mol2 input file.
 -p/--project        : ChemFlow project.
"
exit 0
}


LigFlow_help_full(){
echo "LigFlow is a bash script designed to prepare the ligand for DockFlow and ScoreFlow.

Usage:
LigFlow -l ligand.mol2 -p myproject [--bcc] [--resp] [--resp_sybyl]

[Help]
 -h/--help              : Show this help message and quit
 -hh/--full-help         : Detailed help

[ Required ]
*-p/--project       STR : ChemFlow project
*-l/--ligand       FILE : Ligands mol2 file

[ Optional ]
 --bcc                  : Compute bcc charges
 --resp                 : Compute resp charges with gaff2 atom types
 --resp_sybyl           : Compute resp charges with sybyl atom types

[ Parallel execution ]
 -nc/--cores        INT : Number of cores per node [${NCORES}]
 --pbs/--slurm          : Workload manager, PBS or SLURM
 --header          FILE : Header file provided to run on your cluster.

[ Development ] 
 --charges-file    FILE : Contains the net charges for all ligands in a library.
                          ( name charge )  ( CHEMBL123 -1 ) 

"
    exit 0
}


LigFlow_CLI() {
if [ "$1" == "" ] ; then
    ERROR_MESSAGE="LigFlow called without arguments."
    ChemFlow_error ;
fi

while [[ $# -gt 0 ]]; do
    key="$1"

    case ${key} in
        "-h"|"--help")
            LigFlow_help
            exit 0
        ;;
        "-hh"|"--full-help")
            LigFlow_help_full
            exit 0
        ;;
        "-l"|"--ligand")
            LIGAND_FILE=$(abspath "$2")
            #echo "$LIGAND_FILE"
            IFS=. read var1 end_file <<< $LIGAND_FILE
#            echo $end_file
            shift # past argument
        ;;
        "-p"|"--project")
            PROJECT="$2"
            shift
        ;;
        # Charges
        "--bcc")
            BCC="yes"
            CHARGE="bcc"
	    RESP_GAFF2="no"
	    RESP_SYBYL="no"
        ;;
        "--resp")
            BCC="no"
            RESP="yes"
            CHARGE="resp"
            ATOM_TYPE="gaff2"
	    RESP_GAFF2="yes"
	    RESP_SYBYL="no"
        ;;
	"--resp_sybyl")
            BCC="no"
            RESP="yes"
            CHARGE="resp"
            ATOM_TYPE="sybyl"
	    RESP_SYBYL="yes"  
	    RESP_GAFF2="no"
        ;;
        "-nc"|"--cores") # Number of Cores [1] (or cores/node)
            NCORES="$2" # Same as above.
            #NC_CHANGED="yes"
            shift # past argument
        ;;
        # HPC options
        "--pbs") #Activate the PBS workload
            JOB_SCHEDULLER="PBS"
        ;;
        "--slurm") #Activate the SLURM workload
            JOB_SCHEDULLER="SLURM"
        ;;
        "--header")
            HEADER_PROVIDED="yes"
            HEADER_FILE=$(abspath "$2")
            shift
        ;;
        # Features under Development 
        "--charges-file")
           CHARGE_FILE=$(abspath "$2")
           if [ ! -f ${CHARGE_FILE} ] ; then echo "Charge file \"${CHARGE_FILE}\" not found " ;  exit 1 ; fi
           shift
        ;;
        *)
            unknown="$1"        # unknown option
            echo "Unknown flag \"$unknown\""
        ;;
    esac
    shift # past argument or value
done
}




#######################################################
# For the honor and glory of our lord Jesus !!!       #
#                                                     #
# Everything bellow is overly complicated.            #
#                                                     #
# Please ChemBase deserves a better implementation    #
#                                                     #
# Let's go back to Keeping Things Super Simple (KISS) #
#######################################################



LigFlow_write_HPC_header() {
#===  FUNCTION  ================================================================
#          NAME: DockFlow_write_HPC_header
#   DESCRIPTION: Add the HPC header to DockFlow.run.
#                Default or provided header.
#
#    PARAMETERS: ${RUNDIR}
#                ${CHEMFLOW_HOME}
#                ${JOB_SCHEDULLER}
#                ${WORKDIR}
#                ${HEADER_PROVIDED}
#                ${HEADER_FILE}
#
#       RETURNS: ScoreFlow.pbs for ${LIGAND}
#===============================================================================
if [ ${HEADER_PROVIDED} != "yes" ] ; then
    file=$(cat ${CHEMFLOW_HOME}/templates/dock_${JOB_SCHEDULLER,,}.template)
    eval echo \""${file}"\" > ${RUNDIR}/LigFlow.header
else
    cp ${HEADER_FILE} ${RUNDIR}/LigFlow.header
fi
case "${JOB_SCHEDULLER}" in
        "PBS")
            sed "/PBS -N .*$/ s/$/_${first}/" ${RUNDIR}/LigFlow.header > ${RUNDIR}/LigFlow.${JOB_SCHEDULLER,,}
        ;;
        "SLURM")
            sed "/--job-name=.*$/  s/$/_${first}/" ${RUNDIR}/LigFlow.header > ${RUNDIR}/LigFlow.${JOB_SCHEDULLER,,}
        ;;
        esac

}


not_a_number() {
re='^[0-9]+$'
if ! [[ $nb =~ $re ]] ; then
   ERROR_MESSAGE="Not a number. I was expecting an integer." ; ChemFlow_error ;
fi
}
