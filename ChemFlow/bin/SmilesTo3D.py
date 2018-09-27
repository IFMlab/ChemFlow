#!/usr/bin/env python
# coding: utf8
#####################################################################
#   ChemFlow  -   Computational Chemistry is great again            #
#####################################################################
# Authors:
#         cbouy - Cédric Bouysset
#         cbouysset@unice.fr
#         Institut de Chimie de Nice - Université Côte d'Azur - France
#
#         dgomes - Diego E. B. Gomes
#         dgomes@pq.cnpq.br
#         Instituto Nacional de Metrologia, Qualidade e Tecnologia - Brazil
#         Coordenacao Aperfeicoamento de Pessoal de Ensino Superior - CAPES - Brazil.
#         Université de Strasbourg - France
#
# Brief: Generates 3D structures in SDF format from SMILES, using RDKIT
from rdkit import Chem, RDLogger
lg = RDLogger.logger()
from rdkit.Chem import AllChem
from concurrent import futures
import argparse, textwrap, sys

def InputSmiles(fileInput, args):
	supplier = Chem.SmilesMolSupplier(fileInput, titleLine=args.header, delimiter=args.delimiter, smilesColumn=args.smilesCol -1, nameColumn=args.namesCol -1, sanitize=False)
	smiles = []
	lg.setLevel(RDLogger.CRITICAL)
	for i,mol in enumerate(supplier):
		if mol:
			try:
				Chem.SanitizeMol(mol)
			except ValueError as e:
				sys.stderr.write('Molecule {} - {}\n'.format(i+1,e))
			else:
				# Give name based on line if none was found
				if not mol.HasProp('_Name'):
					mol.SetProp('_Name', str(i+1))
				# Make an iterable list of molecules
				smiles.append(mol)
	print("Read {}/{} molecules".format(len(smiles), len(supplier)))
	lg.setLevel(RDLogger.ERROR)
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
			print("Problem generating 3D structure for", m_H.GetProp('_Name'), "- Switching to RandomCoords method.")
			returnedVal = AllChem.EmbedMolecule(m_H, useRandomCoords=True)
			# if it failed again, print error
			if returnedVal == -1:
				print("Failed to generate 3D structure for", m_H.GetProp('_Name'))
				return None
		# if the generation of a 3D structure was successfull
		else:
			# Minimize with force field
			if   args.method == 'uff' : AllChem.UFFOptimizeMolecule(m_H)
			elif args.method == 'mmff': AllChem.MMFFOptimizeMolecule(m_H)
	elif args.method == 'etkdg':
		returnedVal = AllChem.EmbedMolecule(m_H, AllChem.ETKDG())
		if returnedVal == -1:
			print("Problem generating 3D structure for", m_H.GetProp('_Name'), "with ETKDG. Trying to be more permissive.")
			returnedVal = AllChem.EmbedMolecule(m_H, ignoreSmoothingFailures=True, useExpTorsionAnglePrefs=True, useBasicKnowledge=True)
			if returnedVal == -1:
				print("Problem generating 3D structure for", m_H.GetProp('_Name'), "with ETKDG. Switching to MMFF.")
				returnedVal = AllChem.EmbedMolecule(m_H)
				if returnedVal == -1:
					print("Failed to generate 3D structure for", m_H.GetProp('_Name'))
					return None
				else:
					AllChem.MMFFOptimizeMolecule(m_H)
	# Keep hydrogens or not
	if args.hydrogen:
		m = m_H
	else:
		m = Chem.RemoveHs(m_H)
	return m

def ExThreadSubmit(smiles, args):
	# uses a pool of threads to execute calls asynchronously
	with futures.ThreadPoolExecutor(max_workers=args.nthreads) as executor:
		jobs = []
		structures = []
		# Submit jobs
		for mol in smiles:
			job = executor.submit(Generate3D, mol)
			jobs.append(job)
		# Get results as they are completed
		for job in futures.as_completed(jobs):
			# If result is not None
			if job.result():
				structures.append(job.result())
	return structures

def ExMpiSubmit(smiles, args):
	from mpi4py import futures
	with futures.MPIPoolExecutor(max_workers=args.nthreads) as executor:
		# Submit a set of asynchronous jobs
		jobs = []
		structures = []
		# Submit jobs
		for mol in smiles:
			job = executor.submit(Generate3D, mol)
			jobs.append(job)
		# Get results as they are completed
		for job in futures.as_completed(jobs):
			# If result is not None
			if job.result():
				structures.append(job.result())
	return structures

def RunCPU(smiles, args):
	if args.mpi:
		return ExMpiSubmit(smiles, args)
	else:
		return ExThreadSubmit(smiles, args)

def RunGPU(smiles, args):
	pass

def OutputSDF(structures, args):
	output = Chem.SDWriter(args.output)
	for mol in structures:
		output.write(mol)
		if args.verbose:
			print("Writing: ", mol.GetPropsAsDict(includePrivate=True))
	print("Wrote {}/{} molecules to {}".format(len(structures), len(smiles), args.output))

########
# Main #
########

if __name__ == '__main__':
	# Argparse
	parser = argparse.ArgumentParser(description='Generates 3D structures in SDF format from SMILES, using RDKIT', formatter_class=argparse.RawTextHelpFormatter)

	group_input = parser.add_argument_group('INPUT arguments')
	group_input.add_argument("-i", "--input", metavar='filename', type=str, required=True, help="Path to your SMILES file")
	group_input.add_argument("-sc", "--smilesCol", metavar='int', type=int, default=1, help="Index of the column containing the SMILES. Default: 1")
	group_input.add_argument("-nc","--namesCol", metavar='int', type=int, default=2, help="Index of the column containing the names. Default: 2")
	group_input.add_argument("-d", "--delimiter", metavar="'char'", default='\t', help="If your SMILES file contains several columns: delimiter for the columns. Default: -d '\\t'")
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
	group_args.add_argument("--mpi", action="store_true", help="Run using MPI")
	group_args.add_argument("--gpu", action="store_true", help="Run on GPU (not implemented yet)")
	group_args.add_argument("-nt", "--nthreads", metavar='int', type=int, default=1, help="Specify the number of CPU threads to be used. Default: 1")

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
