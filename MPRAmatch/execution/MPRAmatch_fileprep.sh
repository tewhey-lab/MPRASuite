#!/bin/bash
set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Parse arguments
out=$1
proj=$2
config_file=$3
job_pid=$4
singularity=$5

# Source configuration
source "${config_file}"

# ============================================================================
# Setup container bind mounts for Singularity/Apptainer compatibility
# ============================================================================
setup_container_environment() {
    # Only need to bind output directory and git repo directory
    local bind_paths="${out}:${out}"
    
    # Add git repo directory if it's different from out
    if [ "${gitrepo_dir}" != "${out}" ]; then
        bind_paths="${bind_paths},${gitrepo_dir}:${gitrepo_dir}"
    fi
    
    # Set environment variables for both Singularity and Apptainer
    export SINGULARITY_BIND="${bind_paths}"
    export APPTAINER_BIND="${bind_paths}"
    export SINGULARITYENV_BIND="${bind_paths}"  # For older versions
    
    # Also prepare explicit bind arguments as fallback
    export CONTAINER_BIND_ARGS="--bind ${out}:${out}"
    if [ "${gitrepo_dir}" != "${out}" ]; then
        CONTAINER_BIND_ARGS="${CONTAINER_BIND_ARGS} --bind ${gitrepo_dir}:${gitrepo_dir}"
    fi
    
    echo "Container binds configured: ${bind_paths}"
}

# Call container setup
setup_container_environment

# ============================================================================

outdir="${out}/outputs/MPRAmatch"
fastq_loc="${out}/inputs"
log_file="${out}/logs/${now}_${proj}_MPRAmatch_log.txt"

#*******************Step 1: Merge delta GFP Fastq files*******************

echo "Step 1: Merging FASTQ files..."
for i in $(awk '{print $2}' "${acc_file}" | sort | uniq)
do
    echo "Processing: $i"
    CMD=$(awk -v i="$i" '$2==i {aggr=aggr $1" "} END {print aggr}' "${acc_file}")
    echo "Files to concatenate: $CMD"
    cat $CMD > "${fastq_loc}/$i.fastq.gz"
done

cp "${acc_file}" "${out}/execution/${now}_${proj}_MPRAmatch/"

#********Step 2: Zip (if not already) and rename Fasta reference file with library name ************

echo "Step 2: Processing reference FASTA..."
cp "${fasta}" "${out}/inputs/"
fasta_name=$(basename "${fasta}")

# Check if the file is already zipped
if [[ "$fasta" =~ \.gz$ ]]; then
    echo "File '$fasta' is already zipped."
    cp "$fasta" "${out}/inputs/${proj}_reference.fasta.gz"
    echo "File copied to '${out}/inputs/${proj}_reference.fasta.gz'"
else
    echo "Compressing FASTA file..."
    if gzip -c "$fasta" > "${out}/inputs/${proj}_reference.fasta.gz"; then
        echo "File zipped successfully to '${out}/inputs/${proj}_reference.fasta.gz'"
    else
        echo "Error: Zip operation failed."
        exit 1
    fi
fi

#*******************Step 3: Fill in the match json file**********************

echo "Step 3: Setting up MPRAmatch JSON configuration..."

# Check if MPRAmatch_json variable is set and not empty
if [ -n "${MPRAmatch_json:-}" ]; then
    # Check if the file exists and is readable
    if [ ! -r "${MPRAmatch_json}" ]; then
        echo "Error: MPRAmatch JSON file '${MPRAmatch_json}' not found or not readable."
        exit 1
    fi
    echo "Using custom MPRAmatch JSON: '$MPRAmatch_json'"
    cp "${MPRAmatch_json}" "${out}/MPRAmatch_${proj}_inputs.json"
else
    default_json="${gitrepo_dir}/MPRAmatch/setup/MPRAmatch_input.json"
    if [ ! -r "${default_json}" ]; then
        echo "Error: Default MPRAmatch JSON file '${default_json}' not found or not readable."
        exit 1
    fi
    echo "Using default MPRAmatch JSON: '${default_json}'"
    cp "${default_json}" "${out}/MPRAmatch_${proj}_inputs.json"
fi

# Verify the input JSON was created
input_json="${out}/MPRAmatch_${proj}_inputs.json"
output_json="${out}/execution/${now}_${proj}_MPRAmatch/MPRAmatch_${proj}_inputs.json"

if [ ! -f "${input_json}" ]; then
    echo "Error: Input JSON not found at: ${input_json}"
    exit 1
fi

echo "Creating MPRAmatch configuration with updated paths..."

# Prepare jq filter with proper escaping
jq_filter=". + {
  \"MPRAmatch.read_a\": \"${out}/inputs/${proj}_r1.fastq.gz\",
  \"MPRAmatch.read_b\": \"${out}/inputs/${proj}_r2.fastq.gz\",
  \"MPRAmatch.reference_fasta\": \"${out}/inputs/${proj}_reference.fasta.gz\",
  \"MPRAmatch.id_out\": \"${proj}\",
  \"MPRAmatch.working_directory\": \"${gitrepo_dir}/MPRAmatch/scripts\",
  \"MPRAmatch.out_directory\": \"${out}/outputs/MPRAmatch\"
}"

