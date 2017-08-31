list_include_item() {
# Equivalent to python : if item in list
  local list="$1"
  local item="$2"
  if [[ $list =~ (^|[[:space:]])"$item"($|[[:space:]]) ]] ; then
    # yes, list include item
    result=0
  else
    result=1
  fi
  return $result
}


print_vars() {
# Print all variables defined from the console
# declare -p will print all system variables
# awk '/declare --/ ' will extract all users variables names and values as well as some other undesired variables
# { print substr($0, index($0,$3)) } : print from field #3 to the last
# awk 'f;/^_.*$/{f=1}' will start printing the variables after it reads a variable starting with _
# sed -n '/^_\|_list/!p' : remove every variable that matches the 3 regular expressions : ^_ or _list or bs_center
# in the end we should only be left with variables defined within the workflow which we could need
declare -p | awk '/declare --/ { print substr($0, index($0,$3)) }' | awk 'f;/^_.*$/{f=1}'  | sed -n '/^_\|_list/!p'
}

extract_mol_from_mol2() {
# Extracts a molecule from a mol2 file as a single mol2 file
# Usage : extract_mol_from_mol2 molecule mol2_file
molecule="$1"
mol2_file="$2"

awk -v mol="^${molecule}$" '$0 ~ mol {f=1;print "@<TRIPOS>MOLECULE"};/@<TRIPOS>MOLECULE/{f=0}f{print $0}' ${mol2_file} \
| awk 'BEGIN {count=0} /@<TRIPOS>MOLECULE/{f=1; count+=1}; {if (count <= 1) {print $0}}'
}