.. highlight:: bash

========================
Tutorial, alpha-Thrombin
========================

b1  - 1DWC crystal.

b2-7 - Build up manually by dgomes.

+-----------------------+------------------------------------------------+
| 1DWC.pdb              | Original PDB                                   |
+-----------------------+------------------------------------------------+
| receptor.pdb          | Receptor prepared with pdb4amber and --reduce. |
+-----------------------+------------------------------------------------+
| receptor.mol2         | Receptor prepared using SPORES.                |
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



Step 1: Convert SMILES into 3D structure
----------------------------------------
The default method is ETKDG. In sequence you should make a .mol2 file.

.. code-block:: console

    # First for the b1-b7 from an undisclosed article (blame diego)
    # we do have the affinities.
    python $(which SmilesTo3D.py) -i ligands.smi -o ligands.sdf --hydrogen -v
    babel -isdf ligands.sdf -omol2 ligands.mol2

    # The second set, with lignads from crystal structures.
    # we also have the affinities.
    python $(which SmilesTo3D.py) -i ligands_crystal.smi -o ligands_crystal.sdf --hydrogen -v
    babel -isdf ligands_crystal.sdf -omol2 ligands_crystal.mol2

    # Now the Decoys from DUD-E database. (http://dude.docking.org/targets/thrb)
    # Download, and get the first 14.
    # [ WARNING ] On DUD-E the "field separator" is a SPACE instead of "\t", so you MUST specify it in SmilesTo3D.py.
    wget http://dude.docking.org/targets/thrb/decoys_final.ism
    head -n 14  decoys_final.ism > decoys.smi
    python $(which SmilesTo3D.py) -i decoys.smi -o decoys.sdf --hydrogen -v -d " "
    babel -isdf decoys.sdf -omol2 decoys.mol2


Step 2: Set the center coordinates for the binding pocket
---------------------------------------------------------
You may skip this step if you want to provide the coordinates manually. 

.. code-block:: console

    # Use the reference ligand to compute the center for docking.
    # For PLANTS it's enough to have only the center.
    python /storage/donadef/git/ChemFlow/ChemFlow/bin/bounding_shape.py reference_ligand.mol2 --sphere 8.0

    # For VINA you need the center AND the lenghts of X Y and Z.
    python /storage/donadef/git/ChemFlow/ChemFlow/bin/bounding_shape.py reference_ligand.mol2 --box 8.0


Step 3: Run DockFlow to predict the docking poses.
--------------------------------------------------
To demonstrate **DockFlow** we'll run it with **three** sets of ligands, some of which we only know the binding
affinity (7 compounds), second we know both the affinity and crystal structure (7 compounds)_ and third a set of decoys (14 compounds)
All these scenarios will be used in the report different features. In the first place, we'll confront the 14 actives with the 14 decoys
and evalute the classification (active/inactive) done by the scoring function from each docking program. Then using the crystal structures
we'll evaluate the accuracy of each docking program to produce docking poses near the native one (**docking power**), finally.
Then we'll evaluate the quality of the scoring functions to rank the docking poses (**ranking power**) which will be latter compared with **ScoreFlow**
results together with the **scoring power** which will measure how well it will rank *compounds* against each other.

Let's do it locally:

.. code-block:: console

    # Run DockFlow
    DockFlow -p tutorial --protocol plants -r receptor.mol2 -l ligands.mol2         --center 31.50 13.74 24.36 --radius 20
    DockFlow -p tutorial --protocol plants -r receptor.mol2 -l ligands_crystal.mol2 --center 31.50 13.74 24.36 --radius 20
    DockFlow -p tutorial --protocol plants -r receptor.mol2 -l decoys.mol2          --center 31.50 13.74 24.36 --radius 20

    DockFlow -p tutorial --protocol vina   -r receptor.mol2 -l ligands.mol2         --center 31.50 13.74 24.36 --size 11.83 14.96 12.71 -sf vina
    DockFlow -p tutorial --protocol vina   -r receptor.mol2 -l ligands_crystal.mol2 --center 31.50 13.74 24.36 --size 11.83 14.96 12.71 -sf vina
    DockFlow -p tutorial --protocol vina   -r receptor.mol2 -l decoys.mol2          --center 31.50 13.74 24.36 --size 11.83 14.96 12.71 -sf vina

If you have access to a cluster, you may profit from the HPC resources using --slurm or --pbs flags accordingly. :)

