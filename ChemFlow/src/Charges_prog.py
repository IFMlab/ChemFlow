#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import argparse
import string
import os
import sys
import subprocess
import fileinput
import time
import operator as operator
from functools import reduce 
import Charges as Charges

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Process some integers.')
    parser.add_argument("-i", action="store", type=str, dest='listeLIG', required=True, help="file containing the name of the ligand in txt")
    parser.add_argument("-o", action="store", type=str, dest='OUT', required=True, help="output name")
    parser.add_argument("-f", action="store", type=str, dest='FORMAT', required=True, help="file_format")
    args = parser.parse_args()
    file_lig = args.listeLIG
    file_out = args.OUT
    format_file = args.FORMAT
    ###################################3\
    if format_file == 'mol2' :
        Charges.found_charges_mol2(file_out, file_lig)
    if format_file == 'sdf' :
        Charges.charges_sdf(file_out, file_lig)
