# MPRAmatch - First Module in MPRASuite (MPRA oligo/barcode reconstruction)

### Pipeline Flowchart

![Graphical pipeline](../graphics/MPRAmatch_pipeline.svg")

* Green objects represent files and information provided to the pipeline which are passed directly to a script or program, 
* Blue objects are the calls to the modules called for above, 
* Yellow objects refer to scripts written for the pipeline, 
* Red is for barcode-oligo dictionary.
  

### Pipeline Description

- The two fastq files from the initial barcode-oligo sequencing are fed into FLASH2 in order to merge them into a single fastq. 
- The merged fastq is then passed to a script which pulls the barcode and oligo sequences for each record in the fastq based on the linker sequences between the barcode and oligo, and at the end of the oligo. 
- The barcode/oligo pair information is rearranged into a FASTA format and passed to MiniMap2 along with the reference fasta. - The resulting SAM file is parsed for the Oligo name, barcode sequence, CIGAR, and error information for each mapped record. - The number of times each barcode appears for each oligo is then counted; the output is passed to preseq to determine sequencing depth, and parsed to resolve barcodes which map to multiple oligos.

This pipeline is written in the Workflow Description Language (WDL) version 1.0, more info [here](https://github.com/openwdl/wdl).


### Parameters for MPRAmatch.wdl

There are several optional inputs that can be changed based on a different library preparation.

 - `MPRAmatch.read_len` : Integer, default to 250. Maximum length (in bp) of reads to be flashed
 - `MPRAmatch.seq_min` : Integer, default to 100. Minimum sequence length to pull for barcode
 - `MPRAmatch.enh_min` : Integer, default to 50. Minimum enhancer length to pull
 - `MPRAmatch.enh_max` : Integer, default to 210. Maximum enhancer length to pull
 - `MPRAmatch.barcode_link` : String, default to "TCTAGA". 6 bases at the barcode end of the sequence linking the barcode and oligo
 - `MPRAmatch.oligo_link` : String, default to "AGTG". 4 bases at the oligo end of the sequence linking the barcode and oligo
 - `MPRAmatch.end_oligo_link` : String, default to "CGTC". 4 bases indicating the oligo is no longer being sequenced


### MPRAmatch git repository directory structure in MPRASuite:

```
    - cloned_repository/  
      - environment
      - graphics
      - LICENSE.txt
      - MPRAmatch
        - example
        - execution
        - MPRAmatch.wdl
        - output_file_explanations.md
        - README.md
        - scripts
        - setup
      - output_file_explanations.md
      - README.md
      - scripts
      - setup

```

## Setting up the environment:

We have the whole environment containerized, the definition file is available in the `environment/` folder of this repository.

If you are unable to run the pipeline via a container, then set up your environment as described below:

* Have modules for Cromwell, Womtool, FLASH2, minimap2 (version 2.17), preseq, pandas, reshape2, ggplot2, gridextra, and Biopython available (`.yml` of this conda enviornment can be found in the environment tab)
  * `conda install -c bioconda cromwell womtool flash2 minimap2=2.17 preseq pandas samtools`
  * `conda install -c conda-forge r-reshape2 r-ggplot2 r-gridextra biopython`

* Make sure the contents of the git repo once cloned are in a known directory (you will need to provide the path to this directory)

* WDL does not get rid of intermediate files. The  pipelines are set up to relocate files that are important for later use from where the pipeline is run to a more permanent location. Consider running the pipeline in a scratch area so you don't have to go and delete other intermediate files after the pipeline completes itself. If you do opt to delete the files manually, please check that the relocation at the end of the pipeline has completed.


# Steps to prepare and run MPRAmatch:

**1. Clone Repo (or Pull Updated repo):**

`  git clone https://github.com/tewhey-lab/MPRASuite.git  `

**2. Create `acc_id.txt` file (by the user):**

This file `<library_name>_acc_id.txt` should be manually created prior to creating the MPRAmatch specific config file (described in the next step).
The text file should contain two columns; the first listing full paths to delta GFP files in fastq.gz format and the second column have the respective <library_name>_read_number. No column headers are required in the file.

**Note:** If the sequencing for read1 and read2 results in multiple files for both (i.e. multiple lanes or split between plates) when concatenating them into a single read1 file and read2 file make sure paired files are in the same order between both fastqs. (read1 followed by read2 for same sample). Example:

```
/path/to/OL111_deltaGFP-A_GT23-13735_GACCAGGA-ATAGCCAG_S91_L007_R1_001.fastq.gz OL111_r1
/path/to/OL111_deltaGFP-A_GT23-13735_GACCAGGA-ATAGCCAG_S91_L007_R2_001.fastq.gz OL111_r2
/path/to/OL111_deltaGFP-B_GT23-13736_TGCTGCTG-ATGAGGAC_S92_L007_R1_001.fastq.gz OL111_r1
/path/to/OL111_deltaGFP-B_GT23-13736_TGCTGCTG-ATGAGGAC_S92_L007_R2_001.fastq.gz OL111_r2
/path/to/OL111_deltaGFP-B_GT23-13736_TGCTGCTG-ATGAGGAC_S92_L008_R1_001.fastq.gz OL111_r1
/path/to/OL111_deltaGFP-B_GT23-13736_TGCTGCTG-ATGAGGAC_S92_L008_R2_001.fastq.gz OL111_r2

```

**3. Create MPRAmatch specific config file (by the user):**

Copy the below content and substitute the inputs for each parameter as required and save the file as, for example: `OL111_MPRAmatch.config` (see example below).

**Note:** The variable `proj` and `library_rerun_name` can be the same string when running the pipeline with in-buit settings and parameter values, the variable `library_rerun_name` can be changed when the library is analyzed for a different setting/parameter and the pipeline can be run with updated config file to create a new output folder with respective files.

```
export gitrepo_dir="/path/to/MPRASuite/"
export jq_container="/path/to/MPRASuite/images/jq.sif"
export mpra_oligo_container="/path/to/MPRASuite/images/mpra_oligo_barcode.sif"

export acc_file="/path/to/<library_name>_acc_id.txt"
export fasta="/path/to/<reference>.fa.gz"
export proj="<library_name>"
export results_dir="/path/to/desired/output/folder" 
export library_rerun_name="<library_name>"

```

**4. Run the MPRAmatch pipeline:**

The command to execute the pipeline need 3 inputs (see example below): 
* '-J' string for job name provided by the user which will be appended to the slurm standard error and output files to better tracking,
* absolute path to MPRAmatch_run.sh script within the git repo,
* absolute path the MPRAmatch.config file. This command can be executed directly from the terminal.

```
  sbatch -J "<library_name>" </path/to/MPRASuite/MPRAmatch/execution/MPRAmatch_run.sh> </path/to/<library_name>_MPRAmatch_config.file

```

**5. Quick QC - Manually check the json file (intermediate file):**

The file `MPRAmatch_<library_name>_inputs.json` can be checked in the folder: `YYMMDD-HHMMSS_<library_name>/execution/YYMMDD-HHMMSS_<library_name>_MPRAmatch/` . It is a good practice to check and make sure the default and user provided arguments in the config file have parsed successfully. An example of `json` file is below:

```
{
  "MPRAmatch.read_a": "/full/path/to/read/1.fastq.gz",
  "MPRAmatch.read_b": "/full/path/to/read/2.fastq.gz",
  "MPRAmatch.reference_fasta": "/full/path/to/reference/fasta.fa",
  "MPRAmatch.working_directory": "/full/path/to/MPRASuite/MPRAmatch/scripts",
  "MPRAmatch.out_directory": "/full/path/to/output/directory/"
  "MPRAmatch.id_out": "<library_name>"
  "MPRAmatch.read_b_number": "2",
  "MPRAmatch.read_len": "250",
  "MPRAmatch.seq_min": "100",
  "MPRAmatch.enh_min": "50",
  "MPRAmatch.enh_max": "210",
  "MPRAmatch.barcode_link": "TCTAGA",
  "MPRAmatch.oligo_link": "AGTG",
  "MPRAmatch.end_oligo_link": "CGTC"
}

```

**6. Check the output folders:**

Below is the output run directory organization chart:

```
   - YYMMDD-HHMMSS_<library_name>/
    - execution
      - YYMMDD-HHMMSS_<library_name>_MPRAmatch
        - cromwell-executions
        - cromwell-workflow-logs
        - MPRAmatch_<library_name>_inputs.json    #file we checked in Step 5
        - MPRAmatch_<library_name>_call.sh
    - inputs
      - <library_name>_R1.fastq.gz
      - <library_name>_R2.fastq.gz
      - <library_name>_reference.fastq.gz
    - outputs
      - MPRAmatch
        - <library_name>.merged.match.enh.mapped.barcode.ct.Parsed      #file needed for next module - MPRAcount
    - slurm_logs
      - YYMMDD-HHMMSS_<library_name>_MPRAmatch_cromwell-workflow-logs
```

The output file from `MPRAmatch` needed as input for the `MPRAcount` pipeline can be found at:
**Parsed File:** `YYMMDD-HHMMSS_<library_name>/outputs/MPRAmatch/<library_name>.merged.match.enh.mapped.barcode.ct.parsed`


### Running WDL pipeline as a standalone script:

At any given point if the user would like to run/test the WDL pipeline as a standalone script for their library with a different setting or parameter applied to any tool or          software, the json file generated above will be required as an argument to the below script.

**a. To submit to `slurm` from terminal:**

Make sure you give the pipeline enough memory to run, if the pipeline fails the first time you run it, look at the end of the slurm output file to determine whether you need to      give it more time or more memory

` sbatch -p compute -q batch -t 24:00:00 --mem=45GB -c 8 --wrap "cromwell run /path/to/MPRAmatch.wdl --inputs /path/to/MPRAmatch_<library_name>_inputs.json"`

**b. To submit using the runscript:**

  **b1. Copy the below code and save it in a file named `MPRAmatch_call.sh`. Make sure to update the paths and locations.**

  Runscript:

  ```
  echo "Running Cromwell"

  cromwell run /path/to/MPRASuite/MPRAmatch/MPRAmatch.wdl --inputs /path/to/YYMMDD-HHMMSS_<library_name>/execution/YYMMDD-               HHMMSS_<library_name>_MPRAmatch/MPRAmatch_<library_name>_inputs.json

  echo "Finished Cromwell"
  ```

   **b2. Copy the below code to create a submission template (for a SLURM based scheduler):** 
   Make sure to update the parameters: `--job-name=` with preferably the `library_name`, `--mail-user=` with the email id of the user, path to the container and runscript created       above and save in a file, example MPRAmatch_run.sh. The below script can be submitted by running `sbatch /path/to/MPRAmatch_run.sh` 

    ```
    #!/bin/bash
    #SBATCH --job-name= <library_name>
    #SBATCH -p compute # partition(this is the standard)
    #SBATCH -q batch
    #SBATCH -N 1 # number of nodes
    #SBATCH -n 45 # number of cores
    #SBATCH --mem 200GB # memory pool for all cores
    #SBATCH -t 3-00:00 # time (D-HH:MM)
    #SBATCH --mail-type=END,FAIL
    #SBATCH --mail-user= <your_email_here>

    echo "Loading Singularity Module"
    module load singularity

    echo "Executing SIF with Code"
    singularity exec /path/to/your/built/container sh /path/to/runscript/MPRAmatch_call.sh
    echo "Done"

    ```
