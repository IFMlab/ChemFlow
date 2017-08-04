# Interface for mazinger
check_mazinger_status() {
echo "ChemFlow's jobs status on mazinger :                                   "
empty=false
# Jobs from the rescoring
CFjobs=$(cat ${run_folder}/output/${scoring_function}_rescoring/jobs_list_${datetime}.mazinger)

while ! $empty
do
  # Current jobs of the user (all of them)
  current=$(qstat | tail -n +3)
  names=($(echo "$current" | cut -d" " -f1))
  states=($(echo "$current" | awk '{print $5}'))
  countQ=0
  countR=0
  countF=0

  # Intersection between user's current jobs and rescoring jobs = current rescoring jobs still running
  intersection=$(comm -12 <(echo "${CFjobs}") <(echo "${names}"))

  # If no rescoring jobs are still running, quit
  if [ -z "${intersection}" ]
  then
    empty=true
    echo ""

  else
    for job in $CFjobs; do
      for ((i=0;i<=${#names[@]};i++)); do
        if [ "${names[i]}" = "$job" ]; then
          if   [ "${states[i]}" = "Q" ]; then let countQ+=1
          elif [ "${states[i]}" = "R" ]; then let countR+=1
          fi
          break
        else
          if [ $i -eq ${#names[@]} ]; then
            let countF+=1
          fi
        fi
      done
    done
    printf "${PURPLE}In Queue : %3b${NC} - ${RED}Running : %3b${NC} - ${GREEN}Finished : %3b${NC}\r" "${countQ}" "${countR}" "${countF}"
    sleep 1
  fi
done
echo "All jobs finished                                                                            "
rm -f ${run_folder}/output/${scoring_function}_rescoring/jobs_list_${datetime}.mazinger
}

mazinger_progress_bar() {
echo "ChemFlow's progress on mazinger :                                   "
empty=false
# Jobs from the rescoring
CFjobs=$(cat ${run_folder}/output/${scoring_function}_rescoring/jobs_list_${datetime}.mazinger)

# Run the progress bar
(ProgressBar $count $length) &

# Check jobs status
while ! $empty
do
  # Current jobs of the user (all of them)
  current=$(qstat | tail -n +3)
  names=($(echo "$current" | cut -d" " -f1))
  states=($(echo "$current" | awk '{print $5}'))
  count=0

  # Intersection between user's current jobs and rescoring jobs = current rescoring jobs still running
  intersection=$(comm -12 <(echo "${CFjobs}") <(echo "${names}"))

  # If no rescoring jobs are still running, quit
  if [ -z "${intersection}" ]
  then
    empty=true
    echo ""

  else
    for job in $CFjobs; do
      for ((i=0;i<=${#names[@]};i++)); do
        if [ "${names[i]}" = "$job" ]; then
          break
        else
          if [ $i -eq ${#names[@]} ]; then
            let count+=1
          fi
        fi
      done
    done
    sleep 1
  fi
done

{ kill $! && wait $!; } 2>/dev/null
echo "All jobs finished                                                                            "
rm -f ${run_folder}/output/${scoring_function}_rescoring/jobs_list_${datetime}.mazinger
}