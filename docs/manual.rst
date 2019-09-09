.. highlight:: bash

===========
User Manual
===========

Lig\ *Flow*
============
Lig\ *Flow* handles the curation of compound libraries, stored as SMILES or MOL2 files, automating 3D conformer generation, compound parameterization and charge calculation. It also probes the Chem\ *Base* to avoid redundancy. 

Lig\ *Flow* does it all through a series functions designed to prepare the compound for Dock\ *Flow* and Score\ *Flow*. Lig\ *Flow* supports resuming of unfinished calculation.

**.mol2** files are stored according to the following hierarchy, with file names determined by molecule name.


.. code-block:: bash

    |--${project}.chemflow
    |  |--LigFlow
    |     |--original/${compound}.mol2 
    |     |--${charge/${compound}.mol2 (gas, bcc or resp charges)

**gas** - Gasteiger-Marsili charges ; **bcc** - Bond Charge Correction (AM1-BCC) ; **resp** - Restrained electrostatic fitted charges

.. note:: Lig\ *Flow* uses /tmp/${molecule} during calculations, when running in parallel.



Step 1a - Starting from a *.smi* file. (SMILES)
----------------------------------------------
Conversion of a SMILES library to 3D and conformer generation can be achieved through integration with RDKit, OpenBabel or Chemaxon's molconvert (licence required), pick your favorite. A 3D structure for each compound will be generated and stored as individual **${compound}.mol2** file.

By default only the most probable tautomer for pH 7.0, and 3D conformer is generated, therefore users are highly encouraged to provide isomeric (ism) smiles or carefully inspect the output library to avoid mistakes.


Step 1b - Starting from a *.mol2* file.
---------------------------------------
One should provide a complete .mol2 file, all-hydrogen, correct bond valences. PERIOD. LigFlow will split multimol2 files and store as individual **${compound}.mol2** files.


.. tip:: Chemical library curation is a crutial step. Consider using a specialized tool for compound tautomer and pka prediction.

.. warning:: Lig\ *Flow* will **never** autogenerate names for your molecules, **never**. Make sure you provide proper input files.

Step 2 - Compound parameterization
----------------------------------
Depending on the purpose, a different parameterization should take place. For docking, a Tripos .mol2 file sufices since Dock\ *Flow* has specific routine to prepare it to the target software. 

If one however chooses to use rescore a complex using more accurate free energy methods Lig\ *Flow* automatizes the parameterization to the General Amber Force-Field (GAFF), and charge calculation through QM methods, either AM1 with BCC charges or HF/6-31G* with RESP charges. GAFF works great for small, drug-like molecules, but remember its a **general** force field.

.. tip:: For large screenings we recomend using less accurate BCC charges to prioritize compounds, migrating to more time consuming HF/6-31G* with RESP charges

.. tip:: To improve accuracy one must carefully parameterize each molecule, search for warnings in the **${molecule}.frcmod** file.


Usage
-----
To prepare a compound library for file **ligand.mol2**, for the project **myproject** use the command bellow. Make sure to choose the appropriate charge model for you project.

.. code-block:: bash

    LigFlow -l ligand.mol2 -p myproject [--bcc] [--resp]


Options
-------
The compound file name  (.mol2 file) and project name are mandatory, and you're done. Check the advanced options bellow.

.. code-block:: bash

    [Help]
    -h/--help           : Show this help message and quit
    -hh/--full-help      : Detailed help

    [Required]
    -p/--project        : ChemFlow project.
    -l/--ligand         : Ligands .mol2 input file.

Advanced options
----------------
These options let you better control the execution, including charge calculation, and parallel (local) or HPC execution. Refer to **HPC Run** topic for guidance on how to use a High Performance Computers.


.. code-block:: bash

    [ Optional ]
    --gas                  : Compute Gasteiger-Marsili charges
    --bcc                  : Compute bcc charges
    --resp                 : Compute resp charges

    [ Parallel execution ]
    -nc/--cores        INT : Number of cores per node [8]
    --pbs/--slurm          : Workload manager, PBS or SLURM
    --header          FILE : Header file provided to run on your cluster.

    [ Development ] 
    --charges-file    FILE : Contains the net charges for all ligands in a library.
                            ( name charge )  ( CHEMBL123 -1 ) 


.. note:: RESP charges require a GAUSSIAN 09+ licence.

Dock\ *Flow*
============

Dock\ *Flow* covers docking and Virtual High Throughput Screening (vHTS) of compound(s) against a target (receptor) through the so far implemented docking software: Autodock Vina and PLANTS. The vHTS is efficiently distributed on the available computational resources.


Docking output files are stored according to the following hierarchy, with file names determined by molecule name.

.. code-block:: bash

    |--${project}.ChemFlow
    |  |--DockFlow
    |     |--${project}/${receptor}/${protocol}/${compound}/ligand.out
    |     |--${project}/${receptor}/${protocol}/${compound}/ligand.pdbqt (VINA)
    |     |--${project}/${receptor}/${protocol}/${compound}/ligand.mol2  (PLANTS)



Usage
------
The user should first curate the compound library (.smi or .mol2) using Lig\ *Flow* then provide that same input file. Dock\ *Flow* only uses the molecule name from this file and gets all structural data from the Lig\ *Flow*-generated library. 

.. code-block:: bash

     DockFlow -r receptor.mol2 -l ligand.mol2 -p myproject --center X Y Z [--protocol protocol-name] [-n 10] [-sf chemplp]

.. note:: Make sure to use the same *project* name and *protocol*.

Options
-------
Dock\ *Flow* requires the receptor and "ligands" files are required, together with the center of the binding site.


.. code-block:: bash

    [Help]
    -h/--help              : Show this help message and quit
    -hh/--fullhelp         : Detailed help

    [ Required ]
    -p/--project       STR : ChemFlow project
    -r/--receptor     FILE : Receptor MOL2 file
    -l/--ligand       FILE : Ligands  MOL2 file
    --center         X Y Z : Binding site coordinates (space separated)

Advanced options
----------------
These options let you better control the execution, including the scoring function and specific parameters for each implemented docking software. In addition has options to control the parallel (local) or HPC execution. Refer to **HPC Run** topic for guidance on how to use a High Performance Computers.

.. code-block:: bash

    [ Post Processing ]
    --postprocess          : Process DockFlow output for the specified 
                             project/protocol/receptor.
    --postprocess-all      : Process all DockFlow outputs in a ChemFlow project.
    -n/--n-poses       INT : Number of docked poses to keep.
    --archive              : Compress the docking folder for a project/protocol/receptor.
    --archive-all          : Compress all docking folders in a ChemFLow project.

    [ Optional ]
    --protocol         STR : Name for this specific protocol [default]
    -n/--n-poses       INT : Maximum number docking of poses per ligand [10]
    -sf/--function     STR : vina, chemplp, plp, plp95  [chemplp]

    [ Parallel execution ]
    -nc/--cores        INT : Number of cores per node [${NCORES}]
    --pbs/--slurm          : Workload manager, PBS or SLURM
    --header          FILE : Header file provided to run on your cluster.

    [ Additional ]
    --overwrite            : Overwrite results
    --yes                  : Yes to all questions
    _________________________________________________________________________________
    [ Options for docking program ]

    [ PLANTS ] 
    --radius         FLOAT : Radius of the spheric binding site [15]
    --speed            INT : Search speed for Plants. 1, 2 or 4 [1]
    --ants             INT : Number of ants [20]
    --evap_rate      FLOAT : Evaporation rate of pheromones [0.15]
    --iter_scaling   FLOAT : Iteration scaling factor [1.0]
    --cluster_rmsd   FLOAT : RMSD similarity threshold between poses, in Å [2.0]
    --water           FILE : Path to a structural water molecule (.mol2)
    --water_xyzr      LIST : xyz coordinates and radius of the water sphere, separated by a space
    _________________________________________________________________________________
    [ Vina ]
    --size            LIST : Size of the grid along the x, y and z axis, separated by a space [15 15 15]
    --exhaustiveness   INT : Exhaustiveness of the global search [8]
    --energy_range   FLOAT : Max energy difference (kcal/mol) between the best and worst poses [3.00]
    _________________________________________________________________________________


Options to Postprocess and Archive
----------------------------------

Docking produces a number of poses and their associated energies, but each software does it their way. --postprocess[--all] standardizes the output to two files: docked_ligands.mol2 and DockFlow.csv.

.. code-block:: bash

    |--${project}.ChemFlow
    |  |--DockFlow
    |     |--${project}/${receptor}/${protocol}/docked_ligands.mol2
    |     |--${project}/${receptor}/${protocol}/DockFlow.csv



Score\ *Flow*
=============
ScoreFlow is a bash script designed to work with PLANTS, Vina, IChem and AmberTools16+.
It can perform a rescoring of molecular complexes such as protein-ligand

ScoreFlow requires a project folder named 'myproject'.chemflow. If absent, one will be created.

Usage:
------

# For VINA and PLANTS scoring functions:
ScoreFlow -r receptor.mol2 -l ligand.mol2 -p myproject --center X Y Z [--protocol protocol-name] [-sf vina]
Usage:

# For MMGBSA only
ScoreFlow -r receptor.pdb -l ligand.mol2 -p myproject [-protocol protocol-name] -sf mmgbsa

Options
-------
.. code-block:: bash

    [Help]
    -h/--help           : Show this help message and quit
    -hh/--fullhelp      : Detailed help

    [Required]
    -r/--receptor       : Receptor .mol2 or .pdb file.
    -l/--ligand         : Ligands .mol2 input file.
    -p/--project        : ChemFlow project.

Advanced Options
----------------

.. code-block:: bash

    [ Required ]
    -p/--project       STR : ChemFlow project
    -r/--receptor     FILE : Receptor MOL2 file
    -l/--ligand       FILE : Ligands  MOL2 file

    [ Optional ]
    --protocol         STR : Name for this specific protocol [default]
    -sf/--function     STR : vina, chemplp, plp, plp95, mmgbsa, mmpbsa [chemplp]

    [ Charges for ligands - MMGBSA ]
    --gas                  : Gasteiger-Marsili (default)
    --bcc                  : AM1-BCC charges
    --resp                 : RESP charges (require gaussian)

    [ Simulation - MMGBSA ]
    --maxcyc           INT : Maximum number of energy minimization steps for implicit solvent simulations [1000]
    --water                : Explicit solvent simulation
    --md                   : Molecular dynamics

    [ Parallel execution - MMGBSA ]
    -nc/--cores        INT : Number of cores per node [${NCORES}]
    --pbs/--slurm          : Workload manager, PBS or SLURM
    --header          FILE : Header file provided to run on your cluster.
    --write-only           : Write a template file (ScoreFlow.run.template) command without running.
    --run-only             : Run using the ScoreFlow.run.template file.

    [ Additional ]
    --overwrite            : Overwrite results

    [ Rescoring with vina or plants ]

    --center           STR : xyz coordinates of the center of the binding site, separated by a space

    [ PLANTS ]
    --radius         FLOAT : Radius of the spheric binding site [15]

    [ Vina ]
    --size            LIST : Size of the grid along the x, y and z axis, separated by a space [15 15 15]
    --vina-mode        STR : local_only (local search then score) or score_only [local_only]

    [ Post Processing ]
    --postprocess          : Process ScoreFlow output for the specified project/protocol/receptor.

    Note: You can automatically get the center and radius/size 
        for a particular ligand .mol2 file using the bounding_shape.py script

    _________________________________________________________________________________
Advanced Use
------------
By using the **--write-only** flag, all input files will be written in the following scheme:
**PROJECT**.chemflow/ScoreFlow/**PROTOCOL**/**receptor**/

System Setup
    One can customize the system setup (**tleap.in**) inside a job.

Simulation protocol
    The procedures for each protocol can also be modified, the user must review "ScoreFlow.run.template".

The *run input files* for Amber and MM(PB,GB)-SA, namely:
min1.in, heat.in, equil.in, md.in ... can also be manually modified at wish :)
After the modifications, rerun ScoreFlow using \-\-run-only.
Lig\ *Flow*
===========

Options
-------

Advanced Options
----------------
