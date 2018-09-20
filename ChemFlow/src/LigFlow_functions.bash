#!/usr/bin/env bash

#
#LigFlow_prepare_ligands() {
#for mol2 in ${list[@]}; do
#  cd ${rundir}
#
#  # Create an output folder and go there.
#  if [ ! -d $output/${mol2} ] ; then
#    mkdir -p $output/${mol2}
#  fi
#
#  cd $output/${mol2}
#
#  # Simple Gasteinger charges
#  if [ ! -f lig.mol2 ] ; then
#    echo -ne "${mol2}        \r"
#    antechamber -i ${rundir}/${ligand_folder}/${mol2}.mol2 -fi mol2 -o lig.mol2 -fo mol2 -c gas -rn MOL -dr no &>gas.log
#  fi
#
#  # Additional sanity check for lig.mol
#  # Or else move on to the next molecule.
#  if [ ! -f lig.mol2 ] ; then
#    echo "[ERROR] in ${mol2}. lig.mol2 not generated."
#    let errors++
#    let list_max=${list_max}-1
#    continue
#  fi
#
#  # AM1-BCC charges
#  if [ "$BCC" == "1" ] ; then
#    if [ ! -f "lig_bcc.mol2" ] ; then
#      if [ "${SLURM}" == 1 ] ; then
##      write_sqm_slurm
##      sbatch sqm.slurm
#      bcc_list="${bcc_list} ${mol2}"
#      else
#        antechamber -i lig.mol2 -fi mol2 -o lig_bcc.mol2 -fo mol2 -c bcc -s 2 -eq 1 -rn MOL -pf y -dr no
#      fi
#    fi
#  fi
#
#  # RESP charges
#  if [ "$RESP" == "1" ] ; then
#    if [ "$SLURM" == 1 ] ; then
##      write_gaussian_slurm
##      sbatch gaussian.slurm
#      resp_list="${resp_list} ${mol2}"
#    else
#
#    # Prepare Gaussian
#      antechamber -i lig.mol2 -fi mol2 -o lig.gau -fo gcrt -gv 1 -ge lig.gesp -gm "%mem=16Gb" -gn "%nproc=8" -s 2 -eq 1 -rn MOL -pf y -dr no
#
#    # Run Gaussian to optimize structure and generate electrostatic potential grid
#      g09 lig.gau > lig.gout
#
#    # Read Gaussian output and write new optimized ligand with RESP charges
#      antechamber -i lig.gout -fi gout -o lig_resp.mol2 -fo mol2 -c resp -s 2 -rn MOL -pf y -dr no
#    fi
#  fi
#  let list_max=${list_max}-1
##  echo -ne "[DONE] ${mol2}. REMAINING: $list_max ; ERROR=$errors      \r"
#done
#}
#
#
#
#
#smart_submit_slurm() {
#if [ "$RESP" == 1 ] ; then
#
#  # Count the number of ligands RESP.
#  list=($resp_list)
#  list_max=${#list[@]}
#  #echo ${list[@]}
#
#  echo "There are $list_max RESP simulations to run"
#  read -p "How many do you want per PBS job? : " nlig
#
#  for (( first=0;$first<$list_max; first=$first+$nlig )) ; do
#    echo -ne "Preparing from ${first}          \r"
#    jobname="${first}"
#    write_gaussian_smart
#    sbatch gaussian.slurm
#  done
#fi
#
#if [ "$BCC" == 1 ] ; then
#  # Count the number of ligands BCC.
#  list=($bcc_list)
#  list_max=${#list[@]}
#  #echo ${list[@]}
#
#  echo "There are $list_max AM1-BCC simulations to run"
#  read -p "How many do you want per PBS job? : " nlig
#
#  for (( first=0;$first<$list_max; first=$first+$nlig )) ; do
#    echo -ne "Preparing from ${first}          \r"
#    jobname="${first}"
#    write_bcc_smart
#    sbatch sqm.slurm
#  done
#fi
#}
#
#write_gaussian_smart() {
#echo "#! /bin/bash
## 1 noeud 14 coeurs
##SBATCH -p publicgpu
###SBATCH --sockets-per-node=1
###SBATCH --cores-per-socket=8
##SBATCH -N 1
##SBATCH -n 24
##SBATCH -t 12:00:00
##SBATCH --job-name=${first}
##SBATCH --mem=16000
#
## Environnement par défaut : contient les compilateurs Intel 11
#source /b/home/configfiles/bashrc.default
#
#module load gaussian/g09d01_pgi
#source \$GPROFILE
#export GAUSS_SCRDIR=/scratch/job.\$SLURM_JOB_ID
#
## Source amber variables
#source $HOME/software/amber16/amber.sh
#
## Go to run folder
#cd \$SLURM_SUBMIT_DIR
#
#run_gaussian() {
#antechamber -i lig.mol2 -fi mol2 -o lig.gau -fo gcrt  -gv 1 -ge lig.gesp -gm \"%mem=16Gb\" -gn \"%nproc=8\" -s 2 -eq 2 -rn MOL -pf y -dr no
#g09 lig.gau
#antechamber -i lig.gout -fi gout -o lig_resp.mol2 -fo mol2 -c resp -s 2 -rn MOL -pf y -dr no
#
#parmchk2 -i lig_resp.mol2 -o lig.frcmod -s 2 -f mol2
#}
#
#for RUN_DIR in ${list[@]:${first}:${nlig}} ; do
#  cd \$SLURM_SUBMIT_DIR/${output}/\${RUN_DIR}
#  run_gaussian
#done
#wait
#" > gaussian.slurm
#}
#
#
#write_bcc_smart() {
#echo "#! /bin/bash
## 1 noeud 14 coeurs
###SBATCH -p pri2013-short
###SBATCH -A qosisisifm
##SBATCH -p publicgpu
###SBATCH --sockets-per-node=2
###SBATCH --cores-per-socket=8
##SBATCH -N 1
##SBATCH -n 24
##SBATCH -t 5:00:00
##SBATCH --job-name=${first}
##SBATCH --mem=16000
#
#module purge
#module load compilers/intel17
#
## Environnement par défaut : contient les compilateurs Intel 11
#source /b/home/configfiles/bashrc.default
#
## Source amber variables
##source $HOME/software/amber16/amber.sh
#source $HOME/software/amber17/amber16/amber.sh
#
## Go to run folder
#cd \$SLURM_SUBMIT_DIR
#
#if [ -f sqm_${first}.xargs ] ; then rm -rf sqm_${first}.xargs ; fi
#for RUN_DIR in ${list[@]:${first}:${nlig}} ; do
#  echo \"cd \$SLURM_SUBMIT_DIR/${output}/\${RUN_DIR} ; antechamber -i lig.mol2 -fi mol2 -o lig_bcc.mol2 -fo mol2 -c bcc -s 2 -eq 1 -rn MOL -pf y -dr no ; parmchk2 -i lig_bcc.mol2 -o lig.frcmod -s 2 -f mol2\" >> sqm_${first}.xargs
#done
#cat sqm_${first}.xargs | xargs -P24 -I '{}' bash -c '{}'
#wait
#" > sqm.slurm
#
#}
#
#
#write_gaussian_slurm() {
#echo "#! /bin/bash
## 1 noeud 14 coeurs
##SBATCH -p public
##SBATCH --sockets-per-node=2
##SBATCH --cores-per-socket=14
##SBATCH -t 2:00:00
##SBATCH --job-name=$mol2
##SBATCH --mem=16000
#
## Environnement par défaut : contient les compilateurs Intel 11
#source /b/home/configfiles/bashrc.default
#
#module load gaussian/
#source \$GPROFILE
#export GAUSS_SCRDIR=/scratch/job.\$SLURM_JOB_ID
#
## Source amber variables
#source $HOME/software/amber16/amber.sh
#
## Go to run folder
#cd \$SLURM_SUBMIT_DIR
#
#antechamber -i lig.mol2 -fi mol2 -o lig.gau -fo gcrt  -gv 1 -ge lig.gesp -gm \"%mem=16Gb\" -gn \"%nproc=28\" -s 2 -eq 2 -rn MOL -pf y
#
#g09 lig.gau
#
#antechamber -i lig.gout -fi gout -o lig_resp.mol2 -fo mol2 -c resp -s 2 -rn MOL -pf y
#parmchk2 -i lig_resp.mol2 -o lig.frcmod -s 2 -f mol2
#
#" > gaussian.slurm
#}
#
#
#write_sqm_slurm() {
#echo "#! /bin/bash
## 1 noeud 14 coeurs
##SBATCH -p public
##SBATCH --sockets-per-node=1
##SBATCH --cores-per-socket=1
##SBATCH -t 2:00:00
##SBATCH --job-name=$mol2
##SBATCH --mem=16000
#
#module load compilers/intel15
#module load libs/zlib-1.2.8
#
## Environnement par défaut : contient les compilateurs Intel 11
#source /b/home/configfiles/bashrc.default
#
## Source amber variables
#source $HOME/software/amber16/amber.sh
#
## Go to run folder
#cd \$SLURM_SUBMIT_DIR
#
#antechamber -i lig.mol2 -fi mol2 -o lig_bcc.mol2 -fo mol2 -c bcc -s 2 -eq 2 -rn MOL -pf y
#parmchk2 -i lig_bcc.mol2 -o lig.frcmod -s 2 -f mol2
#
#" > sqm.slurm
#}
#
#
#
## SUBMIT THE SHIT
#cd $rundir
#smart_submit_slurm


