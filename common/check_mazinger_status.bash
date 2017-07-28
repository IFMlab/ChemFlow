# Interface for mazinger
check_mazinger_status() {
echo "ChemFlow's jobs status on mazinger :"
empty=false
CFjobs=$(cat ${dir}/output/${scoring_function}_rescoring/jobs_list_${datetime}.mazinger)

while ! $empty
do
  current=$(qstat | tail -n +3)
  names=($(echo "$current" | cut -d" " -f1))
  states=($(echo "$current" | awk '{print $5}'))
  countQ=0
  countR=0
  countF=0

  if [ -z "${current}" ]
  then
    empty=true
    echo ""
  fi

  for job in $CFjobs; do
    for ((i=0;i<=${#names[@]};i++)); do
      if [ "${names[i]}" = "$job" ]; then
        if   [ "${states[i]}" = "Q" ]; then countQ=$(expr $countQ + 1)
        elif [ "${states[i]}" = "R" ]; then countR=$(expr $countR + 1)
        fi
        break
      else
        if [ $i -eq ${#names[@]} ]; then
          countF=$(expr $countF + 1)
        fi
      fi
    done
  done


  printf "${PURPLE}In Queue : %3b${NC} - ${RED}Running : %3b${NC} - ${GREEN}Finished : %3b${NC}\r" "${countQ}" "${countR}" "${countF}"

  sleep 1
done
echo "All jobs finished                                                                            "
}
