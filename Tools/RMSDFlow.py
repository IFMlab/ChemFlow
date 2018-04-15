#!/usr/bin/python3
# coding: utf8

# @author Cedric Bouysset <bouysset.cedric@gmail.com>
# @author Diego Enry Barreto Gomes <dgomes@pq.cnpq.br>
# @brief Computes RMSD between several references and several inputs in MOL2 files
# @details Different algorithms are available to find optimal atom pairs to account
# for molecules related by symmetry operations.

import argparse, textwrap, re, os.path, shutil
from   concurrent import futures
import numpy as np
import matplotlib.pyplot as plt
from   scipy.optimize import linear_sum_assignment

def mol2_reader(mol2_file, ignoreH):
    '''A simple MOL2 file reader. Can read files with multiple molecules.
    Returns a list of molecules. Each molecule is a list of atoms, where an atom
    is a dictionnary containing atom informations (name and type),
    and coordinates (x,y and z).'''
    molecules       = []
    num_atoms_lines = []
    first_lines     = []

    # Read file
    with open(mol2_file, "r") as f:
        lines = f.readlines()

    # Search for the line where the number of atoms is, and the first line where atom coordinates are readable
    for i, line in enumerate(lines):
        search_molecule = re.search(r'@<TRIPOS>MOLECULE', line)
        search_atom     = re.search(r'@<TRIPOS>ATOM', line)

        if search_molecule:
            # line with the number of atoms
            num_atoms_lines.append(i+2)
        elif search_atom:
            # first line with atom coordinates
            first_lines.append(i+1)

    for num_atoms_line, first_line in zip(num_atoms_lines, first_lines):
        mol  = get_mol_from_mol2(num_atoms_line, first_line, lines, ignoreH)
        name = lines[num_atoms_line - 1].replace("\n","")
        molecules.append([name,mol])

    return molecules

def get_mol_from_mol2(num_atoms_line, first_line, lines, ignoreH):
    '''Extracts a molecule from a mol2 file.
    num_atoms_line: index of the line containing the number of atoms, bonds...etc.
    first_line: index of the first line of the molecule to be extracted
    Returns a molecule as a list of atoms. An atom is a dictionnary containing
    atom informations (name and type), and coordinates (x,y and z).'''
    # Read number of atoms directly from the corresponding line
    data      = lines[num_atoms_line].split()
    num_atoms = int(data[0])

    # create molecule containing a list of atoms
    MOL = []
    # Fill the list with atomic parameters and coordinates
    for line in range(first_line, first_line + num_atoms):
        data = lines[line].split()
        if ignoreH: # if ignore H
            if data[5] == 'H': # if the atom read is an H
                continue # skip this atom
        # if it's not an H, or we don't ignore H, add this atom
        MOL.append(
        {
            'prm': {
                'atom': data[1],
                'type': data[5],
            },
            'crd': [float(data[2]),float(data[3]),float(data[4])],
        },)
    return MOL

# classical RMSD function
def rmsd_standard(ref, mol, cutOff, ignoreOutliers):
    '''Classical RMSD function that compares atoms of the same name.
    ref : list of dictionnaries containing atom information and position for the reference molecule
    mol : list of dictionnaries containing atom information and position for the target molecule
    cutOff : float, cutOff to ignore outliers
    ignoreOutliers: Boolean, ignore outliers'''

    # Compute the sum of squared differences between atomic coordinates
    nb_atoms = len(ref)
    rss_list = []

    for ref_atom in ref:
        for mol_atom in mol:
            # if same atom names
            if ref_atom['prm']['atom'] == mol_atom['prm']['atom']:
                # residual sum of squares, or distance^2
                rss = sum([(ref_atom['crd'][i] - mol_atom['crd'][i])**2 for i in range(3)])

                if rss > cutOff**2:  # if the euclidian distance (sqrt(rss)) is superior to the cut-off
                    if not ignoreOutliers:  # append to the list only if we do not ignore outliers
                        rss_list.append(rss)
                else:
                    rss_list.append(rss)
                break # get out of the mol loop since we found the atom of the same name

    # Compute the RMSD
    nb_atoms_used = len(rss_list)
    if nb_atoms_used == 0:
        rmsd = np.nan
    else:
        rmsd = np.sqrt(1/nb_atoms_used * sum(rss_list))

    # return RMSD, number of atoms used to compute RMSD, number of atoms in the molecule
    return rmsd, len(rss_list), nb_atoms


