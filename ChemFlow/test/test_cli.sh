#!/usr/bin/env bash

source ${CHEMFLOW_HOME}/test/test_function.sh

# Test DockFlow input --------------------------------------------------------------------------------------------------
test_dockflow_without_arg(){
TEST="test_dockflow_without_arg"
output=`DockFlow`
output=`echo ${output}`
expected="[ ERROR ] DockFlow called without arguments. For help, type: DockFlow -h"
assertOutputIsExpected
}

test_dockflow_plants_without_project(){
TEST="test_dockflow_plants_without_project"
output=`DockFlow --protocol plants -r receptor.mol2 -l compounds.mol2`
output=`echo ${output}`
expected="[ ChemFlow ] Checking input files... [ ERROR ] No PROJECT name (-p myproject) For help, type: DockFlow -h"
assertOutputIsExpected
}

test_dockflow_vina_without_project(){
TEST="test_dockflow_vina_without_project"
output=`DockFlow --protocol vina -r receptor.mol2 -l compounds.mol2 -sf vina | tail -4`
output=`echo ${output}`
expected="[ ERROR ] No PROJECT name (-p myproject) For help, type: DockFlow -h"
assertOutputIsExpected
}

test_dockflow_plants_without_receptor_file(){
TEST="test_dockflow_plants_without_receptor_file"
output=`DockFlow -p test --protocol plants -l compounds.mol2 | tail -4`
output=`echo ${output}`
expected="[ ERROR ] No RECEPTOR file name (-r receptor_file.mol2) For help, type: DockFlow -h"
assertOutputIsExpected
}

test_dockflow_vina_without_receptor_file(){
TEST="test_dockflow_vina_without_receptor_file"
output=`DockFlow -p test --protocol vina -l compounds.mol2 -sf vina | tail -4`
output=`echo ${output}`
expected="[ ERROR ] No RECEPTOR file name (-r receptor_file.mol2) For help, type: DockFlow -h"
assertOutputIsExpected
}

test_dockflow_plants_without_ligand_file(){
TEST="test_dockflow_plants_without_ligand_file"
output=`DockFlow -p test --protocol plants -r receptor.mol2 | tail -4`
output=`echo ${output}`
expected="[ ERROR ] No LIGAND filename (-l ligand_file.mol2) For help, type: DockFlow -h"
assertOutputIsExpected
}

test_dockflow_vina_without_ligand_file(){
TEST="test_dockflow_vina_without_ligand_file"
output=`DockFlow -p test --protocol vina -r receptor.mol2 -sf vina | tail -4`
output=`echo ${output}`
expected="[ ERROR ] No LIGAND filename (-l ligand_file.mol2) For help, type: DockFlow -h"
assertOutputIsExpected
}

test_dockflow_plants_without_center(){
TEST="test_dockflow_plants_without_center"
output=`DockFlow --project test --protocol plants -r receptor.mol2 -l compounds.mol2 | tail -4`
output=`echo ${output}`
expected="[ ERROR ] No DOCKING CENTER defined (--center x y z) For help, type: DockFlow -h"
assertOutputIsExpected
}

test_dockflow_vina_without_center(){
TEST="test_dockflow_vina_without_center"
output=`DockFlow --project test --protocol vina -r receptor.mol2 -l compounds.mol2 -sf vina | tail -4`
output=`echo ${output}`
expected="[ ERROR ] No DOCKING CENTER defined (--center x y z) For help, type: DockFlow -h"
assertOutputIsExpected
}

test_dockflow_postdock_empty_plants(){
TEST="test_dockflow_postdock_empty_plants"
mkdir -p test.chemflow/DockFlow/plants/receptor/CHEMBL195725
mkdir -p test.chemflow/DockFlow/plants/receptor/CHEMBL477992
output=`DockFlow --project test --protocol plants -r receptor.mol2 -l compounds.mol2 --postdock | tail -6`
output=`echo ${output}`
expected="[ ChemFlow ] Checking input files... [ ERROR ] Plants result for ligand CHEMBL477992 does not exists. [ ERROR ] Plants result for ligand CHEMBL195725 does not exists. [ DockFlow ] Error during post-docking, see error above."
assertOutputIsExpected
rm -rf test.chemflow/DockFlow/plants
}

