#!/bin/bash
#SBATCH --job-name=MPRAmatch_run_"${proj}"
#SBATCH -N 1
#SBATCH -n 70
#SBATCH --time=72:00:00
#SBATCH --mem 350G
#SBATCH --mail-user=harshpreet.chandok@jax.org	
#SBATCH --output=MPRAmatch-%x.%j.out
#SBATCH --error=MPRAmatch-%x.%j.err	
#SBATCH --mail-type=BEGIN,END,FAIL

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


slurm_logfile="${out}/logs/${SLURM_ARRAY_TASK_ID}.out"

echo "Writing to ${slurm_logfile}"
scontrol show -dd job $SLURM_JOB_ID
printenv


echo ${out}
echo ${proj}

source ${gitrepo_dir}/MPRAmatch/execution/MPRAmatch_fileprep_slurm.sh ${out} ${proj} ${config_file} ${SLURM_ARRAY_TASK_ID} > ${slurm_logfile}
