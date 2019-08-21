# Chemflow installation.

cat << 'EOF'
# Please modify the following paths and add them to your .bashrc

# ChemFlow
export CHEMFLOW_HOME=~/software/ChemFlow/ChemFlow/
export PATH=${PATH}:${CHEMFLOW_HOME}/bin/

# MGLTools
export PATH="${PATH}:~/software/mgltools_x86_64Linux2_1.5.6/bin/"
export PATH="${PATH}:~/software/mgltools_x86_64Linux2_1.5.6/MGLToolsPckgs/AutoDockTools/Utilities24/"

# Autodock Vina
export PATH="${PATH}:~/software/autodock_vina_1_1_2_linux_x86/bin/"

# PLANTS
export PATH="${PATH}:~/software/PLANTS/"

# Optional (paid software)

# Amber18 (Ambertools19 and Amber18)
source ~/software/amber18/amber.sh

# Gaussian 09
export g09root=~/software/
export GAUSS_SCRDIR=/tmp
source $g09root/g09/bsd/g09.profile


EOF
