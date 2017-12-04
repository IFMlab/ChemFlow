# HG<i>Flow</i> - Host-Guest Molecular Dynamics Workflow 
... and Toy System Playground !!!

Copyright (c) 2017 Diego Enry B. Gomes and Marco Cecchini

Developed by:
Diego E. B. Gomes(1,2,3) - dgomes@pq.cnpq.br ; Paulina Pacack (3,4) - ppacak@unistra.fr; Marco Cecchini (3) -  cecchini@unistra.fr

1 - Instituto Nacional de Metrologia, Qualidade e Tecnologia - Brazil ; 
2 - Coordenacao Aperfeicoamento de Pessoal de Ensino Superior - CAPES - Brazil ; 
3 - Universite de Strasbourg - France ; 
4 - Novartis Institutes for BioMedical Research, Basel - Switzerland; 


HG<i>Flow</i> is a complete workflow to investigate Host/Guest systems using AmberTools14 (or latter)

The workflows are divided in 4 parts:
1) Setup
* Docking (future relase, using Dock<i>Flow</i>)
* Parametrization
* Simulation setup

2) Simulation - A single complex simulation or 3 independent simulations (complex, host, guest)
* Minimization
* Heating
* Equilibration
* Production

3) Analysis
* Post-processing, imaging, RMSD, RMSF, Radgyr...
* Linear Interaction Energy (LIE) using Cecchini's model. 
* Molecular Mechanics - Poisson-Boltzman + Solvation Area
* Molecular Mechanics - Generalized Born + Solvation Area

4) Reporting ( offered by Report<i>Flow</i> ) 
* Energies, 
* Center of Mass
* Correlation with experiment
(requires little user intervention)
