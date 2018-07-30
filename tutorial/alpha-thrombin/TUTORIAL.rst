========
Tutorial
========

b1  - 1D3D crystal. 
b2-7 - Build up manually by dgomes.


Step 1: Convert SMILES into 3D structure
----------------------------------------

The default method is ETKDG. In sequence you should make a .mol2 file.
.. code-block:: console
	# First for the b1-b7
	python $(which SmilesTo3D.py) -i ligands.smi -o ligands.sdf --hydrogen -v
        babel -isdf ligands.sdf -omol2 ligands.mol2 

        # The second 
	python $(which SmilesTo3D.py) -i ligands_crystal.smi -o ligands_crystal.sdf --hydrogen -v
        babel -isdf ligands_crystal.sdf -omol2 ligands_crystal.mol2

Step 2: 
Run DockFlow to predict the docking poses.
.. code-block:: console



