.. highlight:: bash

=========
Workflows
=========
Chem\ *Flow* workflows address common computational chemistry tasks and are named with a prefix followed by "*Flow*", their are: Dock\ *Flow*, Score\ *Flow*, and Lig\ *Flow*. Two additional *Flows* will be released soon MD\ *Flow*, HG\ *Flow*, Entropy\ *Flow* (from Pereira, G.) stay tunned for updates!

.. hint:: The work\ *Flows* let you harness the power of your multicore machine or HPC resource.

Dock\ *Flow*
=============
Dock\ *Flow* covers docking and virtual screening of compound(s) against some single or multiple targets, with one or multiple compounds through the so far implemented docking software: Autodock Vina and PLANTS. 

Score\ *Flow*
=============
Score\ *Flow* handles the (re)scoring of complexes (such as docking poses), either with empirical (VinaSF, ChemPLP) or physics-based functions (MM/PBSA, MM/GBSA) with or without MD, implicit/explicit solvent.

Lig\ *Flow*
=============
Lig\ *Flow* handles the curation of compound libraries, stored as SMILES or MOL2 files, automating 3D conformer generation, compound parameterization and charge calculation. It also probes the Chem\ *Base* to avoid redundancy. 


Handles small molecule conversions, conformer search and compound parametrization through assignment to the General Amber Force-Field (GAFF2) and charge calculation through QM methods. It also probes the Chem\ **Base** to avoid redundancy.

Chem\ **Base**
==============
Chem\ **Base** is the Chem\ *Flow database for pre-calculated molecules, so far it spams nearly 9000 drug-like compounds from the *Chimioteque Nationale du CNRS* with QM optimized geometries and assigned parameters for GAFF.


MD\ *Flow* (unreleased)
=============
Handles molecular dynamics simulation protocols and analysis.

HG\ *Flow* (unreleased)
=============
A full fledged workflow designed for Host-Guest systems such as molecular cages.

.. hint:: Dock\ *Flow* and Score\ *Flow* were implemented to comply with docking/scoring benchmarks. One can test new search and scoring functions and directly compare with the competition (within Report\ *Flow*).

.. Note:: Chem\ **Base** is the Chem\ *Flow* database for pre-calculated molecules, so far it contains nearly 9000 drug-like compounds from the “Chimioteque Nationale du CNRS” with HF 6-31G* QM optimized geometries and assigned parameters for GAFF2. Access requires proof of "Chimioteque" licence.



Workflows (extended)
====================
Chem\ *Flow* is a modular platform for computational chemistry workflows using high performance environments.
The workflows address common **computational chemistry** tasks and are named with a prefix followed by *Flow*, Dock\ *Flow*, Score\ *Flow* and Lig\ *Flow*.

* Dock\ *Flow* covers docking and virtual screening of compound(s) against some single or multiple targets, with one, some or all of the implemented docking software (so far Autodock Vina and PLANTS).

* Score\ *Flow* on the other hand handles (re)scoring of (top) docking poses which is more expensive, Structural Interaction fingerprints (using IChem), VinaSF, ChemPLP, PLP, MM/GBSA (with or without MD, implicit/explicit solvent). Both DockFlow and ScoreFlow are implemented to comply with docking/scoring benchmarks so that user can test new search and scoring functions and directly compare with the competition (within ReportFlow).

* Lig\ *Flow* handles conversions (such as smiles to mol2), conformer search and compound parameterization through assignment to the General Amber Force-Field (GAFF2) and charge calculation through QM methods. It also probes the ChemBase to avoid redundancy.

* Chem\ **Base** is the Chem\ *Flow* database for pre-calculated molecules, so far it contains a nearly 9000 drug-like compounds from the “Chimioteque Nationale du CNRS” with QM optimized geometries and assigned parameters for GAFF.

* MD\ *Flow** (not active) handles molecular dynamics simulation protocols and analysis and HGFlow is an application specific workflow designed for Host-Guest systems.
