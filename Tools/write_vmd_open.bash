#!/bin/bash
#
# Copyright (c) 2017 Diego Gomes and Marco Cecchini
# 
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#  
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#  
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#

#
# How to use:
# Step 1 - Change the "sim_list" variable
# Step 2 - Must run this at "summary" folder, with MDReport's standard filenames.
# Step 3 - To open type: vmd -e vmd-open.tcl
# Step 4 - Enjoy.
#
# Configuration -----------------------------------------------------
#

sim_list="FP2_ZINC46238409_MD FP2_ZINC72290626_MD FP2_ZINC72290660_MD FP2_ZINC91441456_MD"


# 
open_molecules() {
echo "
mol addrep ${i}
mol new {${sim}.prmtop} type {parm7} first 0 last -1 step 1 waitfor 1
animate style Loop
display resetview
mol addfile {${sim}.nc} type {netcdf} first 0 last -1 step 1 waitfor -1 ${i}
animate style Loop
" >> vmd-open.tcl
}

set_representation(){
echo "
mol modselect 0 ${i} protein
mol modstyle 0 ${i} NewCartoon 0.300000 10.000000 4.100000 0
mol modcolor 0 ${i} Structure
mol color Structure
mol representation NewCartoon 0.300000 10.000000 4.100000 0
#mol selection protein
#mol material Opaque

mol addrep ${i}
mol modselect 1 ${i} not protein
mol modstyle 1 ${i} Licorice 0.300000 12.000000 12.000000
mol modcolor 1 ${i} Name

# Trajectory smooth
mol smoothrep ${i} 0 5
mol smoothrep ${i} 1 5
" >> vmd-open.tcl
}

if [ -f vmd-open.tcl ] ; then rm -rf vmd-open.tcl ; fi
i=0
for sim in ${sim_list} ; do

 open_molecules
 set_representation
 let i=$i+1
done

