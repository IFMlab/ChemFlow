#!/usr/bin/python3
# coding: utf8

## @package rmsd
# @author Cedric Bouysset <bouysset.cedric@gmail.com>
# @author Diego Enry Barreto Gomes <dgomes@pq.cnpq.br>
# @brief Computes RMSD between two mol2 files, advanced use considers outliers in RMSD.
# @details So far it only computes RMSD between two mol2 files, and you know how mol2 files are 
# totally not regular.
# The advanced mode optimizes the RMSD by finding atoms pairs with high RMSD.

import re
import argparse, textwrap
import os.path
import shutil
import numpy as np
import matplotlib.pyplot as plt
from scipy.optimize import linear_sum_assignment

## Documentation for the mol2_reader function
# Reads the content of a mol2 file and adapts it for the rmsd function 
# @param : file path and name, passed as a string
# @return : list of atom informations (name and type), and coordinates (x,y and z) 
def mol2_reader(file):
    # Read file
    this_file = open(file, "r")
    lines = this_file.readlines()
    this_file.close()

    # Search for the line where the number of atoms is, and the first line where atom coordinates are readable
    for i, line in enumerate(lines):
        search_molecule = re.search(r'@<TRIPOS>MOLECULE', line)
        search_atom = re.search(r'@<TRIPOS>ATOM', line)
        if search_molecule:
            # line with the number of atoms
            num_atoms_line = i+2 
        elif search_atom:
            # first line with atom coordinates
            first_line = i+1

    # Read number of atoms directly from the corresponding line
    data = lines[num_atoms_line].split()
    num_atoms = int(data[0])
    
    POS = [] # List containing atomic coordinates
    ATOM = [] # List containing atom name and type
    
    # Fill the table containing the atoms coordinates--------------------------------------------
    for line in range(first_line, first_line + num_atoms):
        data = lines[line].split()
        ATOM.append([data[1],data[5]])
        POS.append([float(data[2]),float(data[3]),float(data[4])])
    
    return ATOM,POS


def pdb_reader(file, molType):
    # Read file
    this_file = open(file, "r")
    lines = this_file.readlines()
    this_file.close()
    
    POS = [] # List containing atomic coordinates
    ATOM = [] # List containing atom name and type
    
    # molType is used to define what to read in the pdb : ATOM, HETATM, or both.
    # Typical PDB line we want to read is as follow, and the corresponding regular expression in python is shown in the next line (number of spaces not respected)
    # "ATOM      1       N      PRO      A            1       -12.735               38.918                31.287             1.00               39.83              N"
    # '^ATOM \s+ \d+ \s+ .+ \s+ .{3} \s+ [A-Z]{1} \s+ \d+ \s+ \-?\d{1,}\.\d{1,} \s+ \-?\d{1,}\.\d{1,} \s+ \-?\d{1,}\.\d{1,} \s+ \d{1,}\.\d{1,} \s+ \d{1,}\.\d{1,} \s+ .+'

    # Search for the regex, and append the values to table
    for i, line in enumerate(lines):
        search_ATOM =     re.search(r'^ATOM\s+\d+\s+.+\s+.{3}\s+[A-Z]{1}\s+\d+\s+\-?\d{1,}\.\d{1,}\s+\-?\d{1,}\.\d{1,}\s+\-?\d{1,}\.\d{1,}\s+\d{1,}\.\d{1,}\s+\d{1,}\.\d{1,}\s+.+', line)
        search_HETATM = re.search(r'^HETATM\s+\d+\s+.+\s+.{3}\s+[A-Z]{1}\s+\d+\s+\-?\d{1,}\.\d{1,}\s+\-?\d{1,}\.\d{1,}\s+\-?\d{1,}\.\d{1,}\s+\d{1,}\.\d{1,}\s+\d{1,}\.\d{1,}\s+.+', line)
        if ((search_ATOM) and (molType == "ATOM")) or ((search_HETATM) and (molType == "HETATM")):
            data = lines[line].split()  
            # Fill the table containing the atoms coordinates
            ATOM.append([data[2],data[11]]) # atom name and type
            POS.append([float(data[6]),float(data[7]),float(data[8])]) # coordinates

    return ATOM,POS