def rmsd_MDA(ref, mol, cutOff, ignoreOutliers):
    '''A minimal distance algorithm to compute the RMSD. For an atom of the reference
    molecule, search for an atom of the same type in the target molecule with the
    minimal distance possible. Once such atom is found, check that the target atom would
    not be better assigned to another reference atom of the same type. If its the case,
    take the second best candidate and check again. Do this until the reference
    atom and the target atom are both good assignments for each other.'''

    nb_atoms = len(ref)
    M        = {}

    for ref_atom in ref:
        # create a dictionnary of atom types
        atom_type = ref_atom['prm']['type']
        rss_list = []
        if atom_type not in M:
            M[atom_type] = []
        # fill each atom_type with a matrix of RSS between atoms of reference and
        # molecule of the same type
        for mol_atom in mol:
             if ref_atom['prm']['type'] == mol_atom['prm']['type']:
                 # residual sum of squares, or distance^2
                 rss = sum([(ref_atom['crd'][i] - mol_atom['crd'][i])**2 for i in range(3)])
                 rss_list.append(rss)
        M[atom_type].append(rss_list)

    rss_list = []
    for atom_type in M:
        ref_read    = []
        target_read = []
        # convert to numpy array
        matrix = np.array(M[atom_type])
        # set the max number of iterations
        max_iterations = len(matrix)
        # get target atom with min rss to ref atom
        for i_ref in range(len(matrix)):
            target_indices = np.where(matrix[i_ref] == matrix[i_ref].min())[0]
            for i_target in target_indices:
                found = False
                iteration = 0
                while not found:
                    if iteration < max_iterations:
                        iteration += 1
                        pair = search_best_rss(matrix, i_ref, i_target, cutOff, ignoreOutliers)
                        if pair:
                            i_ref, i_target = pair
                            if (i_ref not in ref_read) and (i_target not in target_read):
                                rss = matrix[i_ref][i_target]
                                rss_list.append(rss)
                                ref_read.append(i_ref)
                                target_read.append(i_target)
                                found = True
                            else:
                                matrix[i_ref][i_target] = 1e5
                    else:
                        break

    # Compute the RMSD
    nb_atoms_used = len(rss_list)
    if nb_atoms_used == 0:
        rmsd = np.nan
    else:
        rmsd = np.sqrt(1/nb_atoms_used * sum(rss_list))

    # return RMSD, number of atoms used to compute RMSD, number of atoms in the molecule
    return rmsd, len(rss_list), nb_atoms

def search_best_rss(matrix, i_ref, i_target, cutOff, ignoreOutliers):
    # check if target atom doesn't have a better assignment than the ref atom
    ref_indices = np.where(matrix.T[i_target] < matrix[i_ref][i_target])[0]
    if len(ref_indices): # if there's a better ref candidate for the current target candidate
        return None
    else: # if the ref-target is the best match
        if matrix[i_ref][i_target] > cutOff**2: # if distance larger than cutOff
            if not ignoreOutliers: # if outliers are not ignored
                return i_ref, i_target
            else: # if we don't ignore outliers
                return None
        else: # distance below cutoff
            return i_ref, i_target