LigFlow_write_origin_ligands() {
#===  FUNCTION  ================================================================
#          NAME: DockFlow_rewrite_ligands
#   DESCRIPTION: User interface for the rewrite ligands option.
#                 - Read all ligand names from the header of a .MOL2 file.
#                 - Split each ligand to it's own ".MOL2" file.
#               #  - Create "ligand.lst" with the list of ligands do dock.
#
#    PARAMETERS: ${PROJECT}
#                ${LIGAND_LIST}
#                ${RUNDIR}
#                ${DOCK_PROGRAM}
#                ${WORKDIR}
#
#        Author: Dona de Francquen
#
#        UPDATE: fri. july 6 14:49:50 CEST 2018
#
#===============================================================================
OLDIFS=$IFS
IFS='%'
n=-1
while read line ; do
    if [ "${line}" == '@<TRIPOS>MOLECULE' ]; then
        let n=$n+1
        echo -e "${line}" > ${RUNDIR}/original/${LIGAND_LIST[$n]}.mol2
    else
        echo -e "${line}" >> ${RUNDIR}/original/${LIGAND_LIST[$n]}.mol2
    fi
done < ${LIGAND_FILE}
IFS=${OLDIFS}


#
# QUICK AND DIRTY FIX BY DIEGO - PLEASE FIX THIS FOR THE LOVE OF GOD
#
for LIGAND in ${LIGAND_LIST[@]} ; do
    cd ${RUNDIR}/original/
    antechamber -i ${LIGAND}.mol2 -o tmp.mol2 -fi mol2 -fo mol2 -at sybyl -dr no &>/dev/null
    mv tmp.mol2 ${LIGAND}.mol2
done
#
#
#

rm -f ANTECHAMBER_*
rm ATOMTYPE.INF
}


