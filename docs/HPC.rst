.. highlight:: bash

=======
HPC Run 
=======

Chem\ *Flow* was designed to profit from High Performance Computer (HPC) resources throught SLURM or PBS schedullers (SGE comming soon).

Usage
=====
HPC resources may be requested through **--slurm**, **--pbs** flags, followed by an appropriate TEMPLATE indicated by the **--header** flag.

Sample TEMPLATES
----------------
Here are examples for this header file. One must always provide the HEADER for SLURM and PBS and edit them carefully.

PBS - Using the **public** queue, asking 2 nodes, 28 cores/node, for 2h

.. code-block:: bash

    #! /bin/bash
    #PBS -q public
    #PBS -l nodes=2:ppn=28
    #PBS -l walltime=2:00:00
    #PBS -N myjob
    ...

SLURM - Using the **gpu** queue, asking 1 node with 4 GPUs, for 10 minutes.

.. code-block:: bash

    #! /bin/bash
    #SBATCH -p gpu
    #SBATCH -n 1
    #SBATCH -t 00:10:00
    #SBATCH --gres=gpu:4
    #SBATCH --job-name=myjob
    ...

Additional configuration may needed such as loading the compiler, MPI and CUDA libraries. Also any specifics for proprietary software, such as Amber or Gaussian that may differ from one's workstation installation.

.. code-block:: bash
    
    # Load modules
    module load compilers/gnu
    module load mpi/openmpi-3.0
    module load compilers/cuda-10.1

    # Path to amber.sh replace with your own
    source ~/software/amber18/amber.sh

    # Load Gaussian
    module load gaussian
    ...

.. Tip::
    Seek assistance from the system administrator to optimally configure the TEMPLATE files. 

Sample command lines:
=====================

Lig\ *Flow*:
------------
Prepare compounds with RESP charges, using 28 cores/node and through the SLURM scheduller.

.. code-block:: bash
    
    LigFlow \
    -p myproject  \
    -l compounds.mol2 \
    --resp \
    -nc 28 \
    --slurm --header TEMPLATE.slurm

Dock\ *Flow*:
-------------
Dock compounds using AutoDock Vina. Using 16 cores/node through the PBS scheduller.

.. code-block:: bash
    
    # AutoDock Vina, 16 cores/node, PBS
    DockFlow \
    -p myproject \
    --protocol vina \
    -r receptor.mol2 \
    -l compounds.mol2 \
    --center 31.50 13.74 24.36 \
    --size 11.83 14.96 12.71 \
    -sf vina \
    -nc 16 \
    --pbs --header TEMPLATE.pbs

Score\ *Flow*:
--------------
Standard Minimization and Molecular Dynamics Simulaton in explicit solvent, with RESP charges for the ligand, followed by MM/PBSA binding energy. Using 4 cores and 4 GPUs/node, and double precision CUDA.

.. code-block:: bash

    ScoreFlow \
    -p myproject \
    --protocol MMPBSA \
    -r receptor.pdb \
    -l compounds.mol2 \
    -sf mmpbsa \
    --resp --md --water \
    --cuda-double \
    -nc 4 \
    --slurm --header TEMPLATE.slurm


.. Tip::

    Use the **--write-only** flag to run a test before launching High Throughput calculations.

.. Warning::

    Be aware that HPC systems comonlly limit the amount of submitted jobs, choose your options wisely.
