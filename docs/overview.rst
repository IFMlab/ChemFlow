========
Overview
========

The creation of Chem\ *Flow*
========================

During a virtual High Throughput computational chemistry study we were confronted with unintelligibly data from a previous collaborator and the challenge to produce our own. This is actually a very common scenario, everyone **does their things their own way**. We found it would be valuable to **standardize** the directory structure and file naming. 

The whole point of a standard is to facilitate documentation, comprehension, data retention and reproducibility, so that future users or applications will not have to figure out this structure or migrate to new formats.

Implementation
==============

Chem\ *Flow* was designed as modular tool based on plain Bourne-again Shell (BASH) script, an ubiquitous environment and programming language in every UNIX environment. The code integrates freely available software for structure manipulation (Rdkit and openbabel), molecular docking (PLANTS and Autodock Vina), molecular dynamics (MD) simulation, binding free energy calculations (AmberTools), and structure calculation (SQM). Chem\ *Flow* also contains optional routines for proprietary software Amber18 and Gaussian 09. 

As simple is possible
=====================

By design, the goal was to make Chem\ *Flow* as simple is possible to require minimal installation and promote extension. The code is containerized and modular to allow methods to be applied only in a well-defined way which is **traceable and reproducible** following the ISO/IEC 17025 guidelines for assays. Chem\ *Flow* ships with protocols for common experiments and curated benchmarks to assess the performance of methods.  

Features:
=========

:High Throughput: 
    Chem\ *Flow* was tuned to optimally use the high performance and throughput of available computing resources, following architectural standards of SLURM and PBS queueing systems. The job distribution was designed to minimize I/O and maximize throughput. Simplified configuration files allow them to adapt this policy to the available topology. 

:Fault tolerance and Checkpointing:
    A big concert when dealing with high throughput data is to be able to diagnose and resume after unsuccessful execution. So far, Chem\ *Flow* can only detect and report failed jobs, and resubmit them, letting the user investigate the reasons of failure. 

:Analysis and Reporting:
    The major benefit from standardization is to facilitate analysis. Currently Chem\ *Flow* ships with protocols perform, analyses and report for some common scenarios for computational chemistry. For docking and virtual screening of compounds including prospection, validation and method comparison. For MD simulations, contains protein stability (temperature, solvent, solvent mixture). For any two-molecule system contains “rescoring” and binding free energy estimation. Analysis is implemented with Bourne-again Shell (BASH) and but, for its graphic capabilities, the reporting tools are implemented as interactive Python Notebooks. 

:Data curation and reproducibility: 
    Data curation demand for industrial applications require compliance with ISO/IEC 17025, the standard for which laboratories must hold accreditation in order to be deemed technically competent. The Chem\ *Flow* standard is a readily accessible and familiar specifications useful for data curation on drug discovery and molecular simulation projects. 

Implemented workflows and brief description of experiments 
==========================================================
    Chem\ *Flow* workflows address common computational chemistry tasks and are named with a prefix followed by *Flow*, Dock\ *Flow*, Score\ *Flow*, Lig\ *Flow*. 
:Dock\ *Flow*: Covers docking and virtual screening of compound(s) against some single or multiple targets, with one, some or all of the implemented docking software (so far Autodock Vina and PLANTS). 

:Score\ *Flow*: Handles (re)scoring of (top) docking poses which is more expensive, Structural Interaction fingerprints (using IChem), VinaSF, ChemPLP, PLP, MM/GBSA (with or without MD, implicit/explicit solvent). Both DockFlow and ScoreFlow are implemented to comply with docking/scoring benchmarks so that user can test new search and scoring functions and directly compare with the competition (within ReportFlow). 

:Lig\ *Flow*: 
    Handles conversions (such as smiles to mol2), conformer search and compound parameterization through assignment to the General Amber Force-Field (GAFF2) and charge calculation through QM methods. It also probes the ChemBase to avoid redundancy. ChemBase is the ChemFlow database for pre-calculated molecules, so far it contains a nearly 9000 drug-like compounds from the “Chimioteque Nationale du CNRS” with QM optimized geometries and assigned parameters for GAFF.

:MD\ *Flow* (not active): Handles pure molecular dynamics simulation protocols and analysis 

:HG\ *Flow*: is an application specific workflow designed for Host-Guest systems such as molecular cages.