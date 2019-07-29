.. highlight:: bash

=========================
Installation instructions
=========================

Step 1 - Download ChemFlow sources.
-----------------------------------

The sources for ChemFlow can be downloaded from the `Github repo`_.

.. _Github repo: https://github.com/IFMlab/ChemFlow.git

You can either clone the public repository:

    ``git clone https://github.com/IFMlab/ChemFlow.git``


Step 2 - Install miniconda.
---------------------------
* Download and install miniconda, python 3.
https://docs.conda.io/en/latest/miniconda.html

* Create an environment for ChemFlow.
``conda create -n chemflow``

Step 3 - Install the software dependencies
--------------------------------------------
* rdkit
``conda install -c rdkit rdkit``

* AmberTools
``conda install -c ambermd ambertools``

* AutoDockTools (required for Vina)
Download and install from: http://mgltools.scripps.edu/downloads

* Autodock Vina
Download and install from: http://vina.scripps.edu

* PLANTS ( Requires free registration )
Download and install from: https://uni-tuebingen.de/fakultaeten/mathematisch-naturwissenschaftliche-fakultaet/fachbereiche/pharmazie-und-biochemie/pharmazie/pharmazeutische-chemie/pd-dr-t-exner/research/spores/

* Amber18 (Optional, licence is required)
Download and install from: http://ambermd.org

* Gaussian (Optional, licence is required)
Download and install from: https://gaussian.com

