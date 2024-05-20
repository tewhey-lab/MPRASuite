# MPRAcount - Barcode Counting Pipeline

### Pipeline Flowchart

![Graphical Pipeline](../graphics/MPRAcount_pipeline.svg)

* **Tiled green** object represent arrays of files and information passed to the pipeline, 
* **Turquoise** object represent the output of the MPRAmatch pipeline, 
* **Yellow** objects refer to scripts written for the pipeline, 
* **Red** represents the final count table.


### Pipeline Description

The fastq files are processed concurrently, and the barcodes, along with the barcode-oligo dictionary, are transferred to a script that links the barcodes with their corresponding oligos. Subsequently, these files are forwarded to a script responsible for arranging the matched barcodes and oligos into a count table. This pipeline is implemented using Workflow Description Language (WDL) version 1.0. Further information can be found [here](https://github.com/openwdl/wdl)


**1. Clone Repo (or Pull Updated Repo):**
<br>
Refer to the repository cloned at the MPRAmatch step or clone again.

```
git clone https://github.com/tewhey-lab/MPRASuite.git && cd MPRASuite
```
<br>

**2. **_QC-check:_** Check the MPRAmatch git repository directory structure :**

To ensure proper cloning of the repository, please examine the directory structure provided below. <br>
(**Note:** There are additional folders for other modules, but for the purpose of this instruction, focus on examining only the MPRAcount folder.)
<br>

```
    - MPRASuite/  
      - example
      - graphics
      - LICENSE.txt
      - README.md
      - MPRAcount
        - execution
        - MPRAcount.wdl
        - output_file_explanations.md
        - README.md
        - scripts
        - setup
     - MPRAmatch
     - MPRAmodel

```
<br>

**3. Creating MPRA SIF(singularity image file):**

(If not already installed from the previous step)
MPRAmatch To install a Docker image from Quay.io and converting it into a singularity image to be able to use on the Linux system, ensure haing singularity installed on your system and please follow the below commands:

**a. Pull the Docker image from Quay.io and convert into SIF file:**
<br>
Open a terminal and run the following command:

<br>

```
singularity run docker://quay.io/harshpreet_chandok/mprasuite:latest
```
<br>

**b. Ensure the SIF file is created correctly:**
<br>
```
singularity inspect mprasuite_latest.sif
```
<br>

This command will display metadata about the SIF file, such as the labels, environment variables, and run script. If the SIF file is valid and properly created, this command will return relevant information without any errors.
<br>


**4.  Getting the input files ready:**

The user is responsible for manually generating two files namely ```<library_name>_acc_id_reps.txt```and ```MPRAcount_<library_name>.config```, which are required inputs for the pipeline to proceed. The filenames can be customized by the user, but it is crucial to ensure that the correct files are provided to the pipeline.
<br>

**a. acc_id_reps.txt:**
<br>

This file should consist of four columns listed below and can be saved in a file named `<library_name>_acc_id_reps.txt`. 

1. Sample Ids
2. Plasmid/cell-type replicate
3. Biotype name (DNA for plasmid and cell type names for their respective cell-types)
4. Type (DNA for Plasmid and RNA for cell-types).

The final file should not include a header line. An example is provided below, featuring plasmid (3 replicates) and two cell-types (A549 and Jurkat) with their respective replicates.
<br>
**Note:** When concatenating sequencing results for each sample make sure to list the replicates sequentially per group. Example:
<br>

```
OL111_Plasmid_r1_GT11-15046_CAGCGGTA-CCAAGTCA_S19_R1_001.fastq.gz Plasmid_r1  DNA  DNA
OL111_Plasmid_r2_GT11-15047_CAGCGGTA-CCAAGTCA_S20_R1_001.fastq.gz Plasmid_r2  DNA  DNA
OL111_Plasmid_r3_GT11-15048_CAGCGGTA-CCAAGTCA_S21_R1_001.fastq.gz Plasmid_r3  DNA  DNA
OL111_A549_r1_GT23-15040_TCTCCAAC-AGATGAGA_S22_R1_001.fastq.gz  A549_r1  A549  RNA
OL111_A549_r2_GT23-15041_TCTCCAAC-AGATGAGA_S23_R1_001.fastq.gz  A549_r1  A549  RNA
OL111_Jurkat_r1_GT23-15042_CAACTCTC-GAGAAGAT_S27_R1_001.fastq.gz  Jurkat_r1  Jurkat  RNA
OL111_Jurkat_r2_GT23-15043_CAACTCTC-GAGAAGAT_S28_R1_001.fastq.gz  Jurkat_r2  Jurkat  RNA
OL111_Jurkat_r3_GT23-15044_CAACTCTC-GAGAAGAT_S29_R1_001.fastq.gz  Jurkat_r3  Jurkat  RNA

```

<br>

**b.  MPRAcount specific config file:**
<br>

Please copy the provided content and replace the inputs for each parameter as needed. Save the file with a name such as `OL111_MPRAcount.config` (refer to the example below).
<br>
**Note:** The variables `proj` and `library_rerun_name` can have the same string when running the pipeline with built-in settings and parameter values. However, `library_rerun_name` can be modified when analyzing the library with different settings or parameters. 
We offer users the flexibility to provide a JSON file with their preferred library design settings. If no JSON file is specified in the config file, the pipeline will default to the standard settings and generate a JSON file accordingly.

<br>

```
##Input parameters for MPRAcount

export gitrepo_dir="/path/to/repo/MPRASuite"
#export mpra_container="/projects/tewhey-lab/images/MPRASuite-MPRAmatch_MPRAcount_v1.sif" (path on sumer)
export mpra_container="/path/to/the/sif_file/from/docker"

export mpramatch_dir="/path/to/MPRAmatch/output/directory"
export acc_reps_file="/path/to/<library_name>_acc_id_reps.txt"
export library_rerun_name="<folder_name_for_rerun>"
export proj="<library_name>"

#leave the variable blank if not providing customized json file,the pipeline will utilize the default parameters to generate the JSON and continue processing
export MPRAcount_json="<path/to/user/json/customized/file>"

#leave the variable blank if singularity is installed in the PATH
export singularity="/path/to/installed/singularity"

```
<br>

**5A. Run the MPRAcount pipeline on SLURM configuration:**

The pipeline execution command requires three inputs (refer to the example below):

A user-provided string for the job name (```-J```), which will be added to the slurm standard error and output file names for improved tracking.
The absolute path to the ```MPRAcount_run.sh``` script within the git repository.
The absolute path to the ```MPRAcount.config``` file. 
This command can be executed directly from the terminal.

```
* Secure shell login to Sumner:

ssh <login/to/cluster>

sbatch -J "<library_name>" </path/to/MPRASuite/MPRAcount/execution/MPRAcount_run.sh> </path/to/<library_name>_MPRAcount_config.file

```
<br>

 **5B. Run the MPRAcount pipeline on non-SLURM (any linux configuration):**

The pipeline execution command requires two inputs (refer to the example below):

The absolute path to the ```MPRAcount_run.sh``` script within the git repository.
The absolute path to the ```MPRAcount.config``` file. 
This command can be executed directly from the terminal.

```
* Secure shell login to Sumner:

ssh <login/to/cluster>

bash </path/to/MPRASuite/MPRAcount/execution/MPRAcount_run_non-slurm.sh> </path/to/<library_name>_MPRAcount_config.file

```
<br>
 

**6. Explore the output folder:**

The output folder will be generated under the folder specified in the config file (parameter ```mpramatch_dir```) with a date and time stamp appended to the folder name as a suffix followed by ```<library_name>```. <br>
Within the main parent folder carried over from the output of previous module MPRAmatch in the format `YYMMDD-HHMMSS_<library_name>/outputs/MPRAmatch/`, subfolder namely `YYMMDD-HHMMSS_<library_name>_MPRAcount/` will be created with the output files.
<br>

```
   - YYMMDD-HHMMSS_<library_name>/
    - execution
      - YYMMDD-HHMMSS_<library_name>_MPRAmatch
        - cromwell-executions
        - cromwell-workflow-logs
        - MPRAmatch_<library_name>_inputs.json
        - MPRAmatch_<library_name>_call.sh
      - YYMMDD-HHMMSS_<library_name>_count
        - cromwell-executions
        - cromwell-workflow-logs
        - MPRAcount_<library_name>_inputs.json
        - MPRAcount_<library_name>_call.sh
    - inputs
      - <library_name>_R1.fastq.gz
      - <library_name>_R2.fastq.gz
      - <library_name>_reference.fastq.gz
      - <cell_types>.fastqs.gz
    - outputs
      - MPRAmatch
        - <library_name>.merged.match.enh.mapped.barcode.ct.parsed
        - YYMMDD-HHMMSS_<library_name>_MPRAcount/
    - logs
      - YYMMDD-HHMMSS_<library_name>_MPRAmatch_cromwell-workflow-logs
      - YYMMDD-HHMMSS_<library_name>_MPRAcount_cromwell-workflow-logs

```
<br>

Detailed explanations of the output files, including their headers and columns, can be found [here](https://github.com/tewhey-lab/MPRASuite/blob/main/MPRAcount/output_file_explanations.md).

<br>

The only output file required from the MPRAcount module for the subsequent MPRAmodel pipeline can be located at:
<br>
* Count File       : `- YYMMDD-HHMMSS_<library_name>/MPRAmatch/YYMMDD-HHMMSS_<library_name>_MPRAcount/<library_name>.count`
* Condition file   : `- YYMMDD-HHMMSS_<library_name>/MPRAmatch/YYMMDD-HHMMSS_<library_name>_MPRAcount/<library_name>.condition.txt`
<br>
