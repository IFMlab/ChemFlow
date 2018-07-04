#!/bin/bash

# Run tests for ChemFlow modules

# init
if [ "$(basename ${PWD})" == 'test' ]; then
  rm -rf $(ls | grep -v ".sh" | grep -v ".tar.gz" | grep -v ".MD")
fi
error_count=0
warning_count=0

# utils
source ${CHEMFLOW_HOME}/common/colors.bash

test_error() {
  echo -e "${RED}ERROR${NC} at step: ${step}"
  echo -e "ERROR at step: ${step}" | tee summary.log output.log >/dev/null
  let error_count+=1
}

test_warning() {
  echo -e "${YELLOW}WARNING${NC} at step: ${step}"
  echo -e "WARNING at step: ${step}" | tee summary.log output.log >/dev/null
  echo -e "Expected ${expect}, got ${value}"
  echo -e "Expected ${expect}, got ${value}" | tee summary.log output.log >/dev/null
  let warning_count+=1
}

# untar the archive
tar -zxf hostguest.tar.gz

# TOOLS
# modules tested: SmilesTo3D, RMSDFlow
echo -e "Testing ChemFlow Tools"
step="Babel MOL2 to SMI"
babel -imol2 input/AD0.mol2 -osmi AD0.smi >> output.log 2>&1
babel -ismi AD0.smi -omol2 AD0_babel.mol2 >> output.log 2>&1
if [ ! -f AD0.smi ] || [ ! -f AD0_babel.mol2 ]; then
  test_error
else
  step="Generating 3D structure with SmilesTo3D"
  python $CHEMFLOW_HOME/Tools/SmilesTo3D.py -i AD0.smi -o AD0_smi.sdf --hydrogen -v >> output.log 2>&1
  babel -isdf AD0_smi.sdf -omol2 AD0_smi.mol2 >> output.log 2>&1
  if [ ! -f AD0_smi.mol2 ] || [ ! -f AD0_smi.sdf ]; then
    test_error
  else
    step="RMSDFlow Babel versus SmilesTo3D"
    value=$(python $CHEMFLOW_HOME/Tools/RMSDFlow.py -r AD0_babel.mol2 -i AD0_smi.mol2)
    if [ -z "${value}" ]; then
      test_error
    else
      step="SmilesTo3D comparing rmsd with expected value"
      expect=1.8
      outcome=$(echo ${value}'<='${expect} | bc -l)
      if [ "${outcome}" = 0 ]; then test_warning; fi
    fi
  fi
fi

# DOCKING
# modules tested: DOCKFLOW, bounding_shape
## PLANTS
echo -e "Testing Docking with PLANTS"
step="DOCKING PLANTS"
sphere_list=$(python ${CHEMFLOW_HOME}/Tools/bounding_shape.py input/AD0.mol2 --sphere 0.3)
bs_center=$(echo "${sphere_list}" | cut -d" " -f"1,2,3")
bs_radius=$(echo "${sphere_list}" | cut -d" " -f4)
DockFlow -f input/docking.cfg -r input/CB7.mol2 -l input/AD0.mol2 -o plants \
  -sf chemplp --center ${bs_center} --radius ${bs_radius} >> output.log 2>&1
if [ ! -f plants/ranking_sorted.csv ]; then
  test_error
else
  value=$(tail -1 plants/ranking_sorted.csv | cut -d, -f2)
  step="DOCKING PLANTS accessing affinity"
  if [ -z "${value}" ]; then
    test_error
  else
    step="DOCKING PLANTS comparing affinity with expected value"
    expect=-102
    outcome=$(echo ${value}'<='${expect} | bc -l)
    if [ "${outcome}" = 0 ]; then test_warning; fi
  fi
fi

## Vina
echo -e "Testing Docking with VINA"
step="DOCKING VINA"
sphere_list=$(python ${CHEMFLOW_HOME}/Tools/bounding_shape.py input/AD0.mol2 --box 0.5)
bs_center=$(echo "${sphere_list}" | cut -d" " -f"1,2,3")
bs_size=$(echo "${sphere_list}"   | cut -d" " -f"4,5,6")
DockFlow -f input/docking.cfg  -r input/CB7.mol2 -l input/AD0.mol2 -o vina \
  -sf vina --center ${bs_center} --size ${bs_size} >> output.log 2>&1
if [ ! -f vina/ranking_sorted.csv ]; then
  test_error
else
  value=$(tail -1 vina/ranking_sorted.csv | cut -d, -f2)
  step="DOCKING VINA accessing affinity"
  if [ -z "${value}" ]; then
    test_error
  else
    step="DOCKING VINA comparing affinity with expected value"
    expect=-5.4
    outcome=$(echo ${value}'<='${expect} | bc -l)
    if [ "${outcome}" = 0 ]; then test_warning; fi
  fi
fi

# RMSDFlow
## PLANTS
echo -e "Testing RMSDFlow with PLANTS"
step="RMSD PLANTS"
value=$(python $CHEMFLOW_HOME/Tools/RMSDFlow.py -r input/AD0.mol2 -i plants/AD0/docked_ligands.mol2)
if [ -z "${value}" ]; then
  test_error
else
  step="RMSD PLANTS comparing rmsd with expected value"
  expect=0.26
  outcome=$(echo ${value}'<='${expect} | bc -l)
  if [ "${outcome}" = 0 ]; then test_warning; fi
fi

## VINA
echo -e "Testing RMSDFlow with VINA"
step="RMSD VINA"
value=$(python $CHEMFLOW_HOME/Tools/RMSDFlow.py -r input/AD0.mol2 -i vina/AD0/docked_ligands.mol2)
if [ -z "${value}" ]; then
  test_error
else
  step="RMSD VINA comparing rmsd with expected value"
  expect=1.0
  outcome=$(echo ${value}'<='${expect} | bc -l)
  if [ "${outcome}" = 0 ]; then test_warning; fi
fi

# End tests
if [ "${warning_count}" -gt 0 ]; then
  WARN=${YELLOW}
else
  WARN=${GREEN}
fi
if [ "${error_count}" -gt 0 ]; then
  ERR=${RED}
  echo -e "${ERR}Failed${NC} tests with ${ERR}${error_count} ERRORS${NC} and ${WARN}${warning_count} WARNINGS${NC} !"
else
  ERR=${GREEN}
  echo -e "${WARN}Passed${NC} tests with ${ERR}${error_count} ERRORS${NC} and ${WARN}${warning_count} WARNINGS${NC} !"
fi
