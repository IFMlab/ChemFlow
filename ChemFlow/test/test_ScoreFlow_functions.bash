#!/usr/bin/env bash

source ${CHEMFLOW_HOME}/test/test_functions.bash
source ${CHEMFLOW_HOME}/src/ScoreFlow_functions.bash


test_ScoreFlow_compute_charges_ligand_in_ChemBase() {
TEST="test_ScoreFlow_compute_charges_ligand_in_ChemBase"

WORKDIR="${CHEMFLOW_HOME}/test/protein_ligand"
PROJECT="test"
PROTOCOL="default"
RECEPTOR_NAME="receptor"
RUNDIR="${WORKDIR}/${PROJECT}.chemflow/ScoreFlow/${PROTOCOL}/${RECEPTOR_NAME}/"

LIGAND_LIST=(CHEMBL477992)
LIGAND=${LIGAND_LIST[0]}
CHARGE="bcc"

if [ -d ${RUNDIR}/${LIGAND} ] ; then
    rm -rf ${RUNDIR}/${LIGAND}
fi
mkdir -p ${RUNDIR}/${LIGAND}
cp ${WORKDIR}/ligand_in_ChemBase.mol2 ${RUNDIR}/${LIGAND}/ligand.mol2

# Call the function and check if ChemBase has been used
output=$(ScoreFlow_rescore_mmgbsa_compute_charges)
output=`echo ${output}`
expected="${CHARGE} charges found in ChemBase for CHEMBL477992"
assertOutputIsExpected


# Check if the file has been created
FILE="${RUNDIR}/${LIGAND}/ligand_${CHARGE}.mol2"
msg="The file ligand_${CHARGE} has not been generated. "
assertFileExits
}


test_ScoreFlow_compute_charges_ligand_in_LigFlow() {
TEST="test_ScoreFlow_compute_charges_ligand_in_LigFlow"

WORKDIR="${CHEMFLOW_HOME}/test/protein_ligand"
PROJECT="test"
PROTOCOL="default"
RECEPTOR_NAME="receptor"
RUNDIR="${WORKDIR}/${PROJECT}.chemflow/ScoreFlow/${PROTOCOL}/${RECEPTOR_NAME}/"

LIGAND_LIST=(CHEMBL11336X)
LIGAND=${LIGAND_LIST[0]}
CHARGE="bcc"

if [ -d ${RUNDIR}/${LIGAND} ] ; then
    rm -rf ${RUNDIR}/${LIGAND}
fi
mkdir -p ${RUNDIR}/${LIGAND}
if [ -d ${WORKDIR}/${PROJECT}.chemflow/LigFlow/${CHARGE}/ ] ; then
    rm -rf ${WORKDIR}/${PROJECT}.chemflow/LigFlow/${CHARGE}/
fi
mkdir -p ${WORKDIR}/${PROJECT}.chemflow/LigFlow/${CHARGE}/
cp ${WORKDIR}/ligand_in_LigFlow.mol2 ${WORKDIR}/${PROJECT}.chemflow/LigFlow/${CHARGE}/${LIGAND}.mol2
cp ${WORKDIR}/ligand_in_LigFlow.mol2 ${RUNDIR}/${LIGAND}/ligand.mol2

# Call the function and check if ChemBase has been used
output=$(ScoreFlow_rescore_mmgbsa_compute_charges)
output=`echo ${output}`
expected="${CHARGE} charges found in LigFlow for ${LIGAND}"
assertOutputIsExpected

# Check if the file has been created
FILE="${RUNDIR}/${LIGAND}/ligand_${CHARGE}.mol2"
msg="The file ligand_${CHARGE} has not been generated. "
assertFileExits
}


test_ScoreFlow_compute_charges_ligand_neither_in_ChemBase_or_LigFlow() {
TEST="test_ScoreFlow_compute_charges_ligand_neither_in_ChemBase_or_LigFlow"

WORKDIR="${CHEMFLOW_HOME}/test/protein_ligand"
PROJECT="test"
PROTOCOL="default"
RECEPTOR_NAME="receptor"
RUNDIR="${WORKDIR}/${PROJECT}.chemflow/ScoreFlow/${PROTOCOL}/${RECEPTOR_NAME}/"
NCORES=8

LIGAND_LIST=(CHEMBL11336X)
LIGAND=${LIGAND_LIST[0]}
CHARGE="bcc"

if [ -f ${WORKDIR}/${PROJECT}.chemflow/LigFlow/${CHARGE}/${LIGAND}.mol2 ] ; then
    rm -f ${WORKDIR}/${PROJECT}.chemflow/LigFlow/${CHARGE}/${LIGAND}.mol2
fi

if [ -d ${RUNDIR}/${LIGAND} ] ; then
    rm -rf ${RUNDIR}/${LIGAND}
fi
mkdir -p ${RUNDIR}/${LIGAND}
cp ${WORKDIR}/ligand_in_LigFlow.mol2 ${RUNDIR}/${LIGAND}/ligand.mol2

# Call the function and check if ChemBase has been used
output=$(ScoreFlow_rescore_mmgbsa_compute_charges)
output=`echo ${output}`
expected="Computing ${CHARGE} charges for ${LIGAND}"
assertOutputIsExpected

# Check if the file has been created
FILE="${RUNDIR}/${LIGAND}/ligand_${CHARGE}.mol2"
msg="The file ligand_${CHARGE} has not been generated."
assertFileExits

# Check if it has been copied in the LigFlow db.
FILE="${WORKDIR}/${PROJECT}.chemflow/LigFlow/${CHARGE}/${LIGAND}.mol2"
msg="The file ${LIGAND}.mol2 has not been saved in LigFlow/${CHARGE}/."
assertFileExits
}


test_ScoreFlow_functions() {
# Test on ScoreFlow_compute_charges
# Usage of ChemBase
echo -ne "[ TestFlow ] Test that charges in ChemBase are used.                                              \r"
test_ScoreFlow_compute_charges_ligand_in_ChemBase
# Usage of LigFlow
echo -ne "[ TestFlow ] Test that charges in LigFlow are used.                                               \r"
test_ScoreFlow_compute_charges_ligand_in_LigFlow
# If the ligand is neither in ChemBase or LigFlow, we compute the charges and save them in LigFlow.
echo -ne "[ TestFlow ] Test that we can compute unknown charges and save them in LigFlow (~10 min)          \r"
test_ScoreFlow_compute_charges_ligand_neither_in_ChemBase_or_LigFlow
}