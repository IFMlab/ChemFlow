========
Tutorial
========

Chem\ *Flow* - alpha-Thrombin
+++++++++++++++++++++++++++++

Provided files
**************

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

Lig\ *Flow*
***********

Step 1: Convert SMILES into 3D structure
----------------------------------------
To go from smiles to 3D structures use the script bellow. The default method for Bioactive structure generation is the state-of-the-art ETKDG.
In sequence you should make a .mol2 file using babel or your favorite program.

First for the b1-b7 from an undisclosed article (b1 = 1DWC crystal. b2-7 = Build up manually by dgomes), we do have the affinities.

.. code-block:: bash

    python $(which SmilesTo3D.py) -i ligands.smi -o ligands.sdf --hydrogen -v
    babel -isdf ligands.sdf -omol2 ligands.mol2

The second set, with ligands from crystal structures, we also have the affinities.
We superimposed 1DWC 1DWB 1DWD 1D3D 1D3P 1D3Q 1D3T (1DWC as reference) and saved all ligands as .mol2.
Hydrogens were added using SPORES (from PLANTS). (SPORES_64bit \\-\\-mode complete)

Now the Decoys from `DUD-E database <http://dude.docking.org/targets/thrb>`_.
Download, and get the first 14.
wget http://dude.docking.org/targets/thrb/decoys_final.ism
head -n 14  decoys_final.ism > decoys.smi
[ WARNING ] On DUD-E the "field separator" is a SPACE instead of "\t", so you MUST specify it in SmilesTo3D.py.

.. code-block:: bash

    python $(which SmilesTo3D.py) -i decoys.smi -o decoys.sdf --hydrogen -v -d " "
    babel -isdf decoys.sdf -omol2 decoys.mol2

To keep it simple, let's merge all compounds into a single mol2 file.

.. code-block:: bash

    cat ligands.mol2 ligands_crystal.mol2 decoys.mol2 > compounds.mol2

Step 2: Run Lig\ *Flow* to prepare the ligands.
-----------------------------------------------
Before running unknown compounds within ChemFlow we need to prepare the .mol2 to comply with the used standards using Lig\ *Flow*,
our workflow to handle ligands and general compounds.

Lig\ *Flow* takes multimol2 files as input, then organizes them individually into your project folder while normalizing the .mol2 files.
To perform this action run:

.. code-block:: bash

    LigFlow -p tutorial -l compounds.mol2

In addition Lig\ *Flow* can be used to  build up a compound database with **advanced** charges such as AM1-BCC and RESP and their associated
optimized structures, we'll see it's use latter to compute appropriate charges for the free energy calculations.
Since these calculations are computationally expensive we recomend the users to use a cluster/supercomputer. In the examples bellow
we demonstrate how to derive the AM1-BCC and RESP charges using the two most widespread queueing systems in supercomputers (PBS and SLURM)

.. code-block:: bash

    LigFlow -p tutorial -l compounds.mol2 --bcc --pbs
    LigFlow -p tutorial -l compounds.mol2 --resp --slurm

If a compound already exists in the ChemBase (Chem\ *Flow* database), Lig\ *Flow* won't compute the charges for this compound.

For each of these commands you will be asked:

* Continue? > y

Dock\ *Flow*
************

Step 3: Set the center coordinates for the binding pocket
---------------------------------------------------------
You may skip this step if you want to provide the coordinates manually.

Use the reference ligand to compute the center for docking.
For PLANTS it's enough to have only the center.

.. code-block:: bash

    python $CHEMFLOW_HOME/bin/bounding_shape.py reference_ligand.mol2 --sphere 8.0

For VINA you need the center AND the lenghts of X, Y and Z.

.. code-block:: bash

    python $CHEMFLOW_HOME/bin/bounding_shape.py reference_ligand.mol2 --box 8.0

Step 4: Run Dock\ *Flow* to predict the docking poses.
------------------------------------------------------
To demonstrate Dock\ *Flow* we'll run it with **three** sets of ligands, some of which we only know the binding
affinity (7 compounds), second we know both the affinity and crystal structure (7 compounds)_ and third a set of decoys (14 compounds)
All these scenarios will be used in the report different features. In the first place, we'll confront the 14 actives with the 14 decoys
and evaluate the classification (active/inactive) done by the scoring function from each docking program. Then using the crystal structures
we'll evaluate the accuracy of each docking program to produce docking poses near the native one (**docking power**), finally.

Then we'll evaluate the quality of the scoring functions to rank the docking poses (**ranking power**) which will be latter compared with Score\ *Flow*
results together with the **scoring power** which will measure how well it will rank *compounds* against each other.

Run Dock\ *Flow* for each set of ligands.

* Using plants:

.. code-block:: bash

    DockFlow -p tutorial --protocol plants -r receptor.mol2 -l compounds.mol2 --center 31.50 13.74 24.36 --radius 20

* Using vina:

.. code-block:: bash

    DockFlow -p tutorial --protocol vina -r receptor.mol2 -l compounds.mol2 --center 31.50 13.74 24.36 --size 11.83 14.96 12.71 -sf vina

For each of these commands you will be asked:

