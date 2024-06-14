# MPRAmodel: (A series of functions to assist in analysis of MPRA count tables)

**1. Clone Repo (or Pull Updated Repo):**
<br>
Refer to the repository cloned in the previous step or else clone again.

```
git clone https://github.com/tewhey-lab/MPRASuite.git && cd MPRASuite
```
<br>

**2. **_QC-check:_** Check the MPRAcount git repository directory structure :**

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
     - MPRAmatch
     - MPRAmodel
      - color_schemes.tsv
      - execution
      - graphics
      - MPRAmodel.R
      - output_description.md
      - README.md
      - setup

```
<br>

**3. Creating MPRA SIF(singularity image file):**

Please follow the steps below if the SIF file was not installed in the early MPRAmatch step, if it is already installed, you can skip this section.
<br>
To install a Docker image from Quay.io and converting it into a singularity image to be able to use on the Linux system, ensure haing singularity installed on your system and please follow the below commands:

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
./mprasuite_latest.sif
```
<br>

If the installation is successful, executing this command will list all the tools, software, and libraries along with their versions in the image file for better tracking. If no list is generated, there may be issues with the installation.

<br>


**4.  Getting the input files ready:**

The user is responsible for manually generating ```MPRAmodel_<library_name>.config```, which is required input for the pipeline to proceed. The filenames can be customized by the user, but it is crucial to ensure that the correct files are provided to the pipeline.
<br>
**a.  MPRAmodel specific config file:**
<br>

Please copy the provided content and replace the inputs for each parameter as needed. Save the file with a name such as `OL111_MPRAmodel.config` (refer to the example below).
<br>
### There are 3 files that this pipeline needs as input to proceed with the analysis: <br>
   * `countsTable` : Table of counts with header. Should be either the output of the [MPRAcount](https://github.com/tewhey-lab/MPRASuite/tree/main/MPRAcount) pipeline, or in the same format. <br>
   * `attributesData` : Attributes for each oligo including oligo name, SNP, chromosome, position, reference allele, alt allele, Allele (ref/alt), window, strand, project, haplotype. For Oligos named in the form chr:pos:ref:alt:allele:window(:haplotype) the scripts [here](https://github.com/tewhey-lab/tag_analysis_WDL/blob/master/scripts/make_infile.py) and [here](https://github.com/tewhey-lab/tag_analysis_WDL/blob/master/scripts/make_attributes_oligo.pl) can be used to generate the attributes table.
<br>
   * `conditionData` : 2 columns w/no header column 1 is replicates as found in the count table, column 2 indicates cell type. This can be done in the program of your choice, or taken from the output of [MPRAcount](https://github.com/tewhey-lab/MPRASuite/tree/main/MPRAcount).


<br>
*We offer users the flexibility to provide a JSON file with their preferred library design settings. If no JSON file is specified in the config file, the pipeline will default to the standard settings and generate a JSON file accordingly. Please refer [here](https://github.com/tewhey-lab/MPRASuite/blob/main/MPRAcount/json_file_explanations.md) for detailed explanation of JSON parameters and default settings.
<br>
<br>


```
#Input parameters for MPRAmodel

gitrepo_dir="/projects/tewhey-lab/github/MPRASuite"
mpramodel_container="/projects/tewhey-lab/images/MPRASuite-MPRAmodel_v1.sif"
mpracount_output_folder="/projects/tewhey-lab/projects/collaborations/autoimmune_mpra/231103-233906_OLJR/outputs/MPRAmatch/231108-094515_OLJR_MPRAcount/MPRAmodel/test/"
proj="OLJR"
prefix=
negCtrl="negCtrl"
posCtrl="expCtrl"
attr_proj="/projects/tewhey-lab/projects/collaborations/autoimmune_mpra/Tcell_GWAS_ctrl.attributes"
count_proj="/projects/tewhey-lab/projects/collaborations/autoimmune_mpra/231103-233906_OLJR/outputs/MPRAmatch/231107-231034_OLJR_wo_Bcell_MPRAcount/231115-230534_OLJR.A_MPRAmodel/OLJR.A.count"
#count_proj="/projects/tewhey-lab/projects/collaborations/autoimmune_mpra/231103-233906_OLJR/outputs/MPRAmatch/231107-231034_OLJR_wo_Bcell_MPRAcount/231115-230534_OLJR.A_MPRAmodel/OLJR.A.count"
cond_proj="/projects/tewhey-lab/projects/collaborations/autoimmune_mpra/231103-233906_OLJR/outputs/MPRAmatch/231107-231034_OLJR_wo_Bcell_MPRAcount/231115-230534_OLJR.A_MPRAmodel/OLJR.A_condition.txt"
proj_options="cSkew=F, prior=F, method='ss'"

```
<br>

**5A. Run the MPRAmodel pipeline on a linux workstation:**

The pipeline execution command requires two inputs (refer to the example below):

The absolute path to the ```MPRAmodel_run.sh``` script within the git repository.
The absolute path to the ```MPRAmodel.config``` file. 

This command can be executed <br>
1. directly from the terminal (example below) which will display the standard outputs on the terminal itself.
2. The same command can be run as a job in the background using ```nohup``` (example below) and the standard outputs can be saved to a log file. To check if the status of the job, use the command ```jobs``` on the terminal.
<br>

```
##1. To run on terminal

bash </path/to/MPRASuite/MPRAmodel/execution/MPRAmodel_run.sh> </path/to/<library_name>_MPRAmodel_config.file

## 2. To save the standard output to a log file

nohup bash </path/to/MPRASuite/MPRAmodel/execution/MPRAmodel_run.sh> </path/to/<library_name>_MPRAmodel_config.file > <path/to/MPRAmodel.log 2>&1 &

```
<br>
 

**5B. Run the MPRAmodel pipeline on a SLURM cluster:**

The pipeline execution command requires three inputs (refer to the example below):

A user-provided string for the job name (```-J```), which will be added to the slurm standard error and output file names for improved tracking.
The absolute path to the ```MPRAmodel_run_slurm.sh``` script within the git repository.
The absolute path to the ```MPRAmodel.config``` file. 
This command can be executed directly from the terminal.

```
sbatch -J "<library_name>" </path/to/MPRASuite/MPRAmodel/execution/MPRAmodel_run_slurm.sh> </path/to/<library_name>_MPRAmodel_config.file
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
          - YYMMDD-HHMMSS_<library_name>_MPRAmodel/
            - /plots
            - /results
    - logs
      - YYMMDD-HHMMSS_<library_name>_MPRAmatch_cromwell-workflow-logs
      - YYMMDD-HHMMSS_<library_name>_MPRAcount_cromwell-workflow-logs

```
<br>

Detailed explanations of the output files, including their headers and columns, can be found [here](https://github.com/tewhey-lab/MPRASuite/blob/main/MPRAmodel/output_file_explanations.md).

