.. highlight:: bash

============
Installation
============

From sources
------------

The sources for ChemFlow can be downloaded from the `Github repo`_.

.. _Github repo: https://github.com/IFMlab/ChemFlow.git

You can should clone the private repository: (will be public when paper is out)

    ``git clone https://github.com/IFMlab/ChemFlow.git``


Required software
-----------------
+-----------------------+-------------------------------------------------------------------------------------------------------------------------------------------+
| Program               | Link to Download - Licencing may apply                                                                                                    |
+=======================+===========================================================================================================================================+
| PLANTS                | http://www.mnf.uni-tuebingen.de/fachbereiche/pharmazie-und-biochemie/pharmazie/pharmazeutische-chemie/pd-dr-t-exner/research/plants.html  |
+-----------------------+-------------------------------------------------------------------------------------------------------------------------------------------+
| AmberTools            | http://ambermd.org/GetAmber.php                                                                                                           |
+-----------------------+-------------------------------------------------------------------------------------------------------------------------------------------+
| Anaconda  (or PIP)    | https://www.anaconda.com/download/#linux                                                                                                  |
|                       |                                                                                                                                           |
|                       | After installing Anaconda, add some packages packages:                                                                                    |
|                       |                                                                                                                                           |
|                       |   ``conda install -c rdkit rdkit``                                                                                                        |
|                       |                                                                                                                                           |
|                       |   ``conda install -c schrodinger pymol``                                                                                                  |
+-----------------------+-------------------------------------------------------------------------------------------------------------------------------------------+

[ NOTE ] One may alternatively use *pip* to install python-related libraries.



Additional configuration
------------------------
In addition to downloading the required software, you must be able to run then flawlessly. Please set up the PATHS to the their install locations. (modify to your own)

+----------------------------------+-----------------------------------------------------------------------------+
| Program                          | action                                                                      |
+==================================+=============================================================================+
| ChemFlow                         | export CHEMFLOW_HOME=/home/USER/software/ChemFlow/ChemFlow/                 |
|                                  | export PATH=${PATH}:${CHEMFLOW_HOME}/bin/                                   |
+----------------------------------+-----------------------------------------------------------------------------+
| PLANTS                           | export PATH=${PATH}:/home/USER/software/plants/                             |
+----------------------------------+-----------------------------------------------------------------------------+
| Autodock Vina (qvina2, smina…)   | export PATH=${PATH}:/home/USER/software/autodock_vina_1_1_2_linux_x86/bin/  |
|                                  | export mgltools_folder=/home/USER/software/mgltools_x86_64Linux2_1.5.6/     |
|                                  | export PATH=${mgltools_folder}/bin:$PATH                                    |
+----------------------------------+-----------------------------------------------------------------------------+
| Gaussian (required for RESP)	   | # Setup some variables                                                      |
|                                  | g09root=”/home/USER/software/”                                              |
|                                  | GAUSS_SCRDIR=”${HOME}/scratch/”                                             |
|                                  | export g09root GAUSS_SCRDIR                                                 |
|                                  | . $g09root/g09/bsd/g09.profile                                              |
+----------------------------------+-----------------------------------------------------------------------------+
|AmberTools18	                   | source /home/USER/software/amber18/amber.sh                                 |
+----------------------------------+-----------------------------------------------------------------------------+


Additional software for the tutorial
------------------------------------
To run the jupyter-notebook tutorial, you may also install some python modules.

    ``conda install pandas seaborn``