## Documentation for the stamdard RMSD function.
# @param atompos1 : list of atom information and position returned by the mol2_reader function for the reference file 
# @param atompos2 : list of atom information and position returned by the mol2_reader function for the target file 
# @param ignoreH : Boolean, ignore hydrogen atoms
def rmsd_standard(atompos1, atompos2, ignoreH, cutOff, ignoreOutliers):
    # atompos1 = reference, atompos2 = target
    # atompos[0] = list of atom name and atom type
    # atompos[1] = list of coordinates

    # Compute the sum of squared differences between atomic coordinates
    nb_atoms = len(atompos1[0])
    nb_skipped_H = 0
    delta_squared_sum = []
    
    for line1 in range(nb_atoms):
        if ignoreH == True:
            if atompos1[0][line1][0][0] == "H":
                nb_skipped_H += 1
                continue

        for line2 in range(nb_atoms):
            if atompos1[0][line1][0] == atompos2[0][line2][0]: # if same atom names
                delta_x = atompos1[1][line1][0] - atompos2[1][line2][0]
                delta_y = atompos1[1][line1][1] - atompos2[1][line2][1]
                delta_z = atompos1[1][line1][2] - atompos2[1][line2][2]
                sq_sum = delta_x**2 + delta_y**2 + delta_z**2
                if sq_sum > cutOff**2:  # if the distance is superior to the cut-off
                    if not ignoreOutliers:  # append to the list only if we do not ignore outliers
                        delta_squared_sum.append(sq_sum)
                else:
                    delta_squared_sum.append(sq_sum)
                break
    
    # Compute the sum of sq_sum for all atoms
    sum_d2 = 0
    nb_atoms_read = len(delta_squared_sum)

    for line in range(nb_atoms_read):
        sum_d2 += delta_squared_sum[line]

    # Compute the RMSD
    if nb_atoms_read == 0:
        rmsd = np.nan
    else:
        rmsd = np.sqrt(1/nb_atoms_read * sum_d2)
    
    return rmsd, nb_atoms_read, nb_atoms



## Documentation for the RMSD function based on the custom Minimal Distance Algorithm.
# @param atompos1 : list of atom information and position returned by the mol2_reader function for the reference file 
# @param atompos2 : list of atom information and position returned by the mol2_reader function for the target file 
# @param ignoreH : Boolean, ignore hydrogen atoms
# @param cutOff : Atomic distance cut-off. Used to ignore outliers and/or optimize results.
# @param ignoreOutliers : if an atom in the input molecule cannot be paired with a reference atom with a distance below cutOff, ignore it.
def rmsd_MDA(atompos1, atompos2, cutOff, ignoreOutliers, ignoreH ):
    # atompos1 = reference, atompos2 = target
    # atompos[0] = list of atom name and atom type
    # atompos[1] = list of coordinates

    # Compute the difference between each coordinates------------------------------------------------
    delta_squared_sum = []
    atoms_read = []
    nb_atoms = len(atompos1[0])
    nb_skipped_H = 0
    
    
    for line1 in range(nb_atoms):
        if ignoreH == True:
            if atompos1[0][line1][0][0] == "H":
                # ignore hydrogen atoms
                nb_skipped_H += 1
                # go back to the for loop, don't search for corresponding atom in the target file
                continue

        for line2 in range(nb_atoms):
            # Search for similar atom name
            if atompos1[0][line1][0] == atompos2[0][line2][0]:
                # if both atoms have the same name
                delta_x = atompos1[1][line1][0] - atompos2[1][line2][0]
                delta_y = atompos1[1][line1][1] - atompos2[1][line2][1]
                delta_z = atompos1[1][line1][2] - atompos2[1][line2][2]
                
                sq_sum = delta_x**2 + delta_y**2 + delta_z**2
                
                if sq_sum > cutOff**2:
                    # Can we find an atom of the same type below the cut-off distance ?
                    # if the target atom is over the cut-off distance.
                    found = False
                    min_distance = cutOff
                    for line3 in range(nb_atoms):
                        # Search for similar atom type in target file
                        if atompos1[0][line1][1] == atompos2[0][line3][1] and atompos2[0][line3][0] not in atoms_read:
                            # if both atoms are of the same type
                            delta_x = atompos1[1][line1][0] - atompos2[1][line3][0]
                            delta_y = atompos1[1][line1][1] - atompos2[1][line3][1]
                            delta_z = atompos1[1][line1][2] - atompos2[1][line3][2]
                            sq_sum_temp = delta_x**2 + delta_y**2 + delta_z**2
                            if sq_sum_temp <= min_distance**2:
                                # if this atom seems like a good candidate
                                # maybe it would still be more interesting to keep this atom 
                                # for its equivalent in the reference file.
                                # thus : compute this other distance and keep the one giving the best result
                                for line4 in range(nb_atoms):
                                    if atompos2[0][line3][0] == atompos1[0][line4][0]:
                                        delta_x = atompos1[1][line4][0] - atompos2[1][line3][0]
                                        delta_y = atompos1[1][line4][1] - atompos2[1][line3][1]
                                        delta_z = atompos1[1][line4][2] - atompos2[1][line3][2]
                                        sq_sum_temp2 = delta_x**2 + delta_y**2 + delta_z**2
                                        if sq_sum_temp2 >= sq_sum_temp:
                                            # distance between atoms of the same type but not the same name is better
                                            min_distance = sq_sum_temp
                                            best_sq_sum = sq_sum_temp
                                            best_atom = atompos2[0][line3][0]
                                        else:
                                            min_distance = sq_sum_temp2
                                            best_sq_sum = sq_sum_temp2
                                            best_atom = atompos1[0][line4][0]
                                        found = True
                                        break
                                        # out of the 4th for loop
                                        
                    if found == True:
                        # Once we've looped through all atoms of the same type, add the one giving the best distance
                        delta_squared_sum.append(best_sq_sum)
                        atoms_read.append(best_atom)

                    else:
                        # if the distance was over cutOff and no better atom was found
                        if (not ignoreOutliers) and atompos2[0][line2][0] not in atoms_read:
                            delta_squared_sum.append(sq_sum)
                            atoms_read.append(atompos2[0][line2][0])
                                            
                elif sq_sum <= cutOff**2 and atompos2[0][line2][0] not in atoms_read:
                    # if the distance is below cutOff and this atom haven't already been used
                    delta_squared_sum.append(sq_sum)
                    atoms_read.append(atompos2[0][line2][0])
                     
                break
                # Once a distance has been added between an atom from the reference and the target atom,
                # break out of the second for loop, and continue with the next reference atom
                # in other terms, don't continue searching for a target atom with the same name
                
    # Compute the sum of squared deltas sum----------------------------------------------------------
    sum_d2 = 0
    nb_atoms_read = len(delta_squared_sum)
    
    for line in range(nb_atoms_read):
        sum_d2 += delta_squared_sum[line]

    # Compute the RMSD-------------------------------------------------------------------------------
    if nb_atoms_read == 0:
        rmsd = np.nan
    else:
        rmsd = np.sqrt(1/nb_atoms_read * sum_d2)
    
    return rmsd, nb_atoms_read, nb_atoms



