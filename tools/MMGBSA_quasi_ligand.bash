# Step 3 - Produce ligand trajectory without water
cpptraj <<EOF
parm   ../ligand/ionized_solvated.prmtop
trajin ../ligand/prod.nc
strip :WAT,Na+,Cl-
autoimage familiar
trajout lig_unbound.nc
go
quit
EOF


cpptraj <<EOF
parm   ionized_solvated.prmtop
trajin prod.nc
strip !:MOL
autoimage familiar
trajout lig_bound.nc
go
quit
EOF


# Step 1 - Compute S for ligand in COMPLEX (bound)
cpptraj <<EOF
parm lig.top
trajin lig_bound.nc
reference ../ligand/ligand.rst7
strip @H=
rms mass
matrix mwcovar name lig_matrix
diagmatrix lig_matrix thermo outthermo thermo_bound.out temp 300
go
quit
EOF

# Step 2 - Compute S for ligand in solution (unbound).
cpptraj <<EOF
parm lig.top
trajin lig_unbound.nc
reference ../ligand/ligand.rst7
strip @H=
rms mass
matrix mwcovar name lig_matrix
diagmatrix lig_matrix thermo outthermo thermo_unbound.out temp 300
go
quit
EOF


bound=$(  awk '/Total/ {print $4}'  thermo_bound.out)
unbound=$(awk '/Total/ {print $4}'  thermo_unbound.out)
deltaS_lig=$(echo "$bound - $unbound" | bc)
echo $deltaS_lig

deltaH_complex=$(awk '/DELTA TOTAL/ {print $3}' MMGBSA.dat)
deltaH_complex_2ave=$(awk '/DELTA TOTAL/ {print $3}' MMGBSA_2ave.dat)

deltaG_complex=$(echo ${deltaH_complex} - ${deltaS_lig} | bc )
deltaG_complex_2ave=$(echo ${deltaH_complex_2ave} - ${deltaS_lig} | bc)

echo -e "1 average \t 2 average \t 3 average 
${deltaG_complex} \t ${deltaG_complex_2ave} \t ${deltaG_complex_3ave}"