def rmsd_HA(ref, mol):
    '''RMSD algorithm where the matching between reference and target atoms is done
    by the Hungarian Algorithm. More efficient than the Minimal distance algorithm,
    and the solution includes all the atoms of the molecules.'''

    # Explanation of the problem :
    # We have 2 versions, A (reference) and B (target), of the same molecule, and N atoms in each molecule.
    # The pairwise atomic distance rij between atom i of target molecule B, and atom j of reference molecule A, can be used as
    # a performance rating of the assignment of atom Bj to atom Ai.
    # We need to find the optimal assignment of N atoms in target molecule B to N atoms in reference molecule A.
    # An algorithm to obtain this optimal assignment has been given by H. Kuhn to solve this problem.
    # We will use a variant of this algorithm, presented by J. Munkres, the "Hungarian algorithm":
    # "Munkres J. Algorithms for the Assignment and Transportation Problems. J. Soc. Indust. Appl. Math. 1957, 5, 32–38"
    # Since we don't want to match atom of different type, we will start by dividing the initial matrix of all atom-types pairwise distances into several atom-type dependant matrices.
    # The problem will then be solved as mentionned in the paper above, using a function present in the scipy library, originally written by Brian M. Clapper.

    ## Create matrices according to atom-type
    # Each matrix element corresponds to the sum of the squared differences between atomic coordinates.
    # The pairwise atomic distance can be obtain by taking the squared root of this matrix element. Such value is not needed here.

    nb_atoms = len(ref)
    M        = {}

    for ref_atom in ref:
        # Create an atom-type submatrix
        atom_type = ref_atom['prm']['type']
        rss_list = []
        if atom_type not in M:
            M[atom_type] = []
        # fill each atom_type with a matrix of RSS between atoms of reference and
        # molecule of the same type
        for mol_atom in mol:
             if ref_atom['prm']['type'] == mol_atom['prm']['type']:
                 # residual sum of squares, or distance^2
                 rss = sum([(ref_atom['crd'][i] - mol_atom['crd'][i])**2 for i in range(3)])
                 rss_list.append(rss)
        M[atom_type].append(rss_list)

    # Create a dictionnary of atom types for the solutions.
    # Each atom type will be a matrix containing the row and columns of optimal RSS
    sol = {}
    for atom_type in M:
        sol[atom_type] = linear_sum_assignment(M[atom_type])

    # Make the rows and columns in the solution matrix correspond to the
    # initial cost-matrix M, extract the corresponding sq_sum, and compute the sum of each sq_sum (sum_d2).
    rss_list = []
    for atom_type in M:
        for i in range(len(M[atom_type])):
            row = sol[atom_type][0][i]
            col = sol[atom_type][1][i]
            rss = M[atom_type][row][col]
            rss_list.append(rss)

    # Compute the RMSD
    nb_atoms_used = len(rss_list)
    if nb_atoms_used == 0:
        rmsd = np.nan
    else:
        rmsd = np.sqrt(1/nb_atoms_used * sum(rss_list))

    # return RMSD, number of atoms used to compute RMSD, number of atoms in the molecule
    return rmsd, len(rss_list), nb_atoms


def rmsd(reference, molecule, algorithm, cut_off, ignore_outliers):
    '''Interface function to compute the RMSD with the submit function of concurrent.futures.
    Returns ref_name, mol_name, rmsd, atoms_used, atoms_read.'''
    ref_name        = reference[0]
    ref             = reference[1]
    mol_name        = molecule[0]
    mol             = molecule[1]

    if algorithm == 'std':
        rmsd, atoms_used, atoms_read = rmsd_standard(ref, mol, cutOff=cut_off, ignoreOutliers=ignore_outliers)

    elif algorithm == 'ha':
        rmsd, atoms_used, atoms_read = rmsd_HA(ref, mol)

    elif algorithm == 'mda':
        rmsd, atoms_used, atoms_read = rmsd_MDA(ref, mol, cutOff=cut_off, ignoreOutliers=ignore_outliers)

    return ref_name, mol_name, rmsd, atoms_used, atoms_read