LigFlow_prepare_input() {

LIGAND_LIST=(`echo ${LIGAND_LIST[@]} | sed -e 's/_conf_[0-9]*//'`)

# Original
if [ ! -d ${RUNDIR}/original/ ] ; then
    mkdir -p ${RUNDIR}/original/
fi


for LIGAND in ${LIGAND_LIST[@]} ; do
    if [ ! -f ${RUNDIR}/original/${LIGAND}.mol2 ] ; then
        REWRITE="yes"
    fi
done

if [ "${REWRITE}" == "yes" ] ; then
    LigFlow_write_origin_ligands
fi
}


LigFlow_filter_ligand_list() {
NEW_LIGAND_LIST=""

for LIGAND in ${LIGAND_LIST[@]} ; do
    DONE_CHARGE="false"

    if [ "${DONE_CHARGE}" == "false" ] && [ -s ${CHEMFLOW_HOME}/ChemBase/${CHARGE}/ChemBase_${CHARGE}.lst ] && [ -s ${CHEMFLOW_HOME}/ChemBase/${CHARGE}/ChemBase_${CHARGE}.mol2 ] ; then
        if [ "$(grep ${LIGAND} ${CHEMFLOW_HOME}/ChemBase/${CHARGE}/ChemBase_${CHARGE}.lst)" == ${LIGAND} ] ; then
            ${DONE_CHARGE} = "true"
        fi
    fi
    if [ "${DONE_CHARGE}" == "false" ] && [ -f ${WORKDIR}/${PROJECT}.chemflow/LigFlow/${CHARGE}/${LIGAND}.mol2 ] ; then
        ${DONE_CHARGE} = "true"
    fi
    if [ ${DONE_CHARGE} == "false" ] ; then
        if [ ! -n "`echo ${NEW_LIGAND_LIST} | xargs -n1 echo | grep -e \"^${LIGAND}$\"`" ] ; then
            NEW_LIGAND_LIST="${NEW_LIGAND_LIST} $LIGAND"
        fi
    fi
done

unset LIGAND_LIST
LIGAND_LIST=(${NEW_LIGAND_LIST[@]})
}


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



