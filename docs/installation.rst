.. highlight:: bash

=========================
Installation instructions
=========================

Step 1 - Download ChemFlow sources.
-----------------------------------

The sources for ChemFlow can be downloaded from the `Github repo`_.

.. _Github repo: https://github.com/IFMlab/ChemFlow.git
    
You can clone the Official branch repository:
    
    ``git clone --branch ChemFlow_Official https://github.com/IFMlab/ChemFlow.git``
    
Then you can add in the ~/.bashrc the path to your CHEMFLOW_HOME as follows:

``export CHEMFLOW_HOME="/your/path/here/ChemFlow/ChemFlow/"``

``export PATH="${PATH}:${CHEMFLOW_HOME}/bin/"``

Then source the bashrc:

.. code-block:: bash


    source ~/.bashrc


Step 2 - Install anaconda3.
---------------------------
* Download and install anaconda3.
https://www.anaconda.com/products/individual#linux


-Go to the folder where you downloaded the script of anaconda and type:

**chmod +x Anaconda3-*-Linux-x86_64.sh**

-*execute*: 

**./Anaconda3-*-Linux-x86_64.sh**

* Create a conda environment for ChemFlow, with the provided environment file **chmeflow.txt** that is in the main folder *ChemFlow/*:
``conda create -n ChemFlow --file chemflow.txt``

Step 3 - Install the software dependencies
--------------------------------------------

* Autodock Vina
    Download from: https://vina.scripps.edu/downloads/
    
    Add in your ~/.bashrc : 
    
    **export PATH="/your/path/autodock_vina_1_1_2_linux_x86/bin:$PATH"**

* Qvina (EXECUTABLE FILE)
    Download from: https://github.com/QVina/qvina/blob/master/bin/qvina2.1
    
.. code-block:: bash
    

    mkdir qvina/
    mv qvina2.1 qvina/
    cd qvina/
    chmod +x qvina2.1
    
Add in your ~/.bashrc : 
    
    **export PATH="/your/path/qvina:$PATH"**
        
* Smina (EXECUTABLE FILE)
    Download from:  https://sourceforge.net/projects/smina/
    
.. code-block:: bash

    
    mkdir smina/
    mv smina.static smina/
    cd smina/
    chmod +x smina.static

Add in your ~/.bashrc :

    **export PATH="/your/path/smina:$PATH**
    
    
* PLANTS ( Requires free registration )
    Download and install from: http://www.tcd.uni-konstanz.de/plants_download/
    
    Add in your ~/.bashrc:    
    
    **export PATH="${PATH}:~/software/PLANTS/"**

* Amber18 (Optional, licence is required)

    Download and install from: http://ambermd.org

* Gaussian (Optional, licence is required)

    Download and install from: https://gaussian.com

Step 4 - Set PATHS
------------------
   
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

    # Optional (paid software)
    
    # Amber18 (Ambertools19 and Amber18)
    source ~/software/amber18/amber.sh
    
    # Gaussian 09
    export g09root=~/software/
    export GAUSS_SCRDIR=/tmp
    source $g09root/g09/bsd/g09.profile

Step 5 - Activate the environment and go to the tutorial folder
----------------------------------------------------------------

.. code-block:: bash

    conda activate ChemFlow
    
Now we can work in the tutorial directory:

.. code-block:: bash

    cd $CHEMFLOWHOME
    cd ..
    cd tutorial/example-a-thrombin
    
and follow the intrruction of the tutorial file in the repository: ChemFlow/tutorial/example-a-thrombin/Tutorial-DF-LF-SF.rst
