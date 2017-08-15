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
# awk '/declare --/ {print $3}' will extract all users variables names and values as well as some other undesired variables
# awk 'f;/^_.*$/{f=1}' will start printing the variables after it reads a variable starting with _
# grep -v "^_" will remove all remaining variables starting with _
# grep -v "_list" will remove every list of variables
# in the end we should only be left with variables defined within the workflow which we could need
declare -p | awk '/declare --/ {print $3}' | awk 'f;/^_.*$/{f=1}' | grep -Fv -e "^_" -e "_list" -e "bs_center"
}