LigFlow_prepare_ligands_charges() {

# Actualize the ligand list
LigFlow_filter_ligand_list

cd ${RUNDIR}

if [ ! -d ${RUNDIR}/gas ] ; then
    mkdir -p ${RUNDIR}/gas
fi

if [ ! -d ${RUNDIR}/${CHARGE} ] ; then
    mkdir -p ${RUNDIR}/${CHARGE}
fi

case ${JOB_SCHEDULLER} in
"None")
    if [ -f  LigFlow.run ] ; then
      rm -rf LigFlow.run
    fi

    for LIGAND in ${LIGAND_LIST[@]} ; do
        if [ ! -f ${RUNDIR}/gas/${LIGAND}.mol2 ] ; then
            echo "mkdir -p /tmp/${LIGAND}; cd /tmp/${LIGAND} ; antechamber -i ${RUNDIR}/original/${LIGAND}.mol2 -fi mol2 -o ${RUNDIR}/gas/${LIGAND}.mol2 -fo mol2 -c gas -s 2 -eq 1 -rn MOL -pf y -dr no &> antechamber.log ; rm -rf /tmp/${LIGAND}/" >>  ${RUNDIR}/LigFlow.xargs
        fi
    done

    if [ -f ${RUNDIR}/LigFlow.xargs ] ; then
        cat ${RUNDIR}/LigFlow.xargs | xargs -P${NCORES} -I '{}' bash -c '{}'
    fi
    # Clean up
    rm -rf ${RUNDIR}/LigFlow.xargs

    for LIGAND in ${LIGAND_LIST[@]} ; do
        case ${CHARGE} in
        "bcc")
            # Compute am1-bcc charges
            echo "mkdir -p /tmp/${LIGAND}; cd /tmp/${LIGAND} ; antechamber -i ${RUNDIR}/gas/${LIGAND}.mol2 -fi mol2 -o ${RUNDIR}/bcc/${LIGAND}.mol2 -fo mol2 -c bcc -s 2 -eq 1 -rn MOL -pf y -dr no &> antechamber.log ; rm -rf /tmp/${LIGAND}/">> ${RUNDIR}/LigFlow.xargs
        ;;
        "resp")
        #   Prepare Gaussian
            antechamber -i ${RUNDIR}/gas/${LIGAND}.mol2 -fi mol2 -o ${RUNDIR}/resp/${LIGAND}.gau -fo gcrt -gv 1 -ge ${RUNDIR}/resp/${LIGAND}.gesp -ch ${RUNDIR}/resp/${LIGAND} -gm %mem=16Gb -gn %nproc=${NCORES} -s 2 -eq 1 -rn MOL -pf y -dr no &> antechamber.log

            # Run Gaussian to optimize structure and generate electrostatic potential grid
            g09 <${RUNDIR}/resp/${LIGAND}.gau>${RUNDIR}/resp/${LIGAND}.gout

            # Read Gaussian output and write new optimized ligand with RESP charges
            antechamber -i ${RUNDIR}/resp/${LIGAND}.gout -fi gout -o ${RUNDIR}/resp/${LIGAND}_resp.mol2 -fo mol2 -c resp -s 2 -rn MOL -pf y -dr no &> antechamber.log
        ;;
        esac

    done

    # Actually compute AM1-BCC charges
    if [ -f ${RUNDIR}/LigFlow.xargs ] ; then
        cat ${RUNDIR}/LigFlow.xargs | xargs -P${NCORES} -I '{}' bash -c '{}'
    fi
