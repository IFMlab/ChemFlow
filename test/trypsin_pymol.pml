
from pymol import cmd
PDB_LIST="2j9n 1uto 2bza 1tng 1v2j 1v2u 1tnh 1utn 1v2r 2fx6 1tni 1v2w 1c5t 1v2q 1v2s 1v2l 1c5p 1v2t 1v2o 1ce5 1ghz 1bju 1o2s 1gi1 1bjv 1o33 1qbn 1o2w 1o2x 1v2n 1pph 1o36 1c5s 1eb2 1o2z 1ppc 1v2k 1o2o 1c5q 1k1i 1o3k 1o30 1o3j 1qb1 1k1n 1k1l 1oyq 1gj6 1o3d 1f0u 1g36 1o3i 1k1m 1k1j 1o2q 1qbo".split()
for PDB in PDB_LIST : cmd.load(f'{PDB}/{PDB}.pdb')

# Align to 1bju (no reason for 1bju)
cmd.alignto('1bju')

