# ChemFlow
<img src="https://user-images.githubusercontent.com/27850535/29564754-6b07a548-8743-11e7-9463-8626675b9481.png" alt="Logo" align="left" width=132/>ChemFlow is a series of computational chemistry workflows designed to automatize and simplify the drug discovery pipeline and scoring function benchmarking.

The workflows allow the user to spend more time **thinking**, i.e. running benchmarks or experiments, analyzing the data, and taking decisions, rather than programming/testing/debugging their own scripts.

It consists of *BASH* and *PYTHON* scripts that can be launched locally (serial or with GNU parallel) or on a compute cluster via PBS or SLURM.
* **DockFlow** : Docking and Virtual Screening
* **ScoreFlow** : Rescoring using PLANTS, Vina, or MM(PB,GB)SA
* **ReportFlow** : Extensive data analysis and reporting tool
* and other useful tools !

# :package: Installation

Clone or download the latest version of ChemFlow to it's destination, open a terminal and run the `install.sh` script located inside ChemFlow's directory.
```sh
cd ~/software
git clone https://github.com/IFMlab/ChemFlow.git
cd ChemFlow
./install.sh
```
It will create a `CHEMFLOW_HOME` variable, and check if necessary executables are on your path.

# :warning: Requirements

We do not provide any of the licensed softwares used by ChemFlow. It is up to the user to acquire and install PLANTS, Vina, Amber, Python 3 and the other softwares that might be added in future releases of ChemFlow.

[PLANTS](http://www.uni-tuebingen.de/fakultaeten/mathematisch-naturwissenschaftliche-fakultaet/fachbereiche/pharmazie-und-biochemie/pharmazie/pharmazeutische-chemie/pd-dr-t-exner/research/plants.html) and [SPORES](http://www.mnf.uni-tuebingen.de/fachbereiche/pharmazie-und-biochemie/pharmazie/pharmazeutische-chemie/pd-dr-t-exner/research/spores.html) are both available under a free academic license.
ChemFlow makes heavy uses of [Python 3](https://www.python.org/). It requires the following Python packages to run seamlessly :
* **pandas**
* **rdkit**
* **jupyter**
* **matplotlib**
* **numpy**
* **scikit-learn**
* **scipy**
* **seaborn**

# :package: Installation of Required packages

The required packages can be installed using [Miniconda](https://conda.io/miniconda.html), and pip (installed with Miniconda).
```
conda install -c rdkit rdkit
pip install jupyter matplotlib numpy pandas scikit-learn scipy seaborn
```

We strongly advise the user to install [jupyter_contrib_nbextensions](https://github.com/ipython-contrib/jupyter_contrib_nbextensions) to improve the functionality of the notebooks.

# :question: Usage

Check our awesome :rocket::star: [wiki](https://github.com/IFMlab/ChemFlow/wiki) :rainbow: for a complete documentation and tutorials.
