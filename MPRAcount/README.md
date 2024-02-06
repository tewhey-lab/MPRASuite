#MPRASuite - Second Module: MPRAcount (barcode counting pipeline)

## How the MPRAmatch pipeline work

_MPRAcount_

![Graphical Pipeline](graphics/MPRAcount_pipeline.svg?raw=true "MPRAcount Graphical Pipeline")

The above image is a graphical representation of the MPRAcount pipeline. The tiled green object represents arrays of files and information passed to the pipeline, the turquoise object represents the output of the MPRAmatch pipeline, yellow objects refer to scripts written for the pipeline, and the final count table is in red.

The array of fastq files are processed in parallel and the barcodes, along with the barcode-oligo dictionary, are passed to a script which associates the barcodes with the matching oligo. These files are then passed to a script which organises the matched barcodes and oligos into a count table.


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
* Create MPRAcount specific config file:

Copy the below content and substitute the inputs for each parameter as required and save the file as, for example: OL111_MPRAcount.config.

* Note: The variable 'proj' and 'library_rerun_name' can be the same string when running the pipeline with in-buit settings and parameter values, the variable 'library_rerun_name' can be changed when the library is analyzed for a different setting/parameter and the pipeline can be run with updated config file to create a new output folder with respective files.


```
##Input parameters for MPRAcount

export gitrepo_dir="/path/to/cloned/repo/MPRASuite"
export jq_container="/path/to/images/jq.sif"
export mpra_oligo_container="/path/to/images/mpra_oligo_barcode.sif"


export mpramatch_dir="/path/to/MPRAmatch_output_dir YYMMDD-HHMMSS_<library_name>"
export acc_reps_file="/path/to/<library_name>_acc_id_reps.txt"
export library_rerun_name="<libray_name>"
export proj="<library_name>"
```



##Step 3: 
* Run the MPRAmatch pipeline

* The command to execute the pipeline need 3 inputs; '-J' string for job name provided by the user which will be appended to the slurm standard error and output files to better tracking; absolute path to MPRAmatch_run.sh script within the git repo; absolute path the MPRAcount.config file. This command can be executed directly from the terminal.

```
sbatch -J "<library_name>" </path/to/MPRASuite/MPRAcount/execution/MPRAcount_run.sh> </path/to/<library_name>_MPRAcount_config.file
```


##Step 4:
* Check the json file (generated as a part of the pipeline)

The file MPRAmatch_<library_name>_inputs.json can be checked in the YYMMDD-HHMMSS_<library_name>/execution/YYMMDD-HHMMSS_<library_name>_MPRAcount/ folder. It is s good practice to make sure the default and user provided arguments in the config file have parsed successfully. An example of json file is below:

_MPRAcount.wdl_

```
{
  "MPRAcount.parsed": "/path/to/<library_name>.merged.match.enh.mapped.barcode.ct.parsed",
  "MPRAcount.acc_id": "/path/to/<library_name>_acc_id_reps.txt",
  "MPRAcount.working_directory": "/path/to/git/repo/MPRASuite/MPRAcount/scripts",
  "MPRAcount.out_directory": "/path/to/YYMMDD-HHMMSS_<library_name>/outputs/MPRAmatch/YYMMDD-HHMMSS_<library_name>_MPRAcount",
  "MPRAcount.id_out": "<library_name>",
  "MPRAcount.replicate_fastq": [
    /path/to/replicate/fastqs/for/each/celltype
  ],
  "MPRAcount.replicate_id": [
    replicate_ids
  ]
}

``` 

There are several optional inputs that can be changed based on a different library preparation.
 - `MPRAcount.bc_len` : Integer, default to 20. Length of barcodes to be pulled from replicate files
 - `MPRAcount.flags` : String, default to "-ECSM -A 0.05" Any combination of these flags or none can be used.

##Step 5:
* Check the output folders

The following files can then be input into the R pipeline for analysis:
  * Count File       : `/specified/output/directory/<library_name>.count`
  * Attributes Table : The output of `make_project_list.pl` and `make_attributes_oligo.pl`. If you want to bypass the use of `make_project_list.pl`, you can pass `make_attributes_oligo.pl` a tab delimited file with two columns, the first column should be the oligo names and the second column should be the project(s) that the associated oligo belongs to. If an oligo belongs to multiple projects they should be separated by commas.
  * Condition file   : `/specified/output/directory/<library_name>_condition.txt`


## Output run Directory organization chart:
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
    - slurm_logs
      - YYMMDD-HHMMSS_<library_name>_MPRAmatch_cromwell-workflow-logs
      - YYMMDD-HHMMSS_<library_name>_MPRAcount_cromwell-workflow-logs





** At any given point if the user would like to run/test the WDL pipeline as a standalone script for their library with a different setting or parameter in any tools or softwares, the json file generated above will be required as an argument to the below script.

**To submit to slurm** Make sure that you give the pipeline enough memory to run, if the pipeline fails the first time you run it, look at the end of the slurm output file to determine whether you need to give it more time or more memory
  * `sbatch -p compute -q batch -t 24:00:00 --mem=45GB -c 8 --wrap "cromwell run /path/to/MPRAcount.wdl --inputs /path/to/MPRAcount_<library_name>_inputs.json"` <br>

  * **OR** you can use the runscript and submission template below which utilizes the singularity container: <br>
  Runscript:
  ```
  echo "Running Cromwell"

  cromwell run /path/to/cloned_repository/MPRAcount/MPRAcount.wdl --inputs path/to/cloned_repository/inputs/MPRAcount/MPRAcount_<library_name>_inputs.json

  echo "Finished Cromwell"
  ```
  Submission template (for a SLURM based scheduler):
  ```
  #!/bin/bash
  #SBATCH --job-name= <library_name>_MPRAcount
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

  singularity exec /path/to/your/built/container sh /path/to/runscript/MPRAcount_call.sh

  echo "Done"
  ```