## Documentation for the RMSD function based on the Hungarian Algorithm.
# @param atompos1 : list of atom information and position returned by the mol2_reader function for the reference file 
# @param atompos2 : list of atom information and position returned by the mol2_reader function for the target file 
# @param ignoreH : Boolean, ignore hydrogen atoms
def rmsd_HA(atompos1, atompos2, ignoreH):
    # atompos1 = reference, atompos2 = target
    # atompos[0] = list of atom name and atom type
    # atompos[1] = list of coordinates
    
    '''
    Explanation of the problem :
    We have 2 versions, A (reference) and B (target), of the same molecule, and N atoms in each molecule.
    The pairwise atomic distance rij between atom i of target molecule B, and atom j of reference molecule A, can be used as 
    a performance rating of the assignment of atom Bj to atom Ai.
    We need to find the optimal assignment of N atoms in target molecule B to N atoms in reference molecule A.
    An algorithm to obtain this optimal assignment has been given by H. Kuhn to solve this problem. 
    We will use a variant of this algorithm, presented by J. Munkres, the "Hungarian algorithm":
    "Munkres J. Algorithms for the Assignment and Transportation Problems. J. Soc. Indust. Appl. Math. 1957, 5, 32–38"
    Since we don't want to match atom of different type, we will start by dividing the initial matrix of all atom-types pairwise distances into several atom-type dependant matrices.
    The problem will then be solved as mentionned in the paper above, using a function present in the scipy library, originally written by Brian M. Clapper.
    '''
    
    ## Create matrices according to atom-type
    # Each matrix element corresponds to the sum of the squared differences between atomic coordinates.
    # The pairwise atomic distance can be obtain by taking the squared root of this matrix element. Such value is not needed here.
    
    M = {} # Dictionnary of atom types. Each atom type will be a matrix that will be used by the scipy module to solve the problem. can only contain numbers
    nb_atoms = len(atompos1[0]) # number of atoms in molecule A (should be the same as molecule B)
    nb_skipped_H = 0 # number of hydrogen atotms skipped
    
    # Iterate through reference molecule : A
    for line1 in range(nb_atoms):
        
        # Ignore hydrogen atoms
        if ignoreH == True:
            if atompos1[0][line1][0][0] == "H":
                nb_skipped_H += 1
                # go back to the for loop, don't search for corresponding atom in the target file
                continue
        
        # Create an atom-type submatrice if it doesn't already exist
        if atompos1[0][line1][1] not in M:
            M[atompos1[0][line1][1]] = []
        
        # Create a vector that will contain all sum of squared differences between atomic coordinates (sq_sum) of each Bj atom for a given Ai atom
        Ai_vector = []
        # Iterate through target molecule B
        for line2 in range(nb_atoms):   
            # Search for similar atom type and compute the sq_sum
            if atompos1[0][line1][1] == atompos2[0][line2][1]: # if both atoms have the same type
                delta_x = atompos1[1][line1][0] - atompos2[1][line2][0]
                delta_y = atompos1[1][line1][1] - atompos2[1][line2][1]
                delta_z = atompos1[1][line1][2] - atompos2[1][line2][2]
                sq_sum = delta_x**2 + delta_y**2 + delta_z**2
                Ai_vector.append(sq_sum)
        M[atompos1[0][line1][1]].append(Ai_vector)   
        # In the end, each row of a submatrix is an iteration of Ai, and each column is an iteration of Bj
    
    # Create a dictionnary of atom types for the solutions. Each atom type will be a matrix containing the row and columns of optimal sq_sum
    sol = {}
    for at_type in M:
        sol[at_type] = linear_sum_assignment(M[at_type])
    
    # Make the rows and columns in the solution matrix correspond to the initial cost-matrix M, extract the corresponding sq_sum, and compute the sum of each sq_sum (sum_d2).
    sum_d2 = 0
    nb_atoms_read = 0
    for at_type in M:
        for i in range(len(M[at_type])):
            row = sol[at_type][0][i]
            col = sol[at_type][1][i]
            sq_sum = M[at_type][row][col]
            sum_d2 += sq_sum
        nb_atoms_read += len(M[at_type])

    # Compute the RMSD
    if nb_atoms_read == 0:
        rmsd = np.nan
    else:
        rmsd = np.sqrt(1/nb_atoms_read * sum_d2)
    
    return rmsd, nb_atoms_read, nb_atoms