# Run jq with proper bind mounts
echo "Running jq to update JSON configuration..."
if [ -n "${singularity}" ]; then
    ${singularity} exec ${CONTAINER_BIND_ARGS} ${mpra_container} \
        jq -M "${jq_filter}" "${input_json}" > "${output_json}"
    jq_exit=$?
else
    singularity exec ${CONTAINER_BIND_ARGS} ${mpra_container} \
        jq -M "${jq_filter}" "${input_json}" > "${output_json}"
    jq_exit=$?
fi

# Check if jq succeeded
if [ ${jq_exit} -ne 0 ]; then
    echo "Error: jq command failed with exit code ${jq_exit}"
    if [ -f "${output_json}" ]; then
        echo "Output file contents:"
        cat "${output_json}"
    fi
    exit 1
fi

if [ ! -s "${output_json}" ]; then
    echo "Error: Output JSON is empty: ${output_json}"
    exit 1
fi

echo "Successfully created: ${output_json}"

#*******************Step 4: Create the MPRAmatch_call script*******************

echo "Step 4: Creating MPRAmatch execution script..."

cat > "${out}/execution/${now}_${proj}_MPRAmatch/MPRAmatch_${proj}_call.sh" <<EOF
echo 'Running Cromwell'
cromwell run ${gitrepo_dir}/MPRAmatch/MPRAmatch.wdl --inputs ${out}/execution/${now}_${proj}_MPRAmatch/MPRAmatch_${proj}_inputs.json
echo 'Finished Cromwell'
EOF

chmod +x "${out}/execution/${now}_${proj}_MPRAmatch/MPRAmatch_${proj}_call.sh"

#*******************Step 5: Execute MPRAmatch_call WDL analysis pipeline*********

echo "Step 5: Executing MPRAmatch WDL pipeline..."

cd "${out}/execution/${now}_${proj}_MPRAmatch/"

echo "Loading Singularity Module"
echo "Executing SIF with Code"

if [ -n "${singularity}" ]; then
    ${singularity} exec ${CONTAINER_BIND_ARGS} ${mpra_container} \
        sh "${out}/execution/${now}_${proj}_MPRAmatch/MPRAmatch_${proj}_call.sh"
    cromwell_exit=$?
else  
    singularity exec ${CONTAINER_BIND_ARGS} ${mpra_container} \
        sh "${out}/execution/${now}_${proj}_MPRAmatch/MPRAmatch_${proj}_call.sh"
    cromwell_exit=$?
fi

if [ ${cromwell_exit} -ne 0 ]; then
    echo "Error: Cromwell pipeline failed with exit code ${cromwell_exit}"
    exit 1
fi

echo "Cromwell pipeline completed successfully"

#***************Step 6: Copy WDL and log files***************************

echo "Step 6: Organizing output files..."

# Copy log file if it exists
if [ -f "${results_dir}/MPRAmatch-${proj}.${job_pid}.out" ]; then
    cp "${results_dir}/MPRAmatch-${proj}.${job_pid}.out" "${out}/logs/"
fi

# Move cromwell logs if they exist
if [ -f "${out}/logs/.out" ]; then
    mv "${out}/logs/.out" "${out}/logs/${now}_${proj}_MPRAmatch_cromwell-workflow-logs"
fi

# Clean up temporary input JSON
if [ -f "${out}/MPRAmatch_${proj}_inputs.json" ]; then
    rm "${out}/MPRAmatch_${proj}_inputs.json"
fi

#**************Step 7: Save status and location of output files*****************

echo "Step 7: Writing log file..."

cat > "${log_file}" <<EOF
Results for library analyzed ${proj} are located in directory ${out}
The concatenated delta GFP fastq files are located at: ${fastq_loc}
The reference fasta file is located at: ${out}/inputs/${proj}_reference.fasta.gz
The JSON file with MPRAmatch input parameters is located at: ${out}/execution/${now}_${proj}_MPRAmatch/MPRAmatch_${proj}_inputs.json
The script to run the MPRAmatch WDL pipeline is located at: ${out}/execution/${now}_${proj}_MPRAmatch/MPRAmatch_${proj}_call.sh
Job ID: ${job_pid}
EOF

# Extract the path to the illumina sequencing files
if [ -f "${acc_file}" ]; then
    seq_filepath=$(head -n 1 "${acc_file}" | cut -f 1)
    seq_dir=$(dirname "${seq_filepath}")
    echo "The original sequencing files were copied from: ${seq_dir}" >> "${log_file}"
    echo "The original sequencing files were copied from: ${seq_dir}"
fi

echo "MPRAmatch file preparation completed successfully!"
echo "Log file written to: ${log_file}"
