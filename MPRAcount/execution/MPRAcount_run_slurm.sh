#!/bin/bash
#SBATCH --job-name=MPRAcount_run_"${proj}"
#SBATCH -N 1
#SBATCH -n 16
#SBATCH --time=72:00:00
#SBATCH --mem 600G
<<<<<<< HEAD
#SBATCH --mail-user=firstname.lastname@jax.org	
=======
#SBATCH --mail-user=harshpreet.chandok@jax.org	
>>>>>>> origin/main
#SBATCH --output=MPRAcount-%x.%j.out
#SBATCH --error=MPRAcount-%x.%j.err	
#SBATCH --mail-type=BEGIN,END,FAIL

config_file=$1
source ${config_file}

now=$(date +"%y%m%d-%H%M%S")
out=${now}_${library_rerun_name}

##Setting up the output folders

scontrol show -dd job $SLURM_JOB_ID
printenv
seff $SLURM_JOB_ID

source ${gitrepo_dir}/MPRAcount/execution/MPRAcount_fileprep_slurm.sh  ${out} ${proj} ${config_file} ${library_rerun_name}