;;

"SLURM"|"PBS")
    echo -ne "\nHow many Dockings per PBS/SLURM job? "
    read nlig
    # Check if the user gave a int
    nb=${nlig}
    not_a_number

    for (( first=0;${first}<${#LIGAND_LIST[@]} ; first=${first}+${nlig} )) ; do
#        echo -ne "Docking $first         \r"
        jobname="${first}"

        LigFlow_write_HPC_header

        for LIGAND in ${LIGAND_LIST[@]:$first:$nlig} ; do
            if [ ! -f ${RUNDIR}/gas/${LIGAND}.mol2 ] ; then
                echo "mkdir -p /tmp/\${LIGAND}; cd /tmp/\${LIGAND} ; antechamber -i ${RUNDIR}/original/${LIGAND}.mol2 -fi mol2 -o ${RUNDIR}/gas/${LIGAND}.mol2 -fo mol2 -c gas -s 2 -eq 1 -rn MOL -pf y -dr no &> antechamber.log ; rm -rf /tmp/${LIGAND}/" >>  LigFlow_gas.${first}.xargs
            fi
        done

        # Actually compute Gasteiger charges
        if [ -f ${RUNDIR}/LigFlow_gas.${first}.xargs ] ; then
            echo "cat ${RUNDIR}/LigFlow_gas.${first}.xargs | xargs -P${NCORES} -I '{}' bash -c '{}' " >> ${RUNDIR}/LigFlow.${JOB_SCHEDULLER,,}
            echo "rm -rf ${RUNDIR}/LigFlow_gas.${first}.xargs" >> ${RUNDIR}/LigFlow.${JOB_SCHEDULLER,,}
        fi


        for LIGAND in ${LIGAND_LIST[@]:$first:$nlig} ; do
            case ${CHARGE} in
            "bcc")
                # Compute am1-bcc charges
                echo "mkdir -p /tmp/${LIGAND}; cd /tmp/${LIGAND} ; antechamber -i ${RUNDIR}/gas/${LIGAND}.mol2 -fi mol2 -o ${RUNDIR}/bcc/${LIGAND}.mol2 -fo mol2 -c bcc -s 2 -eq 1 -rn MOL -pf y -dr no &> antechamber.log ; rm -rf /tmp/${LIGAND}/">>  LigFlow_bcc.${first}.xargs
            ;;
            "resp")
            #   Prepare Gaussian
                echo "antechamber -i ${RUNDIR}/gas/${LIGAND}.mol2 -fi mol2 -o ${RUNDIR}/resp/${LIGAND}.gau -fo gcrt -gv 1 -ge ${RUNDIR}/resp/${LIGAND}.gesp -ch  ${RUNDIR}/resp/${LIGAND}  -gm %mem=16Gb -gn %nproc=${NCORES} -s 2 -eq 1 -rn MOL -pf y -dr no &> antechamber.log" >> ${RUNDIR}/LigFlow.${JOB_SCHEDULLER,,}

                # Run Gaussian to optimize structure and generate electrostatic potential grid
                echo "g09 <${RUNDIR}/resp/${LIGAND}.gau>${RUNDIR}/resp/${LIGAND}.gout" >> ${RUNDIR}/LigFlow.${JOB_SCHEDULLER,,}

                # Read Gaussian output and write new optimized ligand with RESP charges
                echo "antechamber -i ${RUNDIR}/resp/${LIGAND}.gout -fi gout -o ${RUNDIR}/resp/${LIGAND}_resp.mol2 -fo mol2 -c resp -s 2 -rn MOL -pf y -dr no &> antechamber.log" >> ${RUNDIR}/LigFlow.${JOB_SCHEDULLER,,}
            ;;
            esac
        done

        # Actually compute AM1-BCC charges
        if [ -f ${RUNDIR}/LigFlow_bcc.${first}.xargs ] ; then
            echo "cat ${RUNDIR}/LigFlow_bcc.${first}.xargs | xargs -P${NCORES} -I '{}' bash -c '{}' " >> ${RUNDIR}/LigFlow.${JOB_SCHEDULLER,,}
            echo "rm -rf ${RUNDIR}/LigFlow_bcc.${first}.xargs" >> ${RUNDIR}/LigFlow.${JOB_SCHEDULLER,,}
        fi


        if [ "${JOB_SCHEDULLER}" == "SLURM" ] ; then
            sbatch LigFlow.slurm
        elif [ "${JOB_SCHEDULLER}" == "PBS" ] ; then
            qsub LigFlow.pbs
        fi
    done
;;
esac
}


