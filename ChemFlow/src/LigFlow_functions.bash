#!/usr/bin/env bash


checkpoint1() {
if [ ! -f ${RUNDIR}/bcc/${LIGAND}/${LIGAND}.mol2 ] ; then
   # echo "Could not complete the AM1-bcc calculation for ligand ${i}. Check the logfile for further information."
    echo "Ligand ${LIGAND} - AM1-BCC charge calculation failed." >> ${RUNDIR}/Failed_bcc.dat
else
   # echo "AM1-Bcc calculation finished for ligand ${i} without problems. Writting to Ligand_bcc.dat"
    echo "Ligand ${LIGAND} - AM1-BCC charge calculation completed." >> ${RUNDIR}/Ligand_bcc.dat 
fi

}

LigFlow_write_origin_ligands() {
#===  FUNCTION  ================================================================
#          NAME: DockFlow_rewrite_ligands
#   DESCRIPTION: User interface for the rewrite ligands option.
#                 - Read all ligand names from the header of a .sdf file.
#                 - Split each ligand to it's own ".sdf" file.
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
#               july 2019 by Marion Sisquellas
#===============================================================================
OLDIFS=$IFS
IFS='%'

if [ "${end_file}" == "sdf" ]; then
n=0
p=0
cpt_sdf=0

while read line ; do   
    if  [ "${line}" == "${LIGAND_LIST[$n]}" ] && [ "${n}" -lt "${NLIGANDS}" ]; then    
        echo -e ${RUNDIR}/original/${LIGAND_LIST[$n]} >> ${RUNDIR}/original/Name.txt
        cpt_sdf=0
        echo -e "${line}" > ${RUNDIR}/original/${LIGAND_LIST[$n]}.sdf
        let n=$n+1
        let p=$n-1
    elif [[ `echo ${line} | cut -c1-4` = '$$$$' ]]
    then
        echo -e "${line}" >> ${RUNDIR}/original/${LIGAND_LIST[$p]}.sdf
        cpt_sdf=1
    elif [ "${cpt_sdf}" == 0 ]
    then
        echo -e "${line}" >> ${RUNDIR}/original/${LIGAND_LIST[$p]}.sdf
    #let n=$n+1
    fi
done < ${LIGAND_FILE}
IFS=${OLDIFS}
fi


if [ "${end_file}" == "mol2" ]; then

n=-1
while read line ; do
    #echo ${line}
    if [ "${line}" == '@<TRIPOS>MOLECULE' ]; then
        let n=$n+1
        #echo ${line}
        echo -e "${line}" > ${RUNDIR}/original/${LIGAND_LIST[$n]}.mol2
        echo -e ${RUNDIR}/original/${LIGAND_LIST[$n]} >> ${RUNDIR}/original/Name.txt
    else
        echo -e "${line}" >> ${RUNDIR}/original/${LIGAND_LIST[$n]}.mol2
    fi
done < ${LIGAND_FILE}
IFS=${OLDIFS}
fi

#<<<<<<< HEAD
#=======
python3 ${CHEMFLOW_HOME}/src/Charges_prog.py -i ${RUNDIR}/original/Name.txt -o ${RUNDIR}/original/Charges.dat -f ${end_file}
CHARGE_FILE=${RUNDIR}/original/Charges.dat

#
# QUICK AND DIRTY FIX BY DIEGO - PLEASE FIX THIS FOR THE LOVE OF GOD
#
#cd ${RUNDIR}/original/
#for LIGAND in ${LIGAND_LIST[@]} ; do
#    antechamber -i ${LIGAND}.sdf -o tmp.sdf -fi sdf -fo mol2 -at sybyl -dr no &>/dev/null
##    if [ -f tmp.mol2 ]; then mv tmp.mol2 ${LIGAND}.mol2; fi
#done
#rm -f ANTECHAMBER_*
#rm ATOMTYPE.INF
#
#
#
#>>>>>>> 11577829f54634cab78841ca43d4ad8ca97d5473
}


LigFlow_prepare_input() {
#LIGAND_LIST=(`echo ${LIGAND_LIST[@]} | sed -e 's/_conf_[0-9]*//g'`)
# Original
if [ ! -d ${RUNDIR}/original/ ] ; then
    mkdir -p ${RUNDIR}/original/
fi


for LIGAND in ${LIGAND_LIST[@]} ; do
    if [ ! -f ${RUNDIR}/original/${LIGAND}.$end_file ] ; then
        REWRITE="yes"
        break
    fi
done

if [ "${REWRITE}" == "yes" ] ; then
    LigFlow_write_origin_ligands
else
    if [ "${CHARGE}" == "gas" ] ; then
        echo "[ LigFlow ] All ligand already present ! " ; exit 0
    fi
fi
}



