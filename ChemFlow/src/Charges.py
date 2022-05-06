#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import os
import shutil


def charges_sdf(file_out, file_lig):
    filout = open(file_out, 'w')
    filin = open(file_lig, 'r')
    lignes_name = filin.readlines()  
    flag = 10    
    for ligne in lignes_name:
        cpt = 16
        protonation = 0
        name = ligne.split('/')[-1][:-1]
        name_full = ligne[:-1]
        ###########
        fil_lig = open(name_full + '.sdf', 'r')
        ligne_SDF = fil_lig.readlines()
        for lignes_file in ligne_SDF :
            if name in lignes_file :
                name_sdf = name
                flag = 0 
            if lignes_file[0:6] == 'M  CHG' and flag == 0:
                flag = 1
                num_atom_protone = int(lignes_file[8]) # gives the number of charge in the structure
                for k in range(0, (num_atom_protone)):
                    proto = lignes_file[cpt-1:cpt+1]
                    proto = int(proto.replace(" ",""))
                    cpt = cpt + 8
                    protonation = int(protonation) + (proto)
                filout.write(name_sdf + ' ' + str(protonation) + '\n')
            if ligne[0:6] == 'M  END' and flag == 0:
               filout.write(name_sdf + ' ' + str(protonation) + '\n')
    filout.close()
    return()



def found_charges_mol2(file_out, file_lig):
    print('lkjhgfds')
    filout = open(file_out, 'w')
    #MOL2
    fil_mol2 = open(file_lig, 'r')
    ligne_m = fil_mol2.readlines()
    for i in ligne_m :
        name_lig = (i[:-1]) 
        fil_lig = open(name_lig + '.mol2', 'r')
        li_lig = fil_lig.readlines()
        flag = 0
        net_charges = 0.0
        for k in li_lig :
            if '@<TRIPOS>BOND' in k :
                flag = 0
            if flag == 1 :
                #net_charges = net_charges + float((k.split('\t')[-1][:-1]))
                net_charges = net_charges + float((k.split(' ')[-1][:-1]))
            if '@<TRIPOS>ATOM' in k :
                flag = 1
        net_charges = round(net_charges)
        filout.write(name_lig.split('/')[-1] + ' ' + str(int(net_charges)) + '\n')
    filout.close()
    return()
























