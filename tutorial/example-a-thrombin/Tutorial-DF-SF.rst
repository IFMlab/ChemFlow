
========
Tutorial
========

Chem\ *Flow* - alpha-Thrombin
+++++++++++++++++++++++++++++

Copy the file "ChemFlow_tutorial_a-thrombin.tar.gz" present in ChemFlow/tutorial/ to place you want to run the tutorial.

Now extract with

``tar xvfz ChemFlow_tutorial_a-thrombin.tar.gz``

Now go to the folder and start playing :)

cd ChemFlow_tutorial_a-thrombin/

Provided files
**************

+-----------------------+------------------------------------------------+
| 1DWD.pdb              | Original PDB                                   |
+-----------------------+------------------------------------------------+
| receptor.pdb          | Receptor prepared with pdb4amber and --reduce. |
+-----------------------+------------------------------------------------+
| receptor.mol2         | Receptor prepared using SPORES.                |
+-----------------------+------------------------------------------------+
| vmd-rec.mol2         | Receptor prepared using SPORES.                |
+-----------------------+------------------------------------------------+
| reference_ligand.pdb  | Ligand from 1DWC crystal structure.            |
+-----------------------+------------------------------------------------+
| reference_ligand.mol2 | converted with openbabel.                      |
+-----------------------+------------------------------------------------+
| ligands.smi           | b1-b7 ligands.                                 |
+-----------------------+------------------------------------------------+
| ligands_crystal.smi   | 1D3D 1D3P 1D3Q 1D3T 1DWB 1DWC 1DWD             |
+-----------------------+------------------------------------------------+
| decoys.smi            | decoys for a-thrombin, from DUD-E              |
+-----------------------+------------------------------------------------+

Dock\ *Flow*
************

Step 1: Set the center coordinates for the binding pocket
---------------------------------------------------------
ChemFlow ships a tool to compute optimal box origin and dimensions provided a known ligand. Use the reference ligand to compute the center for docking. You may skip this step if you want to provide the coordinates manually.

Use the reference ligand to compute the center for docking.

Running the script *bounding_shape.py* you will get the sphere/box dimensions.
Since AutodockVina requires a search space in each dimension that is no less than 15 larger than the size of the ligand, and no less than 22 Å total, we will compute the dimensions of the box with a padding of 15 Å, specified with the flag "-p".

For PLANTS you will get the center and the radius of the sphere

.. code-block:: bash

python $(which bounding_shape.py) reference_ligand.mol2 --shape sphere

For VINA you need the center of the box AND the lenghts of X Y and Z.

.. code-block:: bash

python $(which bounding_shape.py) reference_ligand.mol2 --shape box -p 15


You should obtain:  

    PLANTS: 32.249 13.459 24.955 7.500
    
    VINA: 32.249 13.459 24.955 18.886 22.290 19.700