LigFlow_filter_ligand_list() {

NEW_LIGAND_LIST=""
NEW_LIGAND_LIST_INCHIKEY=""
NEW_LIGAND_LIST_INCHI=""
NEW_LIGAND_SMILES=""

# Step 1 - Check if ChemBase and ChemBase.lst exist
#if [ -s ${CHEMFLOW_HOME}/ChemBase/${CHARGE}/ChemBase_${CHARGE}.lst ] && [ -s ${CHEMFLOW_HOME}/ChemBase/${CHARGE}/ChemBase_${CHARGE}.sdf ] ; then
if  [ "$(ls -A ${CHEMFLOW_HOME}/ChemBase/)" ] ; # line to remove once chembase will be functional
then
if [ -f ${CHEMFLOW_HOME}/ChemBase/${CHARGE}/ChemBase_${CHARGE}.lst ] && [ -f ${CHEMFLOW_HOME}/ChemBase/${CHARGE}/ChemBase_${CHARGE}.mol2 ]  ;
then
# Step 2 - Populate CHEMBASE_LIST
    CHEMBASE_LIST=$(${CHEMFLOW_HOME}/ChemBase/${CHARGE}/ChemBase_${CHARGE}.lst)
    CHEMBASE_LIST=($CHEMBASE_LIST)
else
    CHEMBASE_LIST=''
    echo "#name InChI InChIKey Unique_smile" > ${CHEMFLOW_HOME}/ChemBase/${CHARGE}/ChemBase_${CHARGE}.lst
    echo -n > ${CHEMFLOW_HOME}/ChemBase/${CHARGE}/ChemBase_${CHARGE}.mol2
fi
fi
  # Step 3 - Populate COMPUTED_LIST of charges
if [ -d ${RUNDIR}/${CHARGE}/${ATOM_TYPE} ]
then
    COMPUTED_LIST=$(ls -U ${RUNDIR}/original/ | grep $end_file | sed s/\.$end_file// )
    COMPUTED_LIST=($COMPUTED_LIST)
else
    COMPUTED_LIST=''
fi
  # Step 4 - Check if LIGAND already exists on CHEMBASE
    echo "Ligands already present in the chembase present here : ${CHEMFLOW_HOME}/ChemBase/${CHARGE}/" > ${RUNDIR}/README.txt
    echo "Checking for precomputed charges. Please wait ..."
    conter=0
    cpt=0
    for LIGAND in ${LIGAND_LIST[@]} ; do 
        inchi=$(molconvert -g inchi:AuxNone,key ${RUNDIR}/original/${LIGAND}.$end_file | grep InChI= |  cut -d'=' -f2)
        inchikey=$(molconvert -g inchi:AuxNone,key ${RUNDIR}/original/${LIGAND}.$end_file | grep InChIKey |  cut -d'=' -f2)
        smile_unique=$(molconvert smiles:+u ${RUNDIR}/original/${LIGAND}.$end_file)
        # If found at LigFlow, proceed to next LIGAND.
        #case "${COMPUTED_LIST[@]}" in  *"${LIGAND}"*) continue ;; esac
 
        # If found at ChemBase, proceed to next LIGAND.
        #case "${CHEMBASE_LIST[@]}" in  *"${LIGAND}"*) continue ;; esac
        # Add list of ligands to compute
        #if [ "$(cat ${CHEMFLOW_HOME}/ChemBase/${CHARGE}/ChemBase_${CHARGE}.lst | grep ${LIGAND})" != "${LIGAND}" ] 
         #if [ "$(cat ${CHEMFLOW_HOME}/ChemBase/${CHARGE}/ChemBase_${CHARGE}.lst | cut -d' ' -f2 | grep ${inchikey})" != "${inchikey}" ]    
        #if [ "$(cat ${CHEMFLOW_HOME}/ChemBase/${CHARGE}/ChemBase_${CHARGE}.lst | grep ${smile_unique})" != "${smile_unique}" ]    
        #if  [ "$(ls -A ${CHEMFLOW_HOME}/ChemBase/)" ] 
        #then
        if [ "$(cat ${CHEMFLOW_HOME}/ChemBase/${CHARGE}/ChemBase_${CHARGE}.lst | grep ${smile_unique})" != "${smile_unique}" ]         
        then    
            NEW_LIGAND_LIST[$counter]=${LIGAND}
            NEW_LIGAND_LIST_INCHIKEY[$counter]=${inchikey}
            NEW_LIGAND_LIST_INCHI[$counter]=${inchi}
            NEW_LIGAND_LIST_SMILES[$counter]=${smile_unique}
            let counter++
        else :
            echo ${LIGAND} ${inchi} ${inchikey} ${smile_unique} >> ${RUNDIR}/README.txt
            cpt=1
        fi     
        #fi
    done
    if [ "${cpt}" == "0" ]
        then
        echo "None of the ligans present in the chambase" >> ${RUNDIR}/README.txt
    fi

unset LIGAND_LIST
LIGAND_LIST=(${NEW_LIGAND_LIST[@]})
unset NEW_LIGAND_LIST
}

LigFlow_write_HPC_header2() {
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
            sed "/--job-name=.*$/  s/$/_${LIGAND}/" ${RUNDIR}/LigFlow.header > ${RUNDIR}/LigFlow.${JOB_SCHEDULLER,,}
        ;;
        esac

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


# UPDATE the ligand list
# The filtering will be done once the chembase will be incremented
#LigFlow_filter_ligand_list

NCHARGE=${#LIGAND_LIST[@]}

#if [ ${NCHARGE} == 0 ] ; then
#    echo "[ LigFlow ] All charges already present ! " ; exit 0
#else
#    echo "There are ${NLIGANDS} compounds and ${NCHARGE} remaining to prepare"
#fi


cd ${RUNDIR}

if [ ! -d ${RUNDIR}/gas ] ; then
    mkdir -p ${RUNDIR}/gas
fi


if [ ! -d ${RUNDIR}/${CHARGE} ] ; then
    mkdir -p ${RUNDIR}/${CHARGE}/${ATOM_TYPE}
fi


case ${JOB_SCHEDULLER} in
"None")
    if [ -f  LigFlow.run ] ; then
      rm -rf LigFlow.run
    fi
    cpt_inch=0 
    for LIGAND in ${LIGAND_LIST[@]} ; do
        #LigFlow_filter_ligand_list
        #standardize ${RUNDIR}/original/${LIGAND}.sdf -c clean3d -f sdf -o ${RUNDIR}/original/${LIGAND}_marvin_3d.sdf
        #standardize ${RUNDIR}/original/${LIGAND}_marvin_3d.sdf -f sdf -c dearomatize -o ${RUNDIR}/original/${LIGAND}_clean.sdf
        #standardize ${RUNDIR}/original/${LIGAND}.sdf -c clean3d -f sdf -o ${RUNDIR}/original/${LIGAND}_clean.sdf
        #mkdir -p ${RUNDIR}/${CHARGE}/${LIGAND}     
        mkdir -p ${RUNDIR}/${CHARGE}/${ATOM_TYPE}/${LIGAND}

        case ${CHARGE} in
        "bcc")
            echo ${LIGAND}  >> antechamber_prep_${CHARGE}.log   
            START_TIME_BCC=$SECONDS
            echo  "Starting the AM1-bcc calculation for ligand ${LIGAND}. This will serve as a structure sanity check. Please look at the log file for more information."
            if [ "${CHARGE_FILE}" == '' ] ; then
            # Compute am1-bcc charges
                antechamber -i ${RUNDIR}/original/${LIGAND}.${end_file} -fi ${end_file} -o ${RUNDIR}/bcc/${LIGAND}/${LIGAND}.mol2 -fo mol2 -c bcc -s 2 -eq 1 -rn MOL -pf y -dr y -at sybyl  &>> antechamber_prep_bcc.log 
            else
                net_charge=$(awk -v i=${LIGAND} '$0 ~ i {print $2}' ${CHARGE_FILE})
                echo "Charges file founded"
                echo ${net_charge}
                #antechamber -i ${RUNDIR}/original/${LIGAND}.sdf -fi sdf -o ${RUNDIR}/bcc/${LIGAND}/${LIGAND}.mol2 -fo mol2 -c bcc -s 2 -eq 1 -rn ${LIGAND} -pf y -dr y -at sybyl -nc ${net_charge}  &>> antechamber_prep_bcc.log 
                antechamber -i ${RUNDIR}/original/${LIGAND}.${end_file} -fi ${end_file} -o ${RUNDIR}/bcc/${LIGAND}/${LIGAND}.mol2 -fo mol2 -c bcc -s 2 -eq 1 -rn MOL -pf y -dr n -at sybyl -nc ${net_charge}  &>> antechamber_prep_bcc.log
            fi
            ELAPSED_TIME_BCC=$(($SECONDS - $START_TIME_BCC))
            echo "${LIGAND} : [ LigFlow ] Normal completion in ${ELAPSED_TIME_BCC} seconds."
            echo -e "${LIGAND} : [ LigFlow ] Normal completion in ${ELAPSED_TIME_BCC} seconds." >> TIME.log
            echo -e "\n\n\n" >> TIME.log
            echo -e "AM1-BCC calculation finished for ligand ${LIGAND}. Remember to check the log file for error messages.\n\n"
            echo -e "\n\n\n" >> antechamber_prep_${CHARGE}.log
            checkpoint1
        ;;
        "resp")
        #   Prepare Gaussian
            echo ${LIGAND}  >> antechamber_prep_${CHARGE}_${ATOM_TYPE}.log   
            START_TIME_RESP=$SECONDS
            if [ "${CHARGE_FILE}" == '' ] ; then  
                antechamber -i ${RUNDIR}/original/${LIGAND}.${end_file} -fi ${end_file} -o ${RUNDIR}/resp/${ATOM_TYPE}/${LIGAND}/${LIGAND}.gau -fo gcrt -gv 1 -ge ${RUNDIR}/resp/${ATOM_TYPE}/${LIGAND}/${LIGAND}.gesp -ch ${RUNDIR}/resp/${ATOM_TYPE}/${LIGAND}/${LIGAND} -gm %mem=32Gb -gn %nproc=${NCORES} -s 2 -eq 1 -rn MOL -pf y -dr y &>> antechamber_prep_resp_${ATOM_TYPE}.log   
            else
                net_charge=$(awk -v i=${LIGAND} '$0 ~ i {print $2}' ${CHARGE_FILE})
                echo  "Charges file founded"
                antechamber -i ${RUNDIR}/original/${LIGAND}.${end_file} -fi ${end_file} -o ${RUNDIR}/resp/${ATOM_TYPE}/${LIGAND}/${LIGAND}.gau -fo gcrt -gv 1 -ge ${RUNDIR}/resp/${ATOM_TYPE}/${LIGAND}/${LIGAND}.gesp -ch ${RUNDIR}/resp/${ATOM_TYPE}/${LIGAND}/${LIGAND} -gm %mem=32Gb -gn %nproc=${NCORES} -s 2 -eq 1 -rn MOL -pf y -dr y -nc ${net_charge}  &>> antechamber_prep_resp_${ATOM_TYPE}.log
            fi
            echo -e "\n\n\n" >> antechamber_prep_resp_${ATOM_TYPE}.log
            # Run Gaussian to optimize structure and generate electrostatic potential grid
            g09 <${RUNDIR}/resp/${ATOM_TYPE}/${LIGAND}/${LIGAND}.gau>${RUNDIR}/resp/${ATOM_TYPE}/${LIGAND}/${LIGAND}.gout

            # Read Gaussian output and write new optimized ligand with RESP charges
            
            echo ${LIGAND}  >> antechamber_gauss_resp_${ATOM_TYPE}.log
            #antechamber -i ${RUNDIR}/resp/${ATOM_TYPE}/${LIGAND}/${LIGAND}.gout -fi gout -o ${RUNDIR}/resp/${ATOM_TYPE}/${LIGAND}/${LIGAND}.mol2 -fo mol2 -c resp -s 2 -rn ${LIGAND} -pf y -dr y -at gaff2 &>> antechamber_gauss.log
            antechamber -i ${RUNDIR}/resp/${ATOM_TYPE}/${LIGAND}/${LIGAND}.gout -fi gout -o ${RUNDIR}/resp/${ATOM_TYPE}/${LIGAND}/${LIGAND}.mol2 -fo mol2 -c resp -s 2 -rn MOL -pf y -dr y -at ${ATOM_TYPE} &>> antechamber_gauss_resp_${ATOM_TYPE}.log
	    echo -e "\n\n\n" >> antechamber_gauss_resp_${ATOM_TYPE}.log
            ELAPSED_TIME_RESP=$(($SECONDS - $START_TIME_RESP))
            echo "${LIGAND} : [ LigFlow ] Normal completion in ${ELAPSED_TIME_RESP} seconds."
            echo -e "${LIGAND} : [ LigFlow ] Normal completion in ${ELAPSED_TIME_RESP} seconds." >> TIME.log
            echo -e "\n\n\n" >> TIME.log
        esac
        case ${CHARGE} in
            "bcc")
                cat ${RUNDIR}/${CHARGE}/${LIGAND}/${LIGAND}.mol2 >> ALL_${CHARGE}.mol2
            ;;
            "resp")
                cat ${RUNDIR}/${CHARGE}/${ATOM_TYPE}/${LIGAND}/${LIGAND}.mol2 >> ALL_${CHARGE}_${ATOM_TYPE}.mol2
        esac
        #echo -e "\n\n\n" >> ALL_${CHARGE}.mol2
        # add in the chembase
        #echo ${LIGAND} ${NEW_LIGAND_LIST_INCHI[$cpt_inch]} ${NEW_LIGAND_LIST_INCHIKEY[$cpt_inch]} ${NEW_LIGAND_LIST_SMILES[$cpt_inch]} >> ${CHEMFLOW_HOME}/ChemBase/${CHARGE}/ChemBase_${CHARGE}.lst
        #
        #
        # Remove the following coments once Chembase done it will be to incremente it
        #echo ${LIGAND} ${NEW_LIGAND_LIST_SMILES[$cpt_inch]} >> ${CHEMFLOW_HOME}/ChemBase/${CHARGE}/ChemBase_${CHARGE}.lst
        #cat ${RUNDIR}/${CHARGE}/${LIGAND}/${LIGAND}.mol2 >> ${CHEMFLOW_HOME}/ChemBase/${CHARGE}/ChemBase_${CHARGE}.mol2
        #echo -e "\n\n\n" >> ${CHEMFLOW_HOME}/ChemBase/${CHARGE}/ChemBase_${CHARGE}.mol2
        let  cpt_inch++     
    done
    # Actually compute AM1-BCC charges
