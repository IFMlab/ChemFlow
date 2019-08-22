.. highlight:: bash

=========
Workflows
=========
Chem\ *Flow* workflows address common computational chemistry tasks and are named with a prefix followed by *Flow*, Dock\ *Flow*, Score\ *Flow*, Lig\ *Flow*. 

Dock\ *Flow*
=============
Covers docking and virtual screening of compound(s) against some single or multiple targets, with one, some or all of the implemented docking software (so far Autodock Vina and PLANTS). 

Score\ *Flow*
=============
Handles (re)scoring of (top) docking poses which is more expensive, Structural Interaction fingerprints (using IChem), VinaSF, ChemPLP, PLP, MM/GBSA (with or without MD, implicit/explicit solvent). 

Lig\ *Flow*
=============
Handles conversions (such as smiles to mol2), conformer search and compound parameterization through assignment to the General Amber Force-Field (GAFF2) and charge calculation through QM methods. It also probes the ChemBase to avoid redundancy. 

MD\ *Flow* (unreleased)
=============
Handles pure molecular dynamics simulation protocols and analysis 

HG\ *Flow* (unreleased)
=============
A full fledged workflow designed for Host-Guest systems such as molecular cages.

.. hint:: Dock\ *Flow* and Score\ *Flow* were implemented to comply with docking/scoring benchmarks. One can test new search and scoring functions and directly compare with the competition (within Report\ *Flow*). 

.. Note:: Chem\ **Base** is the Chem\ *Flow* database for pre-calculated molecules, so far it contains a nearly 9000 drug-like compounds from the “Chimioteque Nationale du CNRS” with HF 6-31G* QM optimized geometries and assigned parameters for GAFF.
