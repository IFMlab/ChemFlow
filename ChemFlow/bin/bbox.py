#!/usr/bin/env python3
# coding: utf-8
# Config
def main():
    arguments = get_cmd_line()

    x,y,z = read_mol2(arguments['ligand'])
    cx,cy,cz,sx,sy,sz = enclose_mol2(x,y,z,arguments['padding'])

def read_mol2(ligand) :
    read_coordinates = False
    with open(ligand,'r') as molecule :
        for line in molecule :
            if line.startswith('@<TRIPOS>BOND') :
                break
            if read_coordinates :
                c = line.split()
                x.append(float(c[2]))
                y.append(float(c[3]))
                z.append(float(c[4]))
                continue
            if line.startswith('@<TRIPOS>ATOM') :
                read_coordinates = True
                x = []
                y = []
                z = []
    return x,y,z


def enclose_mol2(x,y,z,padding) :
    '''
    by Diego E.B. Gomes 10/06/2020.


AutoDock Vina: Improving the Speed and Accuracy of
Docking with a New Scoring Function, Efficient
Optimization, and Multithreading
OLEG TROTT, ARTHUR J. OLSON
Department of Molecular Biology, The Scripps Research Institute, La Jolla, California
Received 3 March 2009; Accepted 21 April 2009
DOI 10.1002/jcc.21334
Published online 4 June 2009 in Wiley InterScience (www.interscience.wiley.com).

This is the relevant part of AutoDock Vina's original publication that was considered.

    To select the search spaces for the test, for each complex, we
started with the experimental bound ligand structure and created the
minimal rectangular parallelepiped, aligned with the coordinate sys-
tem, that includes it. Then, its sizes were increased by 10 Å in each
of the three dimensions. Additionally, for each of the three dimen-
sions, one of the two directions was chosen randomly, in which
another 5 Å was added. Finally, if the size of the search space in any
dimension was less than 22.5 Å, it was increased symmetrically to
this value. Thus, the size of the search space in each dimension was
no less than 15 Å larger than the size of the ligand, and no less than
22.5 Å total.
The final step of increasing the size of the search space in all
dimensions to 22.5 Å is for consistency with the earlier tests of
AutoDock on this set, where 22.5 Å sizes were chosen, and because
the developers of AutoDock recommend making sure that the search
space is large enough for the ligand to rotate in. 23
    '''

    '''
    I'm not expanding one or two dimensions randomly.. yet
    '''

    n = len(x)
    cx=sum(x)/n
    cy=sum(y)/n
    cz=sum(z)/n

    # Just enclose the ligand in a box + padding.
    # This is not what AutoDock vina recommends.
    sx = abs( max(x) - min(x)) + padding
    sy = abs( max(y) - min(y)) + padding
    sz = abs( max(z) - min(z)) + padding
    
#    print(f'--center_x {cx:.3f} --center_y {cy:.3f} --center_z {cz:.3f} --size_x {sx:.3f} --size_y {sy:.3f} --size_z {sz:.3f}')

    # Bellow we do box sizes "Vina style".
    # Add 10 A to each direction.
    sx = abs( max(x) - min(x)) + 10
    sy = abs( max(y) - min(y)) + 10
    sz = abs( max(z) - min(z)) + 10
#    print(f'--center_x {cx:.3f} --center_y {cy:.3f} --center_z {cz:.3f} --size_x {sx:.3f} --size_y {sy:.3f} --size_z {sz:.3f}')

    # If any direction is smaller than 22.5, expand it.    
    if sx < 22.5 :
        sx = sx + (22.5 - sx)
    if sy < 22.5 :
            sy = sy + (22.5 - sy)
    if sz < 22.5 :
            sz = sz + (22.5 - sz)

    print(f'--center_x {cx:.3f} --center_y {cy:.3f} --center_z {cz:.3f} --size_x {sx:.3f} --size_y {sy:.3f} --size_z {sz:.3f}')

    return cx,cy,cz,sx,sy,sz

def get_cmd_line() :
    import argparse
    parser = argparse.ArgumentParser(description="Reads a mol2 file and returns the center and size of the smallest shape containing all the atoms of the given molecule.")
    parser.add_argument('ligand',
                        metavar  = None,
                        help     ='.mol2 file')
    
    parser.add_argument('-p','--padding',
                        dest    = 'padding',
                        type    = float,
                        default = 0.0,
                        metavar = 'FLOAT',
                        help    = 'Extra space for the binding box')

    arg_dict = vars(parser.parse_args())
    
    return arg_dict

if __name__=='__main__': main()