def output_rmsd(outputfile, rmsd_list, overwrite):
    '''Outputs the RMSD to a file. Can append or overwrite.
    rmsd_list: list where each element is a list containing the reference name,
     input_name, and RMSD'''
    header  = "Reference,Input,RMSD" #,Number of atoms read,Number of atoms in molecule"

    # if file doesn't exists
    if not os.path.exists(outputfile):
        with open(outputfile, 'w') as f:
            f.write(header)
            for line in rmsd_list:
                myString = '\n{},{},{:.3f}'.format(line[0],line[1],line[2])
                f.write(myString)
    else:
        if overwrite:
            with open(outputfile, 'w') as f:
                f.write(header)
                for line in rmsd_list:
                    myString = '\n{},{},{:.3f}'.format(line[0],line[1],line[2])
                    f.write(myString)
        else:
            with open(outputfile, 'a') as f:
                for line in rmsd_list:
                    myString = '\n{},{},{:.3f}'.format(line[0],line[1],line[2])
                    f.write(myString)

def rmsd_plot(rmsd_list, save):
    '''Barplot of the RMSD, colored by reference and sorted by RMSD to the first given reference'''
    fig, ax = plt.subplots(figsize=(10,8))

    ref_list      = []
    g             = {}
    subset        = {}
    sorted_subset = {}

    # Initialize lists and dictionnaries
    for line in rmsd_list:
        ref = line[0]
        if ref not in ref_list:
            ref_list.append(ref)
            g[ref]             = []
            subset[ref]        = []
            sorted_subset[ref] = None
        subset[ref].append(line)

    # sort by rmsd values for the first reference given by the user
    sorted_list = list(zip(*sorted(zip(*[subset[ref] for ref in subset]), key=lambda x: x[0][2])))
    # *[subset[ref] for ref in subset] unpacks the dictionnary as tuples
    # zip links each Nth element of each tuple together
    # sorted(..., key=lambda x: x[0][2]) performs the sorting according to the RMSD on the first reference
    # *sorted unpacks the results as tuples
    # zip(*sorted) links each Nth elements of the tuples together
    # list(zip) makes the zip object iterable
    for tup,ref in zip(sorted_list, ref_list):
        # create a dictionnary with the sorted values
        sorted_subset[ref] = tup

    # create variables for the bar plot
    labels = [line[1] for line in sorted_subset[ref_list[0]]]
    index = np.arange(len(labels))
    number_of_plots = len(ref_list)
    color=iter(plt.cm.rainbow(np.linspace(0,1,number_of_plots)))
    bar_width = 0.9/number_of_plots
    opacity = 0.85

    # Plot
    for i,ref in enumerate(ref_list):
        c=next(color)
        g[ref] = ax.bar(index + i*bar_width, [data[2] for data in sorted_subset[ref]],
                        label=ref, color=c, alpha=opacity,
                        width=bar_width, linewidth=0)

    # Set legend, axis titles, ticks...
    ax.legend(loc='center left', bbox_to_anchor=(1, 0.5),title="Reference(s) :")
    ax.set_ylabel('RMSD')
    ax.set_xlabel('Input molecules')
    plt.xticks(index + i*bar_width/number_of_plots, labels)
    ax.set_xticklabels(labels, rotation=90, rotation_mode="anchor", ha="right", va="center", fontsize='small')
    ax.set_title('RMSD between reference and input molecules')
    plt.grid(axis='y', linestyle='--', linewidth=1)
    ax.set_axisbelow(True)
    if save:
        plt.savefig('rmsd_barplot.png', bbox_inches='tight')
    else:
        plt.tight_layout()
        plt.gcf().subplots_adjust(right=0.9)
        plt.show()

def verbose(results):
    print("RMSD ({}/{} atoms) {} - {} : {:.3f}".format(results[3],results[4],results[0],results[1],results[2]))


