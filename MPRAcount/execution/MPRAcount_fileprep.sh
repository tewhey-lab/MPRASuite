#!/bin/bash
#SBATCH -N 1
#SBATCH -n 40
#SBATCH --time=72:00:00
#SBATCH --mem 200G
#SBATCH --mail-user=harshpreet.chandok@jax.org	
#SBATCH --mail-type=END,FAIL	
#SBATCH --output=MPRAcount-%x.%j.out
#SBATCH --error=MPRAcount-%x.%j.err	

out=$1
proj=$2
config_file=$3

source ${config_file}

mpramatch_outdir=${mpramatch_dir}/outputs/MPRAmatch
mkdir -p ${mpramatch_outdir}/${out}_MPRAcount
mkdir -p ${mpramatch_dir}/execution/${out}_MPRAcount

mpracount_outdir=${mpramatch_outdir}/${out}_MPRAcount
fastq_loc=${mpramatch_dir}/inputs
log_file="${mpramatch_dir}/${out}_MPRAcount_log.txt"

module load singularity

#***********Step 1: Merge replicate fastq files for plasmid and cell types*********


for i in `awk '{print $2}' ${acc_reps_file} | sort | uniq`
do
echo $i
CMD=`awk -v i="$i" '$2==i {aggr=aggr " "$1""} END {print aggr}' ${acc_reps_file}`
echo $CMD
cat $CMD > ${fastq_loc}/$i.fastq.gz
done


#************Step 2: Fill in the JSON file for MPRAcount****************************

id=`awk '{print $2}' ${acc_reps_file} | uniq | awk '{aggr=aggr",\""$1"\""} END {print aggr}' | sed 's/,//'`
reps=`awk '{print $2}' ${acc_reps_file} | uniq | awk '{aggr=aggr",\"'${fastq_loc}'/"$1".fastq.gz\""} END {print aggr}' | sed 's/,//'`
pars="${mpramatch_outdir}/${proj}.merged.match.enh.mapped.barcode.ct.parsed"

cp ${gitrepo_dir}/MPRAcount/setup/MPRAcount_input.json ${mpramatch_dir}/MPRAcount_${proj}_inputs.json

singularity exec ${mpra_container} jq --arg PROJ ${proj} --arg FLOC ${mpramatch_dir}/fastq --arg ACC ${acc_reps_file} --arg OUT ${proj} --arg ID ${id} --arg REPS ${reps} --arg PARS ${pars} -M '. + {"MPRAcount.out_directory":'\"${mpracount_outdir}\"',"MPRAcount.working_directory":'\"${gitrepo_dir}/MPRAcount/scripts\"',"MPRAcount.id_out":'\"${proj}\"', "MPRAcount.parsed":'\"${pars}\"', "MPRAcount.acc_id":'\"${acc_reps_file}\"', "MPRAcount.replicate_fastq":'\[$reps\]', "MPRAcount.replicate_id":'\[$id\]'}' ${mpramatch_dir}/MPRAcount_${proj}_inputs.json > ${mpramatch_dir}/execution/${out}_MPRAcount/MPRAcount_${proj}_inputs.json


#*************Step 3: Create MPRAcount_call script**********************************


echo -e "echo 'Running Cromwell'" > ${mpramatch_dir}/execution/${out}_MPRAcount/MPRAcount_${proj}_call.sh

echo -e "cromwell run ${gitrepo_dir}/MPRAcount/MPRAcount.wdl --inputs ${mpramatch_dir}/execution/${out}_MPRAcount/MPRAcount_${proj}_inputs.json" >> ${mpramatch_dir}/execution/${out}_MPRAcount/MPRAcount_${proj}_call.sh

echo -e "echo 'Finished Cromwell'" >> ${mpramatch_dir}/execution/${out}_MPRAcount/MPRAcount_${proj}_call.sh


#*************Step 4: Execute MPRAcount_call WDL analysis pipeline******************


cd ${mpramatch_dir}/execution/${out}_MPRAcount/ 

echo "Loading Singularity Module"

module load singularity

echo "Executing SIF with Code"

singularity exec ${mpra_container} sh ${mpramatch_dir}/execution/${out}_MPRAcount/MPRAcount_${proj}_call.sh

echo "Done"


#*******************Step 5: Copy Slurm outputs**************************************


cp ${cmd}/MPRAcount-${proj}.${SLURM_JOB_ID}.out ${mpramatch_dir}/slurm_logs
rm ${mpramatch_dir}/MPRAcount_${proj}_inputs.json
mv ${mpramatch_dir}/slurm_logs/.out ${mpramatch_dir}/slurm_logs/${now}_${proj}_MPRAcount_cromwell-workflow-logs

#*******************Step 6: Save status and location to output files to log file*******************

echo "Results for the library analyzed ${proj} are located in directory ${out}" > ${log_file}
echo "The concatenated plasmid and cell type replicate fastq files processed are located a: ${fastq_loc}" >> ${log_file}
echo "The JSON file with MPRAcount input parameters is located at: ${mpramatch_dir}/execution/${out}_MPRAcount/MPRAcount_${proj}_inputs.json" >> ${log_file}
echo "The script to run the MPRAcount WDL pipeline is located at: ${mpramatch_dir}/execution/${out}_MPRAcount/MPRAcount_${proj}_call.sh" >> ${log_file}
echo "SLURM Job ID: ${SLURM_JOB_ID}" >> ${log_file}