test_dockflow_postdock_empty_vina(){
TEST="test_dockflow_postdock_empty_vina"
mkdir -p test.chemflow/DockFlow/vina/receptor/CHEMBL195725
mkdir -p test.chemflow/DockFlow/vina/receptor/CHEMBL477992
output=`DockFlow --project test --protocol vina -r receptor.mol2 -l compounds.mol2 -sf vina --postdock | tail -6`
output=`echo ${output}`
expected="[ ChemFlow ] Checking input files... [ ERROR ] Vina's result for ligand CHEMBL477992 does not exists. [ ERROR ] Vina's result for ligand CHEMBL195725 does not exists. [ DockFlow ] Error during post-docking, see error above."
assertOutputIsExpected
rm -rf test.chemflow/DockFlow/vina
}

test_dockflow_wrong_sf() {
output=`DockFlow --project test --protocol wrong -r receptor.mol2 -l compounds.mol2 -sf wrong | tail -4`
output=`echo ${output}`
expected="[ ERROR ] SCORING_FUNCTION wrong not implemented For help, type: DockFlow -h"
assertOutputIsExpected
}

test_dockflow_pdb_receptor_file_for_plants() {
output=`DockFlow --project test --protocol plants -r receptor.pdb -l compounds.mol2 | tail -4`
output=`echo ${output}`
expected="[ ERROR ] Docking requires a mol2 file as receptor input For help, type: DockFlow -h"
assertOutputIsExpected
}

test_dockflow_pdb_receptor_file_for_vina() {
output=`DockFlow --project test --protocol plants -r receptor.pdb -l compounds.mol2 -sf vina | tail -4`
output=`echo ${output}`
expected="[ ERROR ] Docking requires a mol2 file as receptor input For help, type: DockFlow -h"
assertOutputIsExpected
}

# Test ScoreFlow input --------------------------------------------------------------------------------------------------
test_scoreflow_without_arg(){
TEST="test_scoreflow_without_arg"
output=`ScoreFlow`
output=`echo ${output}`
expected="[ ERROR ] ScoreFlow called without arguments. For help, type: ScoreFlow -h"
assertOutputIsExpected
}

test_scoreflow_plants_without_project(){
TEST="test_scoreflow_plants_without_project"
output=`ScoreFlow --protocol plants -r receptor.mol2 -l compounds.mol2`
output=`echo ${output}`
expected="[ ChemFlow ] Checking input files... [ ERROR ] No PROJECT name (-p myproject) For help, type: ScoreFlow -h"
assertOutputIsExpected
}

test_scoreflow_vina_without_project(){
TEST="test_scoreflow_vina_without_project"
output=`ScoreFlow --protocol vina -r receptor.mol2 -l compounds.mol2 -sf vina | tail -4`
output=`echo ${output}`
expected="[ ERROR ] No PROJECT name (-p myproject) For help, type: ScoreFlow -h"
assertOutputIsExpected
}

test_scoreflow_mmgbsa_without_project(){
TEST="test_scoreflow_mmgbsa_without_project"
output=`ScoreFlow --protocol vina -r receptor.pdb -l compounds.mol2 -sf mmgbsa | tail -4`
output=`echo ${output}`
expected="[ ERROR ] No PROJECT name (-p myproject) For help, type: ScoreFlow -h"
assertOutputIsExpected
}

test_scoreflow_plants_without_receptor_file(){
TEST="test_scoreflow_plants_without_receptor_file"
output=`ScoreFlow -p test --protocol plants -l compounds.mol2 | tail -4`
output=`echo ${output}`
expected="[ ERROR ] No RECEPTOR file name (-r receptor_file.mol2) For help, type: ScoreFlow -h"
assertOutputIsExpected
}

test_scoreflow_vina_without_receptor_file(){
TEST="test_scoreflow_vina_without_receptor_file"
output=`ScoreFlow -p test --protocol vina -l compounds.mol2 -sf vina | tail -4`
output=`echo ${output}`
expected="[ ERROR ] No RECEPTOR file name (-r receptor_file.mol2) For help, type: ScoreFlow -h"
assertOutputIsExpected
}

test_scoreflow_mmgbsa_without_receptor_file(){
TEST="test_scoreflow_mmgbsa_without_receptor_file"
output=`ScoreFlow -p test --protocol vina -l compounds.mol2 -sf mmgbsa | tail -4`
output=`echo ${output}`
expected="[ ERROR ] No RECEPTOR file name (-r receptor_file.pdb) For help, type: ScoreFlow -h"
assertOutputIsExpected
}

