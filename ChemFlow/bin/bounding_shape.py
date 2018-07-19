#!/usr/bin/python

##################################################################### 
#   ChemFlow  -   Computational Chemistry is great again            #
#####################################################################
# Author: cbouy - Cédric Bouysset
#         cbouysset@unice.fr
#         Institut de Chimie de Nice - Université Côte d'Azur - France
# 
# Brief: This script will read a mol2 file and return the center and radius of the smallest shape containing all the atoms
#
# Usage : python bounding_sphere.py file.mol2 --box/--sphere padding
#         --box will return coordinates and sizes for a cuboid binding site
#         --sphere will return coordinates and radius for a spheric binding site
#         padding is a number added to each radius/size of the shape
#         You can also add 'pymol' as the last argument to print the commands to show the shape on PyMol (just copy/paste them in the pymol console)


from __future__ import print_function
from math import sqrt
import sys, re

def help():
	print("Usage: python bounding_shape.py file.mol2 --box/--sphere padding")
	print("--sphere returns 4 values separated by a space: x, y, z coordinates of the center and radius of the sphere")
	print("--box returns 6 values: x, y, z coordinates of the center, and size along the x, y, z dimensions")
	print("padding is a number added to the radius/sizes of the shape to avoid having a too small binding site")

def distance(a,b):
	'''Euclidian distance between 2 points'''
	return sqrt(sum([(xa-xb)**2 for xa,xb in zip(a,b)]))

def distance_along_axis(a,b, axis=0):
	'''Distance between 2 points along an axis'''
	return abs(a[axis]-b[axis])

def get_center(points):
	'''Centroid for finite number of points'''
	return [sum([point[i] for point in points])/len(points) for i in range(len(points[0]))]

def average_bs(XYZ, padding=0.3):
	'''Bounding sphere where the center is the centroid of the molecule, and the
	 radius is incremented until all atoms fit inside the sphere'''
	# Compute the center of the sphere as the average over x, y and z coordinates
	center = get_center(XYZ)

	# Test if the sphere is big enough to contain all points in XYZ
	found = False
	radius = 2
	while not found:
		for i,point in enumerate(XYZ):
			# If the sphere is too small
			if distance(center, point) > radius:
				# go to next radius
				radius += 0.5
				break
			# If atom in sphere
			else:
				# If it's the last atom of the mol2 file, print the radius and quit
				if i == len(XYZ)-1:
					found = True
					break
	radius += padding
	return center, radius

def ritter_bs(XYZ, padding=0.3):
	"""Bounding sphere using Ritter's algorithm"""
	# start by picking a point p1
	i1 = 0
	p1 = XYZ[i1]
	# search furthest point p2 from p1
	dmax = 0
	p2 = p1
	for i2, point in enumerate(XYZ[:i1] + XYZ[i1+1:]):
		d = distance(p1, point)
		if d > dmax:
			dmax = d
			p2 = point
	# search furthest point p3 from p2
	dmax = 0
	p3 = p2
	for i3, point in enumerate(XYZ[:i2] + XYZ[i2+1:]):
		d = distance(p2, point)
		if d > dmax:
			dmax = d
			p3 = point
	bounding_points = [p2,p3]
	# set initial ball with center as midpoint between p2 and p3,
	# and radius as half the distance between p2 and p3
	center = get_center(bounding_points)
	radius = distance(p2, p3)/2

	found = False
	steps = 0
	while not found:
		steps += 1
		# check if all points are in sphere
		for i, point in enumerate(XYZ):
			if distance(center, point) > radius:
				# found a new bounding point
				bounding_points.append(point)
				old_center = center
				center = get_center(bounding_points)
				radius += distance(center, old_center)
				break
			else:
				# if it's the last point, we found the bounding sphere
				if i == len(XYZ)-1:
					found = True
					break
	radius += padding
	return center, radius

def bounding_box(XYZ, padding=0.5):
	# get center
	center = get_center(XYZ)
	# get furthest point for each axis
	size = []
	for axis in range(3):
		dmax = 0
		for point in XYZ:
			d = distance_along_axis(center, point, axis=axis)
			if d > dmax:
				dmax = d
		dmax += padding
		size.append(dmax)
	return center, size

if __name__ == '__main__':
	if len(sys.argv) < 4:
		help()
		sys.exit()
	elif any(h in sys.argv for h in ['-h','--help']):
		help()
		sys.exit()

	inputfile = sys.argv[1]
	choice = sys.argv[2]
	padding = float(sys.argv[3])
	# print commands to show bounding box on pymol, for debugging
	try:
		pymol = True if sys.argv[4] == 'pymol' else False
	except IndexError:
		pymol = False

	# Read file
	with open(inputfile, "r") as f:
		lines = f.readlines()

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

	# compute bounding shape
	if choice == '--box':
		center, size = bounding_box(XYZ, padding)
		print(' '.join(['{:.3f}'.format(x) for x in center + size]))
		if pymol:
			print('pseudoatom a1, pos={}'.format([center[0]+size[0],center[1]+size[1],center[2]+size[2]]))
			print('pseudoatom a2, pos={}'.format([center[0]+size[0],center[1]+size[1],center[2]-size[2]]))
			print('pseudoatom a3, pos={}'.format([center[0]+size[0],center[1]-size[1],center[2]-size[2]]))
			print('pseudoatom a4, pos={}'.format([center[0]+size[0],center[1]-size[1],center[2]+size[2]]))
			print('pseudoatom a5, pos={}'.format([center[0]-size[0],center[1]-size[1],center[2]+size[2]]))
			print('pseudoatom a6, pos={}'.format([center[0]-size[0],center[1]-size[1],center[2]-size[2]]))
			print('pseudoatom a7, pos={}'.format([center[0]-size[0],center[1]+size[1],center[2]-size[2]]))
			print('pseudoatom a8, pos={}'.format([center[0]-size[0],center[1]+size[1],center[2]+size[2]]))
			print('distance d12, a1, a2')
			print('distance d23, a2, a3')
			print('distance d34, a3, a4')
			print('distance d14, a1, a4')
			print('distance d56, a5, a6')
			print('distance d67, a6, a7')
			print('distance d78, a7, a8')
			print('distance d85, a8, a5')
			print('distance d18, a1, a8')
			print('distance d72, a7, a2')
			print('distance d54, a5, a4')
			print('distance d63, a3, a6')
	elif choice == '--sphere':
		center, radius = average_bs(XYZ, padding)
		print(' '.join(['{:.3f}'.format(x) for x in center + [radius]]))
		if pymol:
			print('pseudoatom boundingsphere, pos={}, vdw={}'.format(center, radius))
			print('show spheres, boundingsphere')
			print('set sphere_quality, 4')
			print('set sphere_transparency, 0.6')
	else:
		help()