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
    Download and install from: http://www.tcd.uni-konstanz.de/plants_download/

* Amber18 (Optional, licence is required)
    Download and install from: http://ambermd.org

* Gaussian (Optional, licence is required)
    Download and install from: https://gaussian.com

Step 4 - Set PATHS
------------------
* AutoDockTools - "Utilities24" must be in the system PATH:
    ``export PATH=${PATH}:[/home/user/myapps/]mgltools_x86_64Linux2_1.5.6/MGLToolsPckgs/AutoDockTools/Utilities24/``
* PLANTS
    ``export PATH=${PATH}:[/home/user/myapps/]PLANTS1.2_64bit``
* AutoDock Vina
    ``export PATH=${PATH}:[/home/user/myapps/]autodock_vina_1_1_2_linux_x86/bin/``
    
If you choose to manually install Amber18 and/or Gaussian, make sure they're also on ${PATH}

* Amber18
    source [/home/user/myapps/]amber18/amber.sh
* Gaussian 09
    ``export g09root=[/home/user/myapps/]``
    
    ``export GAUSS_SCRDIR=/home/user/myapps/scratch``
    
    ``source $g09root/g09/bsd/g09.profile``




Summary of exported PATHS:
--------------------------
In addition to downloading the required software, you must be able to run then flawlessly. Please set up the PATHS to the their install locations. (modify to your own)

+----------------------------------+-----------------------------------------------------------------------------+
| Program                          | action                                                                      |
+==================================+=============================================================================+
| ChemFlow                         | export CHEMFLOW_HOME=/home/user/myapps/ChemFlow/ChemFlow/                   |
|                                  |                                                                             |
|                                  | export PATH=${PATH}:${CHEMFLOW_HOME}/bin/                                   |
+----------------------------------+-----------------------------------------------------------------------------+
| PLANTS                           | export PATH=${PATH}:/home/USER/software/plants/                             |
+----------------------------------+-----------------------------------------------------------------------------+
| Autodock Vina (qvina2, smina…)   | export PATH=${PATH}:/home/USER/software/autodock_vina_1_1_2_linux_x86/bin/  |
|                                  |                                                                             |
|                                  | export mgltools_folder=/home/USER/software/mgltools_x86_64Linux2_1.5.6/     |
|                                  |                                                                             |
|                                  | export PATH=${mgltools_folder}/bin:$PATH                                    |
+----------------------------------+-----------------------------------------------------------------------------+
| Gaussian (required for RESP)	   | g09root=/home/user/myapps/                                                  |
|                                  |                                                                             |
|                                  | GAUSS_SCRDIR=”/home/user/myapps/scratch/”                                   |
|                                  |                                                                             |
|                                  | export g09root GAUSS_SCRDIR                                                 |
|                                  |                                                                             |
|                                  | . $g09root/g09/bsd/g09.profile                                              |
+----------------------------------+-----------------------------------------------------------------------------+
|AmberTools18	                   | source /home/USER/software/amber18/amber.sh                                 |
+----------------------------------+-----------------------------------------------------------------------------+


Additional software for the tutorial
------------------------------------
To run the jupyter-notebook tutorial, you may also install some python modules.

    ``conda install pandas seaborn``




