# MPRAmatch (MPRA Oligo/Barcode Reconstruction)

## Pipeline Flowchart

![Graphical pipeline](../graphics/MPRAmatch_pipeline.svg)


* **Green** objects represent files and information provided to the pipeline, which are directly passed to a script or program.
* **Blue** objects represent calls to the modules mentioned above.
* **Yellow** objects denote scripts specifically designed for the pipeline.
* **Red** objects represent the barcode-oligo dictionary.

## Pipeline Description

This pipeline is implemented in the **Workflow Description Language (WDL)** version 1.0. Further details on WDL can be found [here](https://github.com/openwdl/wdl).

* The process begins with the input of two fastq files generated from the initial barcode-oligo sequencing, which are merged into a single fastq using FLASH2. * Subsequently, barcode and oligo sequences are extracted for each record in the merged fastq, based on the linker sequences between the barcode and oligo, as well as at the end of the oligo.
* The extracted barcode/oligo pair information is then reformatted into FASTA format and provided to MiniMap2, along with the reference fasta.
* The resulting SAM file is parsed to retrieve information such as Oligo name, barcode sequence, CIGAR, and error details for each mapped record.
* Following this, the frequency of each barcode appearing for each oligo is determined.
* The output is directed to preseq for sequencing depth analysis and further parsed to address instances where barcodes map to multiple oligos.

**1. Clone Repo (or Pull Updated Repo):**

```
git clone https://github.com/tewhey-lab/MPRASuite.git && cd MPRASuite
```
<br>

**2. **_QC-check:_** Check the MPRAmatch git repository directory structure :**

To ensure proper cloning of the repository, please examine the directory structure provided below. <br>
(**Note:** There are additional folders for other modules, but for the purpose of this instruction, focus on examining only the MPRAmatch folder.)
<br>

```
    - MPRASuite/
      - example
      - graphics
      - LICENSE.txt
      - README.md
      - MPRAmatch
        - execution
        - MPRAmatch.wdl
        - output_file_explanations.md
        - README.md
        - scripts
        - setup
      - MPRAcount
      - MPRAmodel

```
<br>

**3. Getting the input files ready:**

The user is responsible for manually generating two files namely ```<library_name>_acc_id.txt```and ```MPRAMatch_<library_name>.config```, which are required inputs for the pipeline to proceed. The filenames can be customized by the user, but it is crucial to ensure that the correct files are provided to the pipeline.
<br>

a.  **acc_id.txt:**
<br>

The text file must contain two columns: the first column should include the full paths to delta GFP files (containing the sequences of the reporter gene (e.g., GFP) along with the regulatory elements (e.g., enhancers, promoters) being tested in the MPRA experiment) in fastq.gz format, while the second column should contain the respective <library_name>_read_number. Column headers are not required in the file.

<br>

**Note:** If sequencing for read1 and read2 produces multiple files for both (e.g., multiple lanes or split between plates), ensure that paired files are in the same order between both fastqs when concatenating them into a single read1 file and read2 file (i.e., read1 followed by read2 for the same sample). Failure to maintain the correct order will cause FLASH2 to malfunction and therefore will affect the latter steps. 


```
/path/to/OL111_deltaGFP-A_GT23-13735_GACCAGGA-ATAGCCAG_S91_L007_R1_001.fastq.gz OL111_r1
/path/to/OL111_deltaGFP-A_GT23-13735_GACCAGGA-ATAGCCAG_S91_L007_R2_001.fastq.gz OL111_r2
/path/to/OL111_deltaGFP-B_GT23-13736_TGCTGCTG-ATGAGGAC_S92_L007_R1_001.fastq.gz OL111_r1
/path/to/OL111_deltaGFP-B_GT23-13736_TGCTGCTG-ATGAGGAC_S92_L007_R2_001.fastq.gz OL111_r2
/path/to/OL111_deltaGFP-B_GT23-13736_TGCTGCTG-ATGAGGAC_S92_L008_R1_001.fastq.gz OL111_r1
/path/to/OL111_deltaGFP-B_GT23-13736_TGCTGCTG-ATGAGGAC_S92_L008_R2_001.fastq.gz OL111_r2

```
<br>

b.  **MPRAmatch specific config file:**
<br>

Below is the provided content with parameters that can be substituted as needed. Save the file as, for instance, ```OL111_MPRAmatch.config``` (see example below). <br>
**Note:** When executing the pipeline with built-in settings and parameter values, the variables proj and library_rerun_name may be the same string. However, if analyzing the library for different settings or parameters, library_rerun_name can be modified. Running the pipeline with the updated config file will generate a new output folder with corresponding files.

<br>

```
export gitrepo_dir="/path/to/github/MPRASuite"
export mpra_container="/projects/tewhey-lab/images/MPRASuite-MPRAmatch_MPRAcount_v1.sif"

export acc_file="/path/to/<library_name>_acc_id.txt"
export fasta="/path/to/reference_fasta"
export proj="<library_name>"
export results_dir="<path/to/desired/directory/for/results>" 
export library_rerun_name="<librarary_name or folder_name_for_rerun>"

```
<br>

**4. Run the MPRAmatch pipeline, Default Method:**

The pipeline execution command requires three inputs (refer to the example below):

A user-provided string for the job name (```-J```), which will be added to the slurm standard error and output file names for improved tracking.
The absolute path to the ```MPRAmatch_run.sh``` script within the git repository.
The absolute path to the ```MPRAmatch.config``` file. 
This command can be executed directly from the terminal.

```
# For JAX users:
* Secure shell login to Sumner:

ssh login.sumner.jax.org

sbatch -J "<library_name>" </path/to/MPRASuite/MPRAmatch/execution/MPRAmatch_run.sh> </path/to/<library_name>_MPRAmatch_config.file

# For external users:
bash </path/to/MPRASuite/MPRAmatch/execution/MPRAmatch_run.sh> </path/to/<library_name>_MPRAmatch_config.file

```
<br>

 **5. Explore the output folder:**

The output folder will be generated at the path specified in the config file (parameter ```results_dir```) with a date and time stamp appended to the folder name as a suffix followed by ```<library_name>```. Within the main parent folder, subfolders will be created namely ```execution```, ```inputs```, ```outputs```, and ```slurm_logs```. The pipeline output files for MPRAmatch can be located under ```YYMMDD-HHMMSS_<library_name>/outputs/MPRAmatch/```.
<br>

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
        - <library_name>.merged.match.enh.mapped.barcode.ct.Parsed      #file needed for next module - MPRAcount
    - slurm_logs
      - YYMMDD-HHMMSS_<library_name>_MPRAmatch_cromwell-workflow-logs
```
<br>

Detailed explanations of the output files, including their headers and columns, can be found [here](https://github.com/tewhey-lab/MPRASuite/blob/main/MPRAmatch/output_file_explanations.md).
<br>

The only output file required from the MPRAmatch module for the subsequent MPRAcount pipeline can be located at:
<br>
Parsed File: ```YYMMDD-HHMMSS_<library_name>/outputs/MPRAmatch/<library_name>.merged.match.enh.mapped.barcode.ct.parsed```
<br>

## Run the MPRAmatch pipeline (Step 5), Alternate Method:
<br>
This alternate methood can be implemented when the input values passed to the MPRAmatch WDL pipeline are different than what is set as default (please see below) due to a different library preparation. If the user intends to run or test the WDL pipeline independently for their constructed library, please follow the steps in the documentation located at: https://github.com/tewhey-lab/MPRA_oligo_barcode_pipeline <br>

<br>

```
### Current parameters and values passed to the MPRAmatch WDL pipeline:

 - `MPRAmatch.read_len` : Integer, default to 250. Maximum length (in bp) of reads to be flashed
 - `MPRAmatch.seq_min` : Integer, default to 100. Minimum sequence length to pull for barcode
 - `MPRAmatch.enh_min` : Integer, default to 50. Minimum enhancer length to pull
 - `MPRAmatch.enh_max` : Integer, default to 210. Maximum enhancer length to pull
 - `MPRAmatch.barcode_link` : String, default to "TCTAGA". 6 bases at the barcode end of the sequence linking the barcode and oligo
 - `MPRAmatch.oligo_link` : String, default to "AGTG". 4 bases at the oligo end of the sequence linking the barcode and oligo
 - `MPRAmatch.end_oligo_link` : String, default to "CGTC". 4 bases indicating the oligo is no longer being sequenced
```

