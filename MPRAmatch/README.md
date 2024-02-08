#MPRASuite - First Module: MPRAmatch (MPRA oligo/barcode reconstruction)

## How the MPRAmatch pipeline work

_MPRAmatch_

![Graphical Pipeline](graphics/MPRAmatch_pipeline.svg?raw=true "MPRAmatch Graphical Pipeline")

The above image is a graphical representation of the MPRAmatch pipeline. Green objects represent files and information provided to the pipeline which are passed directly to a script or program, blue objects are the calls to the modules called for above, yellow objects refer to scripts written for the pipeline, and the barcode-oligo dictionary is in red.

The two fastq files from the initial barcode-oligo sequencing are fed into FLASH2 in order to merge them into a single fastq. The merged fastq is then passed to a script which pulls the barcode and oligo sequences for each record in the fastq based on the linker sequences between the barcode and oligo, and at the end of the oligo. The barcode/oligo pair information is rearranged into a FASTA format and passed to MiniMap2 along with the reference fasta. The resulting SAM file is parsed for the Oligo name, barcode sequence, CIGAR, and error information for each mapped record. The number of times each barcode appears for each oligo is then counted; the output is passed to preseq to determine sequencing depth, and parsed to resolve barcodes which map to multiple oligos.


### Written in the Written Description Language (WDL) version 1.0 more info [here](https://github.com/openwdl/wdl)

## Before running the pipeline
We have the whole environment containerized, the definition file is available in the `environment/` folder of this repository.

If you are unable to run the pipeline via a container, then set up your environment as described below:

* Have modules for Cromwell, Womtool, FLASH2, minimap2 (version 2.17), preseq, pandas, reshape2, ggplot2, gridextra, and Biopython available (`.yml` of this conda enviornment can be found in the environment tab)
  * `conda install -c bioconda cromwell womtool flash2 minimap2=2.17 preseq pandas samtools`
  * `conda install -c conda-forge r-reshape2 r-ggplot2 r-gridextra biopython`

* Make sure the contents of the git repo once cloned are in a known directory (you will need to provide the path to this directory)

* WDL does not get rid of intermediate files. The  pipelines are set up to relocate files that are important for later use from where the pipeline is run to a more permanent location. Consider running the pipeline in a scratch area so you don't have to go and delete other intermediate files after the pipeline completes itself. If you do opt to delete the files manually, please check that the relocation at the end of the pipeline has completed.

##The MPRASuite git repo directory structure; let's focus on MPRAmatch:

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
      - MPRAcount
        - example
        - execution
        - MPRAmatch.wdl
        - output_file_explanations.md
        - README.md
        - scripts
        - setup
      - MPRAmodel
        - color_schemes.tsv
        - examples
        - execution
        - graphics
        - MPRAmodel.R
        - output_description.md
        - README.md
      - output_file_explanations.md
      - README.md
      - scripts
      - setup

```

##Step 1:
* Clone Repo (or Pull Updated Repo):

git clone https://github.com/tewhey-lab/MPRASuite1.git


##Step 2: 
* Create MPRAmatch specific config file:

Copy the below content and substitute the inputs for each parameter as required and save the file as, for example: OL111_MPRAmatch.config.

* Note: The variable 'proj' and 'library_rerun_name' can be the same string when running the pipeline with in-buit settings and parameter values, the variable 'library_rerun_name' can be changed when the library is analyzed for a different setting/parameter and the pipeline can be run with updated config file to create a new output folder with respective files.


```
###Input parameters required for MPRAmatch

export gitrepo_dir="/path/to/cloned/MPRASuite/git/repo"
export jq_container="/path/to/images/jq.sif"
export mpra_oligo_container="/path/to/images/mpra_oligo_barcode.sif"

export acc_file="/path/to/<library_name>_acc_id.txt"
export fasta="/path/to/<reference>.fa.gz"
export proj="<library_name>"
export results_dir="/path/to/desired/output/folder" 
export library_rerun_name="<library_name>"

