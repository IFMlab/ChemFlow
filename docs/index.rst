.. ChemFlow documentation master file, created by
   sphinx-quickstart on Fri Jul 27 10:35:54 2018.
   You can adapt this file completely to your liking, but it should at least
   contain the root `toctree` directive.
****************************************
Welcome to Chem\ *Flow*'s documentation!
****************************************
Chem\ *Flow* is a modular platform for computational chemistry workflows using high performance environments.
The workflows address common **computational chemistry** tasks and are named with a prefix followed by *Flow*, Dock\ *Flow*, Score\ *Flow* and Lig\ *Flow*.

Workflows
=========
:DockFlow: Covers docking and virtual screening of compound(s) against some single or multiple targets, with one, some or all of the implemented docking software. 

:ScoreFlow: Handles (re)scoring of (top) docking poses either with empirical (VinaSF, ChemPLP) or physics-based functions (MM/PBSA, MM/GBSA).

:LigFlow: Handles small molecule conversions, conformer search and compound parametrization through assignment to the General Amber Force-Field (GAFF2) and charge calculation through QM methods. It also probes the **ChemBase** to avoid redundancy. 

:ChemBase: is the Chem\ *Flow database for pre-calculated molecules, so far it spams nearly 9000 drug-like compounds from the *Chimioteque Nationale du CNRS* with QM optimized geometries and assigned parameters for GAFF.

Implementation
==============
   ChemFlow was designed as modular tool based on plain Bourne-again Shell (BASH) script, a ubiquitous environment and programming language in every UNIX environment. The code integrates freely available software for structure manipulation, molecular docking, molecular dynamics (MD) simulation, binding free energy calculations, and structure calculation. In addition, it contains optional routines for proprietary software.

.. toctree::
   :maxdepth: 1
   :caption: Contents:

   readme
   installation
   tutorial
   authors

..   usage
..   contributing
..   history

.. Indices and tables
.. ==================
.. * :ref:`genindex`
.. * :ref:`modindex`
.. * :ref:`search`