## Documentation for the rmsd function
# Interface to the actual rmsd_HA function
def rmsd(ref_file, target_file, algorithm, cut_off, ignore_outliers, ignore_H):
    if algorithm == 'std':
        return rmsd_standard( mol2_reader(ref_file), mol2_reader(target_file), cutOff=cut_off, ignoreOutliers=ignore_outliers, ignoreH=ignore_H )
    
    elif algorithm == 'ha':
        if cut_off != 2.0 or ignore_outliers != False:
            print("--cutoff and --outliers are not used by the Hungarian Algorithm. Ignoring these arguments...")
        return rmsd_HA( mol2_reader(ref_file), mol2_reader(target_file), ignoreH=ignore_H )
    
    elif algorithm == 'mda':
        return rmsd_MDA( mol2_reader(ref_file), mol2_reader(target_file), cutOff=cut_off, ignoreOutliers=ignore_outliers, ignoreH=ignore_H )


def output_rmsd(outputfile, rmsd_list):
    my_file = outputfile
    header = "Reference,Input,RMSD,Number of atoms read,Number of atoms in molecule"
    
    # if file doesn't exists
    if not os.path.exists(my_file):
        with open(my_file, 'w') as f:
            f.write(header)
            for line in rmsd_list:
                myString = '\n{},{},{:.6f},{},{}'.format(line[0], line[1], line[2], line[3], line[4])
                f.write(myString)
        f.closed
    else:
        with open(my_file, 'a') as f:
            for line in rmsd_list:
                myString = '\n{},{},{:.6f},{},{}'.format(line[0], line[1], line[2], line[3], line[4])
                f.write(myString)
        f.closed
    print("CSV table created :", my_file)
    
    
