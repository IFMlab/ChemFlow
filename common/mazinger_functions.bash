# Interface for mazinger
check_mazinger_status() {
echo "ChemFlow's jobs status on mazinger :                                   "
empty=false
# Jobs from the rescoring
CFjobs=$(cat $1)

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
rm -f $1
}

mazinger_progress_bar() {
echo "ChemFlow's progress on mazinger :                                   "
# Jobs from the rescoring
CFjobs=$(cat $1)
CFlength=$(echo "$CFjobs" | wc -l)

# Check jobs status
while true
do
  # Current jobs of the user (all of them)
  current=$(qstat | tail -n +3)
  current_jobs=($(echo "$current" | cut -d" " -f1))
  current_length=$(expr ${#current_jobs[@]} - 1)
  count=0

  # Intersection between user's current jobs and rescoring jobs = current rescoring jobs still running
  intersection=$(comm -12 <(echo "${CFjobs}") <(echo "${current_jobs}"))

  # If no rescoring jobs are still running, quit
  if [ -z "${intersection}" ]
  then
    break

  else
    # for every rescoring job
    for CFjob in $CFjobs; do
      # for every current jobs of the user
      for ((i=0;i<${#current_jobs[@]};i++)); do
        # if the rescoring job matches a current job
        if [ "${current_jobs[i]}" = "$CFjob" ]; then
          # the rescoring is not finished yet
          # go to the next rescoring job
          break
        else
          # if the rescoring job didn't match with any of the current jobs, 
          # and it was the last current job
          if [ $i -eq ${current_length} ]; then
            # increment the count of rescoring jobs that are finished
            let count+=1
          fi
        fi
      done
    done
  # Update the progress bar
  (ProgressBar $count $CFlength) &
  sleep 1
  { kill $! && wait $!; } 2>/dev/null
  fi

done

echo -e "\rAll jobs finished                                        "
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