# **DockFlow** tutorial 01
 For this tutorial we'll use the Human Immunodeficiency Disease Virus Protease (HIV-1-PR) in complex with a potent inhibitor (Ki: 0.31 nM) and compare two sets of parameters for docking.  

## Tutorial steps
|Step|            Title      |  Description |
|----|:-------------:|:------|
| 01 | Structure preparation | Splits an input PDB to complex and ligand, complete structures with hydrogen and assign charges |
| 02 | Docking preparation and run 1 | Splits an input PDB to complex and ligand, complete structures with hydrogen and assign charges |
| 03 | Analysis of docking result.
| 04 | Docking preparation and run 2 | Splits an input PDB to complex and ligand, complete structures with hydrogen and assign charges |
| 05 | Comparative analysis of the two runs.

## Part I - A very simple (re)docking with a known binding site to evaluate methods.

ChemFlow **does not** cover structure preparation automatically as it should be **carefully** considered case-by-case.
However we do provide automated scripts for that, at your own risk.
 
 
### Structure preparation
#### Some background
Structural preparation is a crutial step in any molecular modeling campaign **(We need to write a structure preparation paper)**. Assigning proper protonation states both to receptor and the ligand can be a tricky task, be careful especially in the proposed binding site.
The [1HVR](http://www.rcsb.org/pdb/explore.do?structureId=1hvr "1HVR's on PDB") structure contains the HIV-1 protease ([P04585](http://www.uniprot.org/uniprot/P04585 "Uniprot for HIV-1 PR")) which is a symmetric homodimer with 99 aminoacid residues in each chain. 
HIV1PR is an aspartil protease (EC) containing two aspartates, residues 25 of from both chains, facing the binding cavity. 
The protonation state of this residues and impact has been discussed elsewhere (REFERENCES).

This structure also contains [2XR](https://www4.rcsb.org/ligand/XK2 "[4R-(4ALPHA,5ALPHA,6BETA,7BETA)]-HEXAHYDRO- 5,6-DIHYDROXY-1,3-BIS[2-NAPHTHYL-METHYL]- 4,7-BIS(PHENYLMETHYL)-2H-1,3-DIAZEPIN-2-ONE") a potent inhibitor.
There is also a residue modification, CYS 67 has been altered to CSO (L-cysteine sulfenic acid) (I just didn't check why) this must be modifyed.

A quick cleanup and splitting of receptor and ligand into separate files is provided by **split_1hvr.sh**, followed **prepare_1hvr.sh** wich performs the hydrogen assignment.

### Receptor preparation
```bash
pdb4amber -i rec/rec.pdb ... 
SPORES64 ...
```

### Ligand preparation
Ligand preparation has two steps. Fi
```bash
antechamber
SPORES64 ..
```
### Docking preparation
For this tutorial we defined the binding site center as the geometric center of known ligand, with a radius of 10A.
Run **ConfigFlow** and fill the forms to create required configuration files.

| Parameter  | Value |
|---:|---|
|Receptor | rec/rec_prot.mol2 |
|Ligand folder | lig/ |
| Binding site center X | -9.20 | 
| Binding site center Y | 15.90 | 
| Binding site center Z | 27.90 | 
| Radius | 10 |
| Number of docking poses | 25 | 

### Docking Results
Results will be placed in the **docking/** folder.

| File | Description | 
| --- | --- | 
| ranking.csv | Energies | 
| features.csv | Energy decomposition of scoring function terms |
| lig/*.mol2 | Poses | 

### Analysis using ReportFlow notebooks.
The analysis notebooks are a great way to organize and review our data, ChemFlow comes with various notebooks for different analysis scenarios, come and learn from then and write your own !  
We'll :heart: to get your feedback !  
A docking campaign can only be as good as the combination of a **search function** and **scoring function**. In simple terms, the **search function** should be able to sample the correct pose while the **scoring function** should determine that as the best pose. XK2 not a very complicated ligand, with it's only 8 rotatable bonds and a very confined search space. But even like this, it is challenging to sample the correct pose within reasonable time.
In this tutorial we want to evaluate how well the docking procedure performs to re-dock an original ligand to it's crystal structure. 
To assess that, we'll can use RMSD as the fundamental metric, but we also want to know the energy dispersion, which will indicate how well poses are ranked.
(Notice that the procedure already started from the solution, so in principle it should be sampled.)
(**Verify if PLANTS randomized the ligand before docking**)

### Results
A full table of results is available at the notebook as dataframe **XXX**. The dataframe also contains a field classifying a good, medium and bad result based on common cutoffs (customizable)

#### Graphs
Graphs show 
* RMSD by Energy
*

## Part II - Comparing protocols.
There is no **right** way to perform a docking. Several because the of the different complexity of each well receptor and or ligand, the default search function may be insuficient, also, since most search functions are stocastic there is no garantee that a global minima would be found, so multiple docking runs with different inital conditions (random seed) may be necessary. The **scoring functions** are also a big issue. To date, they've been designed to distinguish *actives* from *inactives*, so they're aren't entirely mature to rank compounds (that's a job for **ScoreFlow**!).  

  By now all we want is address if we can improve the outcome of a docking campaign by tunning the parameters. This is extremely important when benchmarking methods. DockFlow was designed (with a trick so far) to address this scenario, with a great ReportFlow notebook. 