def rmsd_plot(rmsd_list):
    
    fig, ax = plt.subplots(figsize=(20,10))

    yval = {}
    xlabels = ()
    ref_list = []
    g = {}
    
    for line in rmsd_list:
        if line[0][:-5] not in ref_list:
            ref = line[0][:-5]
            ref_list.append(ref)
            yval[ref] = ()
            g[ref] = []
        yval[ref] += (line[2],)
        if line[1][:-5] not in xlabels:
            xlabels += (line[1][:-5],)
        
    index = np.arange(len(xlabels))
    number_of_plots = len(ref_list)
    color=iter(plt.cm.rainbow(np.linspace(0,1,number_of_plots)))
    
    bar_width = 0.9/number_of_plots
    opacity = 0.85
    for i,ref in enumerate(ref_list):      
        c=next(color)
        g[ref] = ax.bar(index + i*bar_width, yval[ref],
                        label=ref, color=c, alpha=opacity,
                        width=bar_width, linewidth=0)
        
    ax.legend(loc='center left', bbox_to_anchor=(1, 0.5),title="Reference(s) :")
    ax.set_ylabel('RMSD')
    ax.set_xlabel('Input molecules')
    plt.xticks(index + i*bar_width/number_of_plots, xlabels)
    ax.set_xticklabels(xlabels, rotation=90, rotation_mode="anchor", ha="right", va="center", fontsize='small')
    ax.set_title('RMSD between reference and input molecules'.format(ref))
    plt.grid(axis='y', linestyle='--', linewidth=1)
    ax.set_axisbelow(True)
    print('Saved figure rmsd_plot.png')
    plt.savefig('rmsd_plot.png',bbox_inches='tight')
    plt.tight_layout()
    plt.gcf().subplots_adjust(right=0.9)
    plt.show()
    
def verbose(ref,inp,answer):
    print("RMSD ({}/{} atoms) {} - {} : {:.6f}".format(answer[1], answer[2], ref, inp, answer[0]))


if __name__ == '__main__':
    terminal_size = shutil.get_terminal_size()
    terminal_sep = "=" * int(terminal_size[0]*0.8)
    
    ## Argparse
    parser = argparse.ArgumentParser(description='Computes RMSD between 2 (or more) mol2 files, using a user-defined algorithm.', epilog=textwrap.dedent('''\
    MANDATORY ARGUMENTS : -r -i -a'''), formatter_class=argparse.RawTextHelpFormatter)
    
    group_input = parser.add_argument_group(terminal_sep,'INPUT arguments')
    group_input.add_argument("-r", "--reference", nargs='+', required=True, help="Path to 1 or several reference mol2 file(s).")
    group_input.add_argument("-i", "--input", nargs='+', required=True, help="Path to 1 or several input mol2 file(s).")
    
    group_args = parser.add_argument_group(terminal_sep,'ALGORITHM arguments')
    group_args.add_argument("-a", "--algorithm", choices=['std', 'ha', 'mda'], required=True, help=textwrap.dedent('''\
    Use one of these algorithm : 
    * ha : Hungarian Algorithm (Recommended)
    * std : Standard, matches atom names. Compatible with --cutoff and --outliers
    * mda : Minimal Distance Algorithm. Compatible with --cutoff and --outliers'''))
    
    group_args.add_argument("--hydrogen", action="store_false", default=True, help="Read hydrogen atoms." )
    
    group_std_mda = parser.add_argument_group(terminal_sep,'SPECIFIC ARGUMENTS FOR STANDARD AND MINIMAL DISTANCE ALGORITHM')
    group_std_mda.add_argument("--cutoff", action='store', dest='distance', type=float, default=2.0, help="Atomic distance cut-off. Used to ignore outliers and do MDA optimization. Default : 2.0")
    group_std_mda.add_argument("--outliers", action="store_true", default=False, help="Ignore outliers : atoms that cannot find a match while having a pairwise distance below CUTOFF." )
    
    group_output = parser.add_argument_group(terminal_sep,'OUTPUT arguments')
    group_output.add_argument("-o", "--output", dest='filename', help="Output a CSV file 'FILENAME' containing RMSD between reference and input molecules.")
    group_output.add_argument("-p", "--plot", action="store_true", help="Plot RMSD by input molecule, show the plot and save as a PNG image.")
    group_output.add_argument("-v", "--verbose", action="store_true", help="Increase output verbosity : 'RMSD (atoms read / atoms in file) reference file - input file : RMSD value'")
    group_output.add_argument("-s", "--silent", action="store_true", help="Don't output RMSD results on the terminal.")

    args = parser.parse_args()

    rmsd_list = []
    for reference in args.reference:
        for input_file in args.input:
            ref = os.path.basename(reference)[:-5]	# filenames without path and extension
            inp = os.path.basename(input_file)[:-5]
            answer = rmsd( reference, input_file, algorithm=args.algorithm, cut_off=args.distance, ignore_outliers=args.outliers, ignore_H=args.hydrogen)
            rmsd_list.append([ref, inp, answer[0], answer[1], answer[2]])

            if args.verbose:
                verbose(ref,inp,answer)
            elif args.silent:
                pass
            else:
                print(answer[0])

    if args.filename != None:
        output_rmsd(args.filename, rmsd_list)

    if args.plot == True:
        rmsd_plot(rmsd_list)
