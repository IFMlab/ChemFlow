========
ChemFlow
========

.. image:: https://user-images.githubusercontent.com/27850535/29564754-6b07a548-8743-11e7-9463-8626675b9481.png
        :alt: Logo

* Free software: MIT license

ChemFlow is a series of computational chemistry workflows designed to automatize and simplify the drug discovery pipeline and scoring function benchmarking.

The workflows allow the user to spend more time **thinking**, i.e. running benchmarks or experiments, analyzing the data, and taking decisions, rather than programming/testing/debugging their own scripts.

It consists of *BASH* and *PYTHON* scripts that can be launched locally (serial or with GNU parallel) or on a compute cluster via PBS.

* Lig\ *Flow* : Prepare the compound to dock/to score. Normalize the mol2 files and/or compute charges
* Dock\ *Flow* : Docking and Virtual Screening
* Score\ *Flow* : Rescoring using PLANTS, Vina, or MM(PB,GB)SA


Requirements for Chem\ *Flow*
-----------------------------

We do not provide any of the licensed softwares used by ChemFlow. It is up to the user to acquire and install PLANTS, Vina, Amber and the other softwares that might be added in future releases of ChemFlow.

PLANTS_ and SPORES_ are both available under a free academic license.

.. _PLANTS: http://www.uni-tuebingen.de/fakultaeten/mathematisch-naturwissenschaftliche-fakultaet/fachbereiche/pharmazie-und-biochemie/pharmazie/pharmazeutische-chemie/pd-dr-t-exner/research/plants.html
.. _SPORES: http://www.mnf.uni-tuebingen.de/fachbereiche/pharmazie-und-biochemie/pharmazie/pharmazeutische-chemie/pd-dr-t-exner/research/spores.html