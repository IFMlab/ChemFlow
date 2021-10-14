from rdkit import Chem
PDB_LIST='1bju 1bjv 1c5p 1c5q 1c5s 1c5t 1ce5 1eb2 1f0u 1g36 1ghz 1gi1 1gj6 1k1i 1k1j 1k1l 1k1m 1k1n 1o2o 1o2q 1o2s 1o2w 1o2x 1o2z 1o30 1o33 1o36 1o3d 1o3i 1o3j 1o3k 1oyq 1ppc 1pph 1qb1 1qbn 1qbo 1tng 1tnh 1tni 1utn 1uto 1v2j 1v2k 1v2l 1v2n 1v2o 1v2q 1v2r 1v2s 1v2t 1v2u 1v2w 2bza 2fx6 2j9n'.split()

for PDB in PDB_LIST :
  sdf=f'{PDB}/{PDB}.sdf'
  mol = Chem.MolFromMolFile(sdf)
  print(f'{PDB} {Chem.GetFormalCharge(mol)}')


quit()

