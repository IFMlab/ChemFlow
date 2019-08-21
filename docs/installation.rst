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
    
    ``export GAUSS_SCRDIR=/tmp``
    
    ``source $g09root/g09/bsd/g09.profile``

# Instructions for the impacient:

.. code-block:: bash
    # Please modify the following paths and add them to your .bashrc

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


