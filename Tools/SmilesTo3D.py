#!/usr/bin/python3
# coding: utf8
from rdkit import Chem
from rdkit.Chem import AllChem
from rdkit.Chem import Draw
from time import sleep
import argparse, textwrap, sys
# Download progressbar2 from https://pypi.python.org/pypi/progressbar2
import progressbar

def InputSmiles(fileInput, args):
	supplier = Chem.SmilesMolSupplier(fileInput, titleLine=args.header, delimiter=args.delimiter, smilesColumn=args.smilesCol, nameColumn=args.namesCol)
	smiles = []
	for i,mol in enumerate(supplier):
		if mol:
			# Give name based on line if none was found
			if not mol.HasProp('_Name'):
				mol.SetProp('_Name', str(i+1))
			# Make an iterable list of molecules
			smiles.append(mol)
	print("Read {}/{} molecules".format(len(smiles), len(supplier)))
	return smiles

def Generate3D(mol):
	# Add hydrogens
	m_H = Chem.AddHs(mol)
	if (args.method == 'uff' or args.method == 'mmff') :
		# Try to create a 3D structure
		returnedVal = AllChem.EmbedMolecule(m_H)
		# if it failed
		if returnedVal == -1:
			# try with another method
			returnedVal = AllChem.EmbedMolecule(m_H, useRandomCoords=True)
			# if it failed again, print error
			if returnedVal == -1:
				print("Failed to generate 3D structure for", m_H.GetProp('_Name'), "in AllChem.EmbedMolecule")
		# if the generation of a 3D structure was successfull
		if returnedVal != -1:
			# Minimize with force field
			if   args.method == 'uff' : AllChem.UFFOptimizeMolecule(m_H)
			elif args.method == 'mmff': AllChem.MMFFOptimizeMolecule(m_H)
	elif args.method == 'etkdg':
		returnedVal = AllChem.EmbedMolecule(m_H, AllChem.ETKDG())
	# Keep hydrogens or not
	if args.hydrogen:
		m = m_H
	else:
		m = Chem.RemoveHs(m_H)
	return m

def RunCPU(smiles, args):
	from concurrent import futures
	with futures.ProcessPoolExecutor(max_workers=args.nthreads) as executor:
		# Submit a set of asynchronous jobs
		jobs = []
		structures = []
		for mol in smiles:
			job = executor.submit(Generate3D, mol)
			jobs.append(job)
		# Progress bar
		widgets = ["Generating 3D - [", progressbar.ETA(format='Remaining:  %(eta)s'), "] ", progressbar.Bar(), " ", progressbar.Percentage()]
		pbar = progressbar.ProgressBar(widgets=widgets, max_value=len(jobs))
		# Get results as they are completed
		for job in pbar(futures.as_completed(jobs)):
			structures.append(job.result())
	return structures

def RunGPU(smiles, args):
	from mpi4py import futures
	with futures.MPIPoolExecutor(max_workers=args.nthreads) as executor:
		# Submit a set of asynchronous jobs
		jobs = []
		structures = []
		for mol in smiles:
			job = executor.submit(Generate3D, mol)
			jobs.append(job)
		# Progress bar
		widgets = ["Generating 3D - [", progressbar.ETA(format='Remaining:  %(eta)s'), "] ", progressbar.Bar(), " ", progressbar.Percentage()]
		pbar = progressbar.ProgressBar(widgets=widgets, max_value=len(jobs))
		# Get results as they are completed
		for job in pbar(futures.as_completed(jobs)):
			structures.append(job.result())
	return structures

def OutputSDF(structures, args):
	file = Chem.SDWriter(args.output)
	for mol in structures:
		file.write(mol)
	print("Wrote", len(structures), "molecules to", args.output)

########
# Main #
########

if __name__ == '__main__':
	# Argparse
	parser = argparse.ArgumentParser(description='Generates 3D structures in SDF format from SMILES, using RDKIT', formatter_class=argparse.RawTextHelpFormatter)
	
	group_input = parser.add_argument_group('INPUT arguments')
	group_input.add_argument("-i", "--input", metavar='filename', type=str, required=True, help="Path to your SMILES file")
	group_input.add_argument("-sc", "--smilesCol", metavar='int', type=int, default=0, help="Index of the column containing the SMILES. Default: 0")
	group_input.add_argument("-nc","--namesCol", metavar='int', type=int, default=1, help="Index of the column containing the names. Default: 1")
	group_input.add_argument("-d", "--delimiter", metavar="'char'", default='\t', help="If your SMILES file contains several columns: delimiter for the columns. Default: -d '\t'")
	group_input.add_argument("--header", action="store_true", help="Presence of a header in the input file")
	
	group_output = parser.add_argument_group('OUTPUT arguments')
	group_output.add_argument("-o", "--output", metavar='filename', required=True, type=str, help="Path to the output SDF file")
	group_output.add_argument("--hydrogen", action="store_true", help="Output with all hydrogen atoms" )
	group_output.add_argument("-v", "--verbose", action="store_true", help="Increase terminal output verbosity")

	group_args = parser.add_argument_group('Other arguments')
	group_args.add_argument("-m", "--method", choices=['uff','mmff','etkdg'], default='etkdg', help=textwrap.dedent('''Use one of these algorithm : 
* uff   : distance geometry + force field minimization with UFF
* mmff  : distance geometry + force field minimization with MMFF
* etkdg : distance geometry with experimental torsion angles knowledge from the CSD. Used by default'''))
	group_args.add_argument("--gpu", action="store_true", help="Run on GPU using MPI")
	group_args.add_argument("-nt", "--nthreads", metavar='int', type=int, default=1, help="Specify the number of CPU threads to be used. Default: -nt 1")
	
	# Parse arguments from command line
	args = parser.parse_args()
	# Read SMILES file
	smiles = InputSmiles(args.input, args)
	# Generate the structures
	if args.gpu:
		structures = RunGPU(smiles, args)
	else:
		structures = RunCPU(smiles, args)
	# Output the structures to an SDF file
	OutputSDF(structures, args)