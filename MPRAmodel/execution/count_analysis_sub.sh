#!/bin/bash

#SBATCH --job-name=MPRAmodel_OLJR
#SBATCH --ntasks=4
#SBATCH --time=72:00:00
#SBATCH --mem-per-cpu=30G
#SBATCH --mail-user=harshpreet.chandok@jax.org
#SBATCH --mail-type=END,FAIL
#SBATCH --output=MPRAmodel_OLJR.o

#PROJ=""

module load singularity

cd /projects/tewhey-lab/projects/collaborations/autoimmune_mpra/231103-233906_OLJR/outputs/MPRAmatch/231108-094515_OLJR_MPRAcount/MPRAmodel

singularity run /projects/tewhey-lab/images/tag_analysis.sif Rscript /projects/tewhey-lab/projects/collaborations/autoimmune_mpra/231103-233906_OLJR/outputs/MPRAmatch/231108-094515_OLJR_MPRAcount/MPRAmodel/OLJR_analysis_sub.R