if __name__ == '__main__':
    terminal_size = shutil.get_terminal_size()
    terminal_sep = "=" * int(terminal_size[0]*0.8)

    ## Argparse
    parser = argparse.ArgumentParser(description='Computes the RMSD between 2 (or more) molecules inside mol2 files.',
                                     epilog=textwrap.dedent('''\
    Each MOL2 files can contain multiple molecules.\n\
    MANDATORY ARGUMENTS : -r -i'''), formatter_class=argparse.RawTextHelpFormatter)

    group_input = parser.add_argument_group(terminal_sep,'INPUT arguments')

    group_input.add_argument("-r", "--reference", nargs='+', required=True,
                             help="Path to 1 or several reference mol2 file(s).")

    group_input.add_argument("-i", "--input",     nargs='+', required=True,
                             help="Path to 1 or several input mol2 file(s).")

    group_input.add_argument("--cpu", metavar='int', type=int, default=1,
                             help="Specify the number of CPU cores to be used. Default: 1")


    group_args = parser.add_argument_group(terminal_sep,'ALGORITHM arguments')

    group_args.add_argument("--hydrogen", action="store_false", default=True,
                            help="Read hydrogen atoms." )

    group_args.add_argument("-a", "--algorithm", choices=['std', 'ha', 'mda'], default='ha',
                            help=textwrap.dedent('''\
    Use one of these algorithm :
    * ha : Hungarian Algorithm (Default)
    * std : Standard, matches atom names. Compatible with --cutoff and --outliers
    * mda : Minimal Distance Algorithm.   Compatible with --cutoff and --outliers'''))


    group_std_mda = parser.add_argument_group(terminal_sep,'SPECIFIC ARGUMENTS FOR STANDARD AND MINIMAL DISTANCE ALGORITHM')

    group_std_mda.add_argument("--cutoff", action='store', metavar='distance', type=float, default=2.0,
                               help="Atomic distance cut-off. Used to ignore outliers and do MDA optimization. Default : 2.0")

    group_std_mda.add_argument("--outliers", action="store_true", default=False,
                               help="Ignore atoms that cannot find a match while having a pairwise distance below CUTOFF." )


    group_output = parser.add_argument_group(terminal_sep,'OUTPUT arguments')

    group_output.add_argument("-o", "--output", metavar='filename',
                               help="Output a CSV file 'FILENAME' containing RMSD between reference and input molecules.")

    group_output.add_argument("-O", dest='overwrite', action="store_true", default=False,
                               help="Overwrite output file if it exists.")

    group_output.add_argument("-p", "--plot", action="store_true",
                               help="Show an interactive barplot of the RMSD, sorted and colored by reference molecule.")

    group_output.add_argument("--saveplot", action="store_true", default=False,
                               help="Save a barplot of the RMSD, sorted and colored by reference molecule, without showing it.")

    group_output.add_argument("-v", "--verbose", action="store_true",
                               help="Increase output verbosity : 'RMSD (atoms used / atoms read) reference file - input file : RMSD value'")

    group_output.add_argument("-s", "--silent", action="store_true",
                               help="Don't output RMSD results on the terminal.")

    args = parser.parse_args()

    # warning about the cutoff and outliers parameters for Hungarian algorithm
    if (args.cutoff != 2.0 or args.outliers != False) and (args.algorithm == 'ha'):
        if not args.silent:
            print("--cutoff and --outliers are not used by the Hungarian Algorithm. Ignoring these arguments...")

    # uses a pool of threads to execute calls asynchronously
    with futures.ProcessPoolExecutor(max_workers=args.cpu) as executor:
        jobs = []
        rmsd_list = []

        for reference_file in args.reference:
            references = mol2_reader(reference_file, args.hydrogen)
            for reference in references:
                for input_file in args.input:
                    inputs = mol2_reader(input_file, args.hydrogen)
                    for molecule in inputs:
                        arguments = [reference, molecule, args.algorithm, args.cutoff, args.outliers]
                        job = executor.submit(rmsd, *arguments)
                        jobs.append(job)

    # Get results in order of submission
    for job in jobs:
        # If calculation is done
        if job.done():
            results = job.result()
            rmsd_list.append(results)

            # print results
            if args.verbose:
                verbose(results)
            elif args.silent:
                pass
            else:
                print('{:.3f}'.format(results[2]))

    if args.output:
        output_rmsd(args.output, rmsd_list, overwrite=args.overwrite)

    if args.plot or args.saveplot:
        rmsd_plot(rmsd_list, save=args.saveplot)
