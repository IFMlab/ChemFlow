# Step 1 - Produce complex trajectory without water
cpptraj <<EOF
# Step 1 - Produce 
parm   ionized_solvated.prmtop
trajin prod.nc
strip :WAT,Na+,Cl-
autoimage familiar
trajout com.nc
go
quit
EOF

# Step 2 - Produce receptor trajectory without water
cpptraj <<EOF
parm   ionized_solvated.prmtop
trajin prod.nc
strip :WAT,Na+,Cl-,MOL
autoimage familiar
trajout rec.nc
go
quit
EOF

# Step 3 - Produce ligand trajectory without water
cpptraj <<EOF
parm   ../ligand/ionized_solvated.prmtop
trajin ../ligand/prod.nc
strip :WAT,Na+,Cl-
autoimage familiar
trajout lig.nc
go
quit
EOF

# Step 4 - Procuce the 3 topologies without water.
rm -rf com.top rec.top lig.top
ante-MMPBSA.py -p ionized_solvated.prmtop -c com.top -r rec.top -l lig.top -s ':WAT,Na+,Cl-' -n ':MOL' --radii=mbondi2

# Step 5 - Write MMPBSA input to using SANDER.
# This is necessary to modify (manually) the "intdiel" option
echo "Input file for running GB2
&general
   use_sander=1,verbose=1,keep_files=0,interval=1,
/
&gb
  igb=2, saltcon=0.150
/
" > GB2_intdiel4.in

# Step 6 - Dry-run of MMPBSA.py to write "_MMPBSA_gb.mdin"
MMPBSA.py -O -i GB2_intdiel4.in \
-cp com.top -rp rec.top -lp lig.top \
 -y com.nc   \
 -o MMGBSA.dat -eo MMGBSA.csv -make-mdins
 
# Step 7 - Modify "_MMPBSA_gb.mdin" to use internal dielectric 4.0
sed -i s/'extdiel=80.0'/'intdiel=4,extdiel=80.0'/ _MMPBSA_gb.mdin
 
# Step 8 - Finally run MMPBSA using the modifyed "_MMPBSA_gb.mdin"
mpirun -n 4 MMPBSA.py.MPI -O -i GB2_intdiel4.in \
-cp com.top -rp rec.top -lp lig.top \
 -y com.nc \
 -o MMGBSA.dat -eo MMGBSA.csv -use-mdins
 


# Redo step 6 through step 8 for "2"-average ------------------------
 
# Step 6 - Dry-run of MMPBSA.py to write "_MMPBSA_gb.mdin"
MMPBSA.py -O -i GB2_intdiel4.in \
-cp com.top -rp rec.top -lp lig.top \
 -y com.nc  -yr rec.nc  -yl lig.nc \
 -o MMGBSA_2ave.dat -eo MMGBSA_2ave.csv -make-mdins

 
# Step 7 - Modify "_MMPBSA_gb.mdin" to use internal dielectric 4.0
sed -i s/'extdiel=80.0'/'intdiel=4,extdiel=80.0'/ _MMPBSA_gb.mdin
 
# Step 8 - Finally run MMPBSA using the modifyed "_MMPBSA_gb.mdin"
mpirun -n 4 MMPBSA.py.MPI -O -i GB2_intdiel4.in \
-cp com.top -rp rec.top -lp lig.top \
 -y com.nc  -yr rec.nc  -yl lig.nc \
 -o MMGBSA_2ave.dat -eo MMGBSA_2ave.csv -use-mdins



