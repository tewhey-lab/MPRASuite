#!/bin/bash

out=$1
proj=$2
config_file=$3
job_pid=$4
singularity=$5

source ${config_file}

mpramatch_outdir=${mpramatch_dir}/outputs/MPRAmatch
mkdir -p ${mpramatch_outdir}/${out}_MPRAcount
mkdir -p ${mpramatch_dir}/execution/${out}_MPRAcount

mpracount_outdir=${mpramatch_outdir}/${out}_MPRAcount
fastq_loc=${mpramatch_dir}/inputs
log_file="${mpramatch_dir}/${out}_MPRAcount_log.txt"

#***********Step 1: Merge replicate fastq files for plasmid and cell types*********


for i in `awk '{print $2}' ${acc_reps_file} | sort | uniq`
do
echo $i
CMD=`awk -v i="$i" '$2==i {aggr=aggr " "$1""} END {print aggr}' ${acc_reps_file}`
echo $CMD
cat $CMD > ${fastq_loc}/$i.fastq.gz
done

cp ${acc_reps_file} ${mpramatch_dir}/execution/${out}_MPRAcount/

#************Step 2: Fill in the JSON file for MPRAcount****************************

id=`awk '{print $2}' ${acc_reps_file} | uniq | awk '{aggr=aggr",\""$1"\""} END {print aggr}' | sed 's/,//'`
reps=`awk '{print $2}' ${acc_reps_file} | uniq | awk '{aggr=aggr",\"'${fastq_loc}'/"$1".fastq.gz\""} END {print aggr}' | sed 's/,//'`
pars="${mpramatch_outdir}/${proj}.merged.match.enh.mapped.barcode.ct.parsed"

# Check if MPRAcount_json variable is set and not empty
if [ -n "${MPRAcount_json}" ]; then
  # Check if the file exists and is readable
  if [ -r "${MPRAcount_json}" ]; then
    echo "Using MPRAcount JSON: '$MPRAcount_json'"
    cp "${MPRAcount_json}" "${mpramatch_dir}/MPRAcount_${proj}_inputs.json"
  else
    echo "Error: MPRAcount JSON file '${MPRAcount_json}' not found or not readable."
  fi
else
  echo "Using default MPRAcount JSON: '${gitrepo_dir}/MPRAcount/setup/MPRAcount_input.json'"
  cp "${gitrepo_dir}/MPRAcount/setup/MPRAcount_input.json" "${mpramatch_dir}/MPRAcount_${proj}_inputs.json"
fi

if [ -n "${singularity}" ]; then
"${singularity}" exec ${mpra_container} jq --arg PROJ ${proj} --arg FLOC ${mpramatch_dir}/inputs --arg ACC ${acc_reps_file} --arg OUT ${proj} --arg ID ${id} --arg REPS ${reps} --arg PARS ${pars} -M '. + {"MPRAcount.out_directory":'\"${mpracount_outdir}\"',"MPRAcount.working_directory":'\"${gitrepo_dir}/MPRAcount/scripts\"',"MPRAcount.id_out":'\"${proj}\"', "MPRAcount.parsed":'\"${pars}\"', "MPRAcount.acc_id":'\"${acc_reps_file}\"', "MPRAcount.replicate_fastq":'\[$reps\]', "MPRAcount.replicate_id":'\[$id\]'}' ${mpramatch_dir}/MPRAcount_${proj}_inputs.json > ${mpramatch_dir}/execution/${out}_MPRAcount/MPRAcount_${proj}_inputs.json

else
  singularity exec ${mpra_container} jq --arg PROJ ${proj} --arg FLOC ${mpramatch_dir}/inputs --arg ACC ${acc_reps_file} --arg OUT ${proj} --arg ID ${id} --arg REPS ${reps} --arg PARS ${pars} -M '. + {"MPRAcount.out_directory":'\"${mpracount_outdir}\"',"MPRAcount.working_directory":'\"${gitrepo_dir}/MPRAcount/scripts\"',"MPRAcount.id_out":'\"${proj}\"', "MPRAcount.parsed":'\"${pars}\"', "MPRAcount.acc_id":'\"${acc_reps_file}\"', "MPRAcount.replicate_fastq":'\[$reps\]', "MPRAcount.replicate_id":'\[$id\]'}' ${mpramatch_dir}/MPRAcount_${proj}_inputs.json > ${mpramatch_dir}/execution/${out}_MPRAcount/MPRAcount_${proj}_inputs.json
fi

#*************Step 3: Create MPRAcount_call script**********************************


echo -e "echo 'Running Cromwell'" > ${mpramatch_dir}/execution/${out}_MPRAcount/MPRAcount_${proj}_call.sh

echo -e "cromwell run ${gitrepo_dir}/MPRAcount/MPRAcount.wdl --inputs ${mpramatch_dir}/execution/${out}_MPRAcount/MPRAcount_${proj}_inputs.json" >> ${mpramatch_dir}/execution/${out}_MPRAcount/MPRAcount_${proj}_call.sh

echo -e "echo 'Finished Cromwell'" >> ${mpramatch_dir}/execution/${out}_MPRAcount/MPRAcount_${proj}_call.sh


#*************Step 4: Execute MPRAcount_call WDL analysis pipeline******************


cd ${mpramatch_dir}/execution/${out}_MPRAcount/ 

echo "Loading Singularity Module"

module load singularity

echo "Executing SIF with Code"

if [ -n "${singularity}" ]; then
"${singularity}" exec ${mpra_container} sh ${mpramatch_dir}/execution/${out}_MPRAcount/MPRAcount_${proj}_call.sh
echo "Done"
else
singularity exec ${mpra_container} sh ${mpramatch_dir}/execution/${out}_MPRAcount/MPRAcount_${proj}_call.sh
echo "Done"
fi


#*******************Step 5: Copy outputs**************************************


cp ${cmd}/MPRAcount-${proj}.${job_pid}.out ${mpramatch_dir}/logs
rm ${mpramatch_dir}/MPRAcount_${proj}_inputs.json
mv ${mpramatch_dir}/logs/.out ${mpramatch_dir}/logs/${now}_${proj}_MPRAcount_cromwell-workflow-logs

#*******************Step 6: Save status and location to output files to log file*******************

echo "Results for the library analyzed ${proj} are located in directory ${out}" > ${log_file}
echo "The concatenated plasmid and cell type replicate fastq files processed are located a: ${fastq_loc}" >> ${log_file}
echo "The JSON file with MPRAcount input parameters is located at: ${mpramatch_dir}/execution/${out}_MPRAcount/MPRAcount_${proj}_inputs.json" >> ${log_file}
echo "The script to run the MPRAcount WDL pipeline is located at: ${mpramatch_dir}/execution/${out}_MPRAcount/MPRAcount_${proj}_call.sh" >> ${log_file}
echo "Job ID: ${job_pid}" >> ${log_file}

#extracting the path to the illumina sequencing files released by GT from acc_id.txt file
seq_filepath=$(cat ${acc_reps_file} | cut -f 1| head -n 1)
seq_dir=$(dirname $seq_filepath)

echo "The raw sequencing illumina fastq files for cell types released by GT are located at: ${seq_dir}"