#    case ${CHARGE} in
#    "bcc")
#        if [ -f ${RUNDIR}/LigFlow.xargs ] ; then
#            cat ${RUNDIR}/LigFlow.xargs | xargs -P${NCORES} -I '{}' bash -c '{}'
#        fi
#    ;;
#    esac

;;

"SLURM"|"PBS")
  echo -ne "\nHow many Dockings per PBS/SLURM job? "
  read nlig
#     # Check if the user gave a int
#     #nb=${nlig}
#     nlig=1
#     nb=${nlig}
#     not_a_number
# ###

### WHAT THE HELL WAS THIS ?
# if [ "${nb}" -eq "${nlig}" ] ; then
#     cpt_inch=0 
#     for LIGAND in ${LIGAND_LIST[@]} ; do
# 	jobname="${LIGAND}"
# 	LigFlow_write_HPC_header2
#     mkdir -p /${ATOM_TYPE}/${LIGAND}  
#     echo ${LIGAND}  >> antechamber_prep_${CHARGE}.log
# 	case ${CHARGE} in
# 	    #LigFlow_filter_ligand_list
# 	    #standardize ${RUNDIR}/original/${LIGAND}.sdf -c clean3d -f sdf -o ${RUNDIR}/original/${LIGAND}_marvin_3d.sdf
# 	    #standardize ${RUNDIR}/original/${LIGAND}_marvin_3d.sdf -f sdf -c dearomatize -o ${RUNDIR}/original/${LIGAND}_clean.sdf
# 	    #standardize ${RUNDIR}/original/${LIGAND}.sdf -c clean3d -f sdf -o ${RUNDIR}/original/${LIGAND}_clean.sdf
# 		"bcc")
# 		    START_TIME_BCC=$SECONDS
# 		    echo  "Starting the AM1-bcc calculation for ligand ${LIGAND}. This will serve as a structure sanity check. Please look at the log file for more information."
# 		    if [ "${CHARGE_FILE}" == '' ] ; then
# 		    # Compute am1-bcc charges
# 		        echo "antechamber -i ${RUNDIR}/original/${LIGAND}.$end_file -fi sdf -o ${RUNDIR}/bcc/${LIGAND}/${LIGAND}.mol2 -fo mol2 -c bcc -s 2 -eq 1 -rn MOL -pf y -dr y -at sybyl  &>> antechamber_prep_bcc.log">>  LigFlow_bcc.${LIGAND}.xargs
# 		    else
# 		        net_charge=$(awk -v i=${LIGAND} '$0 ~ i {print $2}' ${CHARGE_FILE})
# 		        #antechamber -i ${RUNDIR}/original/${LIGAND}.$end_file -fi sdf -o ${RUNDIR}/bcc/${LIGAND}/${LIGAND}.mol2 -fo mol2 -c bcc -s 2 -eq 1 -rn ${LIGAND} -pf y -dr y -at sybyl -nc ${net_charge}  &>> antechamber_prep_bcc.log 
# 		        echo "antechamber -i ${RUNDIR}/original/${LIGAND}.$end_file -fi sdf -o ${RUNDIR}/bcc/${LIGAND}/${LIGAND}.mol2 -fo mol2 -c bcc -s 2 -eq 1 -rn MOL -pf y -dr n -at sybyl -nc ${net_charge}  &>> antechamber_prep_bcc.log">>  LigFlow_bcc.${LIGAND}.xargs
# 		    fi
# 		    ELAPSED_TIME_BCC=$(($SECONDS - $START_TIME_BCC))
# 		    #echo "${LIGAND} : [ LigFlow ] Normal completion in ${ELAPSED_TIME_BCC} seconds."
# 		    echo -e "${LIGAND} : [ LigFlow ] Normal completion in ${ELAPSED_TIME_BCC} seconds." >> TIME.log
# 		    echo -e "\n\n\n" >> TIME.log
# 		    #echo -e "AM1-BCC calculation finished for ligand ${LIGAND}. Remember to check the log file for error messages.\n\n"
# 		    echo -e "\n\n\n" >> antechamber_prep_${CHARGE}.log
# 		    checkpoint1

