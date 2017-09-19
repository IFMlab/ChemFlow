#Score*Flow* for Virtual Screening
Virtual Screening (VS) allows large molecular databases to be screened rapidly and indentify leads for drug discovery when a known high quality 3D structure is available for target. 

The ranking of ligand docking poses is **the** most important step in VS, for this docking programs rely on **scoring functions** 
a tiered scoring scheme is often employed whereby a simple scoring function is used as a fast filter of the entire database and a more rigorous and time-consuming scoring function is used to rescore the top hits to produce the final list of ranked compounds. 
according to certain scoring systems to identify the best fit is the most important step in virtual database screening for drug discovery. 


VS relies on scoring functions rank binding poses 

...
ignore bellow so far.

Target-based virtual screening is increasingly used to generate leads for targets for which high quality three-dimensional (3D) structures are available. To allow large molecular databases to be screened rapidly, 

Molecular mechanics Poisson-Boltzmann surface area (MM-PBSA) approaches are currently thought to be quite effective at incorporating implicit solvation into the estimation of ligand binding free energies.

In this paper, the ability of a high-throughput MM-PBSA rescoring function to discriminate between correct and incorrect docking poses is investigated in detail. Various initial scoring functions are used to generate docked poses for a subset of the CCDC/Astex test set and to dock one set of actives/inactives from the DUD data set. 

The effectiveness of each of these initial scoring functions is discussed. Overall, the ability of the MM-PBSA rescoring function to:
  (i) regenerate the set of X-ray complexes when docking the bound conformation of the ligand, 
  (ii) regenerate the X-ray complexes when docking conformationally expanded databases for each ligand which include "conformation decoys" of the ligand, and 
  (iii) enrich known actives in a virtual screen in the presence of "ligand decoys" is assessed. 
