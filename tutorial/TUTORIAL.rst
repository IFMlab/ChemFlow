.. highlight:: bash

========================
Tutorial, alpha-Thrombin
========================

Provided files
**************

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

Run ChemFlow
************

Step 1: Convert SMILES into 3D structure
----------------------------------------
The default method is ETKDG. In sequence you should make a .mol2 file.


First for the b1-b7 from an undisclosed article (blame diego)
We do have the affinities.

    ``python $(which SmilesTo3D.py) -i ligands.smi -o ligands.sdf --hydrogen -v``

    ``babel -isdf ligands.sdf -omol2 ligands.mol2``

The second set, with ligands from crystal structures, we also have the affinities.
We superimposed 1DWC 1DWB 1DWD 1D3D 1D3P 1D3Q 1D3T (1DWC as reference) and saved all ligands as .mol2.
Hydrogens were added using SPORES (from PLANTS). (SPORES_64bit --mode complete)

Now the Decoys from `DUD-E database <http://dude.docking.org/targets/thrb>`_.
Download, and get the first 14.
wget http://dude.docking.org/targets/thrb/decoys_final.ism
head -n 14  decoys_final.ism > decoys.smi
[ WARNING ] On DUD-E the "field separator" is a SPACE instead of "\t", so you MUST specify it in SmilesTo3D.py.

    ``python $(which SmilesTo3D.py) -i decoys.smi -o decoys.sdf --hydrogen -v -d " "``

    ``babel -isdf decoys.sdf -omol2 decoys.mol2``

To keep it simple, let's merge all compounds into a single mol2 file.

    ``cat ligands.mol2 ligands_crystal.mol2 decoys.mol2 > compounds.mol2``


Step 2: Set the center coordinates for the binding pocket
---------------------------------------------------------
You may skip this step if you want to provide the coordinates manually.

Use the reference ligand to compute the center for docking.
For PLANTS it's enough to have only the center.

    ``python $CHEMFLOW_HOME/bin/bounding_shape.py reference_ligand.mol2 --sphere 8.0``

For VINA you need the center AND the lenghts of X Y and Z.

    ``python $CHEMFLOW_HOME/bin/bounding_shape.py reference_ligand.mol2 --box 8.0``


Step 3: Run LigFlow to prepare the ligands.
-------------------------------------------
Before running unknown compounds within ChemFlow we need to prepare the .mol2 to comply with the used standards using Lig*Flow*,
our workflow to handle ligands and general compounds.

LigFlow takes multimol2 files as input, then organizes them individually into your project folder while normalizing the .mol2 files.
To perform this action run:

    ``LigFlow -p tutorial -l compounds.mol2``

In addition LigFlow can be used to  build up a compound database with **advanced** charges such as AM1-BCC and RESP and their associated
optimized structures, we'll see it's use latter to compute appropriate charges for the free energy calculations.
Since these calculations are computationally expensive we recomend the users to use a cluster/supercomputer. In the examples bellow
we demonstrate how to derive the AM1-BCC and RESP charges using the two most widespread queueing systems in supercomputers (PBS and SLURM)

    ``LigFlow -p tutorial -l compounds.mol2 --bcc --pbs``

    ``LigFlow -p tutorial -l compounds.mol2 --resp --slurm``

If a compound already exists in the ChemBase (ChemFlow database), Lig*Flow* won't compute the charges for this compound.


Step 4: Run DockFlow to predict the docking poses.
--------------------------------------------------
To demonstrate **DockFlow** we'll run it with **three** sets of ligands, some of which we only know the binding
affinity (7 compounds), second we know both the affinity and crystal structure (7 compounds)_ and third a set of decoys (14 compounds)
All these scenarios will be used in the report different features. In the first place, we'll confront the 14 actives with the 14 decoys
and evaluate the classification (active/inactive) done by the scoring function from each docking program. Then using the crystal structures
we'll evaluate the accuracy of each docking program to produce docking poses near the native one (**docking power**), finally.

Then we'll evaluate the quality of the scoring functions to rank the docking poses (**ranking power**) which will be latter compared with **ScoreFlow**
results together with the **scoring power** which will measure how well it will rank *compounds* against each other.

Run DockFlow for each set of ligands.

* Using plants:

    ``DockFlow -p tutorial --protocol plants -r receptor.mol2 -l compounds.mol2 --center 31.50 13.74 24.36 --radius 20``

* Using vina:

    ``DockFlow -p tutorial --protocol vina   -r receptor.mol2 -l compounds.mol2 --center 31.50 13.74 24.36 --size 11.83 14.96 12.71 -sf vina``

For each of these commands you will be asked:

* Are you sure you want to OVERWRITE? > y
* Continue? > y
* (Rewrite original ligands? > y)