LigFlow_summary() {
#===  FUNCTION  ================================================================
#          NAME: DockFlow_summary
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
PROTOCOL: ${PROTOCOL}
 WORKDIR: ${WORKDIR}

[ Setup ]
  LIGAND FILE: $(relpath "${LIGAND_FILE}"   "${WORKDIR}")
     NLIGANDS: ${NLIGANDS}

[ Charge options ]
    BCC: ${BCC}
   RESP: ${RESP}

[ Run options ]
JOB SCHEDULLER: ${JOB_SCHEDULLER}
    CORES/NODE: ${NCORES}
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
LigFlow -l ligand.mol2 -p myproject [--bcc] [--resp]

[Options]
 -h/--help           : Show this help message and quit
 -hh/--fullhelp      : Detailed help

 -l/--ligand         : Ligands .mol2 input file.
 -p/--project        : ChemFlow project.
"
exit 0
}


LigFlow_help_full(){
echo "
LigFlow is a bash script designed to prepare the ligand for DockFlow and ScoreFlow.

Usage:
LigFlow -l ligand.mol2 -p myproject [--bcc] [--resp]

[Help]
 -h/--help              : Show this help message and quit
 -hh/--fullhelp         : Detailed help

[ Required ]
*-p/--project       STR : ChemFlow project
*-l/--ligand       FILE : Ligands  MOL2 file

[ Optional ]
 --protocol         STR : Name for this specific protocol [default]
 --bcc                  : Compute bcc charges
 --resp                 : Compute resp charges

[ Parallel execution ]
 -nc/--cores        INT : Number of cores per node [${NCORES}]
 --pbs/--slurm          : Workload manager, PBS or SLURM
 --header          FILE : Header file provided to run on your cluster.

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
            shift # past argument
        ;;
        "-p"|"--project")
            PROJECT="$2"
            shift
        ;;
        "--protocol")
            PROTOCOL="$2"
            shift
        ;;
        # Charges
        "--bcc")
            BCC="yes"
            CHARGE="bcc"
        ;;
        "--resp")
            RESP="yes"
            CHARGE="resp"
        ;;
        "-nc"|"--cores") # Number of Cores [1] (or cores/node)
            NCORES="$2" # Same as above.
            NC_CHANGED="yes"
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
        *)
            unknown="$1"        # unknown option
            echo "Unknown flag \"$unknown\""
        ;;
    esac
    shift # past argument or value
done
}
