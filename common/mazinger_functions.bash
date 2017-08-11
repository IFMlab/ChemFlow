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
CFjobs=$(cat $1)
count=0
length=$(echo "$CFjobs" | wc -l)

# Check jobs status
while ! $empty
do
  # Current jobs of the user (all of them)
  current=$(qstat | tail -n +3)
  names=($(echo "$current" | cut -d" " -f1))
  states=($(echo "$current" | awk '{print $5}'))

  # Run the progress bar
  (ProgressBar $count $length) &

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
  fi

  sleep 1
  { kill $! && wait $!; } 2>/dev/null

done

echo "All jobs finished                                                                            "
rm -f $1
}

mazinger_submitter() {
# Variables
pbs_count=$1
max_jobs_pbs=$2
progress_count=$3
length=$4
prefix="$5"
pbs_function="$6"

if [ ${pbs_count} -eq 0 ]; then
  identifier="${progress_count}"
  ${pbs_function}_header
  ${pbs_function}
  let pbs_count+=1
elif [ ${pbs_count} -lt ${max_jobs_pbs} ]; then
  ${pbs_function}
  let pbs_count+=1
  if [ ${pbs_count} -eq ${max_jobs_pbs} ] || [ ${progress_count} -eq ${length} ]; then
    pbs_count=0
    jobid=$(qsub ${prefix}_${identifier}.pbs)
    qsubbed="true"
  fi
fi

# return value
if [ "${qsubbed}" = "true" ] ; then
  echo "${pbs_count},${identifier},${jobid}"
else
  echo "${pbs_count},${identifier}"
fi
}