When tou are done, postprocess all the results:

.. code-block:: console

    echo n | DockFlow -p tutorial --protocol plants -r receptor.mol2 -l ligands.mol2          --postprocess --overwrite -n 3
    echo n | DockFlow -p tutorial --protocol plants -r receptor.mol2 -l ligands_crystal.mol2  --postprocess -n 3
    echo n | DockFlow -p tutorial --protocol plants -r receptor.mol2 -l decoys.mol2           --postprocess -n 3

    echo n | DockFlow -p tutorial --protocol vina -r receptor.mol2 -l ligands.mol2            --postprocess -sf vina  --overwrite -n 3
    echo n | DockFlow -p tutorial --protocol vina -r receptor.mol2 -l ligands_crystal.mol2    --postprocess -sf vina -n 3
    echo n | DockFlow -p tutorial --protocol vina -r receptor.mol2 -l decoys.mol2             --postprocess -sf vina -n 3

Step 4: Run ScoreFlow to rescore the previous doking poses (best 3 for each ligand)
-----------------------------------------------------------------------------------
Rescoring using MMGBSA method:

.. code-block:: console

    ScoreFlow -p tutorial --protocol mmgbsa          -r receptor.pdb -l tutorial.chemflow/DockFlow/plants/receptor/docked_ligands.mol2 -sf mmgbsa --overwrite<<EOF
    Y
    y
    EOF
    ScoreFlow -p tutorial --protocol mmgbsa_water    -r receptor.pdb -l tutorial.chemflow/DockFlow/plants/receptor/docked_ligands.mol2 -sf mmgbsa --water --overwrite<<EOF
    Y
    y
    EOF
    ScoreFlow -p tutorial --protocol mmgbsa_md       -r receptor.pdb -l tutorial.chemflow/DockFlow/plants/receptor/docked_ligands.mol2 -sf mmgbsa --md --overwrite<<EOF
    Y
    y
    EOF
    ScoreFlow -p tutorial --protocol mmgbsa_water_md -r receptor.pdb -l tutorial.chemflow/DockFlow/plants/receptor/docked_ligands.mol2 -sf mmgbsa --water --md --overwrite<<EOF
    Y
    y
    EOF

Same as for DockFlow, if you have access to a cluster, use the --slurm or --pbs flag.

When tou are done, postprocess all the results:

.. code-block:: console

    ScoreFlow -p tutorial --protocol mmgbsa          -r receptor.pdb -l tutorial.chemflow/DockFlow/plants/receptor/docked_ligands.mol2 -sf mmgbsa --postprocess
    ScoreFlow -p tutorial --protocol mmgbsa_water    -r receptor.pdb -l tutorial.chemflow/DockFlow/plants/receptor/docked_ligands.mol2 -sf mmgbsa --postprocess
    ScoreFlow -p tutorial --protocol mmgbsa_md       -r receptor.pdb -l tutorial.chemflow/DockFlow/plants/receptor/docked_ligands.mol2 -sf mmgbsa --postprocess
    ScoreFlow -p tutorial --protocol mmgbsa_water_md -r receptor.pdb -l tutorial.chemflow/DockFlow/plants/receptor/docked_ligands.mol2 -sf mmgbsa --postprocess




    DockFlow -p tutorial --protocol plants -r receptor.mol2 -l ligands_crystal.mol2 --center 31.50 13.74 24.36 --radius 20  --pbs <<EOF
y
n
16
16
EOF

    DockFlow -p tutorial --protocol plants -r receptor.mol2 -l decoys.mol2          --center 31.50 13.74 24.36 --radius 20 --pbs <<EOF
y
n
16
16
EOF


    DockFlow -p tutorial --protocol vina   -r receptor.mol2 -l ligands.mol2         --center 31.50 13.74 24.36 --size 11.83 14.96 12.71 -sf vina
    DockFlow -p tutorial --protocol vina   -r receptor.mol2 -l ligands_crystal.mol2 --center 31.50 13.74 24.36 --size 11.83 14.96 12.71 -sf vina  --pbs <<EOF
y
n
16
16
EOF

    DockFlow -p tutorial --protocol vina   -r receptor.mol2 -l decoys.mol2          --center 31.50 13.74 24.36 --size 11.83 14.96 12.71 -sf vina  --pbs <<EOF
y
n
16
16
EOF

