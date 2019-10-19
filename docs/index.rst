.. ChemFlow documentation master file, created by
   sphinx-quickstart on Fri Jul 27 10:35:54 2018.
   You can adapt this file completely to your liking, but it should at least
   contain the root `toctree` directive.

****************************************
Welcome to Chem\ *Flow*'s documentation!
****************************************
Chem\ *Flow* is a modular platform for computational chemistry workflows using high performance environments.
The workflows address common **computational chemistry** tasks and are named with a prefix followed by *Flow*, Dock\ *Flow*, Score\ *Flow* and Lig\ *Flow*.

.. toctree::
   :maxdepth: 1
   :caption: Contents:

   readme
   overview
   workflows
   features
   HPC
   installation
   manual
   tutorial
   contributing
   authors

..   usage
..   contributing
..   history

.. Indices and tables
.. ==================
.. * :ref:`genindex`
.. * :ref:`modindex`
.. * :ref:`search`


Workflows
=========
:Dock\ *Flow*: Covers docking and virtual screening of compound(s) against some single or multiple targets, with one, some or all of the implemented docking software. 

:Score\ *Flow*: Handles (re)scoring of (top) docking poses either with empirical (VinaSF, ChemPLP) or physics-based functions (MM/PBSA, MM/GBSA).

:Lig\ *Flow*: Handles small molecule conversions, conformer search and compound parametrization through assignment to the General Amber Force-Field (GAFF2) and charge calculation through QM methods. It also probes the Chem\ **Base** to avoid redundancy. 

:Chem\ **Base**: is the Chem\ *Flow database for pre-calculated molecules, so far it spams nearly 9000 drug-like compounds from the *Chimioteque Nationale du CNRS* with QM optimized geometries and assigned parameters for GAFF.

Implementation
==============
Chem\ *Flow* was designed as modular tool based on plain Bourne-again Shell (BASH) script, a ubiquitous environment and programming language in every UNIX environment. The code integrates freely available software for structure manipulation, molecular docking, molecular dynamics (MD) simulation, binding free energy calculations, and structure calculation. In addition, it contains optional routines for proprietary software.
By design, the goal was to be as simple is possible and facilitate modifications and requires minimal installation. The code is containerized and modular to allow methods to be applied only in a well-defined way which is traceable and reproducible following the ISO/IEC 17025 guidelines for assays. Chem\ *Flow* ships with protocols for common experiments and curated benchmarks to assess the performance of methods.

How ChemFlow was born
=====================
During virtual screening/ molecular dynamics study we were confronted with unintelligibly data from a previous collaborator and the challenge to produce our own. In fact that's an actually a very common scenario, everyone “\ *does their things their own way*”.

We thought it would be valuable if we standardize the directory structure and file naming. The whole point of a standard is to facilitate documentation, comprehension, data retention and reproducibility, so that future users or applications will not have to figure out this structure or migrate to new formats.

Features
========
Chem\ *Flow* was designed as modular tool based on plain Bourne-again Shell (BASH) script, a ubiquitous environment and programming language in every UNIX environment. The code integrates freely available software for structure manipulation (Rdkit and openbabel), molecular docking (PLANTS and Autodock Vina), molecular dynamics (MD) simulation, binding free energy calculations (AmberTools18), and structure calculation (SQM). In addition, it contains optional routines for proprietary software Amber18 and Gaussian 09.

* High Throughput: Chem\ *Flow* was tuned to optimally use the high performance and throughput of available computing resources, following architectural standards of SLURM and PBS queueing systems (SGE coming soon). The job distribution was designed to minimize I/O and maximize throughput. Simplified configuration files allow them to adapt this policy to the available topology. 

* Fault tolerance and Checkpointing: A big concert when dealing with high throughput data is to be able to diagnose and resume after unsuccessful execution. So far, Chem\ *Flow* can only detect and report failed jobs, and resubmit them, letting the user investigate the reasons of failure. 

* Analysis and Reporting: The major benefit from standardization is to facilitate analysis. Currently Chem\ *Flow* ships with protocols perform, analyses and report for some common scenarios for computational chemistry. For docking and virtual screening of compounds including prospection, validation and method comparison. For MD simulations, contains protein stability (temperature, solvent, solvent mixture). For any two-molecule system contains “rescoring” and binding free energy estimation. Analysis is implemented with Bourne-again Shell (BASH) and but, for its graphic capabilities, the reporting tools are implemented as interactive Python Notebooks. 

* Data curation and reproducibility: Data curation demand for industrial applications require compliance with ISO/IEC 17025, the standard for which laboratories must hold accreditation in order to be deemed technically competent. The Chem\ *Flow* standard is a readily accessible and familiar specifications useful for data curation on drug discovery and molecular simulation projects. 

Workflows (extended)
====================
Chem\ *Flow* is a modular platform for computational chemistry workflows using high performance environments.
The workflows address common **computational chemistry** tasks and are named with a prefix followed by *Flow*, Dock\ *Flow*, Score\ *Flow* and Lig\ *Flow*.

* Dock\ *Flow* covers docking and virtual screening of compound(s) against some single or multiple targets, with one, some or all of the implemented docking software (so far Autodock Vina and PLANTS).

* Score\ *Flow* on the other hand handles (re)scoring of (top) docking poses which is more expensive, Structural Interaction fingerprints (using IChem), VinaSF, ChemPLP, PLP, MM/GBSA (with or without MD, implicit/explicit solvent). Both DockFlow and ScoreFlow are implemented to comply with docking/scoring benchmarks so that user can test new search and scoring functions and directly compare with the competition (within ReportFlow).

* Lig\ *Flow* handles conversions (such as smiles to mol2), conformer search and compound parameterization through assignment to the General Amber Force-Field (GAFF2) and charge calculation through QM methods. It also probes the ChemBase to avoid redundancy.

* Chem\ **Base** is the Chem\ *Flow* database for pre-calculated molecules, so far it contains a nearly 9000 drug-like compounds from the “Chimioteque Nationale du CNRS” with QM optimized geometries and assigned parameters for GAFF.

* MD\ *Flow** (not active) handles molecular dynamics simulation protocols and analysis and HGFlow is an application specific workflow designed for Host-Guest systems.
