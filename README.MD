# ChemFlow


## <span style="color:red">DockFlow</span>

to be completed...
It is designed to work with PLANTS (for now).
It can perform an automatic VS based on information given by the user :
ligands, receptor, binding site info, and extra options.


## <span style="color:green">ScoreFlow</span>
to be completed...



## <span style="color:blue">RMSDFlow</span>

RMSDFlow is a **Python 3** script that, as its name states it, computes the Root Mean Squared Deviation (RMSD) between one or several input molecular structures and one or more references. RMSDFlow's force relies on its implementation of the Hungarian Algorithm to correctly account for poses related by symmetry operations. It is also capable of using more classical algorithms to compute the RMSD.


## <span style="color:orange">ReportFlow</span>

ReportFlow is a set of scripts to analyse data obtained from <span style="color:red">DockFlow</span>, <span style="color:green">ScoreFlow</span>, and <span style="color:blue">RMSDFlow</span>.
It can generate automatically tables and figures.
It consists of IPython notebooks that can be opened with **Jupyter-Notebook**.
The code is written in **Python 3**, with some Bash commands.


# Requirements

We do not provide any of the licensed softwares previously mentionned. It is up to the user to acquire and install PLANTS, SPORES, Python 3 and the other softwares that might be added in future releases of ChemFlow.

PLANTS and SPORES are both available under a free academic license [here](http://www.uni-tuebingen.de/fakultaeten/mathematisch-naturwissenschaftliche-fakultaet/fachbereiche/pharmazie-und-biochemie/pharmazie/pharmazeutische-chemie/pd-dr-t-exner/research/plants.html).
As mentionned before, RMSDFlow and ReportFlow make heavy uses of Python 3, which can be downloaded [here](https://www.python.org/). They require the following Python packages to run seamleslly :
* numpy
* matplotlib
* pandas
* seaborn
* scipy

A tutorial on how to install python packages with PIP is available [here](https://pip.pypa.io/en/stable/installing/)

Paths to docking and structure preparation softwares (PLANTS, SPORES) should be added in the `ChemFlow.config` file located in the main ChemFlow folder.
In addition to this, we recommand that you add the following lines to your `.bashrc` file located in your home directory. Please make sure to replace `/path/to/ChemFlow` with ChemFlow's actual destination folder :
``` bash
export CHEMFLOW_HOME="/path/to/ChemFlow"
export PATH=$PATH:$CHEMFLOW_HOME/DockFlow:$CHEMFLOW_HOME/ScoreFlow:$CHEMFLOW_HOME/Tools
```