test_scoreflow_plants_without_ligand_file(){
TEST="test_scoreflow_plants_without_ligand_file"
output=`ScoreFlow -p test --protocol plants -r receptor.mol2 | tail -4`
output=`echo ${output}`
expected="[ ERROR ] No LIGAND filename (-l ligand_file.mol2) For help, type: ScoreFlow -h"
assertOutputIsExpected
}

test_scoreflow_vina_without_ligand_file(){
TEST="test_scoreflow_vina_without_ligand_file"
output=`ScoreFlow -p test --protocol vina -r receptor.mol2 -sf vina | tail -4`
output=`echo ${output}`
expected="[ ERROR ] No LIGAND filename (-l ligand_file.mol2) For help, type: ScoreFlow -h"
assertOutputIsExpected
}

test_scoreflow_mmgbsa_without_ligand_file(){
TEST="test_scoreflow_mmgbsa_without_ligand_file"
output=`ScoreFlow -p test --protocol vina -r receptor.mol2 -sf mmgbsa | tail -4`
output=`echo ${output}`
expected="[ ERROR ] No LIGAND filename (-l ligand_file.mol2) For help, type: ScoreFlow -h"
assertOutputIsExpected
}

test_scoreflow_plants_without_center(){
TEST="test_scoreflow_plants_without_center"
output=`ScoreFlow --project test --protocol plants -r receptor.mol2 -l compounds.mol2 | tail -4`
output=`echo ${output}`
expected="[ ERROR ] No DOCKING CENTER defined (--center x y z) For help, type: ScoreFlow -h"
assertOutputIsExpected
}

test_scoreflow_vina_without_center(){
TEST="test_scoreflow_vina_without_center"
output=`ScoreFlow --project test --protocol vina -r receptor.mol2 -l compounds.mol2 -sf vina | tail -4`
output=`echo ${output}`
expected="[ ERROR ] No DOCKING CENTER defined (--center x y z) For help, type: ScoreFlow -h"
assertOutputIsExpected
}

test_scoreflow_postprocess_empty_plants(){
TEST="test_scoreflow_postprocess_empty_plants"
mkdir -p test.chemflow/ScoreFlow/plants/receptor/
output=`ScoreFlow --project test --protocol plants -r receptor.mol2 -l compounds.mol2 --postprocess | tail -4`
output=`echo ${output}`
expected="[ ERROR ] Plants results for PROJECT 'test' / PROTOCOL 'plants' does not exists. For help, type: ScoreFlow -h"
assertOutputIsExpected
rm -rf test.chemflow/ScoreFlow/plants
}

test_scoreflow_postprocess_empty_vina(){
TEST="test_scoreflow_postprocess_empty_vina"
mkdir -p test.chemflow/ScoreFlow/vina/receptor/
output=`ScoreFlow --project test --protocol vina -r receptor.mol2 -l compounds.mol2 -sf vina --postprocess | tail -5`
output=`echo ${output}`
expected="[ ERROR ] Vina results for PROJECT 'test' / PROTOCOL 'vina' does not exists. For help, type: ScoreFlow -h"
assertOutputIsExpected
rm -rf test.chemflow/ScoreFlow/vina
}

test_scoreflow_postprocess_empty_mmgbsa(){
TEST="test_scoreflow_postprocess_empty_mmgbsa"
mkdir -p test.chemflow/ScoreFlow/mmgbsa/receptor/
output=`ScoreFlow --project test --protocol mmgbsa -r receptor.pdb -l compounds.mol2 -sf mmgbsa --postprocess | tail -5`
output=`echo ${output}`
expected="[ ERROR ] Amber results for PROJECT 'test' / PROTOCOL 'mmgbsa' does not exists. For help, type: ScoreFlow -h"
assertOutputIsExpected
rm -rf test.chemflow/ScoreFlow/vina
}

test_scoreflow_wrong_sf() {
TEST="test_scoreflow_wrong_sf"
output=`ScoreFlow --project test --protocol wrong -r receptor.mol2 -l compounds.mol2 -sf wrong | tail -4`
output=`echo ${output}`
expected="[ ERROR ] SCORING_FUNCTION wrong not implemented For help, type: ScoreFlow -h"
assertOutputIsExpected
}

