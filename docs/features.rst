.. highlight:: bash

========
Features
========

High Throughput
===============
Chem\ *Flow* was tuned to optimally use the high performance and throughput of available computing resources, following architectural standards of SLURM and PBS queueing systems. The job distribution was designed to minimize I/O and maximize throughput. Simplified configuration files allow them to adapt this policy to the available topology.

.. note:: We'll soon add support to Sun Grid Engine.

Fault tolerance and Checkpointing
=================================
A big concert when dealing with high throughput data is to be able to diagnose and resume after unsuccessful execution. Chem\ *Flow* detects and report failed jobs, and resubmit them all.

.. warning:: One should **always** investigate the reasons of failure with proper care.

Analysis and Reporting
======================
The major benefit from standardization is to facilitate analysis. Currently Chem\ *Flow* ships with protocols perform, analyses and report for some common scenarios for computational chemistry.

#. Docking and virtual screening of compounds including prospection, validation and method comparison.

#. MD simulations, contains protein stability (temperature, solvent, solvent mixture).

#. Any two-molecule system contains “rescoring” and binding free energy estimation.

.. note:: Analysis are mostly implemented with Bourne-again Shell (BASH) while the reporting tools are implemented as interactive Python Notebooks.

Data curation and reproducibility
=================================
Data curation demand for industrial applications require compliance with ISO/IEC 17025, the standard for which laboratories must hold accreditation in order to be deemed technically competent. The Chem\ *Flow* standard is a readily accessible and familiar specifications useful for data curation on drug discovery and molecular simulation projects.