.. highlight:: bash

=======
Install
=======

Step 1 - Download ChemFlow sources.
-----------------------------------

The sources for ChemFlow can be downloaded from the `Github repo`_. 

.. _Github repo: https://github.com/IFMlab/ChemFlow.git 

.. code-block:: bash

    # Clone ChemFlow to the install location of your choice:
    git clone https://github.com/IFMlab/ChemFlow.git


Step 2 - Install miniconda.
---------------------------
Download and install the latest version of miniconda for python 3.x 
https://docs.conda.io/en/latest/miniconda.html

.. code-block:: bash

    # Download the latest version of miniconda for python 3.x
    wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
    
    # Install miniconda
    chmod +x  Miniconda3-latest-Linux-x86_64.sh
    ./Miniconda3-latest-Linux-x86_64.sh
      
    #Create an environment for ChemFlow
    conda create -n chemflow

    # Activate chemflow environment
    conda activate chemflow

Step 3 - Install the software dependencies.
--------------------------------------------
.. code-block:: bash

    # rdkit
    conda install -c rdkit rdkit

    # AmberTools (use Amber18 if you have a licence)
    conda install -c ambermd ambertools

    # AutoDockTools (required for Vina)
    Download and install from: http://mgltools.scripps.edu/downloads

    # Autodock Vina
    Download and install from: http://vina.scripps.edu

    # PLANTS ( Requires free registration )
    Download and install from: http://www.tcd.uni-konstanz.de/plants_download/

    # Amber18 (Optional, licence is required)
    Download and install from: http://ambermd.org

    # Gaussian (Optional, licence is required. Required for RESP charges)
    Download and install from: https://gaussian.com


Step 4 - Set PATHS
------------------

In addition to downloading the required software, you must be able to run then flawlessly.
Set up the PATHS to their install locations, as following and add to your .bashrc.

.. code-block:: bash


    # ChemFlow
    export CHEMFLOW_HOME=~/software/ChemFlow/ChemFlow/
    export PATH=${PATH}:${CHEMFLOW_HOME}/bin/

    # MGLTools
    export PATH="${PATH}:~/software/mgltools_x86_64Linux2_1.5.6/bin/"
    export PATH="${PATH}:~/software/mgltools_x86_64Linux2_1.5.6/MGLToolsPckgs/AutoDockTools/Utilities24/"

    # Autodock Vina
    export PATH="${PATH}:~/software/autodock_vina_1_1_2_linux_x86/bin/"

    # PLANTS
    export PATH="${PATH}:~/software/PLANTS/"

    # Optional (paid software)

    # Amber18 (Ambertools19 and Amber18)
    source ~/software/amber18/amber.sh

    # Gaussian 09
    export g09root=~/software/
    export GAUSS_SCRDIR=/tmp
    source $g09root/g09/bsd/g09.profile



Additional software for the tutorial
------------------------------------
To run the jupyter-notebook tutorial, you may also install some python modules.

    ``conda install pandas seaborn``
    