```



##Step 3: 
* Run the MPRAmatch pipeline

* The command to execute the pipeline need 3 inputs; '-J' string for job name provided by the user which will be appended to the slurm standard error and output files to better tracking; absolute path to MPRAmatch_run.sh script within the git repo; absolute path the MPRAmatch.config file. This command can be executed directly from the terminal.

```
sbatch -J "<library_name>" </path/to/MPRASuite/MPRAmatch/execution/MPRAmatch_run.sh> </path/to/<library_name>_MPRAmatch_config.file
```


##Step 4:
* Check the json file (generated as a part of the pipeline)

The file MPRAmatch_<library_name>_inputs.json can be checked in the YYMMDD-HHMMSS_<library_name>/execution/YYMMDD-HHMMSS_<library_name>_MPRAmatch/ folder. It is s good practice to make sure the default and user provided arguments in the config file have parsed successfully. An example of json file is below:

_MPRAmatch.wdl_

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

**NB: If the sequencing for read1 and read2 results in multiple files for both (i.e. multiple lanes or split between plates) when concatenating them into a single read1 file and read2 file make sure paired files are in the same order between both fastqs.**
 

There are several optional inputs that can be changed based on a different library preparation.

 - `MPRAmatch.read_len` : Integer, default to 250. Maximum length (in bp) of reads to be flashed
 - `MPRAmatch.seq_min` : Integer, default to 100. Minimum sequence length to pull for barcode
 - `MPRAmatch.enh_min` : Integer, default to 50. Minimum enhancer length to pull
 - `MPRAmatch.enh_max` : Integer, default to 210. Maximum enhancer length to pull
 - `MPRAmatch.barcode_link` : String, default to "TCTAGA". 6 bases at the barcode end of the sequence linking the barcode and oligo
 - `MPRAmatch.oligo_link` : String, default to "AGTG". 4 bases at the oligo end of the sequence linking the barcode and oligo
 - `MPRAmatch.end_oligo_link` : String, default to "CGTC". 4 bases indicating the oligo is no longer being sequenced


##Step 5:
* Check the output folders

## Outputs Needed at later steps

The output file from `MPRAmatch` needed as input for the `MPRAmatch` pipeline can be found at:
  * Parsed File      : `YYMMDD-HHMMSS_<library_name>/outputs/MPRAmatch/<library_name>.merged.match.enh.mapped.barcode.ct.parsed`


## Output run Directory organization chart:
```
   - YYMMDD-HHMMSS_<library_name>/
    - execution
      - YYMMDD-HHMMSS_<library_name>_MPRAmatch
        - cromwell-executions
        - cromwell-workflow-logs
        - MPRAmatch_<library_name>_inputs.json
        - MPRAmatch_<library_name>_call.sh
    - inputs
      - <library_name>_R1.fastq.gz
      - <library_name>_R2.fastq.gz
      - <library_name>_reference.fastq.gz
    - outputs
      - MPRAmatch
        - <library_name>.merged.match.enh.mapped.barcode.ct.parsed
    - slurm_logs
      - YYMMDD-HHMMSS_<library_name>_MPRAmatch_cromwell-workflow-logs





** At any given point if the user would like to run/test the WDL pipeline as a standalone script for their library with a different setting or parameter in any tools or softwares, the json file generated above will be required as an argument to the below script.

**To submit to slurm** Make sure that you give the pipeline enough memory to run, if the pipeline fails the first time you run it, look at the end of the slurm output file to determine whether you need to give it more time or more memory
  * `sbatch -p compute -q batch -t 24:00:00 --mem=45GB -c 8 --wrap "cromwell run /path/to/MPRAmatch.wdl --inputs /path/to/MPRAmatch_<library_name>_inputs.json"` <br>

  * **OR** you can use the runscript and submission template below which utilizes the singularity container: <br>
  Runscript:
  ```
  echo "Running Cromwell"

  cromwell run /path/to/cloned_repository/MPRAmatch/MPRAmatch.wdl --inputs path/to/cloned_repository/inputs/MPRAmatch/MPRAmatch_<library_name>_inputs.json

  echo "Finished Cromwell"
  ```
  Submission template (for a SLURM based scheduler):
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
