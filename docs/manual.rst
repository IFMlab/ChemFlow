.. highlight:: bash

===========
User Manual
===========

Lig\ *Flow*
============
Lig\ *Flow* handles the curation of compound libraries, stored as SMILES or MOL2 files, automating 3D conformer generation, compound parameterization and charge calculation. It also probes the Chem\ *Base* to avoid redundancy. Lig\ *Flow* does it all through a series functions designed to prepare the compound for Dock\ *Flow* and Score\ *Flow*. 

**.mol2** files are stored according to the following hierarchy, with file names determined by molecule name.

.. code-block:: bash

    |--${project}.chemflow
    |  |--LigFlow
    |     |--original/${molecule}.mol2 (Gasteiger-Marsili charges)
    |     |--${charge/${molecule}.mol2 (bcc or resp charges)


.. note:: Lig\ *Flow* uses /tmp/${molecule} during calculations, when running in parallel.


Compound parameterization
-------------------------
Docking 
through assignment to the General Amber Force-Field (GAFF2), and charge calculation through QM methods. It may also probe the Chem\ *Base* to avoid redundancy.



Starting from a *.smi* file. (SMILES)
---------------------------------------
Conversion of a SMILES library to 3D and conformer generation can be achieved through integration with RDKit, OpenBabel or Chemaxon's molconvert (licence required), pick your favorite. 

By default only the most probable tautomer for pH 7.0, and 3D conformer is generated, therefore users are highly encouraged to provide isomeric (ism) smiles or carefully inspect the output library to avoid mistakes.


Starting from a *.mol2* file.
-------------------------------


.. tip:: Chemical library curation is a crutial step. Consider using a specialized tool for compound tautomer and pka prediction.

.. warning:: Lig\ *Flow* will **never** autogenerate names for your molecules, **never**. Make sure you provide proper input files.

Usage
-----

.. code-block:: bash

    LigFlow -l ligand.mol2 -p myproject [--bcc] [--resp]

Options
-------

.. code-block:: bash

    [Help]
    -h/--help           : Show this help message and quit
    -hh/--full-help      : Detailed help

    -l/--ligand         : Ligands .mol2 input file.
    -p/--project        : ChemFlow project.

Advanced options
----------------

.. code-block:: bash

    [ Optional ]
    --bcc                  : Compute bcc charges
    --resp                 : Compute resp charges

    [ Parallel execution ]
    -nc/--cores        INT : Number of cores per node [${NCORES}]
    --pbs/--slurm          : Workload manager, PBS or SLURM
    --header          FILE : Header file provided to run on your cluster.

    [ Development ] 
    --charges-file    FILE : Contains the net charges for all ligands in a library.
                            ( name charge )  ( CHEMBL123 -1 ) 


Dock\ *Flow*
============

Dock\ *Flow* is a bash script designed to work with PLANTS or Vina.

It can perform an automatic VS based on information given by the user :
ligands, receptor, binding site info, and extra options.

Usage:
------
.. code-block:: bash

     DockFlow -r receptor.mol2 -l ligand.mol2 -p myproject --center X Y Z [--protocol protocol-name] [-n 10] [-sf chemplp]

Options
-------
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
.. code-block:: bash

    [ Post Processing ]
    --postprocess          : Process DockFlow output for the specified 
                             project/protocol/receptor.
    --postprocess-all      : Process DockFlow output in a ChemFlow project.
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

    [ Help ]
    -h/--help              : Show this help message and quit
    -hh/--fullhelp         : Detailed help

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
