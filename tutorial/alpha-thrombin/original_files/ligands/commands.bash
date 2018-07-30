
for i in $(seq 1 7 ) ; do babel -ipdb b${i}_h.pdb -osmi b${i}.smi -d ; done 

sed -i 's/_h.pdb//' ligands.smi 
