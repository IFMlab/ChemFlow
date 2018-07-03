#!/bin/bash 

RECEPTOR="site_noWAT.mol2"
LIGAND="ifp.mol2"
REFERENCE_LIGAND="CK571_chimera.mol2"

ChemFlow_compute_IFP() { 
echo "Computing the IFP and similarity against ${REFERENCE_LIGAND}"

IChem --extended IFP ${RECEPTOR} ${LIGAND} ${REFERENCE_LIGAND} &> IFP.dat

awk '/ChSm_M2_MD_CK571_refine_35.pdb\t1/{f=1}f' IFP.dat > IFP.tanimoto
}

ChemFlow_extract_IFP() {
python <<END
import pandas as pd
# Return the list of best IFP per compound
df = pd.read_csv('IFP.tanimoto',delim_whitespace=True,usecols=[1,2])
df.columns=["POSE","IFP"]
df['LIGAND']=df['POSE'].str.split('_entry').str[0]
df2=df.groupby('LIGAND').max().sort_values('IFP',ascending=False)
df2[df2['IFP']>0.7].sort_index().to_csv('IFP_best.csv')
df2['POSE'][df2['IFP']>0.7].sort_index().to_csv('IFP_best.lst',index=False)
END
}

ChemFlow_compute_IFP
ChemFlow_extract_IFP
