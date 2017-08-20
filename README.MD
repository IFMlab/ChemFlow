# ChemFlow

ChemFlow is a serie of computational chemistry workflow's designed to automatize and simplify as much as possible the drug discovery pipeline and scoring function benchmarking.
It consists of BASH and PYTHON scripts that can be launched locally, locally with GNU parallel, or an a compute node via PBS.
The aim of these workflow's is to let the user spend more time on the experimental part, i.e. running benchmarks or experiments, analysing the data, and taking decisions, rather than the programming/testing/debugging part.
* DockFlow : virtual screening
* LigFlow : ligand extraction and preparation from DockFlow to ScoreFlow
* ScoreFlow : rescoring using PLANTS, Vina, or MM-PB/GB-SA
* ReportFlow : Extensive data analysis
* and other usefull tools !


# Installation

Clone or download the latest version of ChemFlow to it's destination, open a terminal and run the `install.sh` script located inside ChemFlow's directory. It will create a `CHEMFLOW_HOME` variable, and add the necessary executables to your path.


# Requirements

We do not provide any of the licensed softwares used by ChemFlow. It is up to the user to acquire and install PLANTS, Vina, Amber, Python 3 and the other softwares that might be added in future releases of ChemFlow.

[PLANTS](http://www.uni-tuebingen.de/fakultaeten/mathematisch-naturwissenschaftliche-fakultaet/fachbereiche/pharmazie-und-biochemie/pharmazie/pharmazeutische-chemie/pd-dr-t-exner/research/plants.html) and [SPORES](http://www.mnf.uni-tuebingen.de/fachbereiche/pharmazie-und-biochemie/pharmazie/pharmazeutische-chemie/pd-dr-t-exner/research/spores.html) are both available under a free academic license.
ReportFlow makes heavy uses of [Python 3](https://www.python.org/) through Jupyter-Notebook. It requires the following Python packages to run seamleslly :
* jupyter
* matplotlib
* numpy
* pandas
* scikit-learn
* scipy
* seaborn

A tutorial on how to install python packages with PIP is available [here](https://pip.pypa.io/en/stable/installing/)
We also advise the user to install [jupyter_contrib_nbextensions](https://github.com/ipython-contrib/jupyter_contrib_nbextensions) to improve the functionality of the notebooks. 

Paths to some of the softwares executables (PLANTS, SPORES, Vina, Amber) should be added in the `$CHEMFLOW_HOME/ChemFlow.config` file.

# Usage

Check our [wiki](https://github.com/IFMlab/ChemFlow/wiki) for instructions and tutorials.
