# ChemFlow Standards

## The ChemFlowID (unless we invent another name or comply with SDF format)
ChemFlowID should be the molecule unique identificator everywhere.

## DockFlow naming
* The original input <b>molecule name</b> > <b>file name</b> in this order will determine its ChemFlowID.
* All input filenames must be ChemFlowID.mol2. 
* Inside <b>run folders</b>, ligands should be named as <b>lig</b>, and what sets them appart is their location. The motivation is to simplify the use of variables. 

### For input folders
myproject/compounds/ritonavir.mol2
myproject/receptor.mol2

### For output folders
myproject/${METHOD}/${ChemFlowID}/ligand.mol2

For DockFlow output
myproject/docking/ritonavir/ligand.mol2

The Standard follows the same path for Scoreflow ando so on.
myproject/rescoring/ritonavir/{ligand.mol2,ligand.frcmod,ligand.lib}


## DockFlow: 
To avoid overfunction, works exclusively with .mol2 files, any other format must properly be converted first as a preparation step.
The 


a SMILES, MOL2 or SDF file will determine the 

## Stage1 of every ChemFlow tools should perform an input validation
