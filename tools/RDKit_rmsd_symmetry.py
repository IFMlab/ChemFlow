#!/usr/bin/python
'''
calculates RMSD differences between all structures in a file

@author: JP <jp@javaclass.co.uk>
'''
import os
import getopt
import sys

# rdkit imports
from rdkit import Chem
from rdkit.Chem import AllChem

'''
Write contents of a string to file
'''
def write_contents(filename, contents):
  # do some basic checking, could use assert strictly speaking
  assert filename is not None, "filename cannot be None"
  assert contents is not None, "contents cannot be None"
  f = open(filename, "w")
  f.write(contents)
  f.close() # close the file

'''
Write a list to a file
'''
def write_list_to_file(filename, list, line_sep = os.linesep):
  # do some basic checking, could use assert strictly speaking
  assert list is not None and len(list) > 0, "list cannot be None or empty"
  write_contents(filename, line_sep.join(list))

'''
Calculate RMSD spread
'''
def calculate_spread(molecules_file):

  assert os.path.isfile(molecules_file), "File %s does not exist!" % molecules

  # get an iterator
  mols = Chem.SDMolSupplier(molecules_file)

  spread_values = []
  # how many molecules do we have in our file
  mol_count = len(mols)
  # we are going to compare each molecule with every other molecule
  # typical n choose k scenario (n choose 2)
  # where number of combinations is given by (n!) / k!(n-k)! ; if my maths isn't too rusty
  for i in range(mol_count - 1):
      for j in range(i+1, mol_count):
          # show something is being done ... because for large mol_count this will take some time
          print("Aligning molecule #%d with molecule #%d (%d molecules in all)" % (i, j, mol_count))
          # calculate RMSD and store in an array
          # unlike AlignMol this takes care of symmetry
          spread_values.append(str(AllChem.GetBestRMS(mols[i], mols[j])))
  # return that array
  return spread_values


def main():
  try:
      # the options are as follows:
      # f - the actual structure file
      opts, args = getopt.getopt(sys.argv[1:], "vf:o:")
  except getopt.GetoptError:
      # print help information and exit:
      print(str(err)) # will print something like "option -a not recognized"
      sys.exit(401)

  # DEFAULTS
  molecules_file  = None
  output_file = None

  for opt, arg in opts:
      if opt == "-v":
          print("RMSD Spread 1.1")
          sys.exit()
      elif opt == "-f":
          molecules_file = arg
      elif opt == "-o":
          output_file = arg
      else:
          assert False, "Unhandled option: " + opt

  # assert the following - not the cleanest way to do this but this will work
  assert molecules_file is not None, "file containing molecules must be specified, add -f to command line arguments"
  assert output_file is not None, "output file must be specified, add -o to command line arguments"
  # get the RMSD spread values
  spread_values = calculate_spread(molecules_file)
  # write them to file
  write_list_to_file(output_file, spread_values)



if __name__ == "__main__":
  main()
