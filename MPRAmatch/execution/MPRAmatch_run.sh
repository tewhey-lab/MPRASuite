#!/bin/bash

##Check for singularity
# Function to check if a command exists 
command_exists() { command -v "$1" >/dev/null 2>&1; }

# ---- Diagnostic print ----
printf 'singularity var = [%s]\n' "${singularity-<UNSET>}"

# If user provided a path/command name
if [[ -n "${singularity-}" ]]; then
  # If it's an absolute/relative path, require readable+executable
  if [[ "$singularity" == */* ]]; then
    if [[ ! -r "$singularity" || ! -x "$singularity" ]]; then
      echo "Provided singularity path not readable/executable: $singularity"
      exit 1
    fi
  else
    # If it's just a name, require it to resolve on PATH
    if ! command_exists "$singularity"; then
      echo "Provided singularity command not found on PATH: $singularity"
      exit 1
    fi
  fi

else
  # Discover singularity/Apptainer
  if command_exists singularity; then
    singularity=singularity
  elif command_exists module && module avail -t 2>&1 | grep -qi '^singularity'; then
    echo "Loading singularity module..."
    module load singularity || { echo "Failed to load singularity module"; exit 1; }
    singularity=singularity
  elif [[ -x /usr/local/bin/singularity ]]; then
    singularity=/usr/local/bin/singularity
  elif command_exists apptainer; then
    echo "Singularity not found; using Apptainer."
    singularity=apptainer
  else
    echo "Singularity/Apptainer not found."
    exit 1
  fi
fi

echo "Using: $singularity"

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

source ${gitrepo_dir}/MPRAmatch/execution/MPRAmatch_fileprep.sh ${out} ${proj} ${config_file} ${job_pid} ${singularity} >> ${logfile}
