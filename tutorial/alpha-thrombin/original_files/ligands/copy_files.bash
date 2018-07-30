origin="/data/dgomes/MMPBSA_BENCHMARK/thrombin_gpu_md_FIXED/"
for i in $(seq 1 7) ; do 
    for filename in lig.mol2 lig_h.pdb lig.pdb lig_bcc.mol2 lig_resp.mol2 ; do 
        outname=$(echo $filename | sed "s/lig/b${i}/" )
        cp ${origin}/b${i}/${filename} ${outname}
    done
done
