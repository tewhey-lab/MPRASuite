#!/bin/bash
#SBATCH -N 1
#SBATCH -n 40
#SBATCH --time=72:00:00
#SBATCH --mem 200G
#SBATCH --mail-user=harshpreet.chandok@jax.org	
#SBATCH --mail-type=BEGIN,END,FAIL	
#SBATCH --output=MPRAmatch-%x.%j.out
#SBATCH --error=MPRAmatch-%x.%j.err	

out=$1
proj=$2
config_file=$3

source ${config_file}

cmd=${pwd}
outdir=${out}/outputs/MPRAmatch
fastq_loc=${out}/inputs
log_file="${out}/${now}_${proj}_MPRAmatch_log.txt"

module load singularity


#*******************Step 1: Merge delta GFP Fastq files*******************

for i in `awk '{print $2}' ${acc_file} | sort | uniq`
do
echo $i
CMD=`awk -v i="$i" '$2==i {aggr=aggr $1" "} END {print aggr}' ${acc_file}`
echo $CMD
cat $CMD > ${fastq_loc}/$i.fastq.gz
done


#********Step 2: Rename Fasta reference file with library name ************

cp ${fasta} ${out}/inputs
fasta_name=$(basename ${fasta})
mv ${out}/inputs/${fasta_name} ${out}/inputs/${proj}_reference.fasta
gzip ${out}/inputs/${proj}_reference.fasta 

for file in ${out}/inputs/*gz
do
	echo "Checking status for file: '$file'"
if [[ ! -f $file && ! -s $file ]];then
	echo "$file not found or empty"
  	exit 1
fi
done


#*******************Step 3: Fill in the match json file**********************


cp ${gitrepo_dir}/MPRAmatch/setup/MPRAmatch_input.json ${out}/MPRAmatch_${proj}_inputs.json

singularity exec ${mpra_container} jq --arg proj ${proj} --arg FLOC ${out}/inputs --arg OUT ${proj} -M '. + {"MPRAmatch.read_a":'\"${out}/inputs/${proj}_r1.fastq.gz\"', "MPRAmatch.read_b":'\"${out}/inputs/${proj}_r2.fastq.gz\"', "MPRAmatch.reference_fasta":'\"${out}/inputs/${proj}_reference.fasta.gz\"', "MPRAmatch.id_out":'\"${proj}\"',"MPRAmatch.working_directory":'\"${gitrepo_dir}/MPRAmatch/scripts\"',"MPRAmatch.out_directory":'\"${out}/outputs/MPRAmatch\"'}' ${out}/MPRAmatch_${proj}_inputs.json > ${out}/execution/${now}_${proj}_MPRAmatch/MPRAmatch_${proj}_inputs.json


if [[ ! -f  ${out}/execution/${now}_${proj}_MPRAmatch/MPRAmatch_${proj}_inputs.json  && ! -s  ${out}/execution/${now}_${proj}_MPRAmatch/MPRAmatch_${proj}_inputs.json ]];then
        echo "ERROR:MPRAmatch JSON file not found"
        exit 1
fi


#*******************Step 4: Create the MPRAmatch_call script*******************


echo -e " echo 'Running Cromwell'" > ${out}/execution/${now}_${proj}_MPRAmatch/MPRAmatch_${proj}_call.sh

echo -e "cromwell run ${gitrepo_dir}/MPRAmatch/MPRAmatch.wdl --inputs ${out}/execution/${now}_${proj}_MPRAmatch/MPRAmatch_${proj}_inputs.json" >> ${out}/execution/${now}_${proj}_MPRAmatch/MPRAmatch_${proj}_call.sh

echo -e "echo 'Finished Cromwell'" >> ${out}/execution/${now}_${proj}_MPRAmatch/MPRAmatch_${proj}_call.sh



#*******************Step 5: Execute MPRAmatch_call WDL analysis pipeline*********


cd ${out}/execution/${now}_${proj}_MPRAmatch/

echo "Loading Singularity Module"

echo "Executing SIF with Code"

singularity exec ${mpra_container} sh ${out}/execution/${now}_${proj}_MPRAmatch/MPRAmatch_${proj}_call.sh

echo "Done"


#***************Step 6: Copy WDL and Slurm log files***************************

cp ${results_dir}/MPRAmatch-${proj}.${SLURM_JOB_ID}.out ${out}/slurm_logs
rm ${out}/MPRAmatch_${proj}_inputs.json
mv ${out}/slurm_logs/.out ${out}/slurm_logs/${now}_${proj}_MPRAmatch_cromwell-workflow-logs
#mv ${cmd}/cromwell-workflow-logs ${out}/execution/${now}_${proj}_MPRAmatch


#**************Step 7: Save status and location of output files*****************

echo "Results for library analyzed ${proj} are located in directory ${out}" > ${log_file}
echo "The concatenated delta GFP fastq files are located at: ${fastq_loc}" >> ${log_file}
echo "The reference fasta file is located at: ${out}/inputs/${proj}_reference.fasta.gz" >> ${log_file}
echo "The JSON file with MPRAmatch input parameters is located at: ${out}/execution/${now}_${proj}_MPRAmatch/MPRAmatch_${proj}_inputs.json" >> ${log_file}
echo "The script to run the MPRAmatch WDL pipeline is located at: ${out}/execution/${now}_${proj}_MPRAmatch/MPRAmatch_${proj}_call.sh" >> ${log_file}
echo "SLURM Job ID: ${SLURM_JOB_ID}" >> ${log_file}

