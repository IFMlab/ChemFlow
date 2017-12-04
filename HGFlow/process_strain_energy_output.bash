#/bin/bash

get_energies(){
a=$(awk 'f{print $2;f=0} /NSTEP/{f=1}' ${system}/min_host.mdout | head -1)
a="($(sed 's/[eE]+\{0,1\}/*10^/g' <<<"$a"))"

b=$(awk 'f{print $2;f=0} /NSTEP/{f=1}' ${system}/min_host.mdout | tail -1)
b="($(sed 's/[eE]+\{0,1\}/*10^/g' <<<"$b"))"

c=$(echo ${a} - ${b} | bc)
echo "${system},"None",${c}"

a=$(awk 'f{print $2;f=0} /NSTEP/{f=1}' ${system}/min_gbsa_host.mdout | head -1)
a="($(sed 's/[eE]+\{0,1\}/*10^/g' <<<"$a"))"

b=$(awk 'f{print $2;f=0} /NSTEP/{f=1}' ${system}/min_gbsa_host.mdout | tail -1)
b="($(sed 's/[eE]+\{0,1\}/*10^/g' <<<"$b"))"

c=$(echo ${a} - ${b} | bc)
echo "${system},"GBSA1",${c}"
}


# List with names of all system folders
system_list=$(ls -d */ | cut -d/ -f1)

echo "Host-Guest,Solvation,Delta"
for system in ${system_list} ; do
#  cd ${workdir}/${system}

  if [ -f ${system}/min_gbsa_host.mdout ] ; then
    get_energies
  fi

done