#     	;;
# 		"resp")
# 		#   Prepare Gaussian
# 		    START_TIME_RESP=$SECONDS
# 		    if [ "${CHARGE_FILE}" == '' ] ; then  
# 		        echo "antechamber -i ${RUNDIR}/original/${LIGAND}.$end_file -fi sdf -o ${RUNDIR}/resp/${ATOM_TYPE}/${LIGAND}/${LIGAND}.gau -fo gcrt -gv 1 -ge ${RUNDIR}/resp/${ATOM_TYPE}/${LIGAND}/${LIGAND}.gesp -ch ${RUNDIR}/resp/${ATOM_TYPE}/${LIGAND}/${LIGAND} -gm %mem=32Gb -gn %nproc=${NCORES} -s 2 -eq 1 -rn MOL -pf y -dr y &>> antechamber_prep_resp_${ATOM_TYPE}.log" >> ${RUNDIR}/LigFlow.${JOB_SCHEDULLER,,}   
# 		    else
# 		        net_charge=$(awk -v i=${LIGAND} '$0 ~ i {print $2}' ${CHARGE_FILE})
# 		        #echo  "Charges file founded"
# 		        echo "antechamber -i ${RUNDIR}/original/${LIGAND}.$end_file -fi sdf -o ${RUNDIR}/resp/${ATOM_TYPE}/${LIGAND}/${LIGAND}.gau -fo gcrt -gv 1 -ge ${RUNDIR}/resp/${ATOM_TYPE}/${LIGAND}/${LIGAND}.gesp -ch ${RUNDIR}/resp/${ATOM_TYPE}/${LIGAND}/${LIGAND} -gm %mem=32Gb -gn %nproc=${NCORES} -s 2 -eq 1 -rn MOL -pf y -dr y -nc ${net_charge}  &>> antechamber_prep_resp_${ATOM_TYPE}.log" >> ${RUNDIR}/LigFlow.${JOB_SCHEDULLER,,}
# 		    fi
# 		    echo -e "\n\n\n" >> antechamber_prep_${CHARGE}_${ATOM_TYPE}.log
# 		    # Run Gaussian to optimize structure and generate electrostatic potential grid
# 		    echo "g09 <${RUNDIR}/resp/${ATOM_TYPE}/${LIGAND}/${LIGAND}.gau>${RUNDIR}/resp/${ATOM_TYPE}/${LIGAND}/${LIGAND}.gout " >> ${RUNDIR}/LigFlow.${JOB_SCHEDULLER,,}

