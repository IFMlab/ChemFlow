# DockFlow tutorial on virtual screening.
Virtual screening (VS) has become an integral part of the drug discovery process. VS is a computational technique to probe chemical libraries for candidate binders to a target molecule of known structure, typically a protein receptor or enzyme.

Top ranking compounds are prioritized to a manageable number that can be synthesized, purchased, and tested. Practical VS scenarios are focused on the design and optimization combinatorial libraries and to enrich locally avaible libraries or vendor offerings.

Several compound libraries are available for **VS** such as the [NCBI PubChem ](http://pubchem.ncbi.nlm.nih.gov), [eMolecules](www.emolecules.com) and [ZINC](zinc.docking.org), include commercially available compounds. There are also specialized libraries with expected biological features such as the hit or lead-like compounds, nutraceuticals [CITE], natural products [CITE], and metabolome [CITE].  The [FDA-approved drugs](www.epa.gov/ncct/dsstox) library, can also be used to repurpose compounds with acceptable safety/toxicity profiles.

## Summary
Here you will run a virtual screening campaign with the HIV-1 protease (HIVPR) as target. For quality controle and proper assessment of the results, you will be using input files from the [DUD-E](dude.docking.org "DUD-E: A Database of Useful (Docking) Decoys — Enhanced"). The HIVPR subset contains a properly prepared enzyme structure (**receptor**) and sets of active and inactive compounds (**ligands**) in the isomeric SMILES format. A reference ligand crystal structure, and structural files for all compounds are also provided.

First you will prepare the **receptor** and **ligands** to the .mol2 format, as required by DockFlow, then configure...

## Goals
* Prepare structures from a chemical library
* Run the virtual screening compounds
* Prioritize compounds by rescoring biding poses

# Getting Started
## Downloading and extracting the testset
```bash
# Create an empty folder
mkdir dockflow_VS_tutorial
cd dockflow_VS_tutorial

# Download the DUD-E's HIVPR subset
wget http://dude.docking.org/targets/hivpr/hivpr.tar.gz
tar xvfz  hivpr.tar.gz 
``
