#!/usr/bin/python

from __future__ import print_function
from math import sqrt
import sys, re

# Usage : python bounding_sphere.py file.mol2
# This script will read a mol2 file and return the center and radius of the smallest sphere containing all the atoms

def distance(a,b):
	'''Euclidian distance between 2 points'''
	return sqrt(sum([(xa-xb)**2 for xa,xb in zip(a,b)]))

def get_center(points):
	'''Centroid for finite number of points'''
	return [sum([point[i] for point in points])/len(points) for i in range(len(points[0]))]

def average_bs(XYZ):
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
	print(' '.join(['{:.4f}'.format(x) for x in center+[radius]]))

def ritter_bs(XYZ):
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
	print(' '.join(['{:.4f}'.format(x) for x in center+[radius]]))

if __name__ == '__main__':
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

	# get bounding sphere
	average_bs(XYZ)
