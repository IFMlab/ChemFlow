Ligflow specification
=====================

Lig*Flow* is the Chem*Flow* module to handle small molecule structures.

- LigFlow works with the *mol2* format. 

Outline
LigFlow receives a .mol2 input file and outputs a .mol2 file in GAFF2 atom types.

# Sanity checks
* Input/Output
  * Input file must exist and be readable 
  * Output folder must be writable.
  
* AmberTools install
  * AmberTools 17+ must be installed to process input files.
  * Required to compute Gasteiger charges
  * Required to compute BCC charges. 

* Gaussian 09 install. (must generalize on include Gaussian 16)
  * Required to compute RESP charges.