#!/bin/bash

out=$1
proj=$2
config_file=$3
job_pid=$4
singularity=$5

source ${config_file}

cmd=${pwd}
outdir=${out}/outputs/MPRAmatch
fastq_loc=${out}/inputs
log_file="${out}/${now}_${proj}_MPRAmatch_log.txt"


#*******************Step 1: Merge delta GFP Fastq files*******************

for i in `awk '{print $2}' ${acc_file} | sort | uniq`
do
echo $i
CMD=`awk -v i="$i" '$2==i {aggr=aggr $1" "} END {print aggr}' ${acc_file}`
echo $CMD
cat $CMD > ${fastq_loc}/$i.fastq.gz
done

cp ${acc_file} ${out}/execution/${now}_${proj}_MPRAmatch

#********Step 2: Zip (if not already) and rename Fasta reference file with library name ************

cp ${fasta} ${out}/inputs
fasta_name=$(basename ${fasta})

# Check if the file provide is zipped or not
if [[ "$fasta" =~ \.gz$ ]]; then
    echo "File '$fasta' is already zipped."
    # Rename the original file
    mv "$fasta" ${out}/inputs/"${proj}_reference.fasta.gz"
    echo "Original file '$fasta' renamed to '${proj}_reference.fasta.gz'."
else
    gzip "$fasta"

    if [ $? -eq 0 ]; then
        echo "File zipped successfully."
        mv "${fasta}.gz" ${out}/inputs/"${proj}_reference.fasta.gz"
        echo "Original file '$fasta' renamed to '${proj}_reference.fasta.gz'."
    else
        echo "Error: Zip operation failed."
        exit 1
    fi
fi

#*******************Step 3: Fill in the match json file**********************

# Check if MPRAmatch_json variable is set and not empty
if [ -n "${MPRAmatch_json}" ]; then
  # Check if the file exists and is readable
  if [ -r "${MPRAmatch_json}" ]; then
    echo "Using MPRAmatch JSON: '$MPRAmatch_json'"
    cp "${MPRAmatch_json}" "${out}/MPRAmatch_${proj}_inputs.json"
  else
    echo "Error: MPRAmatch JSON file '${MPRAmatch_json}' not found or not readable."
  fi
else
  echo "Using default MPRAmatch JSON: '${gitrepo_dir}/MPRAmatch/setup/MPRAmatch_input.json'"
  cp "${gitrepo_dir}/MPRAmatch/setup/MPRAmatch_input.json" "${out}/MPRAmatch_${proj}_inputs.json"
fi

if [ -n "${singularity}" ]; then

"${singularity}" exec ${mpra_container} jq --arg proj ${proj} --arg FLOC ${out}/inputs --arg OUT ${proj} -M '. + {"MPRAmatch.read_a":'\"${out}/inputs/${proj}_r1.fastq.gz\"', "MPRAmatch.read_b":'\"${out}/inputs/${proj}_r2.fastq.gz\"', "MPRAmatch.reference_fasta":'\"${out}/inputs/${proj}_reference.fasta.gz\"', "MPRAmatch.id_out":'\"${proj}\"',"MPRAmatch.working_directory":'\"${gitrepo_dir}/MPRAmatch/scripts\"',"MPRAmatch.out_directory":'\"${out}/outputs/MPRAmatch\"'}' ${out}/MPRAmatch_${proj}_inputs.json > ${out}/execution/${now}_${proj}_MPRAmatch/MPRAmatch_${proj}_inputs.json
else 

singularity exec ${mpra_container} jq --arg proj ${proj} --arg FLOC ${out}/inputs --arg OUT ${proj} -M '. + {"MPRAmatch.read_a":'\"${out}/inputs/${proj}_r1.fastq.gz\"', "MPRAmatch.read_b":'\"${out}/inputs/${proj}_r2.fastq.gz\"', "MPRAmatch.reference_fasta":'\"${out}/inputs/${proj}_reference.fasta.gz\"', "MPRAmatch.id_out":'\"${proj}\"',"MPRAmatch.working_directory":'\"${gitrepo_dir}/MPRAmatch/scripts\"',"MPRAmatch.out_directory":'\"${out}/outputs/MPRAmatch\"'}' ${out}/MPRAmatch_${proj}_inputs.json > ${out}/execution/${now}_${proj}_MPRAmatch/MPRAmatch_${proj}_inputs.json
fi

#*******************Step 4: Create the MPRAmatch_call script*******************


echo -e " echo 'Running Cromwell'" > ${out}/execution/${now}_${proj}_MPRAmatch/MPRAmatch_${proj}_call.sh

echo -e "cromwell run ${gitrepo_dir}/MPRAmatch/MPRAmatch.wdl --inputs ${out}/execution/${now}_${proj}_MPRAmatch/MPRAmatch_${proj}_inputs.json" >> ${out}/execution/${now}_${proj}_MPRAmatch/MPRAmatch_${proj}_call.sh

echo -e "echo 'Finished Cromwell'" >> ${out}/execution/${now}_${proj}_MPRAmatch/MPRAmatch_${proj}_call.sh



#*******************Step 5: Execute MPRAmatch_call WDL analysis pipeline*********


cd ${out}/execution/${now}_${proj}_MPRAmatch/

echo "Loading Singularity Module"

echo "Executing SIF with Code"

if [ -n "${singularity}" ]; then

  ${singularity} exec ${mpra_container} sh ${out}/execution/${now}_${proj}_MPRAmatch/MPRAmatch_${proj}_call.sh
  echo "Done"
else  
  singularity exec ${mpra_container} sh ${out}/execution/${now}_${proj}_MPRAmatch/MPRAmatch_${proj}_call.sh
  echo "Done"

fi

#***************Step 6: Copy WDL and log files***************************

cp ${results_dir}/MPRAmatch-${proj}.${job_pid}.out ${out}/logs
rm ${out}/MPRAmatch_${proj}_inputs.json
mv ${out}/logs/.out ${out}/logs/${now}_${proj}_MPRAmatch_cromwell-workflow-logs
#mv ${cmd}/cromwell-workflow-logs ${out}/execution/${now}_${proj}_MPRAmatch


#**************Step 7: Save status and location of output files*****************

echo "Results for library analyzed ${proj} are located in directory ${out}" > ${log_file}
echo "The concatenated delta GFP fastq files are located at: ${fastq_loc}" >> ${log_file}
echo "The reference fasta file is located at: ${out}/inputs/${proj}_reference.fasta.gz" >> ${log_file}
echo "The JSON file with MPRAmatch input parameters is located at: ${out}/execution/${now}_${proj}_MPRAmatch/MPRAmatch_${proj}_inputs.json" >> ${log_file}
echo "The script to run the MPRAmatch WDL pipeline is located at: ${out}/execution/${now}_${proj}_MPRAmatch/MPRAmatch_${proj}_call.sh" >> ${log_file}
echo "Job ID: ${job_pid}" >> ${log_file}

#extracting the path to the illumina sequencing files released by GT from acc_id.txt file
seq_filepath=$(cat ${acc_file} | cut -f 1| head -n 1)
seq_dir=$(dirname $seq_filepath)

echo "The raw sequencing illumina files released by GT are located at: ${seq_dir}"