Step 5: Postprocess all the results
-----------------------------------
When tou are done, you can postprocess (--postprocess) the results. Here, we decided to keep only the best 3 poses for each ligand (-n 3)

    ``echo n | DockFlow -p tutorial --protocol plants -r receptor.mol2 -l compounds.mol2 --postprocess --overwrite -n 3``

    ``echo n | DockFlow -p tutorial --protocol vina -r receptor.mol2 -l compounds.mol2   --postprocess -sf vina  --overwrite -n 3``

Step 6: Run ScoreFlow to rescore the previous docking poses (best 3 for each ligand)
-----------------------------------------------------------------------------------
Here, we only keep on with plants results (tutorial.chemflow/DockFlow/plants/receptor/docked_ligands.mol2).

Rescoring using MMGBSA method:

    ``ScoreFlow -p tutorial --protocol mmgbsa          -r receptor.pdb -l tutorial.chemflow/DockFlow/plants/receptor/docked_ligands.mol2 -sf mmgbsa --overwrite``

    ``ScoreFlow -p tutorial --protocol mmgbsa_water    -r receptor.pdb -l tutorial.chemflow/DockFlow/plants/receptor/docked_ligands.mol2 -sf mmgbsa --water --overwrite``

    ``ScoreFlow -p tutorial --protocol mmgbsa_md       -r receptor.pdb -l tutorial.chemflow/DockFlow/plants/receptor/docked_ligands.mol2 -sf mmgbsa --md --overwrite``

    ``ScoreFlow -p tutorial --protocol mmgbsa_water_md -r receptor.pdb -l tutorial.chemflow/DockFlow/plants/receptor/docked_ligands.mol2 -sf mmgbsa --water --md --overwrite``

For each of these commands you will be asked:

* Are you sure you want to OVERWRITE? > y
* Continue? > y

Step 7: Postprocess the results
-------------------------------
When tou are done, you can postprocess (--postprocess) the results:

    ``ScoreFlow -p tutorial --protocol mmgbsa          -r receptor.pdb -l tutorial.chemflow/DockFlow/plants/receptor/docked_ligands.mol2 -sf mmgbsa --postprocess``

    ``ScoreFlow -p tutorial --protocol mmgbsa_water    -r receptor.pdb -l tutorial.chemflow/DockFlow/plants/receptor/docked_ligands.mol2 -sf mmgbsa --postprocess``

    ``ScoreFlow -p tutorial --protocol mmgbsa_md       -r receptor.pdb -l tutorial.chemflow/DockFlow/plants/receptor/docked_ligands.mol2 -sf mmgbsa --postprocess``

    ``ScoreFlow -p tutorial --protocol mmgbsa_water_md -r receptor.pdb -l tutorial.chemflow/DockFlow/plants/receptor/docked_ligands.mol2 -sf mmgbsa --postprocess``


To run DockFlow and ScoreFlow on a super computer
*************************************************

If you have access to a cluster, you may profit from the HPC resources using --slurm or --pbs flags accordingly. :)

To run it properly, you should provide a template for your scheduler.

* Example for pbs:

    #! /bin/bash
    # 1 noeud 8 coeurs
    #PBS -q  route
    #PBS -N
    #PBS -l nodes=1:ppn=1
    #PBS -l walltime=0:30:00
    #PBS -V

    source ~/software/amber16/amber.sh

* Example for slurm:
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

DockFlow:
---------

Connect to your pbs cluster.

* Using plants:

    ``DockFlow -p tutorial --protocol plants -r receptor.mol2 -l compounds.mol2         --center 31.50 13.74 24.36 --radius 20 --pbs --overwrite``

 * Using vina:

    ``DockFlow -p tutorial --protocol vina   -r receptor.mol2 -l compounds.mol2         --center 31.50 13.74 24.36 --size 11.83 14.96 12.71 -sf vina --pbs --overwrite``

Same as for DockFlow, if you have access to a cluster, use the --slurm or --pbs flag.

ScoreFlow:
----------

    ``ScoreFlow -p tutorial --protocol mmgbsa          -r receptor.pdb -l tutorial.chemflow/DockFlow/plants/receptor/docked_ligands.mol2 -sf mmgbsa              --pbs --overwrite``

    ``ScoreFlow -p tutorial --protocol mmgbsa_water    -r receptor.pdb -l tutorial.chemflow/DockFlow/plants/receptor/docked_ligands.mol2 -sf mmgbsa --water      --pbs --overwrite``

    ``ScoreFlow -p tutorial --protocol mmgbsa_md       -r receptor.pdb -l tutorial.chemflow/DockFlow/plants/receptor/docked_ligands.mol2 -sf mmgbsa --md         --pbs --overwrite``

    ``ScoreFlow -p tutorial --protocol mmgbsa_water_md -r receptor.pdb -l tutorial.chemflow/DockFlow/plants/receptor/docked_ligands.mol2 -sf mmgbsa --water --md --pbs --overwrite``

For each of these commands you will be asked:

* Are you sure you want to OVERWRITE? > y
* Continue? > y
* (Rewrite original ligands? > y)
* How many Dockings per PBS/SLURM job? > 1
* How many tasks per node? > 1