* Continue? > y

Step 5: Postprocess all the results
-----------------------------------
When tou are done, you can postprocess (\\-\\-postprocess) the results. Here, we decided to keep only the best 3 poses for each ligand (-n 3)

.. code-block:: bash

    echo n | DockFlow -p tutorial --protocol plants -r receptor.mol2 -l compounds.mol2 --postprocess -n 3
    echo n | DockFlow -p tutorial --protocol vina -r receptor.mol2 -l compounds.mol2   --postprocess -sf vina -n 3


Score\ *Flow*
*************

Step 6: Run Score\ *Flow* to rescore the previous docking poses (best 3 for each ligand)
----------------------------------------------------------------------------------------
Here, we only keep on with plants results (tutorial.chemflow/DockFlow/plants/receptor/docked_ligands.mol2).

Rescoring through the MMGBSA method, using two protocols in **implicit solvent** first just minimization, then 1ns md simulation :

.. code-block:: bash

    ScoreFlow -p tutorial --protocol mmgbsa    -r receptor.pdb -l tutorial.chemflow/DockFlow/plants/receptor/docked_ligands.mol2 -sf mmgbsa
    ScoreFlow -p tutorial --protocol mmgbsa_md -r receptor.pdb -l tutorial.chemflow/DockFlow/plants/receptor/docked_ligands.mol2 -sf mmgbsa --md

For each of these commands you will be asked:

* Continue? > y

Note: You can turn on explicit solvation using the flag \\-\\-water.

Step 7: Postprocess the results
-------------------------------
When you are done, you can postprocess (\\-\\-postprocess) the results:

.. code-block:: bash

    ScoreFlow -p tutorial --protocol mmgbsa    -r receptor.pdb -l tutorial.chemflow/DockFlow/plants/receptor/docked_ligands.mol2 -sf mmgbsa --postprocess
    ScoreFlow -p tutorial --protocol mmgbsa_md -r receptor.pdb -l tutorial.chemflow/DockFlow/plants/receptor/docked_ligands.mol2 -sf mmgbsa --postprocess


Advanced
--------

Using the  **\\-\\-write-only** flag, all input files will be written in tutorial.chemflow/ScoreFlow/mmgbsa_md/receptor/:

* System Setup: You can modify the system setup (tleap.in file) inside your job.
* Simulation protocol: The procedures for each protocol can also be modified, the user must review "ScoreFlow.run.template".
* Run input files (Amber and MMGBSA): Namely min1.in, heat.in, equil.in, md.in ... can also be manually modified at wish :)

* After the modifications, rerun Score\ *Flow* using **\\-\\-run-only**.

To run Dock\ *Flow* and Score\ *Flow* on a super computer
*********************************************************

If you have access to a cluster, you may profit from the HPC resources using \\-\\-slurm or \\-\\-pbs flags. :)

To run it properly, you should provide a template for your scheduler using the \\-\\-header FILE option. Here are examples for this header file.

* Example for pbs::

    #! /bin/bash
    # 1 noeud 8 coeurs
    #PBS -q  route
    #PBS -N
    #PBS -l nodes=1:ppn=1
    #PBS -l walltime=0:30:00
    #PBS -V

    source ~/software/amber16/amber.sh``

* Example for slurm::

    #! /bin/bash
    #SBATCH -p publicgpu
    #SBATCH -n 1
    #SBATCH -t 2:00:00
    #SBATCH --gres=gpu:1
    #SBATCH --job-name=
    #SBATCH -o slurm.out
    #SBATCH -e slurm.err

    #
    # Configuration
    #
    # Make sure you load all the necessary modules for your AMBER installation.
    # Don't forget the CUDA modules
    module load compilers/intel15
    module load libs/zlib-1.2.8
    module load mpi/openmpi-1.8.3.i15
    module load compilers/cuda-8.0

    # Path to amber.sh replace with your own
    source ~/software/amber16_publicgpu/amber.sh


    # You must always provide the HEADER for SLURM and PBS, because this template may not work for you.

Dock\ *Flow*:
-------------
Connect to your pbs cluster.

* Using plants:

.. code-block:: bash

    DockFlow -p tutorial --protocol plants -r receptor.mol2 -l compounds.mol2 --center 31.50 13.74 24.36 --radius 20 --pbs

* Using vina:

.. code-block:: bash

    DockFlow -p tutorial --protocol vina -r receptor.mol2 -l compounds.mol2 --center 31.50 13.74 24.36 --size 11.83 14.96 12.71 -sf vina --pbs

Score\ *Flow*:
--------------

.. code-block:: bash

    ScoreFlow -p tutorial --protocol mmgbsa    -r receptor.pdb -l tutorial.chemflow/DockFlow/plants/receptor/docked_ligands.mol2 --pbs -sf mmgbsa
    ScoreFlow -p tutorial --protocol mmgbsa_md -r receptor.pdb -l tutorial.chemflow/DockFlow/plants/receptor/docked_ligands.mol2 --pbs -sf mmgbsa --md``

For each of these commands you will be asked:

* Continue? > y

For Dock\ *Flow*, you also will have to answer how many compounds should be treated per job.