#!/bin/bash
#SBATCH -J MPRAmodel_wrapr
#SBATCH -q batch 
#SBATCH -t 24:00:00
#SBATCH --ntasks=4
#SBATCH --mail-user=firstname.lastname@jax.org
#SBATCH --mail-type=END,FAIL
#SBATCH --mem 30g
#SBATCH -o '%x.%j.out'
#SBATCH -e '%x.%j.err'

config_file=$1
source ${config_file}

now=$(date +"%y%m%d-%H%M%S")
mkdir -p ${mpracount_output_folder}/${now}_${proj}_MPRAmodel
mkdir -p ${mpracount_output_folder}/${now}_${proj}_MPRAmodel/plots
mkdir -p ${mpracount_output_folder}/${now}_${proj}_MPRAmodel/results

out=${mpracount_output_folder}/${now}_${proj}_MPRAmodel

module load singularity

set -u

# Check if configuration file is provided
if [ $# -lt 1 ]; then
  echo "Usage: $(basename $0) config_file" >&2
  exit 11
fi

if [ ! -f "${config_file}" ]; then
  echo "Configuration file not found!" >&2
  exit 12
fi


cp ${gitrepo_dir}/MPRAmodel/setup/analysis_sub.R ${out}

# Collect the configuration parameters
config_params=()
while IFS='=' read -r key value; do
  config_params+=("$key=$value")
done < "${config_file}"

# Run the R script with the configuration parameters

#singularity run ${mpramodel_container} Rscript ${out}/analysis_sub.R "${config_params[@]}"

echo "singularity run ${mpramodel_container} Rscript ${out}/analysis_sub.R "${config_params[@]}""
