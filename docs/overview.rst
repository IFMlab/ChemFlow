.. highlight:: bash

========
Overview
========
Chem\ *Flow* is a computational software composed of a series of tools within the domain of computational chemistry, and subdomain drug discovery and development. 
It was designed to contain simple and integrated workflows to perform common protocols in the early stages of drug discovery and protein design.

Chem\ *Flow* contains several features that set it apart from competition:

#. Ready to use protocols for drug discovery and drug repurposing.

#. Facilitated usage of high performance computing (HPC) resources.

#. Checkpointing, resuming of calculations, error reporting.

#. Report facility for each protocol.
#. A database. (Chem\ **Base**)
#. It's mostly written in BASH script ! There's no space fancy Python mambo-jambos.

Why Chem\ *Flow*?
=================

During a virtual High Throughput computational chemistry study we were confronted with unintelligibly data from a previous collaborator and the challenge to produce our own. This is actually a very common scenario we've been confronted our whole carreers.

.. warning:: Everyone does things their own way !

We found it would be valuable to do just like proprietary tools and **standardize** the directory structure and file naming for projects. Standardization facilitate documentation, comprehension, data retention and reproducibility, therefore future users or applications will not have to figure out this structure or migrate to new formats.


A standardization effort
------------------------
Before being a software, Chem\ *Flow* is an initiative to fill a gap in the field by developing an open standard for execution and curation of computational chemistry data, to enable access to precomputed data and facilitate method development, validation and comparison.

Implementation
--------------

Chem\ *Flow* was designed as modular tool based on plain Bourne-again Shell (BASH) script, an ubiquitous environment and programming language in every UNIX environment.

.. note:: BASH is the **default shell** for the most popular Linux distributions, and for MacOS.

.. tip:: If you've got to learn a scripting language, go for BASH, is an easy and powerfull.

Middleware design
-----------------
The code integrates to freely available software for structure manipulation (RDKIT and openbabel), molecular docking (PLANTS and Autodock Vina), molecular dynamics (MD) simulation, binding free energy calculations (AmberTools), and structure calculation (SQM). Chem\ *Flow* also contains optional routines for proprietary software Amber18 and Gaussian 09. 

As simple is possible
---------------------

By design, the goal was to make Chem\ *Flow* as simple is possible to require minimal installation and promote extension. The code is containerized and modular to allow methods to be applied only in a well-defined way which is **traceable and reproducible** following the ISO/IEC 17025 guidelines for assays. Chem\ *Flow* ships with protocols for common experiments and curated benchmarks to assess the performance of methods.  

