#!/bin/bash

# Check the ScoreFlow config file, make folders and write config files for rescoring
prepare_rescoring() {
# Instead of absolute path,
# set "dir" to run folder.
dir=$PWD

# Create a time stamp, in order to backup rescoring output directories if they already exists
datetime=$(date "+%Y%m%d%H%M%S")

# Check if everything is ok with the input.
check_input

# Depending on what the user wants to do (VS, BEST or PDB rescoring), take actions

# PDB rescoring mode
if [ "${mode}" = "PDB" ]; then
  # List complexes, create folder
  # and write plants config in each folder
  list_complexes
elif $(list_include_item "VS BEST" "${mode}"); then
  list_docking
fi
}

# List complexes, make folders and write the config files
list_complexes() {
# list all pdb files in the complex folder.
list=$(cd ${PDB_folder} ; ls -1 *.pdb)
com_list=$(echo $list | sed s/.pdb//g )

if [ -z "$list" ]
then
  echo -e "${RED}ERROR${NC} : Could not find pdb files in ${PDB_folder}"
  exit 1
fi

# Create an output folder per complex.
for com in $com_list ; do
  mkdir -p ${dir}/output/${scoring_function}_rescoring/${com}

  # And write the plants config file there.
  cd ${dir}/output/${scoring_function}_rescoring/${com}

  # Separate the complex in protein, ligand(s) and water mol2 files
  cd ${PDB_folder} # otherwise spores will add the path to the ligand name inside the file, which causes some bugs with PLANTS
  ${SPORES} --mode splitpdb ${com}.pdb > ${dir}/output/${scoring_function}_rescoring/${com}/spores.job 2>&1
 
  # Output is $PDB_folder, so we need to move it
  mv ${PDB_folder}/*.mol2 ${dir}/output/${scoring_function}_rescoring/${com}/
  
  # path to ligand and receptor
  lig=$(ls ${dir}/output/${scoring_function}_rescoring/${com}/ligand*.mol2 | sed s/.mol2//g)
  rec=$(ls ${dir}/output/${scoring_function}_rescoring/${com}/protein.mol2 | sed s/.mol2//g)
  if [ "${rescore_method}" = "mmpbsa" ]; then
    babel -imol2 ${rec}.mol2 -opdb babel_${rec}.pdb
    pdb4amber -i babel_${rec}.pdb -o ${rec}.pdb -p
  fi

  # write the config file
  cd ${dir}/output/${scoring_function}_rescoring/${com}
  echo -ne "Configuring ${PURPLE}${lig}${NC}              \r"
  if [ "${rescore_method}" = "plants" ]; then
    write_plants_config
  elif [ "${rescore_method}" = "vina" ]; then
    write_vina_config
  elif [ "${rescore_method}" = "mmpbsa" ]; then
    write_pbsa_config
  fi
done
echo ""
}


# List docking results, make folders and write config files
list_docking() {

# Receptor
filename=$(basename "$rec")
extension="${filename##*.}"
if   [ ! "${extension}" = "pdb" ]  ; then rec=$(echo "$rec" | sed s/.pdb//g)
elif [ ! "${extension}" = "mol2" ] ; then rec=$(echo "$rec" | sed s/.mol2//g)
fi

# list all ligands folder
if [ "${mode}" = "VS" ]; then
 lig_list=$(cd ${VS_folder} ; \ls -l | grep "^d" | awk '{print $9}')
elif [ "${mode}" = "BEST" ]; then
  lig_list=$(cd ${BEST_folder} ; \ls -l | grep "^d" | awk '{print $9}')
fi

# list all docking poses in the VS_folder
pose_list=""
for ligand in $lig_list; do
  if [ "${mode}" = "VS" ]; then
    poses=$(cd ${VS_folder}/${ligand}/docking/; ls *conf*.mol2 | sed s/.mol2//g )
  elif [ "${mode}" = "BEST" ]; then
    poses=$(cd ${BEST_folder}/${ligand}/docking/; ls *.mol2 | sed s/.mol2//g )
  fi
  
  for pose in ${poses}
  do
    if [ "${mode}" = "VS" ]; then
      lig="${VS_folder}/${ligand}/docking/${pose}"
    elif [ "${mode}" = "BEST" ]; then
      lig="${BEST_folder}/${ligand}/docking/${pose}"
    fi
    mkdir -p ${dir}/output/${scoring_function}_rescoring/${ligand}/${pose}
    pose_list+=" ${ligand}/${pose}"

    # And write the plants config file there.
    cd ${dir}/output/${scoring_function}_rescoring/${ligand}/${pose}

    # write the config file
    echo -ne "Configuring ${PURPLE}${pose}${NC} from ${PURPLE}${ligand}${NC}             \r"
    if [ "${rescore_method}" = "plants" ]; then
      write_plants_config
    elif [ "${rescore_method}" = "vina" ]; then
      lig="${dir}/output/${scoring_function}_rescoring/${ligand}/${pose}/${pose}"
      write_vina_config
    elif [ "${rescore_method}" = "mmpbsa" ]; then
      write_pbsa_config
    fi
  done
done

if [ -z "$pose_list" ]
then
  if [ "${mode}" = "VS" ]; then
    echo -e "${RED}ERROR${NC} : Could not find mol2 docking poses in ${VS_folder}"    
  elif [ "${mode}" = "BEST" ]; then
    echo -e "${RED}ERROR${NC} : Could not find mol2 docking poses in ${BEST_folder}"
  fi
  exit 1
fi

}


############################################################
# PLANTS
############################################################

# Write Plants Configuration file
write_plants_config() {
echo -e "
# scoring function and search settings
scoring_function ${scoring_function}
search_speed speed1

# input
protein_file ${rec}.mol2
ligand_file  ${lig}.mol2

# output
output_dir results

# write mol2 files as a single (0) or multiple (1) files
write_multi_mol2 0

# water molecule centered on a sphere of coord x y z and can move in radius r
${dock_water}

# write
write_ranking_links 0
write_protein_bindingsite 1
write_protein_conformations 0
####
">config.plants
}


write_plants_pbs() {
temp_pose=$(echo "$pose" | cut -d"/" -f2)
echo "#!/bin/bash
#PBS -N PLANTS_${temp_pose}
#PBS -l nodes=1:ppn=1,walltime=24:00:00.00
#PBS -o ${dir}/output/${scoring_function}_rescoring/${pose}/${temp_pose}.o
#PBS -e ${dir}/output/${scoring_function}_rescoring/${pose}/${temp_pose}.e

#-----user_section-----------------------------------------------
module load plants/1.2

cd \$PBS_O_WORKDIR

#----Runing the VS---------
plants --mode rescore config.plants

#---Reorganize data
cd results
mv protein_bindingsite_fixed.mol2 ${dir}/output/${scoring_function}_rescoring/
tail -n +2 features.csv >> ${dir}/output/${scoring_function}_rescoring/features.csv
tail -n +2 ranking.csv >> ${dir}/output/${scoring_function}_rescoring/ranking.csv
cd ${dir}/output/${scoring_function}_rescoring/
rm -rf ${common_folder}

"> plants.pbs
}

# Run PLANTS
run_plants() {

# Create features.csv and ranking.csv headers
echo "LIGAND_ENTRY,TOTAL_SCORE,SCORE_RB_PEN,SCORE_NORM_HEVATOMS,SCORE_NORM_CRT_HEVATOMS,SCORE_NORM_WEIGHT,SCORE_NORM_CRT_WEIGHT,SCORE_RB_PEN_NORM_CRT_HEVATOMS,SCORE_NORM_CONTACT,EVAL,TIME">${dir}/output/${scoring_function}_rescoring/ranking.csv
echo "TOTAL_SCORE,SCORE_RB_PEN,SCORE_NORM_HEVATOMS,SCORE_NORM_CRT_HEVATOMS,SCORE_NORM_WEIGHT,SCORE_NORM_CRT_WEIGHT,SCORE_RB_PEN_NORM_CRT_HEVATOMS,SCORE_NORM_CONTACT,PLPtotal,PLPparthbond,PLPpartsteric,PLPpartmetal,PLPpartrepulsive,PLPpartburpolar,LIG_NUM_CLASH,LIG_NUM_CONTACT,LIG_NUM_NO_CONTACT,CHEMpartmetal,CHEMparthbond,CHEMparthbondCHO,DON,ACC,UNUSED_DON,UNUSED_ACC,CHEMPLP_CLASH2,TRIPOS_TORS,ATOMS_OUTSIDE_BINDINGSITE">${dir}/output/${scoring_function}_rescoring/features.csv

# If rescoring mode is for complexes
if [ "${mode}" = "PDB" ]; then
  for com in ${com_list} ; do
    common_folder="${com}"
    cd ${dir}/output/${scoring_function}_rescoring/${com}
    echo -ne "Running ${PURPLE}${com}${NC}              \r"
    if [ "${run_mode}" = "local" ]    ; then
      ${PLANTS} --mode rescore config.plants > plants.job
    fi

    if [ "${run_mode}" = "parallel" ] ; then
      echo "cd ${dir}/output/${scoring_function}_rescoring/${pose} ; ${PLANTS} --mode rescore config.plants > plants.job; cd results; mv protein_bindingsite_fixed.mol2 ${dir}/output/${scoring_function}_rescoring/; tail -n +2 features.csv >> ${dir}/output/${scoring_function}_rescoring/features.csv; tail -n +2 ranking.csv >> ${dir}/output/${scoring_function}_rescoring/ranking.csv; cd ${dir}/output/${scoring_function}_rescoring/; rm -rf ${common_folder}" >> ${dir}/output/${scoring_function}_rescoring/rescore_${datetime}.parallel
    fi
  done
  echo ""

  if [ "${run_mode}" = "parallel" ] ; then
    echo -e "Running in parallel"
    ${parallel} -j ${core_number} < ${dir}/output/${scoring_function}_rescoring/rescore_${datetime}.parallel > ${dir}/output/${scoring_function}_rescoring/parallel.job 2>&1
  fi

# If rescoring mode is for docking results
elif $(list_include_item "VS BEST" "${mode}"); then
  for pose in ${pose_list} ; do
    common_folder="${pose}"
    cd ${dir}/output/${scoring_function}_rescoring/${pose}

    if [ "${run_mode}" = "local" ]    ; then
      echo -ne "Running ${PURPLE}${pose}${NC}              \r"
      ${PLANTS} --mode rescore config.plants > plants.job
      reorganize_plants

    elif [ "${run_mode}" = "parallel" ] ; then
      echo "cd ${dir}/output/${scoring_function}_rescoring/${pose} ; ${PLANTS} --mode rescore config.plants > plants.job; cd results; mv protein_bindingsite_fixed.mol2 ${dir}/output/${scoring_function}_rescoring/; tail -n +2 features.csv | sed 's/\(^.*_entry.*_conf.*\)_entry.*_conf_[[:digit:]]*\(,.*$\)/\1\2/g' >> ${dir}/output/${scoring_function}_rescoring/features.csv; tail -n +2 ranking.csv | sed 's/\(^.*_entry.*_conf.*\)_entry.*_conf_[[:digit:]]*\(,.*$\)/\1\2/g' >> ${dir}/output/${scoring_function}_rescoring/ranking.csv; cd ${dir}/output/${scoring_function}_rescoring/; rm -rf ${common_folder}" >> ${dir}/output/${scoring_function}_rescoring/rescore_${datetime}.parallel
    
    elif [ "${run_mode}" = "mazinger" ]; then
      write_plants_pbs
      jobid=$(qsub plants.pbs)
      echo "$jobid" >> ${dir}/output/${scoring_function}_rescoring/jobs_list_${datetime}.mazinger
      echo -ne "Running ${PURPLE}${pose}${NC} on ${BLUE}${jobid}${NC}              \r"
    fi
  done
  echo ""

  if [ "${run_mode}" = "parallel" ] ; then
    echo -e "Running in parallel"
    ${parallel} -j ${core_number} < ${dir}/output/${scoring_function}_rescoring/rescore_${datetime}.parallel > ${dir}/output/${scoring_function}_rescoring/parallel.job 2>&1
  fi
fi
}

reorganize_plants() {
  cd results
  mv protein_bindingsite_fixed.mol2 ${dir}/output/${scoring_function}_rescoring/
  # the command tail -n +2 skip the first line (containing the header), and starts printing at the 2nd line of the file
  # PLANTS appends _entry_XXX_conf_XX to the rescored poses in the csv tables, so we use sed 's/\(^.*_entry.*_conf.*\)_entry.*_conf_[[:digit:]]*\(,.*$\)/\1\2/g' to remove this string from the names
  tail -n +2 features.csv | sed 's/\(^.*_entry.*_conf.*\)_entry.*_conf_[[:digit:]]*\(,.*$\)/\1\2/g' >> ${dir}/output/${scoring_function}_rescoring/features.csv 
  tail -n +2 ranking.csv | sed 's/\(^.*_entry.*_conf.*\)_entry.*_conf_[[:digit:]]*\(,.*$\)/\1\2/g' >> ${dir}/output/${scoring_function}_rescoring/ranking.csv
  cd ${dir}/output/${scoring_function}_rescoring/
  rm -rf ${common_folder}
}


################################################
# VINA
################################################

write_vina_config() {
echo "# input
receptor = ${rec}.pdbqt
ligand   = ${lig}.pdbqt
">config.vina
}

write_vina_pbs() {
temp_pose=$(echo "$pose" | cut -d"/" -f2)
echo "#!/bin/bash
#PBS -N PLANTS_${temp_pose}
#PBS -l nodes=1:ppn=1,walltime=24:00:00.00
#PBS -o ${dir}/output/${scoring_function}_rescoring/${pose}/${temp_pose}.o
#PBS -e ${dir}/output/${scoring_function}_rescoring/${pose}/${temp_pose}.e

#-----user_section-----------------------------------------------
module load vina

cd \$PBS_O_WORKDIR

# Rescore
vina --score_only --config config.vina --log ${temp_pose}.log
"> vina.pbs
}


run_vina() {
rec=$(ls ${dir}/rec/*.mol2 | sed s/.mol2//g )
if [ "${mode}" = "PDB" ]; then

  for com in ${com_list} ; do
    cd ${dir}/output/${scoring_function}_rescoring/${com}

    if [ "${run_mode}" = "local" ]    ; then
      echo -ne "Running ${PURPLE}${com}${NC}              \r"
      lig=$(ls ligand*.mol2 | sed s/.mol2//g)
      rec=$(ls protein.mol2 | sed s/.mol2//g)
      # Prepare receptor
      ${ADT}/prepare_receptor4.py -r ${rec}.mol2 > convert2pdbqt.job
      # Prepare lig
      ${ADT}/prepare_ligand4.py -l ${lig}.mol2 >> convert2pdbqt.job
      # Run
      ${VINA} --score_only --config config.vina --log output.log > vina.job
    fi

    if [ "${run_mode}" = "parallel" ] ; then
      lig=$(ls ligand*.mol2 | sed s/.mol2//g)
      rec=$(ls protein.mol2 | sed s/.mol2//g)
      echo "cd ${dir}/output/${scoring_function}_rescoring/${com} ; ${ADT}/prepare_receptor4.py -r ${rec}.mol2 > convert2pdbqt.job; ${ADT}/prepare_ligand4.py -l ${lig}.mol2 >> convert2pdbqt.job; ${VINA} --score_only --config config.vina --log output.log > vina.job" >> ${dir}/output/${scoring_function}_rescoring/rescore_${datetime}.parallel
    fi
  done
  echo ""

  if [ "${run_mode}" = "parallel" ] ; then
    echo "Running in parallel"
    ${parallel} -j ${core_number} < ${dir}/output/${scoring_function}_rescoring/rescore_${datetime}.parallel > ${dir}/output/${scoring_function}_rescoring/parallel.job 2>&1
  fi

elif $(list_include_item "VS BEST" "${mode}"); then
  if [ $mode = "VS" ]; then folder="${VS_folder}"
  elif [ $mode = "BEST" ]; then folder="${BEST_folder}"
  fi

  # convert receptor
  cd ${dir}/rec/
  ${ADT}/prepare_receptor4.py -r ${rec}.mol2 > convert2pdbqt.job

  for pose in ${pose_list} ; do
    lig=$(echo "$pose" | cut -d"/" -f1)
    tmp_pose=$(echo "$pose" | cut -d"/" -f2)
    cd ${dir}/output/${scoring_function}_rescoring/${pose}

    if [ "${run_mode}" = "local" ]    ; then
      echo -ne "Running ${PURPLE}${pose}${NC}              \r"
      # Prepare lig
      ${ADT}/prepare_ligand4.py -l ${folder}/${lig}/docking/${tmp_pose}.mol2 >> convert2pdbqt.job
      # Run
      ${VINA} --score_only --config config.vina --log output.log > vina.job

    elif [ "${run_mode}" = "parallel" ] ; then
      echo "cd ${dir}/output/${scoring_function}_rescoring/${pose}; ${ADT}/prepare_ligand4.py -l ${folder}/${lig}/docking/${tmp_pose}.mol2 >> convert2pdbqt.job; ${VINA} --score_only --config config.vina --log output.log > vina.job" >> ${dir}/output/${scoring_function}_rescoring/rescore_${datetime}.parallel

    elif [ "${run_mode}" = "mazinger" ]; then
      write_vina_pbs
      ${ADT}/prepare_ligand4.py -l ${folder}/${lig}/docking/${tmp_pose}.mol2 >> convert2pdbqt.job
      jobid=$(qsub vina.pbs)
      echo -ne "Running ${PURPLE}${pose}${NC} on ${BLUE}${jobid}${NC}              \r"
    fi
  done
  echo ""

  if [ "${run_mode}" = "parallel" ] ; then
    echo "Running in parallel"
    ${parallel} -j ${core_number} < ${dir}/output/${scoring_function}_rescoring/rescore_${datetime}.parallel > ${dir}/output/${scoring_function}_rescoring/parallel.job 2>&1
  fi
fi
}

#################################################
# MMPBSA
#################################################

# Write tleap configuration file, no water
write_tleap_without_water() {
echo "source leaprc.protein.ff14SB
source leaprc.gaff
set default pbradii ${radii}

loadamberparams ${lig}.frcmod
loadOff ${lig}.lib
saveamberparm MOL lig.prmtop lig.rst7
savepdb MOL lig.pdb

rec = loadpdb ${rec}.pdb
saveamberparm rec rec.prmtop rec.rst7
savepdb rec rec.pdb 

com = combine {rec, MOL}
saveamberparm com com.prmtop com.rst7
savepdb com com.pdb
quit">leap.cmd
}

# Write tleap configuration file, with water
write_tleap_with_water() {
echo "source leaprc.protein.ff14SB
source leaprc.gaff
source leaprc.water.tip3p

set default pbradii ${radii}

loadamberparams ${lig}.frcmod
loadOff ${lig}.lib
saveamberparm MOL lig.prmtop lig.rst7
savepdb MOL lig.pdb

rec = loadpdb ${rec}.pdb
saveamberparm rec rec.prmtop rec.rst7
savepdb rec rec.pdb 

wat = loadmol2 $water
com = combine {rec, wat, MOL}
saveamberparm com com.prmtop com.rst7
savepdb com com.pdb
quit">leap.cmd
}

# Run tleap
run_tleap() {
tleap -f leap.cmd &>tleap.job
}

# Write MMPBSA/MMGBSA config files
write_pbsa_config() {
if [ "$scoring_function" = "GB8" ] ; then
echo "GBSA using GB8
&general
verbose=2, keep_files=0,
/
&gb
igb=8, saltcon=0.150,
/
"> GB8.in

elif [ "$scoring_function" = "GB5" ] ; then
echo "GBSA using GB5
&general
verbose=2, keep_files=0,
/
&gb
igb=5, saltcon=0.150,
/
"> GB5.in

elif [ "$scoring_function" == "PB3" ] ; then

# old config
echo "PBSA using PB3
&cntrl
ntx=1, imin=1, igb=10, inp=1,
/
&pb
epsout=80.0, epsin=1.0, space=0.5, bcopt=6, dprob=1.4,
cutnb=0, eneopt=2,
accept=0.001, sprob=1.6, radiopt=0, fillratio=4,
maxitn=1000, arcres=0.0625,
cavity_surften=0.005, cavity_offset=0.86
/
">/dev/null

echo "PBSA using PB3
&general
verbose=2, keep_files=0,
/
&pb
inp=1,                     
radiopt=0,                
istrng=0.15,              
cavity_surften=0.00542,   
cavity_offset=0.92,        
/
"> PB3.in
fi
}



# Write PBS script for MMPBSA
write_pbsa_pbs() {
echo "#!/bin/bash
#PBS -N PBSA_${pose}
#PBS -l nodes=1:ppn=1,walltime=24:00:00.00
#PBS -o ${dir}/output/${scoring_function}_rescoring/${pose}.o
#PBS -e ${dir}/output/${scoring_function}_rescoring/${pose}.e

#-----user_section-----------------------------------------------
source ${amber} 

cd \$PBS_O_WORKDIR
"> mmpbsa.pbs

mmpbsa_text >> mmpbsa.pbs
}

mmpbsa_cmd() {
# Preparation of files for MMPBSA
# Run tleap to prepare topology and coordinates
if [ -z "${water} "]; then
  write_tleap_without_water
else
  write_tleap_with_water
fi
run_tleap

# Run a quick minimization if asked by user
if [ ! -z "${min_steps}" ]; then
  mv com.pdb com_before_min.pdb
  mv com.rst7 com_before_min.rst7
  if [ "${min_type}" = "backbone" ]; then
    minab_mask=":${min_mask}:CA|:${min_mask}:N|:${min_mask}:C|:${min_mask}:O"
  else
    minab_mask="$min_mask"
  fi

  minab com_before_min.pdb com.prmtop com.pdb ${implicit_model} ${min_steps} \'${minab_mask}\' $min_energy > minab.job
  
  cpptraj -p com.prmtop -y com.pdb -x com.rst7
fi

# Calculation
if [ "$scoring_function" = "GB5" ] ; then
  ante-MMPBSA.py -p com.prmtop -c com.top -r rec.top -l lig.top -s \'${strip_mask}\' -n ${lig_mask} --radii=mbondi2
  MMPBSA.py -O -i GB5.in -o MMGBSA.dat -eo MMGBSA.csv -cp com.top -rp rec.top -lp lig.top -y com.rst7 

elif [ "$scoring_function" = "GB8" ] ; then
  ante-MMPBSA.py -p com.prmtop -c com.top -r rec.top -l lig.top -s \'${strip_mask}\' -n ${lig_mask} --radii=mbondi3
  MMPBSA.py -O -i GB8.in -o MMGBSA.dat -eo MMGBSA.csv -cp com.top -rp rec.top -lp lig.top -y com.rst7 

elif [ "$scoring_function" = "PB3" ] ; then
  ante-MMPBSA.py -p com.prmtop -c com.top -r rec.top -l lig.top -s \'${strip_mask}\' -n ${lig_mask}
  MMPBSA.py -O -i PB3.in -o MMPBSA.dat -eo MMPBSA.csv -cp com.top -rp rec.top -lp lig.top -y com.rst7
fi
}

mmpbsa_text() {
echo "
if [ -z \"${water}\"]
then echo \"source leaprc.protein.ff14SB
  source leaprc.gaff
  set default pbradii ${radii}
  
  loadamberparams ${lig}.frcmod
  loadOff ${lig}.lib
  saveamberparm MOL lig.prmtop lig.rst7
  savepdb MOL lig.pdb
  
  rec = loadpdb ${rec}.pdb
  saveamberparm rec rec.prmtop rec.rst7
  savepdb rec rec.pdb 
  
  com = combine {rec, MOL}
  saveamberparm com com.prmtop com.rst7
  savepdb com com.pdb
  quit\">leap.cmd

else echo \"source leaprc.protein.ff14SB
  source leaprc.gaff
  source leaprc.water.tip3p
  
  set default pbradii ${radii}
  
  loadamberparams ${lig}.frcmod
  loadOff ${lig}.lib
  saveamberparm MOL lig.prmtop lig.rst7
  savepdb MOL lig.pdb
 
  rec = loadpdb ${rec}.pdb
  saveamberparm rec rec.prmtop rec.rst7
  savepdb rec rec.pdb 
  
  wat = loadmol2 $water
  com = combine {rec, wat, MOL}
  saveamberparm com com.prmtop com.rst7
  savepdb com com.pdb
  quit\">leap.cmd

fi
tleap -f leap.cmd &>tleap.job

if [ ! -z \"${min_steps}\" ]
then mv com.pdb com_before_min.pdb
  mv com.rst7 com_before_min.rst7
  if [ \"${min_type}\" = \"backbone\" ]
  then minab_mask=\":${min_mask}:CA|:${min_mask}:N|:${min_mask}:C|:${min_mask}:O\"
  else minab_mask=\"$min_mask\"
  fi

  minab com_before_min.pdb com.prmtop com.pdb ${implicit_model} ${min_steps} '\${minab_mask}' $min_energy > minab.job
  
  cpptraj -p com.prmtop -y com.pdb -x com.rst7
fi

if [ \"$scoring_function\" = \"GB5\" ] 
then ante-MMPBSA.py -p com.prmtop -c com.top -r rec.top -l lig.top -s '${strip_mask}' -n ${lig_mask} --radii=mbondi2
     MMPBSA.py -O -i GB5.in -o MMGBSA.dat -eo MMGBSA.csv -cp com.top -rp rec.top -lp lig.top -y com.rst7
elif [ \"$scoring_function\" = \"GB8\" ]
then ante-MMPBSA.py -p com.prmtop -c com.top -r rec.top -l lig.top -s '${strip_mask}' -n ${lig_mask} --radii=mbondi3
     MMPBSA.py -O -i GB8.in -o MMGBSA.dat -eo MMGBSA.csv -cp com.top -rp rec.top -lp lig.top -y com.rst7
elif [ \"$scoring_function\" == \"PB3\" ]
then ante-MMPBSA.py -p com.prmtop -c com.top -r rec.top -l lig.top -s '${strip_mask}' -n ${lig_mask}
     MMPBSA.py -O -i PB3.in -o MMPBSA.dat -eo MMPBSA.csv -cp com.top -rp rec.top -lp lig.top -y com.rst7
fi"
}

# Run MMPBSA or MMGBSA
run_mmpbsa() {
if [ "${mode}" = "PDB" ]; then
  for com in ${com_list} ; do
    cd ${dir}/output/${scoring_function}_rescoring/${com}

    if [ "${run_mode}" = "local" ]      ; then
      mmpbsa_cmd

    elif [ "${run_mode}" = "parallel" ] ; then
      echo -n "cd ${dir}/output/${scoring_function}_rescoring/${com}; " >> ${dir}/output/${scoring_function}_rescoring/rescore_${datetime}.parallel
      mmpbsa_text | sed ':a;N;$!ba;s/\n/; /g' >> ${dir}/output/${scoring_function}_rescoring/rescore_${datetime}.parallel

    elif [ "${run_mode}" = "mazinger" ] ; then
      write_pbsa_pbs
      jobid=$(qsub mmpbsa.pbs)
      echo -ne "Rescoring ${BLUE}${com}${NC} on ${RED}${jobid}${NC}              \r"
    fi
  done

  if [ "${run_mode}" = "parallel" ] ; then
    ${parallel} -j ${core_number} < ${dir}/output/${scoring_function}_rescoring/rescore_${datetime}.parallel > ${dir}/output/${scoring_function}_rescoring/parallel.job 2>&1
  fi

elif $(list_include_item "VS BEST" "${mode}"); then
  for pose in ${pose_list} ; do
    cd ${dir}/output/${scoring_function}_rescoring/${pose}
    lig_name=$(echo "$pose" | cut -d"/" -f1)
    pose_name=$(echo "$pose" | cut -d"/" -f2)
    
    if [ "${mode}" = "VS" ]; then
      lig="${VS_folder}/${lig_name}/docking/${pose_name}"
    elif [ "${mode}" = "BEST" ]; then
      lig="${BEST_folder}/${lig_name}/docking/${pose_name}"
    fi


    if [ "${run_mode}" = "local" ]    ; then
      mmpbsa_cmd

    elif [ "${run_mode}" = "parallel" ] ; then
      echo -n "cd ${dir}/output/${scoring_function}_rescoring/${pose}" >> ${dir}/output/${scoring_function}_rescoring/rescore_${datetime}.parallel
      mmpbsa_text | sed ':a;N;$!ba;s/\n/; /g' >> ${dir}/output/${scoring_function}_rescoring/rescore_${datetime}.parallel    

    elif [ "${run_mode}" = "mazinger" ] ; then
      write_pbsa_pbs
      jobid=$(qsub mmpbsa.pbs)
      echo "$jobid" >> ${dir}/output/${scoring_function}_rescoring/jobs_list_${datetime}.mazinger
      echo -ne "Rescoring ${BLUE}${pose_name}${NC} on ${RED}${jobid}${NC}              \r"
    fi
  done
  echo ""

  if [ "${run_mode}" = "parallel" ] ; then
    ${parallel} -j ${core_number} < ${dir}/output/${scoring_function}_rescoring/rescore_${datetime}.parallel > ${dir}/output/${scoring_function}_rescoring/parallel.job 2>&1
  fi
fi

}
