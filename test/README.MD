# ChemFlow - Computational Chemistry Workflows
## Full workflow testset
Here we provide a full and simple system to evaluate all ChemFlow features, as well as verify the integrity of your installation.

:warning: Before running anything, please run the installation script `install.sh` in the parent folder. 

**1. Testing your installation**

To test the integrity of your installation, simply run the test script with the following command:
```bash
bash test.sh
```

Since docking algorithms are usually partly stochastic, differences between the affinities or RMSD of poses obtained during the test run and those expected are shown as warnings.

A summary of the errors and warning is shown in the `summary.log` file while the complete outputs are available in the `output.log` file.  

**2. Evaluating ChemFlow features**

Start by extracting the files:
```bash
tar -zxvf hostguest.tar.gz
```

Then follow our tutorials !