test_scoreflow_plants_pdb_receptor_file() {
TEST="test_scoreflow_plants_pdb_receptor_file"
output=`ScoreFlow --project test --protocol plants -r receptor.pdb -l compounds.mol2 | tail -4`
output=`echo ${output}`
expected="[ ERROR ] Plants rescoring requires a mol2 file as receptor input For help, type: ScoreFlow -h"
assertOutputIsExpected
}

test_scoreflow_vina_pdb_receptor_file() {
TEST="test_scoreflow_vina_pdb_receptor_file"
output=`ScoreFlow --project test --protocol plants -r receptor.pdb -l compounds.mol2 -sf vina | tail -4`
output=`echo ${output}`
expected="[ ERROR ] Vina rescoring requires a mol2 file as receptor input For help, type: ScoreFlow -h"
assertOutputIsExpected
}

test_scoreflow_mmgbsa_mol2_receptor_file() {
TEST="test_scoreflow_mmgbsa_mol2_receptor_file"
output=`ScoreFlow --project test --protocol plants -r receptor.mol2 -l compounds.mol2 -sf mmgbsa | tail -4`
output=`echo ${output}`
expected="[ ERROR ] mmgbsa rescoring requires a PDB file as receptor input For help, type: ScoreFlow -h"
assertOutputIsExpected
}

test_scoreflow_plants_unexisting_receptor_file() {
TEST="test_scoreflow_plants_unexisting_receptor_file"
output=`ScoreFlow --project test --protocol plants -r receptor_unexisting.mol2 -l compounds.mol2 | tail -4`
output=`echo ${output}`
expected="[ ERROR ] The receptor file receptor_unexisting.mol2 does not exist. For help, type: ScoreFlow -h"
assertOutputIsExpected
}

test_scoreflow_vina_unexisting_receptor_file() {
TEST="test_scoreflow_vina_unexisting_receptor_file"
output=`ScoreFlow --project test --protocol plants -r receptor_unexisting.mol2 -l compounds.mol2 -sf vina | tail -4`
output=`echo ${output}`
expected="[ ERROR ] The receptor file receptor_unexisting.mol2 does not exist. For help, type: ScoreFlow -h"
assertOutputIsExpected
}

test_scoreflow_mmgbsa_unexisting_receptor_file() {
TEST="test_scoreflow_mmgbsa_unexisting_receptor_file"
output=`ScoreFlow --project test --protocol plants -r receptor_unexisting.pdb -l compounds.mol2 -sf mmgbsa | tail -4`
output=`echo ${output}`
expected="[ ERROR ] The receptor file receptor_unexisting.pdb does not exist. For help, type: ScoreFlow -h"
assertOutputIsExpected
}

test_cli() {
# Tests DockFlow cli
test_dockflow_without_arg

test_dockflow_plants_without_project
test_dockflow_vina_without_project

test_dockflow_plants_without_receptor_file
test_dockflow_vina_without_receptor_file

test_dockflow_plants_without_ligand_file
test_dockflow_vina_without_ligand_file

test_dockflow_vina_without_center
test_dockflow_plants_without_center

test_dockflow_postdock_empty_plants
test_dockflow_postdock_empty_vina

# test receptor file
test_dockflow_wrong_sf
test_dockflow_pdb_receptor_file_for_plants
test_dockflow_pdb_receptor_file_for_vina

# Tests ScoreFlow cli
test_scoreflow_without_arg

test_scoreflow_plants_without_project
test_scoreflow_vina_without_project

test_scoreflow_plants_without_receptor_file
test_scoreflow_vina_without_receptor_file

test_scoreflow_plants_without_ligand_file
test_scoreflow_vina_without_ligand_file

test_scoreflow_vina_without_center
test_scoreflow_plants_without_center

test_scoreflow_postprocess_empty_plants
test_scoreflow_postprocess_empty_vina
test_scoreflow_postprocess_empty_mmgbsa

# test receptor file
test_scoreflow_wrong_sf
test_scoreflow_plants_pdb_receptor_file
test_scoreflow_vina_pdb_receptor_file
test_scoreflow_mmgbsa_mol2_receptor_file
test_scoreflow_plants_unexisting_receptor_file
test_scoreflow_vina_unexisting_receptor_file
test_scoreflow_mmgbsa_unexisting_receptor_file


}