# 		    # Read Gaussian output and write new optimized ligand with RESP charges
		    
# 		    echo ${LIGAND}  >> antechamber_gauss.log
# 		    #echo "antechamber -i ${RUNDIR}/resp/${ATOM_TYPE}/${LIGAND}/${LIGAND}.gout -fi gout -o ${RUNDIR}/resp/${ATOM_TYPE}/${LIGAND}/${LIGAND}.mol2 -fo mol2 -c resp -s 2 -rn ${LIGAND} -pf y -dr y -at gaff2 &>> antechamber_gauss.log" >> ${RUNDIR}/LigFlow.${JOB_SCHEDULLER,,}
# 		   echo "antechamber -i ${RUNDIR}/resp/${ATOM_TYPE}/${LIGAND}/${LIGAND}.gout -fi gout -o ${RUNDIR}/resp/${ATOM_TYPE}/${LIGAND}/${LIGAND}.mol2 -fo mol2 -c resp -s 2 -rn MOL -pf y -dr y -at ${ATOM_TYPE} &>> antechamber_gauss.log" >> ${RUNDIR}/LigFlow.${JOB_SCHEDULLER,,}
# 		    echo -e "\n\n\n" >> antechamber_gauss.log
# 		    ELAPSED_TIME_RESP=$(($SECONDS - $START_TIME_RESP))
# 		    echo "${LIGAND} : [ LigFlow ] Normal completion in ${ELAPSED_TIME_RESP} seconds."
# 		    echo -e "${LIGAND} : [ LigFlow ] Normal completion in ${ELAPSED_TIME_RESP} seconds." >> TIME.log
# 		    echo -e "\n\n\n" >> TIME.log
 
