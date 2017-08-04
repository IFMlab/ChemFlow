#!/usr/bin/python

from __future__ import print_function
from math import sqrt
import sys, re

# Usage : python bounding_sphere.py file.mol2
# This script will read a mol2 file and return the center and radius of the smallest sphere containing all the atoms

if len(sys.argv) != 2:
	print("Illegal number of arguments")
	sys.exit()

# Read file
this_file = open(sys.argv[1], "r")
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

# Append data in list
XYZ = []
for line in range(first_line, first_line + num_atoms):
    data = lines[line].split()
    XYZ.append([ float(data[i]) for i in [2,3,4] ])

# Compute the center of the sphere as the average over x, y and z coordinates
x,y,z = [0,0,0]
for point in XYZ:
	x += point[0]
	y += point[1]
	z += point[2]
center = [x/num_atoms,y/num_atoms,z/num_atoms]

# Test if the sphere is big enough to contain all points in XYZ
for radius in range(2,100,1):
	for i,point in enumerate(XYZ):
		# Distance between center and atom
		d = sqrt((center[0] - point[0])**2 + (center[1] - point[1])**2 + (center[2] - point[2])**2)
		# If the sphere is too small
		if d >= radius:
			# Stop computing distances and go to next radius
			break
		# If atom in sphere
		else:
			# If it's the last atom of the mol2 file, print the radius and quit
			if i == len(XYZ)-1:
				print(' '.join('{:.4f}'.format(v) for v in center),radius,sep=";")
				sys.exit()