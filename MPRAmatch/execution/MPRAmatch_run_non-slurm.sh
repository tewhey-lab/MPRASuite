#!/bin/bash

##Check for singularity
# Function to check if a command exists 
command_exists () {
    type "$1" &> /dev/null ;
}

#check if singularity path is provided by the user

if [ -n "${singularity}" ]; then
  # Check if the file exists and is readable
    if [ ! -r "${singularity}" ]; then
        echo "exiting" 
    fi    
    if [ command_exists "${singularity}" ]; then
        echo "Singularity found in PATH"
        singularity="${singularity}"
    fi    
else
#check if singularity is installed in the PATH
    if command_exists singularity; then
        singularity='singularity'

#check if singularity is loaded as a module
    elif command_exists which module; then
        module_avail=$(module avail singularity 2>&1 | grep -i singularity)
        if [[ "$module_avail" == *"singularity"* ]]; then
            echo "Singularity module found. Loading module."
            singularity="singularity"

    elif [[ -x "/usr/local/bin/singularity" ]]; then
        echo "Singularity found in /usr/local/bin."
        singularity="/usr/local/bin/singularity"
    fi
fi 
fi

#####

config_file=$1
source ${config_file}

now=$(date +"%y%m%d-%H%M%S")
mkdir -p ${results_dir}/${now}_${library_rerun_name} 
out=${results_dir}/${now}_${library_rerun_name}

##Setting up the output folders

mkdir -p ${out}/outputs/MPRAmatch
mkdir -p ${out}/execution/
mkdir -p ${out}/execution/${now}_${proj}_MPRAmatch
mkdir -p ${out}/inputs
mkdir -p ${out}/logs

echo ${out}
echo ${proj}

job_pid=$$
logfile="${out}/logs/${proj}_${job_pid}.out"

# Resources
echo "Resources: " > ${logfile}
echo "Number of CPUs: $(nproc)" >> ${logfile}
echo "Total Memory: $(free -h | awk '/Mem/{print $2}') " >> ${logfile}
echo "Disk Space: $(df -h / | awk 'NR==2{print $4}')" >> ${logfile}
echo "Job PID is ${job_pid}" >> ${logfile}

source ${gitrepo_dir}/MPRAmatch/execution/MPRAmatch_fileprep_non_slurm.sh ${out} ${proj} ${config_file} ${job_pid} ${singularity} >> ${logfile}