# 		esac	    
# 		    #cat ${RUNDIR}/${CHARGE}/${LIGAND}/${LIGAND}.mol2 >> ALL_${CHARGE}.mol2
# 		    #echo -e "\n\n\n" >> ALL_${CHARGE}.mol2
# 		    # add in the chembase
# 		    #echo ${LIGAND} ${NEW_LIGAND_LIST_INCHI[$cpt_inch]} ${NEW_LIGAND_LIST_INCHIKEY[$cpt_inch]} ${NEW_LIGAND_LIST_SMILES[$cpt_inch]} >> ${CHEMFLOW_HOME}/ChemBase/${CHARGE}/ChemBase_${CHARGE}.lst
# 		    #echo ${LIGAND} ${NEW_LIGAND_LIST_SMILES[$cpt_inch]} >> ${CHEMFLOW_HOME}/ChemBase/${CHARGE}/ChemBase_${CHARGE}.lst
# 		    #cat ${RUNDIR}/${CHARGE}/${LIGAND}/${LIGAND}.mol2 >> ${CHEMFLOW_HOME}/ChemBase/${CHARGE}/ChemBase_${CHARGE}.mol2
# 		    #echo -e "\n\n\n" >> ${CHEMFLOW_HOME}/ChemBase/${CHARGE}/ChemBase_${CHARGE}.mol2
# 		    #let  cpt_inch++   
# 		if [ "${JOB_SCHEDULLER}" == "SLURM" ] ; then
# 			sbatch LigFlow.slurm
# 		elif [ "${JOB_SCHEDULLER}" == "PBS" ] ; then
# 			qsub LigFlow.pbs
# 		fi
# 	done

# else 
### WHAT THE HELL WAS THIS ?

####
    for (( first=0;${first}<${#LIGAND_LIST[@]} ; first=${first}+${nlig} )) ; do
#        echo -ne "Docking $first         \r"
        jobname="${first}"

        LigFlow_write_HPC_header

        for LIGAND in ${LIGAND_LIST[@]:$first:$nlig} ; do
            case ${CHARGE} in
            "bcc")
                # Compute am1-bcc charges
                if [ "${CHARGE_FILE}" == '' ] ; then
                    echo "mkdir -p /tmp/${USER}/${LIGAND}; cd /tmp/${USER}/${LIGAND} ; antechamber -i ${RUNDIR}/original/${LIGAND}.mol2 -fi mol2 -o ${RUNDIR}/bcc/${LIGAND}.mol2 -fo mol2 -c bcc -s 2 -eq 1 -rn MOL -pf y -dr no -at sybyl &> antechamber.log ; rm -rf /tmp/${USER}/${LIGAND}/">>  LigFlow_bcc.${first}.xargs
                else
                    net_charge=$(awk -v i=${LIGAND} '$0 ~ i {print $2}' ${CHARGE_FILE})
                    echo "mkdir -p /tmp/${USER}/${LIGAND}; cd /tmp/${USER}/${LIGAND} ; antechamber -i ${RUNDIR}/original/${LIGAND}.mol2 -fi mol2 -o ${RUNDIR}/bcc/${LIGAND}.mol2 -fo mol2 -c bcc -s 2 -eq 1 -rn MOL -pf y -dr no -at sybyl -nc ${net_charge} &> antechamber.log ; rm -rf /tmp/${USER}/${LIGAND}/">>  LigFlow_bcc.${first}.xargs
                fi
            ;;
            "resp")
            #   Prepare Gaussian
                if [ "${CHARGE_FILE}" == '' ] ; then
                    echo "mkdir -p /tmp/${USER}/${LIGAND}; cd /tmp/${USER}/${LIGAND} ; antechamber -i ${RUNDIR}/original/${LIGAND}.mol2 -fi mol2 -o ${RUNDIR}/resp/${LIGAND}.gau -fo gcrt -gv 1 -ge ${RUNDIR}/resp/${LIGAND}.gesp -ch  ${RUNDIR}/resp/${LIGAND}  -gm %mem=32Gb -gn %nproc=${NCORES} -s 2 -eq 1 -rn MOL -pf y -dr no &> antechamber.log ;rm -rf /tmp/${USER}/${LIGAND}/" >> ${RUNDIR}/LigFlow.${JOB_SCHEDULLER,,}
                else
                    net_charge=$(awk -v i=${LIGAND} '$0 ~ i {print $2}' ${CHARGE_FILE})
                    echo "mkdir -p /tmp/${USER}/${LIGAND}; cd /tmp/${USER}/${LIGAND} ; antechamber -i ${RUNDIR}/original/${LIGAND}.mol2 -fi mol2 -o ${RUNDIR}/resp/${LIGAND}.gau -fo gcrt -gv 1 -ge ${RUNDIR}/resp/${LIGAND}.gesp -ch  ${RUNDIR}/resp/${LIGAND}  -gm %mem=32Gb -gn %nproc=${NCORES} -s 2 -eq 1 -rn MOL -pf y -dr no -nc ${net_charge} &> antechamber.log ; rm -rf /tmp/${USER}/${LIGAND}/" >> ${RUNDIR}/LigFlow.${JOB_SCHEDULLER,,}
                fi
                # Run Gaussian to optimize structure and generate electrostatic potential grid
                echo "g09 <${RUNDIR}/resp/${LIGAND}.gau>${RUNDIR}/resp/${LIGAND}.gout" >> ${RUNDIR}/LigFlow.${JOB_SCHEDULLER,,}

                # Read Gaussian output and write new optimized ligand with RESP charges
                # echo "mkdir -p /tmp/${USER}/${LIGAND}; cd /tmp/${USER}/${LIGAND} ; antechamber -i ${RUNDIR}/resp/${LIGAND}.gout -fi gout -o ${RUNDIR}/resp/${LIGAND}.mol2 -fo mol2 -c resp -s 2 -rn MOL -pf y -dr no -at gaff2 &> antechamber.log ; rm -rf /tmp/${USER}/${LIGAND}/" >> ${RUNDIR}/LigFlow.${JOB_SCHEDULLER,,}
		echo "mkdir -p /tmp/${USER}/${LIGAND}; cd /tmp/${USER}/${LIGAND} ; antechamber -i ${RUNDIR}/resp/${LIGAND}.gout -fi gout -o ${RUNDIR}/resp/${LIGAND}.mol2 -fo mol2 -c resp -s 2 -rn MOL -pf y -dr no -at ${ATOM_TYPE} &> antechamber.log ; rm -rf /tmp/${USER}/${LIGAND}/" >> ${RUNDIR}/LigFlow.${JOB_SCHEDULLER,,}
            ;;
            esac
        done

        # Actually compute AM1-BCC charges
        case ${CHARGE} in
        "bcc")
            if [ -f ${RUNDIR}/LigFlow_bcc.${first}.xargs ] ; then
                echo "cat ${RUNDIR}/LigFlow_bcc.${first}.xargs | xargs -P${NCORES} -I '{}' bash -c '{}' " >> ${RUNDIR}/LigFlow.${JOB_SCHEDULLER,,}
                echo "rm -rf ${RUNDIR}/LigFlow_bcc.${first}.xargs" >> ${RUNDIR}/LigFlow.${JOB_SCHEDULLER,,}
            fi
        ;;
        esac


        if [ "${JOB_SCHEDULLER}" == "SLURM" ] ; then
            sbatch LigFlow.slurm
        elif [ "${JOB_SCHEDULLER}" == "PBS" ] ; then
            qsub LigFlow.pbs
        fi
    done
###
### [END] WHAT THE HELL WAS THIS ?
# fi
# ###
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
$(abspath "$2")
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
LigFlow -l ligand.sdf -p myproject [--bcc] [--resp][--resp_sybyl] --charges-file mychargefile.dat
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
LigFlow -l ligand.sdf -p myproject [--bcc] [--resp] [--resp_sybyl]

[Help]
 -h/--help              : Show this help message and quit
 -hh/--full-help         : Detailed help

[ Required ]
*-p/--project       STR : ChemFlow project
*-l/--ligand       FILE : Ligands  sdf file

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
            echo $end_file
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
            RESP="yes"
            CHARGE="resp"
            ATOM_TYPE="gaff2"
	    RESP_GAFF2="yes"
	    RESP_SYBYL="no"
        ;;
	"--resp_sybyl")
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
        #   CHARGE_FILE=$(abspath "$2")
        #   if [ ! -f ${CHARGE_FILE} ] ; then echo "Charge file \"${CHARGE_FILE}\" not found " ;  exit 1 ; fi
        #   shift
        ;;
        *)
            unknown="$1"        # unknown option
            echo "Unknown flag \"$unknown\""
        ;;
    esac
    shift # past argument or value
done
}
